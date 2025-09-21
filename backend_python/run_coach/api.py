"""
Flask API endpoints for Run Coach feature
"""

from flask import Blueprint, request, jsonify
from typing import Dict, List, Tuple
import logging
from datetime import datetime
from .core.cache_manager import cache

from .core.optimizer import RunCoachOptimizer
from .core.pollution_grid import PollutionGrid
from .core.health_risk import HealthRiskCalculator
from .services.air_quality_service import AirQualityService
from .services.route_generator import RouteGenerator
from .services.time_optimizer import TimeWindowOptimizer
from .models import UserProfile, RunningPreferences, RouteRecommendation, RouteSegment

logger = logging.getLogger(__name__)

# Create Blueprint
run_coach_bp = Blueprint('run_coach', __name__, url_prefix='/api/run-coach')

# Lazy initialization of services
_services_initialized = False
air_quality_service = None
pollution_grid = None
route_generator = None
health_risk_calculator = None
time_optimizer = None
route_optimizer = None

def _initialize_services():
    """Initialize services on first request"""
    global _services_initialized, air_quality_service, pollution_grid, route_generator
    global health_risk_calculator, time_optimizer, route_optimizer
    
    if not _services_initialized:
        air_quality_service = AirQualityService()
        # Use 2000m resolution for demo performance (much faster)
        pollution_grid = PollutionGrid(resolution_meters=2000)
        route_generator = RouteGenerator()
        health_risk_calculator = HealthRiskCalculator()
        time_optimizer = TimeWindowOptimizer(air_quality_service)
        route_optimizer = RunCoachOptimizer(pollution_grid)
        _services_initialized = True


@run_coach_bp.route('/health-check', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'Run Coach API',
        'version': '1.0.0'
    })


