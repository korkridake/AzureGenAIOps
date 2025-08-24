"""
Azure AI Foundry client for centralized AI operations.
"""

import os
from typing import Dict, Any, Optional
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
import logging

logger = logging.getLogger(__name__)


class AzureFoundryClient:
    """Central client for Azure AI Foundry operations."""
    
    def __init__(self, subscription_id: str = None, resource_group: str = None, project_name: str = None):
        """Initialize Azure AI Foundry client."""
        self.subscription_id = subscription_id or os.getenv("AZURE_SUBSCRIPTION_ID")
        self.resource_group = resource_group or os.getenv("AZURE_RESOURCE_GROUP")
        self.project_name = project_name or os.getenv("AZURE_AI_PROJECT_NAME")
        
        if not all([self.subscription_id, self.resource_group, self.project_name]):
            raise ValueError("Missing required Azure AI configuration")
        
        self.credential = DefaultAzureCredential()
        self._ml_client = None
        self._ai_client = None
    
    @property
    def ml_client(self) -> MLClient:
        """Get Azure ML client."""
        if self._ml_client is None:
            self._ml_client = MLClient(
                credential=self.credential,
                subscription_id=self.subscription_id,
                resource_group_name=self.resource_group,
                workspace_name=self.project_name
            )
        return self._ml_client
    
    @property
    def ai_client(self) -> AIProjectClient:
        """Get Azure AI Project client."""
        if self._ai_client is None:
            connection_string = f"https://{self.project_name}.cognitiveservices.azure.com/"
            self._ai_client = AIProjectClient.from_connection_string(
                credential=self.credential,
                conn_str=connection_string
            )
        return self._ai_client
    
    def get_deployment(self, deployment_name: str) -> Dict[str, Any]:
        """Get model deployment details."""
        try:
            deployment = self.ml_client.online_deployments.get(
                name=deployment_name,
                endpoint_name=deployment_name
            )
            return {
                "name": deployment.name,
                "model": deployment.model,
                "endpoint": deployment.endpoint_name,
                "status": deployment.provisioning_state
            }
        except Exception as e:
            logger.error(f"Failed to get deployment {deployment_name}: {e}")
            return {}
    
    def list_models(self) -> list:
        """List available models in the project."""
        try:
            models = self.ml_client.models.list()
            return [{"name": model.name, "version": model.version} for model in models]
        except Exception as e:
            logger.error(f"Failed to list models: {e}")
            return []
    
    def get_connection(self, connection_name: str) -> Optional[Dict[str, Any]]:
        """Get connection details for external services."""
        try:
            connection = self.ml_client.connections.get(connection_name)
            return {
                "name": connection.name,
                "type": connection.type,
                "target": getattr(connection, 'target', None)
            }
        except Exception as e:
            logger.error(f"Failed to get connection {connection_name}: {e}")
            return None