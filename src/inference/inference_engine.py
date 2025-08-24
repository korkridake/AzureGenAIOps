"""
Core inference engine for LLM predictions.
"""

from typing import Dict, Any, List, Optional, Union, AsyncGenerator
import asyncio
import json
from openai import AzureOpenAI, AsyncAzureOpenAI
from ..common import LLMConfig, get_logger
from ..safety_security import ContentFilter

logger = get_logger(__name__)


class InferenceEngine:
    """
    Core LLM inference engine with safety filters and monitoring.
    """
    
    def __init__(self, config: LLMConfig = None):
        """Initialize inference engine."""
        self.config = config or LLMConfig()
        
        # Initialize OpenAI clients
        self.client = AzureOpenAI(
            api_key=self.config.azure_openai_api_key,
            azure_endpoint=self.config.azure_openai_endpoint,
            api_version=self.config.azure_openai_api_version
        )
        
        self.async_client = AsyncAzureOpenAI(
            api_key=self.config.azure_openai_api_key,
            azure_endpoint=self.config.azure_openai_endpoint,
            api_version=self.config.azure_openai_api_version
        )
        
        # Initialize content filter
        self.content_filter = ContentFilter(config) if config.content_filter_enabled else None
    
    def generate_completion(
        self,
        prompt: str,
        model: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        top_p: float = 1.0,
        frequency_penalty: float = 0.0,
        presence_penalty: float = 0.0,
        stop: Optional[List[str]] = None,
        stream: bool = False
    ) -> Dict[str, Any]:
        """
        Generate text completion from prompt.
        
        Args:
            prompt: Input prompt
            model: Model to use (defaults to config)
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            top_p: Nucleus sampling parameter
            frequency_penalty: Frequency penalty
            presence_penalty: Presence penalty
            stop: Stop sequences
            stream: Whether to stream response
            
        Returns:
            Completion response with metadata
        """
        try:
            # Apply content filtering
            if self.content_filter:
                filter_result = self.content_filter.check_input(prompt)
                if not filter_result["is_safe"]:
                    return {
                        "error": "Content filtered",
                        "filter_reason": filter_result["reason"],
                        "completion": None
                    }
            
            # Prepare parameters
            model_name = model or self.config.azure_openai_deployment_name
            
            response = self.client.completions.create(
                model=model_name,
                prompt=prompt,
                max_tokens=max_tokens,
                temperature=temperature,
                top_p=top_p,
                frequency_penalty=frequency_penalty,
                presence_penalty=presence_penalty,
                stop=stop,
                stream=stream
            )
            
            if stream:
                return {"stream": response}
            
            # Extract completion
            completion_text = response.choices[0].text
            
            # Apply output filtering
            if self.content_filter:
                filter_result = self.content_filter.check_output(completion_text)
                if not filter_result["is_safe"]:
                    return {
                        "error": "Output filtered",
                        "filter_reason": filter_result["reason"],
                        "completion": None
                    }
            
            return {
                "completion": completion_text,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": model_name,
                "finish_reason": response.choices[0].finish_reason
            }
            
        except Exception as e:
            logger.error(f"Completion generation failed: {e}")
            return {"error": str(e), "completion": None}
    
    def chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        top_p: float = 1.0,
        frequency_penalty: float = 0.0,
        presence_penalty: float = 0.0,
        stop: Optional[List[str]] = None,
        stream: bool = False,
        functions: Optional[List[Dict]] = None,
        function_call: Optional[Union[str, Dict]] = None
    ) -> Dict[str, Any]:
        """
        Generate chat completion from messages.
        
        Args:
            messages: List of message dictionaries
            model: Model to use (defaults to config)
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            top_p: Nucleus sampling parameter
            frequency_penalty: Frequency penalty
            presence_penalty: Presence penalty
            stop: Stop sequences
            stream: Whether to stream response
            functions: Available functions for function calling
            function_call: Function call configuration
            
        Returns:
            Chat completion response with metadata
        """
        try:
            # Apply content filtering to user messages
            if self.content_filter:
                for message in messages:
                    if message.get("role") == "user":
                        filter_result = self.content_filter.check_input(message["content"])
                        if not filter_result["is_safe"]:
                            return {
                                "error": "Content filtered",
                                "filter_reason": filter_result["reason"],
                                "response": None
                            }
            
            # Prepare parameters
            model_name = model or self.config.azure_openai_deployment_name
            
            params = {
                "model": model_name,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": temperature,
                "top_p": top_p,
                "frequency_penalty": frequency_penalty,
                "presence_penalty": presence_penalty,
                "stream": stream
            }
            
            if stop:
                params["stop"] = stop
            if functions:
                params["functions"] = functions
            if function_call:
                params["function_call"] = function_call
            
            response = self.client.chat.completions.create(**params)
            
            if stream:
                return {"stream": response}
            
            # Extract response
            message = response.choices[0].message
            response_content = message.content
            
            # Apply output filtering
            if self.content_filter and response_content:
                filter_result = self.content_filter.check_output(response_content)
                if not filter_result["is_safe"]:
                    return {
                        "error": "Output filtered",
                        "filter_reason": filter_result["reason"],
                        "response": None
                    }
            
            result = {
                "response": response_content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": model_name,
                "finish_reason": response.choices[0].finish_reason
            }
            
            # Include function call if present
            if hasattr(message, 'function_call') and message.function_call:
                result["function_call"] = {
                    "name": message.function_call.name,
                    "arguments": message.function_call.arguments
                }
            
            return result
            
        except Exception as e:
            logger.error(f"Chat completion failed: {e}")
            return {"error": str(e), "response": None}
    
    async def async_chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7,
        stream: bool = False
    ) -> Dict[str, Any]:
        """
        Asynchronous chat completion.
        
        Args:
            messages: List of message dictionaries
            model: Model to use
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            stream: Whether to stream response
            
        Returns:
            Chat completion response
        """
        try:
            model_name = model or self.config.azure_openai_deployment_name
            
            response = await self.async_client.chat.completions.create(
                model=model_name,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
                stream=stream
            )
            
            if stream:
                return {"stream": response}
            
            return {
                "response": response.choices[0].message.content,
                "usage": {
                    "prompt_tokens": response.usage.prompt_tokens,
                    "completion_tokens": response.usage.completion_tokens,
                    "total_tokens": response.usage.total_tokens
                },
                "model": model_name,
                "finish_reason": response.choices[0].finish_reason
            }
            
        except Exception as e:
            logger.error(f"Async chat completion failed: {e}")
            return {"error": str(e), "response": None}
    
    async def stream_chat_completion(
        self,
        messages: List[Dict[str, str]],
        model: str = None,
        max_tokens: int = 1000,
        temperature: float = 0.7
    ) -> AsyncGenerator[str, None]:
        """
        Stream chat completion responses.
        
        Args:
            messages: List of message dictionaries
            model: Model to use
            max_tokens: Maximum tokens to generate
            temperature: Sampling temperature
            
        Yields:
            Streaming response chunks
        """
        try:
            model_name = model or self.config.azure_openai_deployment_name
            
            response = await self.async_client.chat.completions.create(
                model=model_name,
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature,
                stream=True
            )
            
            async for chunk in response:
                if chunk.choices[0].delta.content:
                    yield chunk.choices[0].delta.content
                    
        except Exception as e:
            logger.error(f"Streaming failed: {e}")
            yield f"Error: {str(e)}"
    
    def get_model_info(self, model: str = None) -> Dict[str, Any]:
        """
        Get information about a model.
        
        Args:
            model: Model name (defaults to config)
            
        Returns:
            Model information
        """
        try:
            model_name = model or self.config.azure_openai_deployment_name
            
            # This would typically call a model info endpoint
            # For now, return basic info
            return {
                "model": model_name,
                "max_tokens": 4096,  # Default for GPT models
                "context_length": 8192,
                "supports_functions": True,
                "supports_streaming": True
            }
            
        except Exception as e:
            logger.error(f"Failed to get model info: {e}")
            return {"error": str(e)}
    
    def validate_input(self, text: str, max_length: int = 8000) -> Dict[str, Any]:
        """
        Validate input text.
        
        Args:
            text: Input text to validate
            max_length: Maximum allowed length
            
        Returns:
            Validation result
        """
        if not text or not text.strip():
            return {"is_valid": False, "reason": "Empty input"}
        
        if len(text) > max_length:
            return {"is_valid": False, "reason": f"Input too long: {len(text)} > {max_length}"}
        
        # Additional validation can be added here
        return {"is_valid": True}