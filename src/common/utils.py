"""
Utility functions for LLM operations.
"""

import logging
import os
from typing import Dict, Any


def get_logger(name: str, level: str = None) -> logging.Logger:
    """Get configured logger."""
    log_level = level or os.getenv("LOG_LEVEL", "INFO")
    logger = logging.getLogger(name)
    
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    
    logger.setLevel(getattr(logging, log_level.upper()))
    return logger


def validate_environment() -> bool:
    """Validate that required environment variables are set."""
    required_vars = [
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_RESOURCE_GROUP", 
        "AZURE_AI_PROJECT_NAME",
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_API_KEY"
    ]
    
    missing_vars = [var for var in required_vars if not os.getenv(var)]
    
    if missing_vars:
        raise ValueError(f"Missing required environment variables: {missing_vars}")
    
    return True


def safe_format_prompt(template: str, **kwargs) -> str:
    """Safely format prompt template with validation."""
    try:
        return template.format(**kwargs)
    except KeyError as e:
        raise ValueError(f"Missing required template variable: {e}")


def calculate_token_estimate(text: str) -> int:
    """Rough estimation of token count (1 token ≈ 4 characters)."""
    return len(text) // 4


def validate_model_response(response: Dict[str, Any]) -> bool:
    """Validate model response structure."""
    required_fields = ["choices", "usage"]
    return all(field in response for field in required_fields)