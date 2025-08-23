"""Model training and evaluation pipeline."""

import json
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

import mlflow
import pandas as pd
from azure.ai.ml import MLClient
from azure.identity import DefaultAzureCredential
from sklearn.metrics import accuracy_score, classification_report, f1_score

from ..config import config
from .azure_openai import GenAIModel, PromptTemplate

logger = logging.getLogger(__name__)


class ModelTrainer:
    """Train and evaluate GenAI models."""

    def __init__(self):
        self.ml_client = self._get_ml_client()
        self.model = GenAIModel()

    def _get_ml_client(self) -> MLClient:
        """Get Azure ML client."""
        credential = DefaultAzureCredential()
        return MLClient(
            credential=credential,
            subscription_id=config.azure.subscription_id,
            resource_group_name=config.azure.resource_group,
            workspace_name=config.ml.workspace_name,
        )

    def evaluate_classification(
        self,
        test_data: pd.DataFrame,
        text_column: str,
        label_column: str,
        prompt_template: str,
        categories: List[str],
    ) -> Dict[str, Any]:
        """Evaluate classification model."""
        try:
            # Start MLflow run
            with mlflow.start_run() as run:
                predictions = []
                true_labels = test_data[label_column].tolist()

                template = PromptTemplate(prompt_template)

                for _, row in test_data.iterrows():
                    prompt = template.format(
                        text=row[text_column], categories=", ".join(categories)
                    )

                    try:
                        prediction = self.model.predict(prompt)
                        # Extract the predicted category (simple heuristic)
                        predicted_category = self._extract_category(
                            prediction, categories
                        )
                        predictions.append(predicted_category)
                    except Exception as e:
                        logger.error(f"Error predicting for row: {e}")
                        predictions.append(categories[0])  # Default to first category

                # Calculate metrics
                accuracy = accuracy_score(true_labels, predictions)
                f1 = f1_score(true_labels, predictions, average="weighted")

                # Log metrics to MLflow
                mlflow.log_metric("accuracy", accuracy)
                mlflow.log_metric("f1_score", f1)
                mlflow.log_param("model_type", "azure_openai")
                mlflow.log_param("prompt_template", prompt_template)

                # Generate classification report
                report = classification_report(
                    true_labels, predictions, target_names=categories, output_dict=True
                )

                results = {
                    "accuracy": accuracy,
                    "f1_score": f1,
                    "classification_report": report,
                    "predictions": predictions,
                    "true_labels": true_labels,
                    "run_id": run.info.run_id,
                }

                logger.info(
                    f"Evaluation completed. Accuracy: {accuracy:.3f}, F1: {f1:.3f}"
                )
                return results

        except Exception as e:
            logger.error(f"Error in model evaluation: {e}")
            raise

    def _extract_category(self, prediction: str, categories: List[str]) -> str:
        """Extract category from model prediction."""
        prediction_lower = prediction.lower()

        for category in categories:
            if category.lower() in prediction_lower:
                return category

        # If no match found, return the first category as default
        return categories[0]

    def fine_tune_model(
        self,
        training_data: pd.DataFrame,
        validation_data: pd.DataFrame,
        model_name: str,
    ) -> str:
        """Fine-tune a model (placeholder for actual fine-tuning)."""
        # Note: This would involve uploading data to Azure OpenAI fine-tuning service
        # For now, this is a placeholder that logs the training configuration

        try:
            with mlflow.start_run() as run:
                mlflow.log_param("training_samples", len(training_data))
                mlflow.log_param("validation_samples", len(validation_data))
                mlflow.log_param("base_model", model_name)

                # In a real implementation, you would:
                # 1. Format data for fine-tuning
                # 2. Upload to Azure OpenAI
                # 3. Start fine-tuning job
                # 4. Monitor training progress
                # 5. Deploy fine-tuned model

                logger.info(f"Fine-tuning job initiated for {model_name}")
                return run.info.run_id

        except Exception as e:
            logger.error(f"Error in fine-tuning: {e}")
            raise

    def save_model_artifacts(
        self, model_info: Dict[str, Any], output_dir: Path
    ) -> None:
        """Save model artifacts and metadata."""
        try:
            output_dir.mkdir(parents=True, exist_ok=True)

            # Save model metadata
            model_metadata = {
                "model_type": "azure_openai",
                "deployment_name": config.openai.deployment_name,
                "api_version": config.openai.api_version,
                "created_at": pd.Timestamp.now().isoformat(),
                **model_info,
            }

            metadata_path = output_dir / "model_metadata.json"
            with open(metadata_path, "w") as f:
                json.dump(model_metadata, f, indent=2)

            logger.info(f"Model artifacts saved to {output_dir}")

        except Exception as e:
            logger.error(f"Error saving model artifacts: {e}")
            raise


def train_model(
    train_data_path: str,
    val_data_path: str,
    model_output_path: str,
    task_type: str = "classification",
) -> None:
    """Main training function."""
    trainer = ModelTrainer()

    # Load data
    train_df = pd.read_csv(train_data_path)
    val_df = pd.read_csv(val_data_path)

    if task_type == "classification":
        # Example classification evaluation
        categories = train_df["label"].unique().tolist()

        results = trainer.evaluate_classification(
            test_data=val_df,
            text_column="text",
            label_column="label",
            prompt_template="""
            Classify the following text into one of these categories: {categories}
            
            Text: {text}
            
            Classification:
            """,
            categories=categories,
        )

        # Save results
        trainer.save_model_artifacts(
            model_info=results, output_dir=Path(model_output_path)
        )

    logger.info("Training pipeline completed successfully")
