"""Test configuration module."""

import os
import pytest
from src.config import config, validate_config


def test_config_structure():
    """Test that config has expected structure."""
    assert hasattr(config, "azure")
    assert hasattr(config, "openai")
    assert hasattr(config, "ml")
    assert hasattr(config, "storage")
    assert hasattr(config, "paths")


def test_azure_config(mock_env_vars):
    """Test Azure configuration."""
    from src.config import AzureConfig
    
    azure_config = AzureConfig()
    assert azure_config.subscription_id == "test-subscription-id"
    assert azure_config.resource_group == "test-resource-group"
    assert azure_config.location == "eastus"


def test_openai_config(mock_env_vars):
    """Test OpenAI configuration."""
    from src.config import OpenAIConfig
    
    openai_config = OpenAIConfig()
    assert openai_config.endpoint == "https://test-openai.openai.azure.com/"
    assert openai_config.api_key == "test-api-key"
    assert openai_config.deployment_name == "gpt-35-turbo"


def test_validate_config_success(mock_env_vars):
    """Test config validation with all required vars."""
    assert validate_config() is True


def test_validate_config_failure(monkeypatch):
    """Test config validation with missing vars."""
    # Remove required environment variable
    monkeypatch.delenv("AZURE_SUBSCRIPTION_ID", raising=False)
    
    with pytest.raises(ValueError, match="Missing required environment variables"):
        validate_config()