@run_coach_bp.route('/recommend-route', methods=['POST'])
def recommend_route():
    _initialize_services()
    """
    Get optimized running route recommendation
    
    Request body:
    {
        "location": {"lat": 37.7749, "lon": -122.4194},
        "user_profile": {
            "user_id": "uuid",
            "health_conditions": ["asthma"],
            "age_group": "25-34",
            "fitness_level": "intermediate",
            "resting_hr": 55,
            "avg_hrv": 45
        },
        "preferences": {
            "preferred_distance_m": 5000,
            "max_elevation_gain_m": 100,
            "avoid_traffic": true,
            "prioritize_parks": true
        }
    }
    """
    try:
        data = request.json
        
        # Parse location
        location = (data['location']['lat'], data['location']['lon'])
        
        # Create user profile
        user_profile = UserProfile(
            user_id=data['user_profile']['user_id'],
            health_conditions=data['user_profile'].get('health_conditions', []),
            age_group=data['user_profile'].get('age_group', '25-34'),
            fitness_level=data['user_profile'].get('fitness_level', 'intermediate'),
            resting_hr=data['user_profile'].get('resting_hr'),
            avg_hrv=data['user_profile'].get('avg_hrv')
        )
        
        # Create preferences
        prefs = RunningPreferences(
            preferred_distance_m=data['preferences'].get('preferred_distance_m', 5000),
            max_elevation_gain_m=data['preferences'].get('max_elevation_gain_m', 100),
            avoid_traffic=data['preferences'].get('avoid_traffic', True),
            prioritize_parks=data['preferences'].get('prioritize_parks', True)
        )
        
        # Get current air quality data
        logger.info(f"Fetching air quality data for {location}")
        air_quality_data = air_quality_service.get_current_air_quality(location)
        
        # Update pollution grid only if we have sufficient data
        if len(air_quality_data) >= 3:
            pollution_grid.update_grid(air_quality_data)
        else:
            logger.warning(f"Insufficient air quality data points: {len(air_quality_data)}")
        
        # Generate route candidates
        logger.info("Generating route candidates")
        try:
            candidates = route_generator.generate_route_candidates(
                location,
                data['preferences']
            )
            
            if not candidates:
                # Return mock route if no candidates generated
                logger.warning("No route candidates generated, using mock route")
                return jsonify(_get_mock_route_response(location, prefs))
                
        except Exception as e:
            logger.error(f"Error generating routes: {e}")
            # Return mock route on error
            return jsonify(_get_mock_route_response(location, prefs))
        
        # Optimize route selection
        logger.info(f"Optimizing route selection from {len(candidates)} candidates")
        try:
            best_route = route_optimizer.optimize_route(
                location,
                user_profile,
                prefs,
                candidates
            )
        except ValueError as e:
            logger.error(f"Route optimization error: {e}")
            # Return the first candidate if optimization fails
            if candidates:
                best_route = _convert_candidate_to_recommendation(candidates[0])
            else:
                return jsonify(_get_mock_route_response(location, prefs))
        
        # Get elevation profile
        elevation_profile = route_generator.get_elevation_profile({
            'geometry': best_route.geometry
        })
        
        # Find optimal time windows
        time_windows = time_optimizer.find_optimal_windows(
            location,
            user_profile,
            int(best_route.duration_min),
            lookahead_hours=24
        )
        
        # Format response
        response = {
            'route': {
                'id': best_route.route_id,
                'polyline': best_route.encoded_polyline,
                'distance_m': best_route.total_distance_m,
                'duration_min': best_route.duration_min,
                'elevation_gain_m': best_route.elevation_gain_m,
                'avg_aqi': best_route.avg_aqi,
                'max_aqi': best_route.max_aqi,
                'exposure_score': best_route.exposure_score,
                'green_coverage': best_route.green_coverage,
                'safety_score': best_route.safety_score,
                'elevation_profile': elevation_profile
            },
            'segments': [
                {
                    'start': seg.start_point,
                    'end': seg.end_point,
                    'distance_m': seg.distance_m,
                    'aqi': seg.aqi,
                    'pm25': seg.pm25,
                    'recommended_pace': seg.recommended_pace
                }
                for seg in best_route.segments[:10]  # Limit segments in response
            ],
            'time_windows': [
                {
                    'start': window.start.isoformat(),
                    'end': window.end.isoformat(),
                    'avg_aqi': window.avg_aqi,
                    'quality': 'excellent' if window.avg_aqi < 50 else 'good',
                    'confidence': window.confidence
                }
                for window in time_windows
            ],
            'health_recommendation': health_risk_calculator.get_activity_recommendations(
                user_profile,
                best_route.avg_aqi,
                [w.avg_aqi for w in time_windows]
            )
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in recommend_route: {e}")
        return jsonify({'error': str(e)}), 500


@run_coach_bp.route('/pollution-heatmap', methods=['GET'])
def get_pollution_heatmap():
    _initialize_services()
    """
    Get pollution heatmap for visualization
    
    Query params:
    - lat: latitude
    - lon: longitude
    - radius_km: radius in kilometers
    - pollutant: pollutant type (aqi, pm25, pm10, o3, no2)
    """
    try:
        lat = float(request.args.get('lat', 37.7749))
        lon = float(request.args.get('lon', -122.4194))
        radius_km = float(request.args.get('radius_km', 10))
        pollutant = request.args.get('pollutant', 'aqi')
        
        # Check cache first
        cache_params = {'lat': lat, 'lon': lon, 'radius_km': radius_km, 'pollutant': pollutant}
        cached_data = cache.get('pollution_heatmap', cache_params)
        if cached_data:
            return jsonify(cached_data)
        
        # Get air quality data
        air_quality_data = air_quality_service.get_current_air_quality(
            (lat, lon),
            radius_km
        )
        
        # Update grid
        pollution_grid.update_grid(air_quality_data)
        
        # Get heatmap data
        heatmap_data = pollution_grid.get_pollution_heatmap(pollutant)
        
        if heatmap_data is None:
            # Return empty heatmap if no data
            return jsonify({
                'bounds': {
                    'min_lat': lat - radius_km / 111,
                    'max_lat': lat + radius_km / 111,
                    'min_lon': lon - radius_km / 111,
                    'max_lon': lon + radius_km / 111
                },
                'values': [],
                'uncertainty': [],
                'resolution': 100,
                'pollutant': pollutant,
                'timestamp': None,
                'message': 'No pollution data available for this area'
            })
        
        # Cache the result
        cache.set('pollution_heatmap', cache_params, heatmap_data)
        
        return jsonify(heatmap_data)
        
    except Exception as e:
        logger.error(f"Error in get_pollution_heatmap: {e}")
        return jsonify({'error': str(e)}), 500


@run_coach_bp.route('/optimal-times', methods=['POST'])
def get_optimal_times():
    _initialize_services()
    """
    Get optimal time windows for running
    
    Request body:
    {
        "location": {"lat": 37.7749, "lon": -122.4194},
        "user_profile": {...},
        "duration_minutes": 45,
        "lookahead_hours": 48
    }
    """
    try:
        data = request.json
        location = (data['location']['lat'], data['location']['lon'])
        
        # Create user profile
        user_profile = UserProfile(
            user_id=data['user_profile']['user_id'],
            health_conditions=data['user_profile'].get('health_conditions', []),
            age_group=data['user_profile'].get('age_group', '25-34'),
            fitness_level=data['user_profile'].get('fitness_level', 'intermediate')
        )
        
        # Find optimal windows
        windows = time_optimizer.find_optimal_windows(
            location,
            user_profile,
            data.get('duration_minutes', 45),
            data.get('lookahead_hours', 48),
            min_windows=5
        )
        
        # Format response
        response = {
            'optimal_windows': [
                {
                    'start': w.start.isoformat(),
                    'end': w.end.isoformat(),
                    'avg_aqi': w.avg_aqi,
                    'weather_score': w.weather_score,
                    'confidence': w.confidence,
                    'quality_rating': _get_quality_rating(w.factors['overall_score'])
                }
                for w in windows
            ],
            'personalized_threshold': health_risk_calculator.calculate_personal_threshold(
                user_profile,
                'moderate'
            )
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in get_optimal_times: {e}")
        return jsonify({'error': str(e)}), 500


@run_coach_bp.route('/health-risk-assessment', methods=['POST'])
def assess_health_risk():
    _initialize_services()
    """
    Get personalized health risk assessment
    
    Request body:
    {
        "user_profile": {...},
        "current_aqi": 75,
        "activity_type": "running"
    }
    """
    try:
        data = request.json
        
        # Create user profile
        user_profile = UserProfile(
            user_id=data['user_profile']['user_id'],
            health_conditions=data['user_profile'].get('health_conditions', []),
            age_group=data['user_profile'].get('age_group', '25-34'),
            fitness_level=data['user_profile'].get('fitness_level', 'intermediate'),
            resting_hr=data['user_profile'].get('resting_hr'),
            avg_hrv=data['user_profile'].get('avg_hrv')
        )
        
        # Get personalized threshold
        threshold = health_risk_calculator.calculate_personal_threshold(
            user_profile,
            data.get('activity_type', 'moderate')
        )
        
        # Get exposure budget
        exposure_budget = health_risk_calculator.calculate_exposure_budget(
            user_profile
        )
        
        # Get activity recommendations
        recommendations = health_risk_calculator.get_activity_recommendations(
            user_profile,
            data.get('current_aqi', 50),
            []  # No forecast for simple assessment
        )
        
        response = {
            'personal_threshold': threshold,
            'current_risk_level': _assess_risk_level(
                data.get('current_aqi', 50),
                threshold
            ),
            'exposure_budget': exposure_budget,
            'recommendations': recommendations
        }
        
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in assess_health_risk: {e}")
        return jsonify({'error': str(e)}), 500


@run_coach_bp.route('/weekly-schedule', methods=['POST'])
def get_weekly_schedule():
    _initialize_services()
    """
    Get suggested weekly running schedule
    
    Request body:
    {
        "location": {"lat": 37.7749, "lon": -122.4194},
        "user_profile": {...},
        "runs_per_week": 3
    }
    """
    try:
        data = request.json
        location = (data['location']['lat'], data['location']['lon'])
        
        # Create user profile
        user_profile = UserProfile(
            user_id=data['user_profile']['user_id'],
            health_conditions=data['user_profile'].get('health_conditions', []),
            age_group=data['user_profile'].get('age_group', '25-34')
        )
        
        # Get weekly schedule
        schedule = time_optimizer.suggest_weekly_schedule(
            location,
            user_profile,
            data.get('runs_per_week', 3)
        )
        
        # Format response
        response = {
            'weekly_schedule': {}
        }
        
        for day, windows in schedule.items():
            if windows:
                response['weekly_schedule'][day] = {
                    'recommended': True,
                    'best_time': {
                        'start': windows[0].start.isoformat(),
                        'end': windows[0].end.isoformat(),
                        'avg_aqi': windows[0].avg_aqi
                    }
                }
            else:
                response['weekly_schedule'][day] = {
                    'recommended': False,
                    'reason': 'Rest day'
                }
                
        return jsonify(response)
        
    except Exception as e:
        logger.error(f"Error in get_weekly_schedule: {e}")
        return jsonify({'error': str(e)}), 500


def _get_quality_rating(score: float) -> str:
    """Convert numerical score to quality rating"""
    if score >= 0.8:
        return "excellent"
    elif score >= 0.6:
        return "good"
    elif score >= 0.4:
        return "fair"
    else:
        return "poor"


def _assess_risk_level(aqi: float, threshold: float) -> str:
    """Assess risk level based on AQI and personal threshold"""
    ratio = aqi / threshold
    
    if ratio < 0.5:
        return "very_low"
    elif ratio < 0.75:
        return "low"
    elif ratio < 1.0:
        return "moderate"
    elif ratio < 1.5:
        return "high"
    else:
        return "very_high"


def _get_mock_route_response(location: Tuple[float, float], prefs: RunningPreferences) -> Dict:
    """Generate mock route response for testing/fallback"""
    lat, lon = location
    
    # Create a simple circular route
    import math
    points = []
    radius = prefs.preferred_distance_m / (2 * math.pi) / 111000  # Convert to degrees
    
    for i in range(8):
        angle = (i / 8) * 2 * math.pi
        points.append([
            lat + radius * math.cos(angle),
            lon + radius * math.sin(angle)
        ])
    points.append(points[0])  # Close the loop
    
    route = RouteRecommendation(
        route_id='mock_route_1',
        geometry=points,
        encoded_polyline='mock_polyline',
        segments=[
            RouteSegment(
                start_point=points[i],
                end_point=points[i+1],
                distance_m=prefs.preferred_distance_m / 8,
                aqi=40 + i * 2,
                pm25=12 + i,
                elevation_change_m=5,
                recommended_pace='moderate'
            )
            for i in range(min(3, len(points)-1))
        ],
        total_distance_m=prefs.preferred_distance_m,
        duration_min=prefs.preferred_distance_m / 150,  # ~9km/h pace
        avg_aqi=45,
        max_aqi=55,
        exposure_score=0.3,
        elevation_gain_m=25,
        green_coverage=0.4,
        safety_score=0.8
    )
    
    return {
        'route': {
            'id': route.route_id,
            'polyline': route.encoded_polyline,
            'distance_m': route.total_distance_m,
            'duration_min': route.duration_min,
            'elevation_gain_m': route.elevation_gain_m,
            'avg_aqi': route.avg_aqi,
            'max_aqi': route.max_aqi,
            'exposure_score': route.exposure_score,
            'green_coverage': route.green_coverage,
            'safety_score': route.safety_score,
            'elevation_profile': [10, 15, 20, 15, 10]
        },
        'segments': [
            {
                'start': seg.start_point,
                'end': seg.end_point,
                'distance_m': seg.distance_m,
                'aqi': seg.aqi,
                'pm25': seg.pm25,
                'recommended_pace': seg.recommended_pace
            }
            for seg in route.segments
        ],
        'time_windows': [
            {
                'start': datetime.now().replace(hour=6, minute=0).isoformat(),
                'end': datetime.now().replace(hour=7, minute=0).isoformat(),
                'avg_aqi': 35,
                'quality': 'excellent',
                'confidence': 0.9
            },
            {
                'start': datetime.now().replace(hour=17, minute=0).isoformat(),
                'end': datetime.now().replace(hour=18, minute=0).isoformat(),
                'avg_aqi': 42,
                'quality': 'good',
                'confidence': 0.85
            }
        ],
        'health_recommendation': {
            'current': {
                'status': 'good',
                'advice': 'Good conditions for outdoor activities'
            }
        }
    }


def _convert_candidate_to_recommendation(candidate: Dict) -> RouteRecommendation:
    """Convert route candidate to RouteRecommendation"""
    return RouteRecommendation(
        route_id=candidate.get('route_id', 'generated'),
        geometry=candidate['geometry'],
        encoded_polyline=candidate.get('encoded_polyline', ''),
        segments=[],  # Will be filled later
        total_distance_m=candidate['distance_m'],
        duration_min=candidate['duration_min'],
        avg_aqi=45,  # Default values
        max_aqi=55,
        exposure_score=0.3,
        elevation_gain_m=candidate.get('elevation_gain_m', 0),
        green_coverage=candidate.get('green_coverage', 0.5),
        safety_score=candidate.get('safety_score', 0.8)
    )