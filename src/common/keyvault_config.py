"""
Azure Key Vault configuration management for secure secret retrieval.
"""

import os
import logging
from typing import Optional, Dict, Any, Union
from pathlib import Path

try:
    from azure.identity import DefaultAzureCredential, ClientSecretCredential
    from azure.keyvault.secrets import SecretClient
    AZURE_AVAILABLE = True
except ImportError:
    AZURE_AVAILABLE = False
    DefaultAzureCredential = None
    SecretClient = None
    ClientSecretCredential = None

logger = logging.getLogger(__name__)


class KeyVaultConfig:
    """Configuration management using Azure Key Vault for secrets."""
    
    def __init__(
        self,
        key_vault_name: Optional[str] = None,
        use_managed_identity: bool = True,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
        tenant_id: Optional[str] = None
    ):
        """
        Initialize Key Vault configuration.
        
        Args:
            key_vault_name: Name of the Azure Key Vault
            use_managed_identity: Whether to use managed identity (recommended for Azure environments)
            client_id: Service principal client ID (for service principal auth)
            client_secret: Service principal client secret (for service principal auth)
            tenant_id: Azure tenant ID (for service principal auth)
        """
        if not AZURE_AVAILABLE:
            logger.warning("Azure SDK not available. Falling back to environment variables.")
            self._client = None
            return
        
        self.key_vault_name = key_vault_name or os.getenv("AZURE_KEY_VAULT_NAME")
        if not self.key_vault_name:
            logger.warning("No Key Vault name provided. Falling back to environment variables.")
            self._client = None
            return
        
        # Initialize credential
        if use_managed_identity:
            credential = DefaultAzureCredential()
        else:
            # Use service principal authentication
            credential = ClientSecretCredential(
                tenant_id=tenant_id or os.getenv("AZURE_TENANT_ID"),
                client_id=client_id or os.getenv("AZURE_CLIENT_ID"),
                client_secret=client_secret or os.getenv("AZURE_CLIENT_SECRET")
            )
        
        # Initialize Key Vault client
        vault_url = f"https://{self.key_vault_name}.vault.azure.net/"
        try:
            self._client = SecretClient(vault_url=vault_url, credential=credential)
            logger.info(f"Initialized Key Vault client for {self.key_vault_name}")
        except Exception as e:
            logger.error(f"Failed to initialize Key Vault client: {e}")
            self._client = None
    
    def get_secret(self, secret_name: str, default_value: Optional[str] = None) -> Optional[str]:
        """
        Get a secret from Key Vault, falling back to environment variables.
        
        Args:
            secret_name: Name of the secret in Key Vault
            default_value: Default value if secret not found
            
        Returns:
            Secret value or default value
        """
        if not self._client:
            # Fall back to environment variable
            env_var_name = secret_name.upper().replace("-", "_")
            return os.getenv(env_var_name, default_value)
        
        try:
            secret = self._client.get_secret(secret_name)
            logger.debug(f"Retrieved secret '{secret_name}' from Key Vault")
            return secret.value
        except Exception as e:
            logger.warning(f"Failed to retrieve secret '{secret_name}' from Key Vault: {e}")
            # Fall back to environment variable
            env_var_name = secret_name.upper().replace("-", "_")
            return os.getenv(env_var_name, default_value)
    
    def get_all_secrets(self) -> Dict[str, str]:
        """Get all secrets from Key Vault."""
        if not self._client:
            return {}
        
        secrets = {}
        try:
            secret_properties = self._client.list_properties_of_secrets()
            for secret_property in secret_properties:
                try:
                    secret = self._client.get_secret(secret_property.name)
                    secrets[secret_property.name] = secret.value
                except Exception as e:
                    logger.warning(f"Failed to retrieve secret '{secret_property.name}': {e}")
            
            logger.info(f"Retrieved {len(secrets)} secrets from Key Vault")
        except Exception as e:
            logger.error(f"Failed to list secrets from Key Vault: {e}")
        
        return secrets


