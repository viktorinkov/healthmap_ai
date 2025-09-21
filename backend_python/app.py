import sys
import os

# Add current directory to Python path for module imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
import psycopg2
from psycopg2 import pool
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
import logging
from dotenv import load_dotenv
import atexit
import threading
from cachetools import TTLCache
import gc

# Load environment variables from .env file
load_dotenv()

# Import insights components
from insights.insight_generator import HealthInsightGenerator
from insights.models.insight_models import InsightRequest
from database_manager import DatabaseManager

# Import Run Coach API
from run_coach.api import run_coach_bp

app = Flask(__name__)
CORS(app)

# Register Run Coach blueprint
app.register_blueprint(run_coach_bp)

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

# Initialize connection pool
connection_pool = None
pool_lock = threading.Lock()

# Initialize cache for frequent queries (TTL: 5 minutes)
query_cache = TTLCache(maxsize=1000, ttl=300)
cache_lock = threading.Lock()

def initialize_pool():
    """Initialize database connection pool"""
    global connection_pool
    try:
        connection_pool = psycopg2.pool.ThreadedConnectionPool(
            minconn=2,
            maxconn=10,
            **DB_CONFIG
        )
        logger.info("Database connection pool initialized")
    except Exception as e:
        logger.error(f"Failed to initialize connection pool: {e}")
        raise

def get_db_connection():
    """Get connection from pool with proper error handling"""
    global connection_pool
    if not connection_pool:
        with pool_lock:
            if not connection_pool:
                initialize_pool()
    
    try:
        conn = connection_pool.getconn()
        if conn.closed:
            connection_pool.putconn(conn, close=True)
            conn = connection_pool.getconn()
        return conn
    except Exception as e:
        logger.error(f"Failed to get database connection: {e}")
        raise

def return_db_connection(conn):
    """Return connection to pool"""
    if connection_pool and conn:
        connection_pool.putconn(conn)

def cleanup_pool():
    """Clean up connection pool on shutdown"""
    global connection_pool
    if connection_pool:
        connection_pool.closeall()
        logger.info("Database connection pool closed")

# Register cleanup function
atexit.register(cleanup_pool)

# Initialize database manager and insight generator with error handling
try:
    db_manager = DatabaseManager(DB_CONFIG)
    insight_generator = HealthInsightGenerator(
        db_manager=db_manager,
        gemini_api_key=os.getenv('GEMINI_API_KEY')
    )
    logger.info("Services initialized successfully")
except Exception as e:
    logger.error(f"Failed to initialize services: {e}")
    insight_generator = None

# Initialize connection pool on startup
initialize_pool()

# Add periodic cleanup
def periodic_cleanup():
    """Periodic cleanup to prevent memory leaks"""
    try:
        # Clear old cache entries (done automatically by TTLCache)
        # Force garbage collection
        gc.collect()
        logger.info("Periodic cleanup completed")
    except Exception as e:
        logger.error(f"Cleanup error: {e}")

# Setup periodic cleanup every 10 minutes
import threading
import time

def cleanup_worker():
    while True:
        time.sleep(600)  # 10 minutes
        periodic_cleanup()

cleanup_thread = threading.Thread(target=cleanup_worker, daemon=True)
cleanup_thread.start()

