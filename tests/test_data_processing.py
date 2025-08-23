"""Test data processing module."""

import pandas as pd
import pytest
from pathlib import Path
from unittest.mock import Mock, patch

from src.data.make_dataset import DataProcessor, make_dataset


@pytest.fixture
def sample_data():
    """Create sample data for testing."""
    return pd.DataFrame(
        {
            "text": ["Hello world", "This is a test", "Another example", ""],
            "label": ["positive", "neutral", "positive", "negative"],
        }
    )


def test_load_csv_data(tmp_path, sample_data):
    """Test loading CSV data."""
    # Create temporary CSV file
    csv_path = tmp_path / "test_data.csv"
    sample_data.to_csv(csv_path, index=False)

    processor = DataProcessor()
    loaded_data = processor.load_csv_data(csv_path)

    assert len(loaded_data) == 4
    assert list(loaded_data.columns) == ["text", "label"]


def test_preprocess_text_data(sample_data):
    """Test text preprocessing."""
    processor = DataProcessor()
    processed_data = processor.preprocess_text_data(sample_data, "text")

    # Should remove empty strings
    assert len(processed_data) == 3
    assert "" not in processed_data["text"].values


def test_split_data(sample_data):
    """Test data splitting."""
    processor = DataProcessor()
    splits = processor.split_data(sample_data, train_ratio=0.6, val_ratio=0.2)

    assert "train" in splits
    assert "validation" in splits
    assert "test" in splits

    total_samples = (
        len(splits["train"]) + len(splits["validation"]) + len(splits["test"])
    )
    assert total_samples == len(sample_data)


def test_save_processed_data(tmp_path, sample_data):
    """Test saving processed data."""
    processor = DataProcessor()
    splits = {"train": sample_data, "validation": sample_data}

    processor.save_processed_data(splits, tmp_path)

    assert (tmp_path / "train.csv").exists()
    assert (tmp_path / "validation.csv").exists()


@patch("src.data.make_dataset.DataProcessor")
def test_make_dataset(mock_processor_class, tmp_path, sample_data):
    """Test main make_dataset function."""
    # Setup mocks
    mock_processor = Mock()
    mock_processor_class.return_value = mock_processor
    mock_processor.load_csv_data.return_value = sample_data
    mock_processor.preprocess_text_data.return_value = sample_data
    mock_processor.split_data.return_value = {"train": sample_data}

    input_path = tmp_path / "input.csv"
    output_path = tmp_path / "output"

    make_dataset(input_path, output_path, "text")

    # Verify method calls
    mock_processor.load_csv_data.assert_called_once_with(input_path)
    mock_processor.preprocess_text_data.assert_called_once_with(sample_data, "text")
    mock_processor.split_data.assert_called_once()
    mock_processor.save_processed_data.assert_called_once()
