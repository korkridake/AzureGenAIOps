"""Data processing utilities for Azure GenAI Ops."""

import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

import pandas as pd
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

from ..config import config

logger = logging.getLogger(__name__)


class AzureDataLoader:
    """Load data from Azure Storage."""

    def __init__(self, storage_account_name: Optional[str] = None):
        self.storage_account_name = storage_account_name or config.storage.account_name
        self.credential = DefaultAzureCredential()
        self.blob_service_client = self._get_blob_service_client()

    def _get_blob_service_client(self) -> BlobServiceClient:
        """Get Azure Blob Service client."""
        account_url = f"https://{self.storage_account_name}.blob.core.windows.net"
        return BlobServiceClient(account_url=account_url, credential=self.credential)

    def download_blob(
        self, container_name: str, blob_name: str, local_path: Path
    ) -> None:
        """Download a blob from Azure Storage."""
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=container_name, blob=blob_name
            )

            with open(local_path, "wb") as download_file:
                download_file.write(blob_client.download_blob().readall())

            logger.info(f"Downloaded {blob_name} to {local_path}")
        except Exception as e:
            logger.error(f"Error downloading blob {blob_name}: {e}")
            raise

    def upload_blob(
        self, container_name: str, blob_name: str, local_path: Path
    ) -> None:
        """Upload a blob to Azure Storage."""
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=container_name, blob=blob_name
            )

            with open(local_path, "rb") as data:
                blob_client.upload_blob(data, overwrite=True)

            logger.info(f"Uploaded {local_path} to {blob_name}")
        except Exception as e:
            logger.error(f"Error uploading blob {blob_name}: {e}")
            raise


class DataProcessor:
    """Process data for GenAI training and inference."""

    def __init__(self):
        self.loader = AzureDataLoader()

    def load_csv_data(self, file_path: Union[str, Path]) -> pd.DataFrame:
        """Load CSV data."""
        try:
            df = pd.read_csv(file_path)
            logger.info(f"Loaded {len(df)} rows from {file_path}")
            return df
        except Exception as e:
            logger.error(f"Error loading CSV data: {e}")
            raise

    def preprocess_text_data(self, df: pd.DataFrame, text_column: str) -> pd.DataFrame:
        """Preprocess text data for GenAI models."""
        try:
            # Basic text preprocessing
            df = df.copy()
            df[text_column] = df[text_column].astype(str)
            df[text_column] = df[text_column].str.strip()
            df = df[df[text_column] != ""]

            logger.info(f"Preprocessed {len(df)} text samples")
            return df
        except Exception as e:
            logger.error(f"Error preprocessing text data: {e}")
            raise

    def split_data(
        self, df: pd.DataFrame, train_ratio: float = 0.8, val_ratio: float = 0.1
    ) -> Dict[str, pd.DataFrame]:
        """Split data into train/validation/test sets."""
        try:
            n = len(df)
            train_size = int(n * train_ratio)
            val_size = int(n * val_ratio)

            # Shuffle data
            df_shuffled = df.sample(frac=1).reset_index(drop=True)

            train_df = df_shuffled[:train_size]
            val_df = df_shuffled[train_size : train_size + val_size]
            test_df = df_shuffled[train_size + val_size :]

            logger.info(
                f"Split data: train={len(train_df)}, val={len(val_df)}, test={len(test_df)}"
            )

            return {"train": train_df, "validation": val_df, "test": test_df}
        except Exception as e:
            logger.error(f"Error splitting data: {e}")
            raise

    def save_processed_data(
        self, data_splits: Dict[str, pd.DataFrame], output_dir: Path
    ) -> None:
        """Save processed data splits."""
        try:
            output_dir.mkdir(parents=True, exist_ok=True)

            for split_name, df in data_splits.items():
                output_path = output_dir / f"{split_name}.csv"
                df.to_csv(output_path, index=False)
                logger.info(f"Saved {split_name} data to {output_path}")
        except Exception as e:
            logger.error(f"Error saving processed data: {e}")
            raise


def make_dataset(
    input_path: Union[str, Path],
    output_path: Union[str, Path],
    text_column: str = "text",
) -> None:
    """Main function to process raw data into train/val/test sets."""
    processor = DataProcessor()

    # Load raw data
    raw_df = processor.load_csv_data(input_path)

    # Preprocess
    processed_df = processor.preprocess_text_data(raw_df, text_column)

    # Split data
    data_splits = processor.split_data(processed_df)

    # Save processed data
    processor.save_processed_data(data_splits, Path(output_path))

    logger.info("Data processing completed successfully")
