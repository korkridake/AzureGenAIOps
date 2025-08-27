#!/usr/bin/env python3
"""Deploy Azure ML pipeline."""

import logging
from pathlib import Path

from azure.ai.ml import MLClient, command
from azure.ai.ml.entities import Environment, Job
from azure.identity import DefaultAzureCredential

from src.config import config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def create_environment() -> Environment:
    """Create Azure ML environment."""
    env = Environment(
        name="genai-ops-env",
        description="Environment for GenAI Ops pipeline",
        conda_file="environment.yml",
        image="mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:latest",
    )
    return env


def create_training_job() -> Job:
    """Create training job."""
    job = command(
        code="./src",
        command="python -m models.train_model --train-data ${{inputs.train_data}} --val-data ${{inputs.val_data}} --output-dir ${{outputs.model_dir}}",
        environment="genai-ops-env@latest",
        inputs={
            "train_data": {"type": "uri_file", "path": "azureml://datastores/workspaceblobstore/paths/data/train.csv"},
            "val_data": {"type": "uri_file", "path": "azureml://datastores/workspaceblobstore/paths/data/validation.csv"},
        },
        outputs={
            "model_dir": {"type": "uri_folder", "path": "azureml://datastores/workspaceblobstore/paths/models/"},
        },
        compute="cpu-cluster",
        display_name="GenAI Model Training",
        description="Train GenAI model using Azure OpenAI",
    )
    return job


def main():
    """Deploy ML pipeline to Azure."""
    try:
        # Initialize ML client
        credential = DefaultAzureCredential()
        ml_client = MLClient(
            credential=credential,
            subscription_id=config.azure.subscription_id,
            resource_group_name=config.azure.resource_group,
            workspace_name=config.ml.workspace_name,
        )
        
        # Create environment
        env = create_environment()
        ml_client.environments.create_or_update(env)
        logger.info("Environment created/updated successfully")
        
        # Create and submit training job
        job = create_training_job()
        job_result = ml_client.jobs.create_or_update(job)
        logger.info(f"Training job submitted: {job_result.name}")
        
        # You can add pipeline creation here for more complex workflows
        
    except Exception as e:
        logger.error(f"Error deploying ML pipeline: {e}")
        raise


if __name__ == "__main__":
    main()