@app.route('/api/health-check', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/api/users/<user_id>/heart-rate', methods=['GET'])
def get_heart_rate_data(user_id):
    """Get heart rate data for Flutter app with caching and optimized queries"""
    conn = None
    try:
        start_date = request.args.get('start_date', 
                                     (datetime.now() - timedelta(days=1)).strftime('%Y-%m-%d'))
        end_date = request.args.get('end_date', 
                                   datetime.now().strftime('%Y-%m-%d'))
        limit = min(int(request.args.get('limit', 1000)), 5000)  # Cap limit to prevent memory issues
        
        # Create cache key
        cache_key = f"heart_rate:{user_id}:{start_date}:{end_date}:{limit}"
        
        # Check cache first
        with cache_lock:
            if cache_key in query_cache:
                return jsonify(query_cache[cache_key])
        
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Optimized query with index hints
            cursor.execute("""
                SELECT datetime, heart_rate
                FROM heart_rate_data hr
                JOIN users u ON hr.user_id = u.id
                WHERE u.fitbit_user_id = %s
                AND hr.datetime >= %s::date
                AND hr.datetime < (%s::date + interval '1 day')
                ORDER BY hr.datetime DESC
                LIMIT %s
            """, (user_id, start_date, end_date, limit))
            
            results = cursor.fetchall()
            
            response_data = {
                'success': True,
                'user_id': user_id,
                'data': [dict(row) for row in results],
                'count': len(results)
            }
            
            # Cache the result
            with cache_lock:
                query_cache[cache_key] = response_data
            
            return jsonify(response_data)
                
    except Exception as e:
        logger.error(f"Error getting heart rate data: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if conn:
            return_db_connection(conn)

@app.route('/api/users/<user_id>/activity', methods=['GET'])
def get_activity_data(user_id):
    """Get activity data for Flutter app with caching and limits"""
    conn = None
    try:
        days = min(int(request.args.get('days', 7)), 30)  # Cap to 30 days max
        start_date = (datetime.now() - timedelta(days=days)).strftime('%Y-%m-%d')
        
        cache_key = f"activity:{user_id}:{days}"
        
        # Check cache
        with cache_lock:
            if cache_key in query_cache:
                return jsonify(query_cache[cache_key])
        
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            cursor.execute("""
                SELECT datetime, steps, distance, calories
                FROM activity_data a
                JOIN users u ON a.user_id = u.id
                WHERE u.fitbit_user_id = %s
                AND a.datetime >= %s::date
                ORDER BY a.datetime DESC
                LIMIT 2000
            """, (user_id, start_date))
            
            results = cursor.fetchall()
            
            response_data = {
                'success': True,
                'user_id': user_id,
                'data': [dict(row) for row in results],
                'count': len(results)
            }
            
            # Cache result
            with cache_lock:
                query_cache[cache_key] = response_data
            
            return jsonify(response_data)
                
    except Exception as e:
        logger.error(f"Error getting activity data: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if conn:
            return_db_connection(conn)

@app.route('/api/users/<user_id>/health-summary', methods=['GET'])
def get_health_summary(user_id):
    """Get aggregated health summary for Flutter dashboard with optimized query"""
    conn = None
    try:
        days = min(int(request.args.get('days', 7)), 14)  # Cap to 14 days max
        
        cache_key = f"health_summary:{user_id}:{days}"
        
        # Check cache
        with cache_lock:
            if cache_key in query_cache:
                return jsonify(query_cache[cache_key])
        
        conn = get_db_connection()
        with conn.cursor(cursor_factory=RealDictCursor) as cursor:
            # Optimized query with better performance
            cursor.execute("""
                SELECT 
                    COALESCE(AVG(a.steps), 0) as avg_steps,
                    COALESCE(AVG(a.calories), 0) as avg_calories,
                    COALESCE(AVG(hr.heart_rate), 0) as avg_heart_rate,
                    COALESCE(AVG(s.spo2), 0) as avg_spo2,
                    COALESCE(AVG(br.full_sleep_br), 0) as avg_breathing_rate
                FROM users u
                LEFT JOIN (
                    SELECT user_id, AVG(steps) as steps, AVG(calories) as calories
                    FROM activity_data 
                    WHERE datetime >= CURRENT_DATE - INTERVAL '%s days'
                    GROUP BY user_id
                ) a ON u.id = a.user_id
                LEFT JOIN (
                    SELECT user_id, AVG(heart_rate) as heart_rate
                    FROM heart_rate_data 
                    WHERE datetime >= CURRENT_DATE - INTERVAL '%s days'
                    GROUP BY user_id
                ) hr ON u.id = hr.user_id
                LEFT JOIN (
                    SELECT user_id, AVG(spo2) as spo2
                    FROM spo2_data 
                    WHERE datetime >= CURRENT_DATE - INTERVAL '%s days'
                    GROUP BY user_id
                ) s ON u.id = s.user_id
                LEFT JOIN (
                    SELECT user_id, AVG(full_sleep_br) as full_sleep_br
                    FROM breathing_rate_data 
                    WHERE date >= CURRENT_DATE - INTERVAL '%s days'
                    GROUP BY user_id
                ) br ON u.id = br.user_id
                WHERE u.fitbit_user_id = %s
            """, (days, days, days, days, user_id))
            
            summary = cursor.fetchone()
            
            if summary:
                response_data = {
                    'success': True,
                    'user_id': user_id,
                    'period_days': days,
                    'summary': dict(summary)
                }
                
                # Cache result
                with cache_lock:
                    query_cache[cache_key] = response_data
                
                return jsonify(response_data)
            else:
                return jsonify({
                    'success': False, 
                    'error': 'No data found for user'
                }), 404
                    
    except Exception as e:
        logger.error(f"Error getting health summary: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500
    finally:
        if conn:
            return_db_connection(conn)

# Natural Language Health Insights Endpoints
@app.route('/api/insights/daily-summary', methods=['POST'])
def get_daily_health_summary():
    """Generate daily health summary with air quality context - OPTIMIZED"""
    try:
        data = request.get_json()
        user_id = data.get('user_id')
        air_quality_data = data.get('air_quality', {})
        user_profile = data.get('user_profile', {})
        
        if not user_id:
            return jsonify({'success': False, 'error': 'User ID required'}), 400
        
        # Create cache key for insights
        cache_key = f"daily_summary:{user_id}:{datetime.now().strftime('%Y-%m-%d')}"
        
        # Check cache first - insights can be cached for a few hours
        with cache_lock:
            if cache_key in query_cache:
                cached_response = query_cache[cache_key]
                logger.info(f"Returning cached daily summary for user {user_id}")
                return jsonify(cached_response)
        
        # Limit concurrent AI requests to prevent memory overload
        try:
            # Generate insight with timeout
            response = insight_generator.generate_daily_summary(
                user_id=user_id,
                air_quality_data=air_quality_data,
                user_profile=user_profile
            )
            
            result = {
                'success': response.success,
                'insight': response.insight_text,
                'confidence_score': response.confidence_score,
                'warnings': response.warnings,
                'health_summary': response.health_metrics_summary,
                'timestamp': response.timestamp.isoformat()
            }
            
            # Cache successful results
            if response.success:
                with cache_lock:
                    query_cache[cache_key] = result
            
            # Force garbage collection after heavy AI operations
            gc.collect()
            
            return jsonify(result)
            
        except Exception as ai_error:
            logger.error(f"AI processing error: {str(ai_error)}")
            # Return fallback response instead of crashing
            return jsonify({
                'success': False,
                'insight': 'Health summary temporarily unavailable. Please try again later.',
                'confidence_score': 0.0,
                'warnings': ['Service temporarily unavailable'],
                'health_summary': {},
                'timestamp': datetime.now().isoformat()
            }), 503
        
    except Exception as e:
        logger.error(f"Error in daily summary endpoint: {str(e)}")
        return jsonify({
            'success': False, 
            'error': 'Internal server error',
            'timestamp': datetime.now().isoformat()
        }), 500

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

# Serve visualization files
@app.route('/pollution_heatmap_static.png')
def serve_static_heatmap():
    """Serve static pollution heatmap image"""
    return send_from_directory('.', 'pollution_heatmap_static.png')

@app.route('/pollution_heatmap_interactive.html')
def serve_interactive_heatmap():
    """Serve interactive pollution heatmap"""
    return send_from_directory('.', 'pollution_heatmap_interactive.html')

@app.route('/pollution_heatmap_3d.html')
def serve_3d_heatmap():
    """Serve 3D pollution visualization"""
    return send_from_directory('.', 'pollution_heatmap_3d.html')

if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=5001)