from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import os
import logging
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Import insights components
from insights.insight_generator import HealthInsightGenerator
from insights.models.insight_models import InsightRequest
from database_manager import DatabaseManager

app = Flask(__name__)
CORS(app)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'health_monitoring'),
    'user': os.getenv('DB_USER', 'postgres'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'port': int(os.getenv('DB_PORT', 5432))
}

def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)

# Initialize database manager and insight generator
db_manager = DatabaseManager(DB_CONFIG)
insight_generator = HealthInsightGenerator(
    db_manager=db_manager,
    gemini_api_key=os.getenv('GEMINI_API_KEY')
)

@app.route('/api/health-check', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/api/users/<user_id>/heart-rate', methods=['GET'])
def get_heart_rate_data(user_id):
    """Get heart rate data for Flutter app"""
    try:
        start_date = request.args.get('start_date', 
                                     (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d'))
        end_date = request.args.get('end_date', 
                                   datetime.now().strftime('%Y-%m-%d'))
        limit = int(request.args.get('limit', 1000))
        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT datetime, heart_rate
                    FROM heart_rate_data hr
                    JOIN users u ON hr.user_id = u.id
                    WHERE u.fitbit_user_id = %s
                    AND hr.datetime::date BETWEEN %s AND %s
                    ORDER BY hr.datetime DESC
                    LIMIT %s
                """, (user_id, start_date, end_date, limit))
                
                results = cursor.fetchall()
                
                return jsonify({
                    'success': True,
                    'user_id': user_id,
                    'data': [dict(row) for row in results],
                    'count': len(results)
                })
                
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/users/<user_id>/activity', methods=['GET'])
def get_activity_data(user_id):
    """Get activity data for Flutter app"""
    try:
        days = int(request.args.get('days', 7))
        start_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                cursor.execute("""
                    SELECT datetime, steps, distance, calories
                    FROM activity_data a
                    JOIN users u ON a.user_id = u.id
                    WHERE u.fitbit_user_id = %s
                    AND a.datetime::date >= %s
                    ORDER BY a.datetime DESC
                """, (user_id, start_date))
                
                results = cursor.fetchall()
                
                return jsonify({
                    'success': True,
                    'user_id': user_id,
                    'data': [dict(row) for row in results],
                    'count': len(results)
                })
                
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/users/<user_id>/health-summary', methods=['GET'])
def get_health_summary(user_id):
    """Get aggregated health summary for Flutter dashboard"""
    try:
        days = int(request.args.get('days', 7))
        
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=RealDictCursor) as cursor:
                # Get recent health averages
                cursor.execute("""
                    WITH recent_data AS (
                        SELECT 
                            AVG(a.steps) as avg_steps,
                            AVG(a.calories) as avg_calories,
                            AVG(hr.heart_rate) as avg_heart_rate,
                            AVG(s.spo2) as avg_spo2,
                            AVG(br.full_sleep_br) as avg_breathing_rate
                        FROM users u
                        LEFT JOIN activity_data a ON u.id = a.user_id 
                            AND a.datetime >= CURRENT_TIMESTAMP - INTERVAL '%s days'
                        LEFT JOIN heart_rate_data hr ON u.id = hr.user_id 
                            AND hr.datetime >= CURRENT_TIMESTAMP - INTERVAL '%s days'
                        LEFT JOIN spo2_data s ON u.id = s.user_id 
                            AND s.datetime >= CURRENT_TIMESTAMP - INTERVAL '%s days'
                        LEFT JOIN breathing_rate_data br ON u.id = br.user_id 
                            AND br.date >= CURRENT_DATE - INTERVAL '%s days'
                        WHERE u.fitbit_user_id = %s
                    )
                    SELECT * FROM recent_data
                """, (days, days, days, days, user_id))
                
                summary = cursor.fetchone()
                
                if summary:
                    return jsonify({
                        'success': True,
                        'user_id': user_id,
                        'period_days': days,
                        'summary': dict(summary)
                    })
                else:
                    return jsonify({
                        'success': False, 
                        'error': 'No data found for user'
                    }), 404
                    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

# Natural Language Health Insights Endpoints
@app.route('/api/insights/daily-summary', methods=['POST'])
def get_daily_health_summary():
    """Generate daily health summary with air quality context"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        air_quality_data = data.get('air_quality', {})
        user_profile = data.get('user_profile', {})
        
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        # Generate insight
        response = insight_generator.generate_daily_summary(
            user_id=user_id,
            air_quality_data=air_quality_data,
            user_profile=user_profile
        )
        
        return jsonify({
            'success': response.success,
            'insight': response.insight_text,
            'confidence_score': response.confidence_score,
            'warnings': response.warnings,
            'health_summary': response.health_metrics_summary,
            'timestamp': response.timestamp.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in daily summary endpoint: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/insights/activity-recommendation', methods=['POST'])
def get_activity_recommendation():
    """Get recommendation for specific activity"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        activity_type = data.get('activity_type')
        air_quality_data = data.get('air_quality', {})
        user_profile = data.get('user_profile', {})
        
        if not user_id or not activity_type:
            return jsonify({'success': False, 'error': 'User ID and activity type required'}), 400
        
        response = insight_generator.generate_activity_recommendation(
            user_id=user_id,
            activity_type=activity_type,
            air_quality_data=air_quality_data,
            user_profile=user_profile
        )
        
        return jsonify({
            'success': response.success,
            'insight': response.insight_text,
            'confidence_score': response.confidence_score,
            'warnings': response.warnings,
            'timestamp': response.timestamp.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in activity recommendation endpoint: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/insights/ask-question', methods=['POST'])
def ask_health_question():
    """Answer specific health questions"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        question = data.get('question')
        context = data.get('context', {})
        
        if not user_id or not question:
            return jsonify({'success': False, 'error': 'User ID and question required'}), 400
        
        response = insight_generator.answer_health_question(
            user_id=user_id,
            question=question,
            context=context
        )
        
        return jsonify({
            'success': response.success,
            'insight': response.insight_text,
            'confidence_score': response.confidence_score,
            'warnings': response.warnings,
            'timestamp': response.timestamp.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in health question endpoint: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/insights/health-patterns', methods=['GET'])
def get_health_patterns():
    """Get insights about health patterns and trends"""
    try:
        user_id = request.args.get('user_id')
        
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        response = insight_generator.generate_pattern_insight(user_id=user_id)
        
        return jsonify({
            'success': response.success,
            'insight': response.insight_text,
            'confidence_score': response.confidence_score,
            'warnings': response.warnings,
            'timestamp': response.timestamp.isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error in health patterns endpoint: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5001)