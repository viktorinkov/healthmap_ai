"""
Safety validation system for health insights
"""
import re
from typing import Tuple, List
import logging


class HealthInsightValidator:
    """Validates health insights for safety and appropriateness"""
    
    # Terms that indicate medical overreach
    FORBIDDEN_MEDICAL_TERMS = [
        'diagnose', 'diagnosis', 'disease', 'disorder', 'syndrome',
        'prescription', 'medication', 'treatment', 'cure', 'therapy',
        'pathology', 'abnormal', 'condition requires', 'you have',
        'suffering from', 'medical condition'
    ]
    
    # Terms that should trigger healthcare referral
    CONCERNING_PATTERNS = [
        'chest pain', 'shortness of breath', 'dizziness', 'fainting',
        'irregular heartbeat', 'severe', 'emergency', 'urgent',
        'dangerous', 'concerning decline', 'significant drop'
    ]
    
    # Required safety elements
    REQUIRED_DISCLAIMERS = [
        'wellness guidance', 'not medical advice', 'healthcare provider',
        'consult', 'medical professional', 'doctor'
    ]
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
    
    def validate_insight(self, insight: str, context: str = "") -> Tuple[bool, str, List[str]]:
        """
        Validate health insight for safety and appropriateness
        
        Args:
            insight: Generated insight text
            context: Context about the type of insight
            
        Returns:
            Tuple of (is_valid, processed_insight, warnings)
        """
        warnings = []
        
        # Check for medical overreach
        medical_issues = self._check_medical_overreach(insight)
        if medical_issues:
            warnings.extend(medical_issues)
            insight = self._sanitize_medical_language(insight)
        
        # Check for concerning health patterns that need medical attention
        concerning_issues = self._check_concerning_patterns(insight)
        if concerning_issues:
            warnings.extend(concerning_issues)
            insight = self._add_medical_referral(insight)
        
        # Ensure appropriate disclaimers
        if not self._has_appropriate_disclaimers(insight):
            insight = self._add_safety_disclaimer(insight)
        
        # Check response length and readability
        insight = self._ensure_readability(insight)
        
        # Final safety check
        is_safe = len([w for w in warnings if 'CRITICAL' in w]) == 0
        
        return is_safe, insight, warnings
    
    def _check_medical_overreach(self, text: str) -> List[str]:
        """Check for inappropriate medical language"""
        issues = []
        text_lower = text.lower()
        
        for term in self.FORBIDDEN_MEDICAL_TERMS:
            if term in text_lower:
                issues.append(f"Medical overreach detected: '{term}'")
        
        # Check for definitive medical statements
        definitive_patterns = [
            r'you have \w+',
            r'this indicates \w+ disease',
            r'your condition is',
            r'diagnosis of'
        ]
        
        for pattern in definitive_patterns:
            if re.search(pattern, text_lower):
                issues.append(f"CRITICAL: Definitive medical statement detected")
        
        return issues
    
    def _check_concerning_patterns(self, text: str) -> List[str]:
        """Check for concerning health patterns that need medical attention"""
        issues = []
        text_lower = text.lower()
        
        for pattern in self.CONCERNING_PATTERNS:
            if pattern in text_lower:
                issues.append(f"Concerning health pattern mentioned: '{pattern}'")
        
        return issues
    
    def _has_appropriate_disclaimers(self, text: str) -> bool:
        """Check if text has appropriate medical disclaimers"""
        text_lower = text.lower()
        return any(disclaimer in text_lower for disclaimer in self.REQUIRED_DISCLAIMERS)
    
    def _sanitize_medical_language(self, text: str) -> str:
        """Remove or replace inappropriate medical language"""
        # Replace problematic terms with safer alternatives
        replacements = {
            'diagnose': 'suggest',
            'diagnosis': 'observation',
            'disease': 'health pattern',
            'disorder': 'variation',
            'abnormal': 'outside typical range',
            'you have': 'your data shows',
            'suffering from': 'experiencing'
        }
        
        for original, replacement in replacements.items():
            text = re.sub(r'\b' + original + r'\b', replacement, text, flags=re.IGNORECASE)
        
        return text
    
    def _add_medical_referral(self, text: str) -> str:
        """Add medical referral for concerning patterns"""
        if 'healthcare provider' not in text.lower():
            text += " Please consult a healthcare provider about these patterns."
        return text
    
    def _add_safety_disclaimer(self, text: str) -> str:
        """Add appropriate safety disclaimer"""
        disclaimer = "\n\nRemember: This is wellness guidance, not medical advice. Consult healthcare providers for medical concerns."
        
        if not any(phrase in text.lower() for phrase in ['wellness guidance', 'not medical advice']):
            text += disclaimer
        
        return text
    
    def _ensure_readability(self, text: str) -> str:
        """Ensure text is appropriate length and readable"""
        # Limit length for mobile display
        if len(text) > 800:
            text = text[:750] + "..."
        
        # Ensure proper sentence structure
        text = text.strip()
        if text and not text.endswith('.'):
            text += '.'
        
        return text
    
    def validate_user_question(self, question: str) -> Tuple[bool, str]:
        """Validate user questions for appropriateness"""
        question_lower = question.lower()
        
        # Check for inappropriate medical questions
        inappropriate_patterns = [
            'do i have', 'am i sick', 'what disease', 'should i take medication',
            'diagnose me', 'what\'s wrong with me', 'medical emergency'
        ]
        
        for pattern in inappropriate_patterns:
            if pattern in question_lower:
                return False, "I can provide wellness insights, but please consult healthcare providers for medical questions."
        
        return True, question