"""
Main service for generating health insights
"""
from typing import Dict, Optional, List
import logging
from datetime import datetime

from insights.health_analyzer import HealthDataAnalyzer
from insights.gemini_service import GeminiHealthService
from insights.prompt_templates import PromptTemplateManager
from insights.safety_validator import HealthInsightValidator
from insights.models.insight_models import InsightRequest, InsightResponse


class HealthInsightGenerator:
    """Main service for generating health insights"""
    
    def __init__(self, db_manager, gemini_api_key: str):
        self.health_analyzer = HealthDataAnalyzer(db_manager)
        self.gemini_service = GeminiHealthService(gemini_api_key)
        self.prompt_manager = PromptTemplateManager()
        self.validator = HealthInsightValidator()
        self.logger = logging.getLogger(__name__)
    
    def generate_daily_summary(self, user_id: str, air_quality_data: Dict,
                             user_profile: Dict) -> InsightResponse:
        """Generate daily health summary insight"""
        try:
            # Analyze user's health data
            health_metrics = self.health_analyzer.analyze_user_health(user_id)
            
            # Generate prompt
            prompt = self.prompt_manager.generate_daily_summary_prompt(
                health_metrics, air_quality_data, user_profile
            )
            
            # Get insight from Gemini
            raw_insight = self.gemini_service.generate_health_insight(prompt)
            
            # Validate and sanitize
            is_valid, validated_insight, warnings = self.validator.validate_insight(
                raw_insight, "daily_summary"
            )
            
            return InsightResponse(
                success=True,
                insight_text=validated_insight,
                insight_type="daily_summary",
                confidence_score=0.8 if is_valid else 0.6,
                warnings=warnings,
                timestamp=datetime.now(),
                health_metrics_summary={
                    'recovery_score': health_metrics.hrv['recovery_score'],
                    'activity_level': health_metrics.activity['activity_level'],
                    'data_quality': health_metrics.heart_rate['data_quality']
                }
            )
            
        except Exception as e:
            self.logger.error(f"Error generating daily summary: {str(e)}")
            return self._create_error_response("daily_summary", str(e))
    
    def generate_activity_recommendation(self, user_id: str, activity_type: str,
                                       air_quality_data: Dict, user_profile: Dict) -> InsightResponse:
        """Generate activity-specific recommendations"""
        try:
            # Validate activity question
            is_valid_question, processed_activity = self.validator.validate_user_question(activity_type)
            if not is_valid_question:
                return InsightResponse(
                    success=False,
                    insight_text=processed_activity,
                    insight_type="activity_recommendation",
                    error="Invalid question type",
                    confidence_score=0.0,
                    timestamp=datetime.now()
                )
            
            # Analyze health data
            health_metrics = self.health_analyzer.analyze_user_health(user_id)
            
            # Generate recommendation prompt
            prompt = self.prompt_manager.generate_activity_recommendation_prompt(
                health_metrics, air_quality_data, processed_activity, user_profile
            )
            
            # Get recommendation from Gemini
            raw_recommendation = self.gemini_service.generate_health_insight(prompt)
            
            # Validate recommendation
            is_valid, validated_recommendation, warnings = self.validator.validate_insight(
                raw_recommendation, "activity_recommendation"
            )
            
            return InsightResponse(
                success=True,
                insight_text=validated_recommendation,
                insight_type="activity_recommendation",
                confidence_score=0.9 if is_valid else 0.7,
                warnings=warnings,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"Error generating activity recommendation: {str(e)}")
            return self._create_error_response("activity_recommendation", str(e))
    
    def generate_pattern_insight(self, user_id: str) -> InsightResponse:
        """Generate insights about health patterns and trends"""
        try:
            # Analyze health patterns
            health_metrics = self.health_analyzer.analyze_user_health(user_id, days_back=14)
            
            # Generate pattern analysis prompt
            prompt = self.prompt_manager.generate_pattern_insight_prompt(
                health_metrics, {}  # Historical patterns would be added here
            )
            
            # Get pattern insight from Gemini
            raw_insight = self.gemini_service.generate_health_insight(prompt)
            
            # Validate insight
            is_valid, validated_insight, warnings = self.validator.validate_insight(
                raw_insight, "pattern_insight"
            )
            
            return InsightResponse(
                success=True,
                insight_text=validated_insight,
                insight_type="pattern_insight",
                confidence_score=0.7 if is_valid else 0.5,
                warnings=warnings,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"Error generating pattern insight: {str(e)}")
            return self._create_error_response("pattern_insight", str(e))
    
    def answer_health_question(self, user_id: str, question: str,
                             context: Dict) -> InsightResponse:
        """Answer specific user questions about their health data"""
        try:
            # Validate question
            is_valid_question, processed_question = self.validator.validate_user_question(question)
            if not is_valid_question:
                return InsightResponse(
                    success=False,
                    insight_text=processed_question,
                    insight_type="health_qa",
                    error="Inappropriate question type",
                    confidence_score=0.0,
                    timestamp=datetime.now()
                )
            
            # Analyze health data
            health_metrics = self.health_analyzer.analyze_user_health(user_id)
            
            # Generate Q&A prompt
            prompt = self.prompt_manager.generate_qa_prompt(
                health_metrics, processed_question, context
            )
            
            # Get answer from Gemini
            raw_answer = self.gemini_service.generate_health_insight(prompt)
            
            # Validate answer
            is_valid, validated_answer, warnings = self.validator.validate_insight(
                raw_answer, "health_qa"
            )
            
            return InsightResponse(
                success=True,
                insight_text=validated_answer,
                insight_type="health_qa",
                confidence_score=0.8 if is_valid else 0.6,
                warnings=warnings,
                timestamp=datetime.now()
            )
            
        except Exception as e:
            self.logger.error(f"Error answering health question: {str(e)}")
            return self._create_error_response("health_qa", str(e))
    
    def _create_error_response(self, insight_type: str, error_message: str) -> InsightResponse:
        """Create standardized error response"""
        return InsightResponse(
            success=False,
            insight_text="Unable to generate insight at this time. Please try again later.",
            insight_type=insight_type,
            confidence_score=0.0,
            error=error_message,
            timestamp=datetime.now()
        )