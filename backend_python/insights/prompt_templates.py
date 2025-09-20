"""
Prompt template management for health insights generation
"""
from typing import Dict, Any
from insights.models.health_metrics import HealthMetrics


class PromptTemplateManager:
    """Manages structured prompts for different insight types"""
    
    BASE_SYSTEM_PROMPT = """
    You are a health and wellness data interpreter for a fitness app. Your role is to:
    
    1. Translate complex health metrics into clear, actionable insights
    2. Explain relationships between health patterns and environmental factors
    3. Provide activity recommendations based on current health status
    4. Always prioritize user safety and wellbeing
    
    CRITICAL SAFETY GUIDELINES:
    - Never provide medical diagnoses or replace professional medical advice
    - Always include disclaimers about consulting healthcare providers for medical concerns
    - Avoid recommending activities that could be harmful
    - Focus on general wellness and activity optimization, not medical treatment
    - If concerning patterns are detected, recommend consulting a healthcare provider
    
    COMMUNICATION STYLE:
    - Clear, conversational, and encouraging tone
    - Explain the 'why' behind recommendations using specific metrics
    - Use accessible language, avoid medical jargon
    - Acknowledge limitations when data is insufficient
    - Keep responses concise and actionable (2-3 sentences max)
    """
    
    def generate_daily_summary_prompt(self, health_metrics: HealthMetrics, 
                                    air_quality: Dict, user_profile: Dict) -> str:
        """Generate prompt for daily health summary"""
        return f"""
        {self.BASE_SYSTEM_PROMPT}
        
        Based on this user's health data and environmental conditions, provide a personalized daily health summary:
        
        HEALTH RECOVERY STATUS:
        - HRV: {health_metrics.hrv['current_rmssd']} (baseline: {health_metrics.hrv['baseline_rmssd']})
        - Resting HR: {health_metrics.heart_rate['current_resting']} bpm (baseline: {health_metrics.heart_rate['baseline_resting']} bpm)
        - Sleep Quality: {health_metrics.sleep['estimated_sleep_quality']}/100
        - Recovery Score: {health_metrics.hrv['recovery_score']}/100
        
        ACTIVITY PATTERNS:
        - Recent activity level: {health_metrics.activity['activity_level']}
        - Exercise consistency: {health_metrics.activity['exercise_consistency']:.1%}
        - Daily steps average: {health_metrics.activity['daily_average_steps']}
        
        RESPIRATORY HEALTH:
        - SpO2 average: {health_metrics.spo2['recent_average']}%
        - Breathing stability: {health_metrics.sleep['breathing_stability']}
        
        TODAY'S CONDITIONS:
        - Air Quality Index: {air_quality.get('aqi', 'unknown')}
        - Primary pollutant: {air_quality.get('primary_pollutant', 'unknown')}
        - Location type: {air_quality.get('location_type', 'unknown')}
        
        USER CONTEXT:
        - Health conditions: {', '.join(user_profile.get('health_conditions', [])) or 'None reported'}
        - Fitness level: {user_profile.get('fitness_level', 'moderate')}
        - Age range: {user_profile.get('age_range', 'adult')}
        
        Provide a 2-3 sentence summary that:
        1. Explains how their recovery and readiness look today based on HRV and heart rate
        2. Describes how current air quality might affect them personally
        3. Gives one specific, actionable recommendation for today's activities
        
        Focus on being encouraging while being realistic about limitations.
        """
    
    def generate_activity_recommendation_prompt(self, health_metrics: HealthMetrics,
                                              air_quality: Dict, activity_type: str,
                                              user_profile: Dict) -> str:
        """Generate prompt for specific activity recommendations"""
        return f"""
        {self.BASE_SYSTEM_PROMPT}
        
        The user is asking about: "{activity_type}"
        
        Analyze their current readiness and provide a recommendation:
        
        CURRENT HEALTH STATUS:
        - Resting HR: {health_metrics.heart_rate['current_resting']} bpm (trend: {health_metrics.heart_rate['trend']})
        - HRV Recovery Score: {health_metrics.hrv['recovery_score']}/100 (trend: {health_metrics.hrv['trend']})
        - Recent activity level: {health_metrics.activity['activity_level']}
        - Heart rate recovery: {health_metrics.heart_rate['recovery_time_minutes']} minutes average
        
        ENVIRONMENTAL CONDITIONS:
        - Air Quality: {air_quality.get('aqi', 'unknown')} AQI
        - Conditions: {air_quality.get('conditions', 'unknown')}
        
        USER CONSIDERATIONS:
        - Health conditions: {', '.join(user_profile.get('health_conditions', [])) or 'None'}
        - Fitness level: {user_profile.get('fitness_level', 'moderate')}
        
        Provide a specific recommendation about whether to proceed with "{activity_type}" right now, including:
        1. Yes/No/Modified recommendation with reasoning
        2. Optimal timing if not recommended now
        3. Any modifications to consider (intensity, duration, location)
        
        Base your recommendation on their recovery metrics and air quality impact.
        """
    
    def generate_pattern_insight_prompt(self, health_metrics: HealthMetrics,
                                      historical_patterns: Dict) -> str:
        """Generate prompt for health pattern analysis"""
        return f"""
        {self.BASE_SYSTEM_PROMPT}
        
        Analyze this user's health patterns and provide insights:
        
        CURRENT TRENDS:
        - Heart rate trend: {health_metrics.heart_rate['trend']}
        - HRV trend: {health_metrics.hrv['trend']}
        - Activity trend: {health_metrics.activity['step_trend']}
        - SpO2 trend: {health_metrics.spo2['trend']}
        
        PATTERN OBSERVATIONS:
        - Exercise consistency: {health_metrics.activity['exercise_consistency']:.1%}
        - Recovery quality: {health_metrics.hrv['sleep_quality_correlation']:.1%}
        - Data completeness: {health_metrics.trends['data_completeness']}
        
        Identify one interesting pattern or trend in their data and explain:
        1. What the pattern suggests about their health/fitness
        2. Whether this is a positive or concerning trend
        3. One actionable insight they can use
        
        Keep the insight encouraging and focused on actionable improvements.
        """
    
    def generate_qa_prompt(self, health_metrics: HealthMetrics, user_question: str,
                          context: Dict) -> str:
        """Generate prompt for answering specific user questions"""
        return f"""
        {self.BASE_SYSTEM_PROMPT}
        
        User Question: "{user_question}"
        
        Use their health data to provide a personalized answer:
        
        RELEVANT HEALTH DATA:
        - Current HRV: {health_metrics.hrv['current_rmssd']} (recovery score: {health_metrics.hrv['recovery_score']}/100)
        - Resting HR: {health_metrics.heart_rate['current_resting']} bpm
        - Activity level: {health_metrics.activity['activity_level']}
        - SpO2: {health_metrics.spo2['recent_average']}%
        - Sleep quality: {health_metrics.sleep['estimated_sleep_quality']}/100
        
        CONTEXT:
        - Air quality: {context.get('air_quality', {}).get('aqi', 'unknown')} AQI
        - Time of day: {context.get('time_of_day', 'unknown')}
        - User conditions: {', '.join(context.get('user_profile', {}).get('health_conditions', [])) or 'None'}
        
        Answer their question using their specific health data as evidence. If the question is outside your scope (medical diagnosis, specific medical advice), politely redirect to healthcare providers while still providing general wellness context if appropriate.
        
        Keep your answer conversational, specific to their data, and actionable.
        """