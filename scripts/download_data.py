#!/usr/bin/env python3
"""Download data from Azure Storage."""

import argparse
import logging
from pathlib import Path

from src.data.make_dataset import AzureDataLoader
from src.config import config

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def download_data(version: str = "latest") -> None:
    """Download training data from Azure Storage."""
    try:
        loader = AzureDataLoader()
        
        # Create data directories
        raw_data_dir = Path("data/raw")
        raw_data_dir.mkdir(parents=True, exist_ok=True)
        
        # Download training data
        blob_name = f"training_data_{version}.csv" if version != "latest" else "training_data.csv"
        local_path = raw_data_dir / "training_data.csv"
        
        loader.download_blob(
            container_name=config.storage.container_name,
            blob_name=blob_name,
            local_path=local_path
        )
        
        logger.info(f"Downloaded training data version {version} to {local_path}")
        
    except Exception as e:
        logger.error(f"Error downloading data: {e}")
        raise


def main():
    """Main function."""
    parser = argparse.ArgumentParser(description="Download training data from Azure Storage")
    parser.add_argument("--version", default="latest", help="Data version to download")
    
    args = parser.parse_args()
    download_data(args.version)


if __name__ == "__main__":
    main()