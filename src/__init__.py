"""
AzureGenAIOps - Comprehensive LLM Operations Platform

A complete GenAI Operations platform with Azure AI Foundry integration,
providing end-to-end LLM lifecycle management.

## Features
🚀 LLM Training & Fine-tuning
🧱 LLM Application Development  
🩸 LLM RAG (Retrieval-Augmented Generation)
🟩 LLM Inference & Completions
🚧 LLM Serving & Deployment
📤 LLM Data Extraction
🌠 LLM Data Generation
💎 LLM Agents & Workflows
⚖️ LLM Evaluation & Testing
🔍 LLM Monitoring & Observability
📅 LLM Prompts & Engineering
📝 LLM Structured Outputs
🛑 LLM Safety & Security
💠 LLM Embedding Models

## Azure AI Foundry Integration
- Azure OpenAI Service
- Azure AI Search
- Azure Document Intelligence
- Azure Monitor
- Azure Storage
"""

__version__ = "1.0.0"
__author__ = "Korkrid Kyle Akepanidtaworn"
__email__ = "korkrid@example.com"

# Core imports (always available)
from .common import LLMConfig, get_logger, validate_environment

# Optional imports (may fail if dependencies not installed)
try:
    from .common import AzureFoundryClient
except ImportError:
    AzureFoundryClient = None

try:
    from .inference import InferenceEngine
except ImportError:
    InferenceEngine = None

try:
    from .rag import RAGPipeline
except ImportError:
    RAGPipeline = None

try:
    from .embeddings import EmbeddingGenerator
except ImportError:
    EmbeddingGenerator = None

try:
    from .safety_security import ContentFilter
except ImportError:
    ContentFilter = None

__all__ = [
    # Core components (always available)
    "LLMConfig",
    "get_logger",
    "validate_environment",
    
    # Optional LLM Operations (may be None)
    "AzureFoundryClient",
    "InferenceEngine",
    "RAGPipeline", 
    "EmbeddingGenerator",
    "ContentFilter",
    
    # Version info
    "__version__",
    "__author__",
    "__email__"
]
