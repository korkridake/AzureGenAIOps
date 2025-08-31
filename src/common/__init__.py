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

# Import config without relative import to avoid issues
try:
    import sys
    from pathlib import Path
    config_path = Path(__file__).parent.parent / "config.py"
    if config_path.exists():
        spec = __import__("importlib.util").util.spec_from_file_location("config", config_path)
        config_module = __import__("importlib.util").util.module_from_spec(spec)
        spec.loader.exec_module(config_module)
        LLMConfig = config_module.LLMConfig
    else:
        LLMConfig = None
except Exception:
    LLMConfig = None

from .utils import get_logger, validate_environment

__all__ = ["AzureFoundryClient", "get_logger", "validate_environment"]
if LLMConfig is not None:
    __all__.append("LLMConfig")