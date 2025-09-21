"""
Personalized health risk assessment for outdoor activities
"""

import numpy as np
from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta
import logging

from ..models import UserProfile, PollutantData

logger = logging.getLogger(__name__)


class HealthRiskCalculator:
    """
    Calculate personalized health risk thresholds and exposure budgets
    based on user health conditions, fitness level, and biometric data
    """
    
    # Base AQI thresholds for different activity levels
    BASE_THRESHOLDS = {
        'rest': 150,
        'light': 100,
        'moderate': 75,
        'vigorous': 50
    }
    
    # Condition-specific risk multipliers
    CONDITION_MULTIPLIERS = {
        'asthma': 0.6,
        'copd': 0.5,
        'heart_disease': 0.65,
        'allergies': 0.8,
        'pregnancy': 0.7,
        'diabetes': 0.85,
        'hypertension': 0.8
    }
    
    # Age group risk factors
    AGE_MULTIPLIERS = {
        '0-12': 0.6,
        '13-17': 0.8,
        '18-24': 1.0,
        '25-34': 1.0,
        '35-44': 0.95,
        '45-54': 0.9,
        '55-64': 0.8,
        '65+': 0.7
    }
    
    def __init__(self):
        self.exposure_history = {}
        
    def calculate_personal_threshold(
        self, 
        user_profile: UserProfile,
        activity_level: str = 'moderate'
    ) -> float:
        """
        Calculate personalized AQI threshold for safe activity
        
        Args:
            user_profile: User health and fitness profile
            activity_level: Activity intensity level
            
        Returns:
            Personalized AQI threshold
        """
        # Start with base threshold
        base_threshold = self.BASE_THRESHOLDS.get(activity_level, 75)
        
        # Apply health condition multipliers
        condition_multiplier = 1.0
        for condition in user_profile.health_conditions:
            if condition in self.CONDITION_MULTIPLIERS:
                condition_multiplier = min(
                    condition_multiplier,
                    self.CONDITION_MULTIPLIERS[condition]
                )
                
        # Apply age group multiplier
        age_multiplier = self.AGE_MULTIPLIERS.get(user_profile.age_group, 0.9)
        
        # Apply fitness level adjustments
        fitness_multiplier = self._calculate_fitness_multiplier(user_profile)
        
        # Apply HRV-based recovery status
        hrv_multiplier = self._calculate_hrv_multiplier(user_profile)
        
        # Calculate final threshold
        threshold = base_threshold * condition_multiplier * age_multiplier * fitness_multiplier * hrv_multiplier
        
        logger.info(f"Personal threshold: {threshold:.1f} (base: {base_threshold}, "
                   f"conditions: {condition_multiplier:.2f}, age: {age_multiplier:.2f}, "
                   f"fitness: {fitness_multiplier:.2f}, HRV: {hrv_multiplier:.2f})")
                   
        return threshold
        
    def _calculate_fitness_multiplier(self, user_profile: UserProfile) -> float:
        """Calculate fitness-based adjustment factor"""
        
        multiplier = 1.0
        
        # Adjust based on VO2 max estimate
        if user_profile.vo2_max_estimate:
            # Higher VO2 max = better pollution tolerance
            # Average VO2 max ~40, good ~50, excellent ~60
            if user_profile.vo2_max_estimate < 35:
                multiplier *= 0.85
            elif user_profile.vo2_max_estimate > 50:
                multiplier *= 1.15
            elif user_profile.vo2_max_estimate > 60:
                multiplier *= 1.25
                
        # Adjust based on resting heart rate
        if user_profile.resting_hr:
            # Lower resting HR = better fitness
            if user_profile.resting_hr > 80:
                multiplier *= 0.9
            elif user_profile.resting_hr < 55:
                multiplier *= 1.1
            elif user_profile.resting_hr < 45:
                multiplier *= 1.2
                
        # Cap multiplier
        return min(max(multiplier, 0.8), 1.3)
        
    def _calculate_hrv_multiplier(self, user_profile: UserProfile) -> float:
        """Calculate HRV-based recovery status multiplier"""
        
        if not user_profile.avg_hrv:
            return 1.0
            
        # HRV varies by individual, use relative values
        # Higher HRV = better recovery
        hrv = user_profile.avg_hrv
        
        if hrv < 30:
            return 0.85  # Poor recovery
        elif hrv < 50:
            return 0.95  # Moderate recovery
        elif hrv > 70:
            return 1.1   # Excellent recovery
        else:
            return 1.0
            
    def calculate_exposure_budget(
        self,
        user_profile: UserProfile,
        time_window_days: int = 7
    ) -> Dict[str, float]:
        """
        Calculate cumulative exposure budget over time window
        
        Returns dict with:
        - daily_limit: Maximum daily exposure score
        - weekly_limit: Maximum weekly cumulative exposure
        - current_usage: Current exposure in window
        - remaining_budget: Available exposure budget
        """
        # Base exposure limits (arbitrary units)
        daily_base = 1000
        weekly_base = 5000
        
        # Apply personal risk factors
        risk_factor = self.calculate_personal_threshold(user_profile, 'moderate') / 75
        
        daily_limit = daily_base * risk_factor
        weekly_limit = weekly_base * risk_factor
        
        # Calculate current usage from history
        current_usage = self._calculate_recent_exposure(
            user_profile.user_id,
            time_window_days
        )
        
        remaining_budget = max(0, weekly_limit - current_usage)
        
        return {
            'daily_limit': daily_limit,
            'weekly_limit': weekly_limit,
            'current_usage': current_usage,
            'remaining_budget': remaining_budget,
            'usage_percentage': (current_usage / weekly_limit) * 100
        }
        
    def _calculate_recent_exposure(self, user_id: str, days: int) -> float:
        """Calculate cumulative exposure over recent days"""
        
        if user_id not in self.exposure_history:
            return 0.0
            
        cutoff_date = datetime.now() - timedelta(days=days)
        recent_exposure = 0.0
        
        for date, exposure in self.exposure_history[user_id].items():
            if date >= cutoff_date:
                recent_exposure += exposure
                
        return recent_exposure
        
    def update_exposure_history(
        self, 
        user_id: str,
        exposure_score: float,
        date: Optional[datetime] = None
    ):
        """Update user's exposure history"""
        
        if date is None:
            date = datetime.now()
            
        if user_id not in self.exposure_history:
            self.exposure_history[user_id] = {}
            
        # Store by date
        date_key = date.date()
        if date_key in self.exposure_history[user_id]:
            self.exposure_history[user_id][date_key] += exposure_score
        else:
            self.exposure_history[user_id][date_key] = exposure_score
            
    def get_activity_recommendations(
        self,
        user_profile: UserProfile,
        current_aqi: float,
        forecast_aqi: List[float]
    ) -> Dict:
        """
        Get personalized activity recommendations based on conditions
        
        Args:
            user_profile: User health profile
            current_aqi: Current AQI at location
            forecast_aqi: Forecasted AQI for next hours
            
        Returns:
            Dict with recommendations for different activity types
        """
        threshold = self.calculate_personal_threshold(user_profile, 'moderate')
        recommendations = {}
        
        # Current conditions
        if current_aqi < threshold * 0.5:
            current_status = "excellent"
            current_advice = "Perfect conditions for outdoor exercise"
        elif current_aqi < threshold * 0.75:
            current_status = "good"
            current_advice = "Good conditions for outdoor activities"
        elif current_aqi < threshold:
            current_status = "moderate"
            current_advice = "Consider shorter duration or reduced intensity"
        elif current_aqi < threshold * 1.5:
            current_status = "poor"
            current_advice = "Limit outdoor activity, consider indoor alternatives"
        else:
            current_status = "hazardous"
            current_advice = "Avoid outdoor exercise, stay indoors"
            
        recommendations['current'] = {
            'status': current_status,
            'advice': current_advice,
            'aqi': current_aqi,
            'threshold': threshold
        }
        
        # Find optimal windows in forecast
        optimal_windows = self._find_optimal_windows(forecast_aqi, threshold)
        recommendations['forecast_windows'] = optimal_windows
        
        # Activity-specific recommendations
        activities = {
            'running': self._get_running_recommendation(current_aqi, threshold, user_profile),
            'cycling': self._get_cycling_recommendation(current_aqi, threshold, user_profile),
            'walking': self._get_walking_recommendation(current_aqi, threshold, user_profile),
            'outdoor_sports': self._get_sports_recommendation(current_aqi, threshold, user_profile)
        }
        
        recommendations['activities'] = activities
        
        return recommendations
        
    def _find_optimal_windows(
        self, 
        forecast_aqi: List[float],
        threshold: float,
        min_duration_hours: int = 1
    ) -> List[Dict]:
        """Find time windows with AQI below threshold"""
        
        windows = []
        start_idx = None
        
        for i, aqi in enumerate(forecast_aqi):
            if aqi < threshold:
                if start_idx is None:
                    start_idx = i
            else:
                if start_idx is not None and (i - start_idx) >= min_duration_hours:
                    windows.append({
                        'start_hour': start_idx,
                        'end_hour': i,
                        'duration_hours': i - start_idx,
                        'avg_aqi': np.mean(forecast_aqi[start_idx:i]),
                        'quality': 'good' if np.mean(forecast_aqi[start_idx:i]) < threshold * 0.75 else 'moderate'
                    })
                start_idx = None
                
        # Check last window
        if start_idx is not None and (len(forecast_aqi) - start_idx) >= min_duration_hours:
            windows.append({
                'start_hour': start_idx,
                'end_hour': len(forecast_aqi),
                'duration_hours': len(forecast_aqi) - start_idx,
                'avg_aqi': np.mean(forecast_aqi[start_idx:]),
                'quality': 'good' if np.mean(forecast_aqi[start_idx:]) < threshold * 0.75 else 'moderate'
            })
            
        return windows
        
    def _get_running_recommendation(self, aqi: float, threshold: float, user_profile: UserProfile) -> Dict:
        """Get running-specific recommendations"""
        
        if aqi < threshold * 0.5:
            return {
                'recommended': True,
                'intensity': 'normal',
                'duration': 'normal',
                'notes': 'Excellent conditions for running'
            }
        elif aqi < threshold * 0.75:
            return {
                'recommended': True,
                'intensity': 'moderate',
                'duration': 'normal',
                'notes': 'Good conditions, stay hydrated'
            }
        elif aqi < threshold:
            return {
                'recommended': True,
                'intensity': 'easy',
                'duration': 'reduced',
                'notes': 'Run at easy pace, consider shorter route'
            }
        else:
            return {
                'recommended': False,
                'intensity': None,
                'duration': None,
                'notes': 'Consider indoor treadmill or postpone'
            }
            
    def _get_cycling_recommendation(self, aqi: float, threshold: float, user_profile: UserProfile) -> Dict:
        """Get cycling-specific recommendations"""
        
        # Cycling typically involves higher ventilation rates
        adjusted_threshold = threshold * 0.85
        
        if aqi < adjusted_threshold * 0.5:
            return {
                'recommended': True,
                'intensity': 'normal',
                'notes': 'Great conditions for cycling'
            }
        elif aqi < adjusted_threshold:
            return {
                'recommended': True,
                'intensity': 'moderate',
                'notes': 'Moderate pace recommended, avoid high-traffic areas'
            }
        else:
            return {
                'recommended': False,
                'intensity': None,
                'notes': 'Indoor cycling recommended'
            }
            
    def _get_walking_recommendation(self, aqi: float, threshold: float, user_profile: UserProfile) -> Dict:
        """Get walking-specific recommendations"""
        
        # Walking has lower intensity, more tolerant of pollution
        adjusted_threshold = threshold * 1.3
        
        if aqi < adjusted_threshold:
            return {
                'recommended': True,
                'duration': 'normal',
                'notes': 'Walking is fine, choose parks if available'
            }
        else:
            return {
                'recommended': False,
                'duration': None,
                'notes': 'Limit time outdoors'
            }
            
    def _get_sports_recommendation(self, aqi: float, threshold: float, user_profile: UserProfile) -> Dict:
        """Get outdoor sports recommendations"""
        
        if aqi < threshold * 0.6:
            return {
                'recommended': True,
                'notes': 'Good conditions for outdoor sports'
            }
        elif aqi < threshold:
            return {
                'recommended': 'limited',
                'notes': 'Light activities only, frequent breaks'
            }
        else:
            return {
                'recommended': False,
                'notes': 'Move activities indoors'
            }