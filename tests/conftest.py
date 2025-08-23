"""Test configuration."""

import os
import pytest


@pytest.fixture
def mock_env_vars(monkeypatch):
    """Mock environment variables for testing."""
    test_vars = {
        "AZURE_SUBSCRIPTION_ID": "test-subscription-id",
        "AZURE_RESOURCE_GROUP": "test-resource-group",
        "AZURE_LOCATION": "eastus",
        "AZURE_OPENAI_ENDPOINT": "https://test-openai.openai.azure.com/",
        "AZURE_OPENAI_API_KEY": "test-api-key",
        "AZURE_OPENAI_API_VERSION": "2023-12-01-preview",
        "AZURE_OPENAI_DEPLOYMENT_NAME": "gpt-35-turbo",
        "AZURE_ML_WORKSPACE_NAME": "test-workspace",
        "AZURE_STORAGE_ACCOUNT_NAME": "teststorage",
    }
    
    for key, value in test_vars.items():
        monkeypatch.setenv(key, value)
    
    return test_vars