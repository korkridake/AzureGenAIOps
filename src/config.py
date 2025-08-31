"""
Configuration management for AzureGenAIOps LLM Operations.
"""

import os
from pathlib import Path
from typing import Optional, Dict, Any

try:
    from azure.identity import DefaultAzureCredential
    AZURE_AVAILABLE = True
except ImportError:
    AZURE_AVAILABLE = False
    DefaultAzureCredential = None

try:
    from dotenv import load_dotenv
    # Load environment variables
    load_dotenv()
except ImportError:
    # dotenv is optional
    pass

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
REPORTS_DIR = PROJECT_ROOT / "reports"


class LLMConfig:
    """LLM Operations configuration."""
    
    def __init__(self):
        # Azure AI Foundry Configuration
        self.azure_subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
        self.azure_resource_group = os.getenv("AZURE_RESOURCE_GROUP")
        self.azure_location = os.getenv("AZURE_LOCATION", "eastus")
        self.azure_ai_project_name = os.getenv("AZURE_AI_PROJECT_NAME")
        
        # Azure OpenAI Configuration
        self.azure_openai_endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        self.azure_openai_api_key = os.getenv("AZURE_OPENAI_API_KEY")
        self.azure_openai_deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4")
        self.azure_openai_api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-01")
        
        # Azure AI Search Configuration (for RAG)
        self.azure_search_endpoint = os.getenv("AZURE_SEARCH_ENDPOINT")
        self.azure_search_api_key = os.getenv("AZURE_SEARCH_API_KEY")
        self.azure_search_index_name = os.getenv("AZURE_SEARCH_INDEX_NAME", "documents")
        
        # Azure Document Intelligence (for data extraction)
        self.azure_doc_intelligence_endpoint = os.getenv("AZURE_DOC_INTELLIGENCE_ENDPOINT")
        self.azure_doc_intelligence_api_key = os.getenv("AZURE_DOC_INTELLIGENCE_API_KEY")
        
        # Azure Storage Configuration
        self.azure_storage_account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
        self.azure_storage_container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "llm-data")
        
        # Embedding Models Configuration
        self.embedding_model_name = os.getenv("EMBEDDING_MODEL_NAME", "text-embedding-ada-002")
        self.embedding_dimensions = int(os.getenv("EMBEDDING_DIMENSIONS", "1536"))
        
        # LLM Training Configuration
        self.training_data_path = os.getenv("TRAINING_DATA_PATH", "data/training")
        self.max_training_tokens = int(os.getenv("MAX_TRAINING_TOKENS", "100000"))
        self.training_epochs = int(os.getenv("TRAINING_EPOCHS", "3"))
        
        # Safety and Security Configuration
        self.content_filter_enabled = os.getenv("CONTENT_FILTER_ENABLED", "true").lower() == "true"
        self.pii_detection_enabled = os.getenv("PII_DETECTION_ENABLED", "true").lower() == "true"
        self.jailbreak_detection_enabled = os.getenv("JAILBREAK_DETECTION_ENABLED", "true").lower() == "true"
        
        # Monitoring Configuration
        self.azure_monitor_connection_string = os.getenv("AZURE_MONITOR_CONNECTION_STRING")
        self.enable_telemetry = os.getenv("ENABLE_TELEMETRY", "true").lower() == "true"
        
        # Application Configuration
        self.log_level = os.getenv("LOG_LEVEL", "INFO")
        self.environment = os.getenv("ENVIRONMENT", "development")
        self.api_host = os.getenv("API_HOST", "0.0.0.0")
        self.api_port = int(os.getenv("API_PORT", "8000"))
        
        # Azure credential
        if AZURE_AVAILABLE:
            self.credential = DefaultAzureCredential()
        else:
            self.credential = None
        
        # Paths
        self.paths = {
            "project_root": PROJECT_ROOT,
            "data": DATA_DIR,
            "models": MODELS_DIR,
            "reports": REPORTS_DIR,
        }
    
    def get_azure_openai_config(self) -> Dict[str, Any]:
        """Get Azure OpenAI configuration as dictionary."""
        return {
            "endpoint": self.azure_openai_endpoint,
            "api_key": self.azure_openai_api_key,
            "deployment_name": self.azure_openai_deployment_name,
            "api_version": self.azure_openai_api_version
        }
    
    def get_azure_search_config(self) -> Dict[str, Any]:
        """Get Azure AI Search configuration as dictionary."""
        return {
            "endpoint": self.azure_search_endpoint,
            "api_key": self.azure_search_api_key,
            "index_name": self.azure_search_index_name
        }


# Global configuration instance
config = LLMConfig()

# Enhanced configuration with Key Vault support
try:
    from src.common.keyvault_config import create_config
    enhanced_config = create_config()
except ImportError:
    # Fallback to regular config if Key Vault support is not available
    enhanced_config = config


def validate_config() -> bool:
    """Validate that required configuration is present."""
    required_vars = [
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_RESOURCE_GROUP",
        "AZURE_AI_PROJECT_NAME",
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_API_KEY",
    ]

    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        raise ValueError(f"Missing required environment variables: {missing_vars}")

    return True


def get_config(use_key_vault: bool = None):
    """
    Get configuration instance with optional Key Vault support.
    
    Args:
        use_key_vault: Whether to use Key Vault (auto-detected if None)
        
    Returns:
        Configuration instance (enhanced if Key Vault available, regular otherwise)
    """
    try:
        from src.common.keyvault_config import create_config
        return create_config(use_key_vault=use_key_vault)
    except ImportError:
        # Fallback to regular config if Key Vault support is not available
        return config
