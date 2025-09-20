"""
Health Data Analysis Engine for generating insights from Fitbit data
"""
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

from insights.models.health_metrics import HealthMetrics


class HealthDataAnalyzer:
    """Analyzes raw health data to extract meaningful patterns"""
    
    def __init__(self, db_manager):
        self.db_manager = db_manager
    
    def analyze_user_health(self, user_id: str, days_back: int = 7) -> HealthMetrics:
        """
        Analyze user's health data and extract key patterns
        
        Args:
            user_id: User identifier
            days_back: Number of days to analyze
            
        Returns:
            HealthMetrics object with analyzed patterns
        """
        try:
            # Get raw data from existing database
            health_data = self._fetch_user_data(user_id, days_back)
            
            # Analyze each metric type
            heart_rate_analysis = self._analyze_heart_rate(health_data['heart_rate'])
            hrv_analysis = self._analyze_hrv(health_data['hrv'])
            spo2_analysis = self._analyze_spo2(health_data['spo2'])
            activity_analysis = self._analyze_activity(health_data['activity'])
            sleep_analysis = self._analyze_sleep(health_data['breathing_rate'])
            trends = self._calculate_trends(health_data)
            
            return HealthMetrics(
                heart_rate=heart_rate_analysis,
                hrv=hrv_analysis,
                spo2=spo2_analysis,
                activity=activity_analysis,
                sleep=sleep_analysis,
                trends=trends
            )
            
        except Exception as e:
            # Return safe defaults if analysis fails
            return self._get_default_metrics()
    
    def _fetch_user_data(self, user_id: str, days_back: int) -> Dict[str, pd.DataFrame]:
        """Fetch user data using existing database manager"""
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days_back)
        
        # For development, use CSV data if database is not available
        try:
            with self.db_manager.get_connection() as conn:
                # Use existing database schema
                heart_rate_df = pd.read_sql("""
                    SELECT datetime, heart_rate 
                    FROM heart_rate_data hr
                    JOIN users u ON hr.user_id = u.id
                    WHERE u.fitbit_user_id = %s 
                    AND hr.datetime >= %s
                    ORDER BY hr.datetime
                """, conn, params=[user_id, start_date])
                
                hrv_df = pd.read_sql("""
                    SELECT datetime, rmssd, lf, hf 
                    FROM hrv_data hrv
                    JOIN users u ON hrv.user_id = u.id
                    WHERE u.fitbit_user_id = %s 
                    AND hrv.datetime >= %s
                    ORDER BY hrv.datetime
                """, conn, params=[user_id, start_date])
                
                spo2_df = pd.read_sql("""
                    SELECT datetime, spo2 
                    FROM spo2_data s
                    JOIN users u ON s.user_id = u.id
                    WHERE u.fitbit_user_id = %s 
                    AND s.datetime >= %s
                    ORDER BY s.datetime
                """, conn, params=[user_id, start_date])
                
                activity_df = pd.read_sql("""
                    SELECT datetime, steps, distance, calories 
                    FROM activity_data a
                    JOIN users u ON a.user_id = u.id
                    WHERE u.fitbit_user_id = %s 
                    AND a.datetime >= %s
                    ORDER BY a.datetime
                """, conn, params=[user_id, start_date])
                
                breathing_df = pd.read_sql("""
                    SELECT date, deep_sleep_br, rem_sleep_br, light_sleep_br, full_sleep_br 
                    FROM breathing_rate_data br
                    JOIN users u ON br.user_id = u.id
                    WHERE u.fitbit_user_id = %s 
                    AND br.date >= %s
                    ORDER BY br.date
                """, conn, params=[user_id, start_date.date()])
                
        except Exception:
            # Fallback to CSV data for development
            heart_rate_df = self._load_csv_fallback('processed_heart_rate_data.csv', start_date, days_back)
            hrv_df = self._load_csv_fallback('processed_hrv_data.csv', start_date, days_back)
            spo2_df = self._load_csv_fallback('processed_spo2_data.csv', start_date, days_back)
            activity_df = self._load_csv_fallback('processed_activity_data.csv', start_date, days_back)
            breathing_df = self._load_csv_fallback('processed_breathing_rate_data.csv', start_date, days_back)
        
        return {
            'heart_rate': heart_rate_df,
            'hrv': hrv_df,
            'spo2': spo2_df,
            'activity': activity_df,
            'breathing_rate': breathing_df
        }
    
    def _load_csv_fallback(self, filename: str, start_date: datetime, days_back: int) -> pd.DataFrame:
        """Load data from CSV files as fallback"""
        try:
            df = pd.read_csv(f'/Users/chanyeong/Desktop/Hackrice/backend/{filename}')
            
            # Handle different date column names
            if 'datetime' in df.columns:
                df['datetime'] = pd.to_datetime(df['datetime'])
                date_mask = df['datetime'] >= start_date
                return df[date_mask].tail(1000)  # Limit for performance
            elif 'date' in df.columns:
                df['date'] = pd.to_datetime(df['date'])
                date_mask = df['date'] >= start_date.date()
                return df[date_mask]
            else:
                # Return recent data if no date filtering possible
                return df.tail(min(100, len(df)))
                
        except Exception:
            return pd.DataFrame()
    
    def _analyze_heart_rate(self, df: pd.DataFrame) -> Dict:
        """Analyze heart rate patterns"""
        if df.empty:
            return self._get_default_hr_analysis()
        
        # Calculate resting heart rate (lowest 10th percentile during nighttime hours)
        if 'datetime' in df.columns:
            df['hour'] = pd.to_datetime(df['datetime']).dt.hour
            nighttime_hr = df[df['hour'].isin([23, 0, 1, 2, 3, 4, 5, 6])]
            current_resting = nighttime_hr['heart_rate'].quantile(0.1) if not nighttime_hr.empty else df['heart_rate'].min()
            
            # Calculate baseline (7-day rolling average)
            daily_resting = df.groupby(df['datetime'].dt.date)['heart_rate'].quantile(0.1)
        else:
            current_resting = df['heart_rate'].quantile(0.1)
            daily_resting = pd.Series([current_resting])
        
        baseline_resting = daily_resting.mean()
        
        # Trend analysis
        if len(daily_resting) >= 6:
            recent_3day = daily_resting.tail(3).mean()
            older_3day = daily_resting.head(3).mean()
            trend = 'increasing' if recent_3day > older_3day + 2 else 'decreasing' if recent_3day < older_3day - 2 else 'stable'
        else:
            trend = 'stable'
        
        # Recovery analysis (how quickly HR returns to baseline after peaks)
        recovery_times = self._calculate_recovery_times(df)
        
        return {
            'current_resting': round(current_resting),
            'baseline_resting': round(baseline_resting),
            'trend': trend,
            'recovery_time_minutes': round(recovery_times.mean()) if len(recovery_times) > 0 else 5,
            'variability': round(df['heart_rate'].std(), 1),
            'data_quality': 'good' if len(df) > 1000 else 'limited'
        }
    
    def _analyze_hrv(self, df: pd.DataFrame) -> Dict:
        """Analyze heart rate variability patterns"""
        if df.empty:
            return self._get_default_hrv_analysis()
        
        current_rmssd = df['rmssd'].tail(7).mean()  # Last week average
        baseline_rmssd = df['rmssd'].mean()  # Overall average
        
        # Trend calculation
        if len(df) >= 6:
            recent_trend = df['rmssd'].tail(3).mean()
            older_trend = df['rmssd'].head(3).mean()
        else:
            recent_trend = current_rmssd
            older_trend = baseline_rmssd
        
        trend = 'improving' if recent_trend > older_trend + 5 else 'declining' if recent_trend < older_trend - 5 else 'stable'
        
        # Sleep correlation (higher HRV generally indicates better recovery)
        sleep_quality_correlation = 0.7 if current_rmssd > baseline_rmssd else 0.4
        
        return {
            'current_rmssd': round(current_rmssd, 1),
            'baseline_rmssd': round(baseline_rmssd, 1),
            'trend': trend,
            'sleep_quality_correlation': sleep_quality_correlation,
            'recovery_score': min(100, max(0, int((current_rmssd / baseline_rmssd) * 50)))
        }
    
    def _analyze_spo2(self, df: pd.DataFrame) -> Dict:
        """Analyze blood oxygen patterns"""
        if df.empty:
            return self._get_default_spo2_analysis()
        
        recent_average = df['spo2'].tail(100).mean()  # Recent readings
        
        # Count significant dips (below 94%)
        nighttime_dips = len(df[df['spo2'] < 94])
        
        # Trend analysis
        if 'datetime' in df.columns:
            daily_avg = df.groupby(df['datetime'].dt.date)['spo2'].mean()
        else:
            daily_avg = pd.Series([recent_average])
            
        trend = 'improving' if len(daily_avg) >= 4 and daily_avg.tail(2).mean() > daily_avg.head(2).mean() else 'stable'
        
        return {
            'recent_average': round(recent_average, 1),
            'nighttime_dips': nighttime_dips,
            'trend': trend,
            'respiratory_health_indicator': 'good' if recent_average >= 96 and nighttime_dips < 5 else 'monitor'
        }
    
    def _analyze_activity(self, df: pd.DataFrame) -> Dict:
        """Analyze activity patterns"""
        if df.empty:
            return self._get_default_activity_analysis()
        
        # Daily aggregation
        if 'datetime' in df.columns:
            daily_activity = df.groupby(df['datetime'].dt.date).agg({
                'steps': 'sum',
                'calories': 'sum',
                'distance': 'sum'
            })
        else:
            # For daily data (already aggregated)
            daily_activity = df[['steps', 'calories', 'distance']]
        
        weekly_active_minutes = daily_activity['steps'].sum() / 20  # Rough estimate
        step_trend = 'increasing' if len(daily_activity) >= 6 and daily_activity['steps'].tail(3).mean() > daily_activity['steps'].head(3).mean() else 'stable'
        
        # Consistency score (how regular is the exercise pattern)
        step_std = daily_activity['steps'].std()
        step_mean = daily_activity['steps'].mean()
        consistency = max(0, 1 - (step_std / step_mean)) if step_mean > 0 else 0
        
        return {
            'weekly_active_minutes': int(weekly_active_minutes),
            'step_trend': step_trend,
            'exercise_consistency': round(consistency, 2),
            'daily_average_steps': int(daily_activity['steps'].mean()),
            'activity_level': 'high' if weekly_active_minutes > 150 else 'moderate' if weekly_active_minutes > 75 else 'low'
        }
    
    def _analyze_sleep(self, df: pd.DataFrame) -> Dict:
        """Analyze sleep patterns from breathing rate data"""
        if df.empty:
            return self._get_default_sleep_analysis()
        
        # Average sleep metrics
        avg_full_sleep_br = df['full_sleep_br'].mean()
        
        # Sleep quality estimation based on breathing rate stability
        br_variability = df['full_sleep_br'].std()
        sleep_score = max(70, min(100, 100 - (br_variability * 2)))
        
        return {
            'average_breathing_rate': round(avg_full_sleep_br, 1),
            'sleep_score_trend': 'stable',
            'breathing_stability': 'good' if br_variability < 2 else 'variable',
            'estimated_sleep_quality': round(sleep_score)
        }
    
    def _calculate_trends(self, health_data: Dict) -> Dict:
        """Calculate overall health trends"""
        trends = {}
        
        # Overall health trajectory
        hr_stable = len(health_data['heart_rate']) > 0
        activity_present = len(health_data['activity']) > 0
        
        overall_trend = 'stable'
        if hr_stable and activity_present:
            overall_trend = 'improving'
        
        trends['overall_health'] = overall_trend
        trends['data_completeness'] = 'good' if all(len(df) > 0 for df in health_data.values()) else 'partial'
        
        return trends
    
    def _calculate_recovery_times(self, df: pd.DataFrame) -> np.ndarray:
        """Calculate heart rate recovery times after exercise"""
        # Simplified recovery calculation
        # In a real implementation, this would identify exercise periods and measure recovery
        return np.array([5, 6, 4, 7, 5])  # Mock recovery times in minutes
    
    # Default methods for fallback scenarios
    def _get_default_metrics(self) -> HealthMetrics:
        """Return safe default metrics when analysis fails"""
        return HealthMetrics(
            heart_rate=self._get_default_hr_analysis(),
            hrv=self._get_default_hrv_analysis(),
            spo2=self._get_default_spo2_analysis(),
            activity=self._get_default_activity_analysis(),
            sleep=self._get_default_sleep_analysis(),
            trends={'overall_health': 'stable', 'data_completeness': 'limited'}
        )
    
    def _get_default_hr_analysis(self) -> Dict:
        return {
            'current_resting': 70,
            'baseline_resting': 70,
            'trend': 'stable',
            'recovery_time_minutes': 5,
            'variability': 10.0,
            'data_quality': 'limited'
        }
    
    def _get_default_hrv_analysis(self) -> Dict:
        return {
            'current_rmssd': 35.0,
            'baseline_rmssd': 35.0,
            'trend': 'stable',
            'sleep_quality_correlation': 0.5,
            'recovery_score': 50
        }
    
    def _get_default_spo2_analysis(self) -> Dict:
        return {
            'recent_average': 97.0,
            'nighttime_dips': 0,
            'trend': 'stable',
            'respiratory_health_indicator': 'good'
        }
    
    def _get_default_activity_analysis(self) -> Dict:
        return {
            'weekly_active_minutes': 100,
            'step_trend': 'stable',
            'exercise_consistency': 0.7,
            'daily_average_steps': 8000,
            'activity_level': 'moderate'
        }
    
    def _get_default_sleep_analysis(self) -> Dict:
        return {
            'average_breathing_rate': 16.0,
            'sleep_score_trend': 'stable',
            'breathing_stability': 'good',
            'estimated_sleep_quality': 80
        }