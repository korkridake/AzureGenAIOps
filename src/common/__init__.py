"""
Common utilities and Azure AI Foundry integration for LLM operations.
"""

try:
    from .azure_foundry import AzureFoundryClient
except ImportError:
    # Handle missing Azure dependencies gracefully
    class AzureFoundryClient:
        def __init__(self, *args, **kwargs):
            raise ImportError("Azure dependencies not installed. Please install with: pip install azure-ai-ml")

from ..config import LLMConfig
from .utils import get_logger, validate_environment

__all__ = ["AzureFoundryClient", "LLMConfig", "get_logger", "validate_environment"]