"""Configuration management for Azure GenAI Ops."""

import os
from pathlib import Path
from typing import Optional

from azure.identity import DefaultAzureCredential
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent.parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
REPORTS_DIR = PROJECT_ROOT / "reports"


class AzureConfig:
    """Azure service configuration."""

    def __init__(self):
        self.subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
        self.resource_group = os.getenv("AZURE_RESOURCE_GROUP")
        self.location = os.getenv("AZURE_LOCATION", "eastus")
        self.credential = DefaultAzureCredential()


class OpenAIConfig:
    """Azure OpenAI configuration."""

    def __init__(self):
        self.endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        self.api_key = os.getenv("AZURE_OPENAI_API_KEY")
        self.api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2023-12-01-preview")
        self.deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-35-turbo")


class MLConfig:
    """Machine Learning configuration."""

    def __init__(self):
        self.workspace_name = os.getenv("AZURE_ML_WORKSPACE_NAME")
        self.compute_name = os.getenv("AZURE_ML_COMPUTE_NAME")
        self.model_name = os.getenv("MODEL_NAME", "gpt-35-turbo")
        self.max_tokens = int(os.getenv("MAX_TOKENS", "1000"))
        self.temperature = float(os.getenv("TEMPERATURE", "0.7"))
        self.batch_size = int(os.getenv("BATCH_SIZE", "32"))


class StorageConfig:
    """Azure Storage configuration."""

    def __init__(self):
        self.account_name = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")
        self.container_name = os.getenv("AZURE_STORAGE_CONTAINER_NAME", "genai-data")


class Config:
    """Main configuration class."""

    def __init__(self):
        self.azure = AzureConfig()
        self.openai = OpenAIConfig()
        self.ml = MLConfig()
        self.storage = StorageConfig()
        self.paths = {
            "project_root": PROJECT_ROOT,
            "data": DATA_DIR,
            "models": MODELS_DIR,
            "reports": REPORTS_DIR,
        }


# Global configuration instance
config = Config()


def validate_config() -> bool:
    """Validate that required configuration is present."""
    required_vars = [
        "AZURE_SUBSCRIPTION_ID",
        "AZURE_RESOURCE_GROUP",
        "AZURE_OPENAI_ENDPOINT",
        "AZURE_OPENAI_API_KEY",
    ]

    missing_vars = [var for var in required_vars if not os.getenv(var)]

    if missing_vars:
        raise ValueError(f"Missing required environment variables: {missing_vars}")

    return True
