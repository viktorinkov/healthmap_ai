"""
Health metrics data structures for insight generation
"""
from dataclasses import dataclass
from typing import Dict, Optional


@dataclass
class HealthMetrics:
    """Structured health metrics for analysis"""
    heart_rate: Dict
    hrv: Dict
    spo2: Dict
    activity: Dict
    sleep: Dict
    trends: Dict