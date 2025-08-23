"""Azure OpenAI integration for GenAI models."""

import json
import logging
from typing import Any, Dict, List, Optional, Union

import openai
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

from ..config import config

logger = logging.getLogger(__name__)


class AzureOpenAIClient:
    """Client for Azure OpenAI services."""

    def __init__(self):
        self.endpoint = config.openai.endpoint
        self.api_key = config.openai.api_key
        self.api_version = config.openai.api_version
        self.deployment_name = config.openai.deployment_name

        # Initialize OpenAI client for Azure
        openai.api_type = "azure"
        openai.api_base = self.endpoint
        openai.api_version = self.api_version
        openai.api_key = self.api_key

    def generate_completion(
        self,
        prompt: str,
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None,
        **kwargs,
    ) -> str:
        """Generate text completion using Azure OpenAI."""
        try:
            max_tokens = max_tokens or config.ml.max_tokens
            temperature = temperature or config.ml.temperature

            response = openai.Completion.create(
                engine=self.deployment_name,
                prompt=prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                **kwargs,
            )

            return response.choices[0].text.strip()
        except Exception as e:
            logger.error(f"Error generating completion: {e}")
            raise

    def generate_chat_completion(
        self,
        messages: List[Dict[str, str]],
        max_tokens: Optional[int] = None,
        temperature: Optional[float] = None,
        **kwargs,
    ) -> str:
        """Generate chat completion using Azure OpenAI."""
        try:
            max_tokens = max_tokens or config.ml.max_tokens
            temperature = temperature or config.ml.temperature

            response = openai.ChatCompletion.create(
                engine=self.deployment_name,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
                **kwargs,
            )

            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"Error generating chat completion: {e}")
            raise

    def generate_embeddings(self, texts: List[str], **kwargs) -> List[List[float]]:
        """Generate embeddings using Azure OpenAI."""
        try:
            response = openai.Embedding.create(
                engine="text-embedding-ada-002",  # Embedding model
                input=texts,
                **kwargs,
            )

            return [item["embedding"] for item in response["data"]]
        except Exception as e:
            logger.error(f"Error generating embeddings: {e}")
            raise


class PromptTemplate:
    """Template for managing prompts."""

    def __init__(self, template: str):
        self.template = template

    def format(self, **kwargs) -> str:
        """Format the template with provided variables."""
        try:
            return self.template.format(**kwargs)
        except KeyError as e:
            logger.error(f"Missing template variable: {e}")
            raise

    @classmethod
    def from_file(cls, file_path: str) -> "PromptTemplate":
        """Load template from file."""
        with open(file_path, "r") as f:
            template = f.read()
        return cls(template)


class GenAIModel:
    """High-level interface for GenAI models."""

    def __init__(self, model_type: str = "chat"):
        self.client = AzureOpenAIClient()
        self.model_type = model_type

    def predict(self, input_text: Union[str, List[Dict[str, str]]], **kwargs) -> str:
        """Generate prediction using the model."""
        try:
            if self.model_type == "chat":
                if isinstance(input_text, str):
                    messages = [{"role": "user", "content": input_text}]
                else:
                    messages = input_text
                return self.client.generate_chat_completion(messages, **kwargs)
            else:
                if isinstance(input_text, list):
                    input_text = "\n".join(
                        [msg.get("content", "") for msg in input_text]
                    )
                return self.client.generate_completion(input_text, **kwargs)
        except Exception as e:
            logger.error(f"Error in model prediction: {e}")
            raise

    def batch_predict(
        self, inputs: List[Union[str, List[Dict[str, str]]]], **kwargs
    ) -> List[str]:
        """Generate predictions for a batch of inputs."""
        results = []
        for input_item in inputs:
            try:
                result = self.predict(input_item, **kwargs)
                results.append(result)
            except Exception as e:
                logger.error(f"Error in batch prediction: {e}")
                results.append("")  # Add empty result for failed predictions
        return results


# Common prompt templates
CLASSIFICATION_TEMPLATE = """
Classify the following text into one of these categories: {categories}

Text: {text}

Classification:
"""

SUMMARIZATION_TEMPLATE = """
Summarize the following text in {max_sentences} sentences:

Text: {text}

Summary:
"""

QA_TEMPLATE = """
Context: {context}

Question: {question}

Answer:
"""
