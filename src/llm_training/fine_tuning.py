"""
Fine-tuning manager for Azure OpenAI models.
"""

import json
import os
import time
from typing import Dict, Any, List, Optional
from azure.ai.ml import MLClient
from openai import AzureOpenAI
from ..common import AzureFoundryClient, get_logger

logger = get_logger(__name__)


class FineTuningManager:
    """Manage fine-tuning operations for Azure OpenAI models."""
    
    def __init__(self, foundry_client: AzureFoundryClient = None):
        """Initialize fine-tuning manager."""
        self.foundry_client = foundry_client or AzureFoundryClient()
        self.openai_client = AzureOpenAI(
            api_key=self.foundry_client.credential.get_token("https://cognitiveservices.azure.com/.default").token,
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            api_version="2024-02-01"
        )
    
    def prepare_training_data(self, conversations: List[Dict], output_path: str) -> str:
        """
        Prepare training data in JSONL format for fine-tuning.
        
        Args:
            conversations: List of conversation dictionaries with 'messages' key
            output_path: Path to save the training data file
            
        Returns:
            Path to the created training file
        """
        with open(output_path, 'w') as f:
            for conversation in conversations:
                if 'messages' not in conversation:
                    logger.warning("Skipping conversation without 'messages' key")
                    continue
                
                # Validate message format
                messages = conversation['messages']
                if not all('role' in msg and 'content' in msg for msg in messages):
                    logger.warning("Skipping conversation with invalid message format")
                    continue
                
                # Write to JSONL
                training_example = {"messages": messages}
                f.write(json.dumps(training_example) + '\n')
        
        logger.info(f"Training data prepared: {output_path}")
        return output_path
    
    def upload_training_file(self, file_path: str) -> str:
        """
        Upload training file to Azure OpenAI.
        
        Args:
            file_path: Path to the training data file
            
        Returns:
            File ID for the uploaded file
        """
        try:
            with open(file_path, 'rb') as f:
                response = self.openai_client.files.create(
                    file=f,
                    purpose="fine-tune"
                )
            
            file_id = response.id
            logger.info(f"Training file uploaded: {file_id}")
            return file_id
        
        except Exception as e:
            logger.error(f"Failed to upload training file: {e}")
            raise
    
    def create_fine_tuning_job(
        self, 
        training_file_id: str, 
        model: str = "gpt-35-turbo",
        validation_file_id: Optional[str] = None,
        hyperparameters: Optional[Dict] = None
    ) -> str:
        """
        Create a fine-tuning job.
        
        Args:
            training_file_id: ID of the uploaded training file
            model: Base model to fine-tune
            validation_file_id: Optional validation file ID
            hyperparameters: Optional hyperparameters for training
            
        Returns:
            Fine-tuning job ID
        """
        try:
            job_params = {
                "training_file": training_file_id,
                "model": model
            }
            
            if validation_file_id:
                job_params["validation_file"] = validation_file_id
            
            if hyperparameters:
                job_params["hyperparameters"] = hyperparameters
            
            response = self.openai_client.fine_tuning.jobs.create(**job_params)
            
            job_id = response.id
            logger.info(f"Fine-tuning job created: {job_id}")
            return job_id
        
        except Exception as e:
            logger.error(f"Failed to create fine-tuning job: {e}")
            raise
    
    def monitor_fine_tuning_job(self, job_id: str, poll_interval: int = 60) -> Dict[str, Any]:
        """
        Monitor fine-tuning job progress.
        
        Args:
            job_id: Fine-tuning job ID
            poll_interval: Polling interval in seconds
            
        Returns:
            Final job status
        """
        logger.info(f"Monitoring fine-tuning job: {job_id}")
        
        while True:
            try:
                job = self.openai_client.fine_tuning.jobs.retrieve(job_id)
                status = job.status
                
                logger.info(f"Job {job_id} status: {status}")
                
                if status in ["succeeded", "failed", "cancelled"]:
                    logger.info(f"Fine-tuning job completed with status: {status}")
                    return {
                        "job_id": job_id,
                        "status": status,
                        "fine_tuned_model": getattr(job, 'fine_tuned_model', None),
                        "training_file": job.training_file,
                        "created_at": job.created_at,
                        "finished_at": getattr(job, 'finished_at', None)
                    }
                
                time.sleep(poll_interval)
                
            except Exception as e:
                logger.error(f"Error monitoring job: {e}")
                time.sleep(poll_interval)
    
    def list_fine_tuning_jobs(self, limit: int = 10) -> List[Dict[str, Any]]:
        """
        List recent fine-tuning jobs.
        
        Args:
            limit: Maximum number of jobs to return
            
        Returns:
            List of job information
        """
        try:
            jobs = self.openai_client.fine_tuning.jobs.list(limit=limit)
            
            return [
                {
                    "id": job.id,
                    "status": job.status,
                    "model": job.model,
                    "fine_tuned_model": getattr(job, 'fine_tuned_model', None),
                    "created_at": job.created_at
                }
                for job in jobs.data
            ]
        
        except Exception as e:
            logger.error(f"Failed to list fine-tuning jobs: {e}")
            return []
    
    def delete_fine_tuned_model(self, model_id: str) -> bool:
        """
        Delete a fine-tuned model.
        
        Args:
            model_id: ID of the fine-tuned model to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            self.openai_client.models.delete(model_id)
            logger.info(f"Fine-tuned model deleted: {model_id}")
            return True
        
        except Exception as e:
            logger.error(f"Failed to delete model {model_id}: {e}")
            return False