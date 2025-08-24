"""
AzureGenAIOps - Comprehensive LLM Operations API.

A complete GenAI Operations platform with Azure AI Foundry integration, 
supporting all aspects of LLM lifecycle management.
"""

import logging
from typing import Dict, List, Any, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

# Import LLM Operations modules
from .common import LLMConfig, AzureFoundryClient, get_logger
from .inference import InferenceEngine
from .rag import RAGPipeline
from .embeddings import EmbeddingGenerator
from .safety_security import ContentFilter
from .monitoring import TelemetryCollector
from .evaluation import ModelEvaluator

# Configure logging
logger = get_logger(__name__)

# Global components
config = LLMConfig()
foundry_client = AzureFoundryClient()
inference_engine = InferenceEngine(config)
rag_pipeline = RAGPipeline(config)
embedding_generator = EmbeddingGenerator(config)
content_filter = ContentFilter(config)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager."""
    logger.info("Starting AzureGenAIOps API...")
    # Startup logic here
    yield
    logger.info("Shutting down AzureGenAIOps API...")
    # Cleanup logic here


app = FastAPI(
    title="AzureGenAIOps - LLM Operations Platform",
    description="""
    🚀 Comprehensive GenAI Operations platform with Azure AI Foundry integration
    
    ## Features
    - 🚀 LLM Training & Fine-tuning
    - 🧱 Application Development
    - 🩸 RAG (Retrieval-Augmented Generation)
    - 🟩 Model Inference & Completions
    - 🚧 Model Serving & Deployment
    - 📤 Data Extraction from Documents
    - 🌠 Synthetic Data Generation
    - 💎 AI Agents & Workflows
    - ⚖️ Model Evaluation & Testing
    - 🔍 Monitoring & Observability
    - 📅 Prompt Management
    - 📝 Structured Output Generation
    - 🛑 Safety & Security Filtering
    - 💠 Embedding Generation & Search
    """,
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic models
class ChatMessage(BaseModel):
    role: str = Field(..., description="Message role: 'system', 'user', or 'assistant'")
    content: str = Field(..., description="Message content")


class ChatCompletionRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., description="List of chat messages")
    model: Optional[str] = Field(None, description="Model to use")
    max_tokens: int = Field(1000, description="Maximum tokens to generate")
    temperature: float = Field(0.7, description="Sampling temperature")
    stream: bool = Field(False, description="Enable streaming response")


class CompletionRequest(BaseModel):
    prompt: str = Field(..., description="Input prompt")
    model: Optional[str] = Field(None, description="Model to use")
    max_tokens: int = Field(1000, description="Maximum tokens to generate")
    temperature: float = Field(0.7, description="Sampling temperature")


class RAGQueryRequest(BaseModel):
    question: str = Field(..., description="Question to answer")
    top_k: int = Field(5, description="Number of documents to retrieve")
    score_threshold: float = Field(0.7, description="Minimum relevance score")
    system_prompt: Optional[str] = Field(None, description="Custom system prompt")


class EmbeddingRequest(BaseModel):
    texts: List[str] = Field(..., description="Texts to embed")
    model: Optional[str] = Field(None, description="Embedding model to use")


class SafetyCheckRequest(BaseModel):
    text: str = Field(..., description="Text to check for safety")
    check_type: str = Field("both", description="Check type: 'input', 'output', or 'both'")


# API Endpoints

@app.get("/")
async def root():
    """Root endpoint with API information."""
    return {
        "message": "AzureGenAIOps - LLM Operations Platform",
        "version": "1.0.0",
        "features": [
            "🚀 LLM Training", "🧱 App Development", "🩸 RAG", "🟩 Inference",
            "🚧 Serving", "📤 Data Extraction", "🌠 Data Generation", "💎 Agents",
            "⚖️ Evaluation", "🔍 Monitoring", "📅 Prompts", "📝 Structured Outputs",
            "🛑 Safety & Security", "💠 Embeddings"
        ],
        "azure_ai_foundry": True
    }


@app.get("/health")
async def health_check():
    """Health check endpoint."""
    try:
        # Basic connectivity check
        model_info = inference_engine.get_model_info()
        return {
            "status": "healthy",
            "azure_ai_foundry": "connected",
            "model": model_info.get("model", "unknown"),
            "timestamp": "2024-01-01T00:00:00Z"
        }
    except Exception as e:
        return {
            "status": "unhealthy",
            "error": str(e),
            "timestamp": "2024-01-01T00:00:00Z"
        }


# 🟩 Inference Endpoints
@app.post("/completions")
async def create_completion(request: CompletionRequest):
    """Generate text completion."""
    try:
        result = inference_engine.generate_completion(
            prompt=request.prompt,
            model=request.model,
            max_tokens=request.max_tokens,
            temperature=request.temperature
        )
        return result
    except Exception as e:
        logger.error(f"Completion failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat/completions")
async def create_chat_completion(request: ChatCompletionRequest):
    """Generate chat completion."""
    try:
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        result = inference_engine.chat_completion(
            messages=messages,
            model=request.model,
            max_tokens=request.max_tokens,
            temperature=request.temperature,
            stream=request.stream
        )
        return result
    except Exception as e:
        logger.error(f"Chat completion failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# 🩸 RAG Endpoints
@app.post("/rag/query")
async def rag_query(request: RAGQueryRequest):
    """Query using RAG (Retrieval-Augmented Generation)."""
    try:
        result = rag_pipeline.query(
            question=request.question,
            top_k=request.top_k,
            score_threshold=request.score_threshold,
            system_prompt=request.system_prompt
        )
        return result
    except Exception as e:
        logger.error(f"RAG query failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# 💠 Embedding Endpoints
@app.post("/embeddings")
async def create_embeddings(request: EmbeddingRequest):
    """Generate embeddings for texts."""
    try:
        embeddings = embedding_generator.generate_embeddings_batch(request.texts)
        return {
            "embeddings": embeddings,
            "model": embedding_generator.model_name,
            "usage": {
                "total_tokens": sum(len(text.split()) for text in request.texts)
            }
        }
    except Exception as e:
        logger.error(f"Embedding generation failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# 🛑 Safety Endpoints
@app.post("/safety/check")
async def safety_check(request: SafetyCheckRequest):
    """Check text for safety and content filtering."""
    try:
        if request.check_type in ["input", "both"]:
            input_result = content_filter.check_input(request.text)
        else:
            input_result = {"is_safe": True}
            
        if request.check_type in ["output", "both"]:
            output_result = content_filter.check_output(request.text)
        else:
            output_result = {"is_safe": True}
        
        return {
            "input_check": input_result,
            "output_check": output_result,
            "overall_safe": input_result["is_safe"] and output_result["is_safe"]
        }
    except Exception as e:
        logger.error(f"Safety check failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# 🔍 Monitoring Endpoints
@app.get("/metrics")
async def get_metrics():
    """Get system metrics and telemetry."""
    try:
        return {
            "api_status": "operational",
            "azure_ai_foundry": "connected",
            "models_available": foundry_client.list_models(),
            "content_filter_stats": content_filter.get_filter_stats(),
            "requests_processed": 0  # Would be tracked in real implementation
        }
    except Exception as e:
        logger.error(f"Metrics collection failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# Azure AI Foundry Integration Endpoints
@app.get("/foundry/models")
async def list_foundry_models():
    """List available models in Azure AI Foundry project."""
    try:
        models = foundry_client.list_models()
        return {"models": models}
    except Exception as e:
        logger.error(f"Failed to list foundry models: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/foundry/deployments/{deployment_name}")
async def get_deployment_info(deployment_name: str):
    """Get deployment information from Azure AI Foundry."""
    try:
        deployment = foundry_client.get_deployment(deployment_name)
        return deployment
    except Exception as e:
        logger.error(f"Failed to get deployment info: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app, 
        host=config.api_host, 
        port=config.api_port,
        log_level=config.log_level.lower()
    )
