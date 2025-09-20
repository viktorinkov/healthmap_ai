"""
Core service for Gemini API integration with health insights
"""
import google.generativeai as genai
import os
from typing import Optional, Dict
import json
import logging


class GeminiHealthService:
    """Core service for Gemini API integration with health insights"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv('GEMINI_API_KEY')
        if not self.api_key:
            raise ValueError("Gemini API key required. Set GEMINI_API_KEY environment variable.")
        
        genai.configure(api_key=self.api_key)
        self.model = genai.GenerativeModel('gemini-2.5-pro')
        self.logger = logging.getLogger(__name__)
    
    def generate_health_insight(self, prompt: str, max_tokens: int = 8192) -> str:
        """
        Generate health insight using Gemini Pro
        
        Args:
            prompt: Formatted prompt with health data
            max_tokens: Maximum response length
            
        Returns:
            Generated insight text with safety validation
        """
        try:
            # Configure safety settings to allow health/medical content
            safety_settings = [
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                }
            ]
            
            response = self.model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    max_output_tokens=max_tokens,
                    temperature=0.7,  # Balanced creativity and consistency
                    top_k=40,
                    top_p=0.95,
                ),
                safety_settings=safety_settings
            )
            
            # Workaround for Gemini text property bug
            response_text = self._extract_text_from_response(response)
            if response_text and response_text != "Unable to extract text from response":
                return self._post_process_response(response_text)
            else:
                return "Unable to generate insight at this time."
                
        except Exception as e:
            self.logger.error(f"Gemini API error: {str(e)}")
            return self._get_fallback_response()
    
    def _extract_text_from_response(self, response) -> str:
        """Workaround to extract text from Gemini response due to library bug"""
        try:
            # Try the direct approach first
            return response.text
        except TypeError:
            # Fallback: extract text from candidates manually
            if response.candidates and len(response.candidates) > 0:
                candidate = response.candidates[0]
                if hasattr(candidate, 'content') and hasattr(candidate.content, 'parts'):
                    parts_text = []
                    for part in candidate.content.parts:
                        if hasattr(part, 'text'):
                            parts_text.append(part.text)
                    return ''.join(parts_text)
            return "Unable to extract text from response"
    
    def _post_process_response(self, response: str) -> str:
        """Post-process Gemini response for safety and formatting"""
        # Remove any potential harmful content
        response = response.strip()
        
        # Ensure appropriate medical disclaimers
        if not any(disclaimer in response.lower() for disclaimer in 
                  ['wellness guidance', 'not medical advice', 'healthcare provider']):
            response += "\n\nRemember: This is wellness guidance, not medical advice. Consult healthcare providers for medical concerns."
        
        # Limit response length for mobile UI
        if len(response) > 800:
            response = response[:750] + "..."
        
        return response
    
    def _get_fallback_response(self) -> str:
        """Provide fallback response when API fails"""
        return ("Unable to generate personalized insight right now. "
                "Please check your health metrics manually and consult healthcare providers for any concerns.")
    
    def test_connection(self) -> bool:
        """Test Gemini API connectivity"""
        try:
            safety_settings = [
                {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
                {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
            ]
            test_response = self.model.generate_content("Generate a wellness tip about hydration", safety_settings=safety_settings)
            response_text = self._extract_text_from_response(test_response)
            return response_text is not None and response_text != "Unable to extract text from response"
        except Exception:
            return False