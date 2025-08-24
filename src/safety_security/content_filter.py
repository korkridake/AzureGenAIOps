"""
Content filtering for LLM inputs and outputs.
"""

import re
from typing import Dict, Any, List
from ..common import LLMConfig, get_logger

logger = get_logger(__name__)


class ContentFilter:
    """
    Content filtering and safety checking for LLM operations.
    """
    
    def __init__(self, config: LLMConfig = None):
        """Initialize content filter."""
        self.config = config or LLMConfig()
        
        # Define harmful content patterns
        self.harmful_patterns = [
            # Violence and threats
            r'\b(?:kill|murder|assassinate|hurt|harm|attack|violence)\b.*\b(?:you|me|someone|people)\b',
            r'\b(?:bomb|explosive|weapon|gun|knife)\b.*\b(?:make|build|create|instructions)\b',
            
            # Illegal activities
            r'\b(?:drugs|narcotics|cocaine|heroin|meth)\b.*\b(?:how to|make|buy|sell)\b',
            r'\b(?:hack|hacking|phishing|malware)\b.*\b(?:tutorial|guide|instructions)\b',
            
            # Hate speech
            r'\b(?:hate|racist|discrimination)\b.*\b(?:against|towards)\b',
            
            # Self-harm
            r'\b(?:suicide|self-harm|cut myself|kill myself)\b',
            
            # Sexual content (basic patterns)
            r'\b(?:sex|sexual|porn|pornography)\b.*\b(?:explicit|graphic|detailed)\b',
        ]
        
        # Jailbreak attempt patterns
        self.jailbreak_patterns = [
            r'ignore\s+(?:previous|above|all)\s+instructions',
            r'pretend\s+(?:you are|to be)\s+(?:not|an?).*ai',
            r'act\s+as\s+(?:if|though)\s+you\s+(?:are|were)',
            r'roleplay\s+as',
            r'simulate\s+being',
            r'you\s+are\s+now\s+(?:a|an)\s+(?:uncensored|unfiltered)',
        ]
        
        # Allowed categories for content
        self.allowed_categories = {
            "educational", "informational", "creative", "analytical", 
            "technical", "scientific", "business", "academic"
        }
    
    def check_input(self, text: str) -> Dict[str, Any]:
        """
        Check input text for harmful content.
        
        Args:
            text: Input text to check
            
        Returns:
            Safety check result
        """
        if not text or not text.strip():
            return {"is_safe": True, "reason": None, "confidence": 1.0}
        
        text_lower = text.lower()
        
        # Check for harmful content patterns
        for pattern in self.harmful_patterns:
            if re.search(pattern, text_lower, re.IGNORECASE):
                return {
                    "is_safe": False,
                    "reason": "Potentially harmful content detected",
                    "confidence": 0.8,
                    "pattern_matched": pattern
                }
        
        # Check for jailbreak attempts
        if self.config.jailbreak_detection_enabled:
            jailbreak_result = self._check_jailbreak_attempts(text_lower)
            if not jailbreak_result["is_safe"]:
                return jailbreak_result
        
        # Check for PII if enabled
        if self.config.pii_detection_enabled:
            pii_result = self._check_pii(text)
            if not pii_result["is_safe"]:
                return pii_result
        
        return {"is_safe": True, "reason": None, "confidence": 1.0}
    
    def check_output(self, text: str) -> Dict[str, Any]:
        """
        Check output text for harmful content.
        
        Args:
            text: Output text to check
            
        Returns:
            Safety check result
        """
        if not text or not text.strip():
            return {"is_safe": True, "reason": None, "confidence": 1.0}
        
        text_lower = text.lower()
        
        # Check for harmful content in output
        for pattern in self.harmful_patterns:
            if re.search(pattern, text_lower, re.IGNORECASE):
                return {
                    "is_safe": False,
                    "reason": "Harmful content in model output",
                    "confidence": 0.9,
                    "pattern_matched": pattern
                }
        
        # Check for leaked prompts or system instructions
        system_leakage_patterns = [
            r'you are a helpful assistant',
            r'i am an ai language model',
            r'as an ai assistant',
            r'my training data',
            r'openai',
            r'gpt-[0-9]'
        ]
        
        for pattern in system_leakage_patterns:
            if re.search(pattern, text_lower, re.IGNORECASE):
                return {
                    "is_safe": False,
                    "reason": "Potential system prompt leakage",
                    "confidence": 0.7,
                    "pattern_matched": pattern
                }
        
        return {"is_safe": True, "reason": None, "confidence": 1.0}
    
    def _check_jailbreak_attempts(self, text: str) -> Dict[str, Any]:
        """Check for jailbreak attempt patterns."""
        for pattern in self.jailbreak_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return {
                    "is_safe": False,
                    "reason": "Potential jailbreak attempt detected",
                    "confidence": 0.8,
                    "pattern_matched": pattern
                }
        
        # Check for role-playing attempts
        role_patterns = [
            r'you\s+are\s+(?:now|no longer)\s+(?:a|an)',
            r'from\s+now\s+on\s+you\s+(?:are|will be)',
            r'forget\s+that\s+you\s+are\s+an?\s+ai',
            r'you\s+must\s+(?:not|never)\s+(?:mention|say|tell)',
        ]
        
        for pattern in role_patterns:
            if re.search(pattern, text, re.IGNORECASE):
                return {
                    "is_safe": False,
                    "reason": "Role manipulation attempt detected",
                    "confidence": 0.7,
                    "pattern_matched": pattern
                }
        
        return {"is_safe": True, "reason": None, "confidence": 1.0}
    
    def _check_pii(self, text: str) -> Dict[str, Any]:
        """Check for personally identifiable information."""
        pii_patterns = [
            # Email addresses
            (r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b', "email"),
            
            # Phone numbers (basic patterns)
            (r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b', "phone"),
            (r'\(\d{3}\)\s*\d{3}[-.]?\d{4}', "phone"),
            
            # Social Security Numbers (US)
            (r'\b\d{3}-\d{2}-\d{4}\b', "ssn"),
            
            # Credit card numbers (basic check)
            (r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b', "credit_card"),
            
            # IP addresses
            (r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', "ip_address"),
        ]
        
        detected_pii = []
        for pattern, pii_type in pii_patterns:
            matches = re.findall(pattern, text)
            if matches:
                detected_pii.append({
                    "type": pii_type,
                    "count": len(matches),
                    "examples": matches[:2]  # Only show first 2 examples
                })
        
        if detected_pii:
            return {
                "is_safe": False,
                "reason": "PII detected in text",
                "confidence": 0.9,
                "detected_pii": detected_pii
            }
        
        return {"is_safe": True, "reason": None, "confidence": 1.0}
    
    def sanitize_text(self, text: str) -> str:
        """
        Sanitize text by removing or masking sensitive content.
        
        Args:
            text: Input text to sanitize
            
        Returns:
            Sanitized text
        """
        sanitized = text
        
        # Mask email addresses
        sanitized = re.sub(
            r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            '[EMAIL]',
            sanitized
        )
        
        # Mask phone numbers
        sanitized = re.sub(
            r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
            '[PHONE]',
            sanitized
        )
        
        # Mask SSN
        sanitized = re.sub(
            r'\b\d{3}-\d{2}-\d{4}\b',
            '[SSN]',
            sanitized
        )
        
        # Mask credit card numbers
        sanitized = re.sub(
            r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b',
            '[CREDIT_CARD]',
            sanitized
        )
        
        return sanitized
    
    def add_custom_pattern(self, pattern: str, category: str = "custom"):
        """
        Add custom harmful content pattern.
        
        Args:
            pattern: Regular expression pattern
            category: Category of the pattern
        """
        try:
            # Test if pattern is valid
            re.compile(pattern)
            self.harmful_patterns.append(pattern)
            logger.info(f"Added custom pattern for category: {category}")
        except re.error as e:
            logger.error(f"Invalid regex pattern: {pattern}, error: {e}")
    
    def get_filter_stats(self) -> Dict[str, Any]:
        """Get content filter statistics."""
        return {
            "harmful_patterns": len(self.harmful_patterns),
            "jailbreak_patterns": len(self.jailbreak_patterns),
            "content_filter_enabled": self.config.content_filter_enabled,
            "pii_detection_enabled": self.config.pii_detection_enabled,
            "jailbreak_detection_enabled": self.config.jailbreak_detection_enabled
        }