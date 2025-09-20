"""
Data models for health insights
"""
from dataclasses import dataclass
from typing import Dict, List, Optional
from datetime import datetime


@dataclass
class InsightRequest:
    """Request model for health insights"""
    user_id: str
    insight_type: str  # 'daily_summary', 'activity_recommendation', 'pattern_insight', 'health_qa'
    air_quality_data: Optional[Dict] = None
    user_profile: Optional[Dict] = None
    activity_type: Optional[str] = None
    question: Optional[str] = None
    context: Optional[Dict] = None


@dataclass
class InsightResponse:
    """Response model for health insights"""
    success: bool
    insight_text: str
    insight_type: str
    confidence_score: float
    timestamp: datetime
    warnings: Optional[List[str]] = None
    health_metrics_summary: Optional[Dict] = None
    error: Optional[str] = None