class EnhancedLLMConfig:
    """Enhanced LLM configuration with Key Vault integration."""
    
    def __init__(self, use_key_vault: bool = True, key_vault_name: Optional[str] = None):
        """
        Initialize enhanced configuration.
        
        Args:
            use_key_vault: Whether to use Key Vault for secrets
            key_vault_name: Name of the Key Vault (optional)
        """
        # Initialize Key Vault client if requested
        if use_key_vault:
            # Detect if running in Azure (managed identity available)
            use_managed_identity = os.getenv("AZURE_CLIENT_ID") is None
            self.kv_config = KeyVaultConfig(
                key_vault_name=key_vault_name,
                use_managed_identity=use_managed_identity
            )
        else:
            self.kv_config = None
        
        # Load configuration with Key Vault fallback
        self._load_configuration()
    
    def _get_config_value(self, key_vault_key: str, env_var_key: str, default_value: Optional[str] = None) -> Optional[str]:
        """Get configuration value from Key Vault, environment, or default."""
        if self.kv_config:
            return self.kv_config.get_secret(key_vault_key, os.getenv(env_var_key, default_value))
        else:
            return os.getenv(env_var_key, default_value)
    
    def _load_configuration(self):
        """Load all configuration values."""
        # Azure AI Foundry Configuration
        self.azure_subscription_id = self._get_config_value("subscription-id", "AZURE_SUBSCRIPTION_ID")
        self.azure_resource_group = self._get_config_value("resource-group", "AZURE_RESOURCE_GROUP")
        self.azure_location = self._get_config_value("location", "AZURE_LOCATION", "eastus")
        self.azure_ai_project_name = self._get_config_value("ai-project-name", "AZURE_AI_PROJECT_NAME")
        
        # Azure OpenAI Configuration
        self.azure_openai_endpoint = self._get_config_value("openai-endpoint", "AZURE_OPENAI_ENDPOINT")
        self.azure_openai_api_key = self._get_config_value("openai-api-key", "AZURE_OPENAI_API_KEY")
        self.azure_openai_deployment_name = self._get_config_value("openai-deployment-name", "AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4")
        self.azure_openai_api_version = self._get_config_value("openai-api-version", "AZURE_OPENAI_API_VERSION", "2024-02-01")
        
        # Azure AI Search Configuration
        self.azure_search_endpoint = self._get_config_value("search-endpoint", "AZURE_SEARCH_ENDPOINT")
        self.azure_search_api_key = self._get_config_value("search-api-key", "AZURE_SEARCH_API_KEY")
        self.azure_search_index_name = self._get_config_value("search-index-name", "AZURE_SEARCH_INDEX_NAME", "documents")
        
        # Azure Document Intelligence
        self.azure_doc_intelligence_endpoint = self._get_config_value("doc-intelligence-endpoint", "AZURE_DOC_INTELLIGENCE_ENDPOINT")
        self.azure_doc_intelligence_api_key = self._get_config_value("doc-intelligence-api-key", "AZURE_DOC_INTELLIGENCE_API_KEY")
        
        # Azure Storage Configuration
        self.azure_storage_account_name = self._get_config_value("storage-account-name", "AZURE_STORAGE_ACCOUNT_NAME")
        self.azure_storage_container_name = self._get_config_value("storage-container-name", "AZURE_STORAGE_CONTAINER_NAME", "llm-data")
        self.azure_storage_connection_string = self._get_config_value("storage-connection-string", "AZURE_STORAGE_CONNECTION_STRING")
        
        # Azure Key Vault Configuration
        self.azure_key_vault_name = self._get_config_value("key-vault-name", "AZURE_KEY_VAULT_NAME")
        
        # Embedding Models Configuration
        self.embedding_model_name = self._get_config_value("embedding-model-name", "EMBEDDING_MODEL_NAME", "text-embedding-ada-002")
        embedding_dimensions_str = self._get_config_value("embedding-dimensions", "EMBEDDING_DIMENSIONS", "1536")
        self.embedding_dimensions = int(embedding_dimensions_str) if embedding_dimensions_str else 1536
        
        # LLM Training Configuration
        self.training_data_path = self._get_config_value("training-data-path", "TRAINING_DATA_PATH", "data/training")
        max_tokens_str = self._get_config_value("max-training-tokens", "MAX_TRAINING_TOKENS", "100000")
        self.max_training_tokens = int(max_tokens_str) if max_tokens_str else 100000
        epochs_str = self._get_config_value("training-epochs", "TRAINING_EPOCHS", "3")
        self.training_epochs = int(epochs_str) if epochs_str else 3
        
        # Safety and Security Configuration
        content_filter_str = self._get_config_value("content-filter-enabled", "CONTENT_FILTER_ENABLED", "true")
        self.content_filter_enabled = content_filter_str.lower() == "true" if content_filter_str else True
        pii_detection_str = self._get_config_value("pii-detection-enabled", "PII_DETECTION_ENABLED", "true")
        self.pii_detection_enabled = pii_detection_str.lower() == "true" if pii_detection_str else True
        jailbreak_detection_str = self._get_config_value("jailbreak-detection-enabled", "JAILBREAK_DETECTION_ENABLED", "true")
        self.jailbreak_detection_enabled = jailbreak_detection_str.lower() == "true" if jailbreak_detection_str else True
        
        # Monitoring Configuration
        self.azure_monitor_connection_string = self._get_config_value("monitor-connection-string", "AZURE_MONITOR_CONNECTION_STRING")
        telemetry_str = self._get_config_value("enable-telemetry", "ENABLE_TELEMETRY", "true")
        self.enable_telemetry = telemetry_str.lower() == "true" if telemetry_str else True
        
        # Application Configuration
        self.log_level = self._get_config_value("log-level", "LOG_LEVEL", "INFO")
        self.environment = self._get_config_value("environment", "ENVIRONMENT", "development")
        self.api_host = self._get_config_value("api-host", "API_HOST", "0.0.0.0")
        api_port_str = self._get_config_value("api-port", "API_PORT", "8000")
        self.api_port = int(api_port_str) if api_port_str else 8000
        
        # JWT Configuration
        self.jwt_signing_key = self._get_config_value("jwt-signing-key", "JWT_SIGNING_KEY")
        
        # Azure credential for programmatic access
        if AZURE_AVAILABLE:
            try:
                self.credential = DefaultAzureCredential()
            except Exception as e:
                logger.warning(f"Failed to initialize Azure credential: {e}")
                self.credential = None
        else:
            self.credential = None
        
        # Project paths
        project_root = Path(__file__).parent.parent.parent
        self.paths = {
            "project_root": project_root,
            "data": project_root / "data",
            "models": project_root / "models",
            "reports": project_root / "reports",
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
    
    def validate_required_config(self) -> bool:
        """Validate that required configuration is present."""
        required_configs = [
            ("azure_subscription_id", "Azure Subscription ID"),
            ("azure_resource_group", "Azure Resource Group"),
            ("azure_ai_project_name", "Azure AI Project Name"),
            ("azure_openai_endpoint", "Azure OpenAI Endpoint"),
            ("azure_openai_api_key", "Azure OpenAI API Key"),
        ]
        
        missing_configs = []
        for config_attr, config_name in required_configs:
            if not getattr(self, config_attr):
                missing_configs.append(config_name)
        
        if missing_configs:
            raise ValueError(f"Missing required configuration: {', '.join(missing_configs)}")
        
        return True


# Convenience function to create configuration
def create_config(use_key_vault: bool = None, key_vault_name: Optional[str] = None) -> EnhancedLLMConfig:
    """
    Create configuration instance with automatic Key Vault detection.
    
    Args:
        use_key_vault: Whether to use Key Vault (auto-detected if None)
        key_vault_name: Key Vault name (auto-detected if None)
    
    Returns:
        Enhanced configuration instance
    """
    if use_key_vault is None:
        # Auto-detect: use Key Vault if name is available and Azure SDK is available
        use_key_vault = AZURE_AVAILABLE and (
            key_vault_name is not None or 
            os.getenv("AZURE_KEY_VAULT_NAME") is not None
        )
    
    return EnhancedLLMConfig(use_key_vault=use_key_vault, key_vault_name=key_vault_name)