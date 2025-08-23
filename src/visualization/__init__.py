"""Visualization utilities."""

import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from pathlib import Path
from typing import List, Optional

# Set style
plt.style.use("seaborn-v0_8")
sns.set_palette("husl")


def plot_label_distribution(
    df: pd.DataFrame, label_column: str, title: str = "Label Distribution"
) -> None:
    """Plot distribution of labels."""
    plt.figure(figsize=(10, 6))
    sns.countplot(data=df, x=label_column)
    plt.title(title)
    plt.xlabel(label_column.title())
    plt.ylabel("Count")
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()


def plot_text_length_distribution(
    df: pd.DataFrame,
    text_column: str,
    label_column: Optional[str] = None,
    title: str = "Text Length Distribution",
) -> None:
    """Plot distribution of text lengths."""
    df_plot = df.copy()
    df_plot["text_length"] = df_plot[text_column].str.len()

    plt.figure(figsize=(12, 6))

    if label_column:
        sns.histplot(data=df_plot, x="text_length", hue=label_column, bins=30)
    else:
        sns.histplot(data=df_plot, x="text_length", bins=30)

    plt.title(title)
    plt.xlabel("Text Length (characters)")
    plt.ylabel("Frequency")
    plt.tight_layout()
    plt.show()


def plot_model_metrics(metrics: dict, save_path: Optional[Path] = None) -> None:
    """Plot model evaluation metrics."""
    fig, axes = plt.subplots(1, 2, figsize=(15, 6))

    # Accuracy and F1 score
    metrics_to_plot = ["accuracy", "f1_score"]
    values = [metrics.get(metric, 0) for metric in metrics_to_plot]

    axes[0].bar(metrics_to_plot, values)
    axes[0].set_title("Model Performance Metrics")
    axes[0].set_ylabel("Score")
    axes[0].set_ylim(0, 1)

    # Classification report heatmap
    if "classification_report" in metrics:
        report_df = pd.DataFrame(metrics["classification_report"]).transpose()
        # Remove 'support' column and last three rows (macro avg, weighted avg, accuracy)
        report_df = report_df.drop(["support"], axis=1).iloc[:-3]

        sns.heatmap(report_df, annot=True, cmap="Blues", ax=axes[1])
        axes[1].set_title("Classification Report")

    plt.tight_layout()

    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches="tight")

    plt.show()


def save_plots_to_reports(output_dir: Path) -> None:
    """Save all generated plots to reports directory."""
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Plots saved to {output_dir}")
