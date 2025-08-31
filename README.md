# AzureGenAIOps - Comprehensive LLM Operations Platform

A comprehensive GenAIOps (Generative AI Operations) platform built on Azure AI Foundry, providing end-to-end LLM lifecycle management with industry best practices.

## 📖 Documentation

- **🎯 [END-TO-END GUIDE](END_TO_END_GUIDE.md)** - Complete setup and operations guide
- **🔐 [GitHub Secrets Guide](GITHUB_SECRETS_GUIDE.md)** - Secure credential management  
- **🔄 [Migration Guide](MIGRATION_GUIDE.md)** - Migrate from .env files to GitHub secrets
- **🏗️ [Infrastructure Guide](infrastructure/README.md)** - Deployment details

## 🚀 Features

### Core LLM Operations
- **🚀 LLM Training**: Fine-tuning and custom model training with Azure OpenAI
- **🧱 LLM Application Development**: Build production-ready AI applications  
- **🩸 LLM RAG**: Retrieval-Augmented Generation with Azure AI Search
- **🟩 LLM Inference**: High-performance model serving and completions
- **🚧 LLM Serving**: Scalable model deployment and endpoint management
- **📤 LLM Data Extraction**: Document processing with Azure Document Intelligence
- **🌠 LLM Data Generation**: Synthetic data creation for training and testing
- **💎 LLM Agents**: AI agent frameworks and multi-step workflows
- **⚖️ LLM Evaluation**: Comprehensive model testing and quality assessment
- **🔍 LLM Monitoring**: Real-time observability and performance tracking
- **📅 LLM Prompts**: Advanced prompt engineering and management
- **📝 LLM Structured Outputs**: JSON, XML, and schema-based generation
- **🛑 LLM Safety and Security**: Content filtering and jailbreak protection
- **💠 LLM Embedding Models**: Vector search and semantic similarity

### Azure AI Foundry Integration
- Seamless integration with Azure AI Foundry projects
- Native support for Azure OpenAI Service
- Azure AI Search for vector and hybrid search
- Azure Document Intelligence for data extraction
- Azure Monitor for comprehensive observability
- Azure Key Vault for secure credential management

## 🏗️ Architecture

```
src/
├── common/                # Azure AI Foundry client and shared utilities
├── llm_training/          # 🚀 Model training and fine-tuning
├── app_development/       # 🧱 Application development frameworks
├── rag/                   # 🩸 Retrieval-Augmented Generation
├── inference/             # 🟩 Model inference and completions
├── serving/               # 🚧 Model serving and deployment
├── data_extraction/       # 📤 Document processing and data extraction
├── data_generation/       # 🌠 Synthetic data generation
├── agents/                # 💎 AI agents and workflows
├── evaluation/            # ⚖️ Model evaluation and testing
├── monitoring/            # 🔍 Observability and monitoring
├── prompts/               # 📅 Prompt engineering and management
├── structured_outputs/    # 📝 Structured output generation
├── safety_security/       # 🛑 Safety filtering and security
├── embeddings/            # 💠 Embedding generation and vector ops
└── app.py                 # FastAPI application with all endpoints
```

## 🛠️ Setup

### 📚 Complete Setup Guide

**🎯 NEW: [END-TO-END GUIDE](END_TO_END_GUIDE.md) - Comprehensive step-by-step guide covering:**
- 🏗️ Resource setup (Greenfield & Brownfield deployments)  
- 🔐 GitHub secrets integration with Azure subscription
- 🔬 Experimentation with RAG, Fine-Tuning, Prompt Management & Evaluation
- 🧪 Unit testing and development workflows
- 🚀 CI/CD for LLM operations pipeline
- 📊 Monitoring and observability

### 🚀 Quick Start with Automated Deployment

The fastest way to get started is using our automated Azure deployment:

#### Option 1: Deploy Everything New (Recommended)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fkorkridake%2FAzureGenAIOps%2Fmain%2Finfrastructure%2Fazuredeploy.json)

Click the "Deploy to Azure" button above for a guided deployment experience, or use the command line:

```bash
# Clone the repository
git clone https://github.com/korkridake/AzureGenAIOps.git
cd AzureGenAIOps

# Run automated deployment (creates all Azure resources)
./infrastructure/scripts/deploy-new.sh
```

#### Option 2: Use Your Existing Azure Resources
```bash
# Deploy using your existing Azure AI services
./infrastructure/scripts/deploy-existing.sh
```

The deployment scripts will:
- ✅ Create/configure all required Azure resources
- ✅ Set up monitoring and security
- ✅ Deploy the GenAIOps application
- ✅ Generate environment configuration files
- ✅ Provide testing endpoints

### 📋 Prerequisites

#### For Automated Deployment:
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 2.50.0+
- Azure subscription with **Contributor** access
- **10-15 minutes** for complete deployment

#### For Manual Setup:
- Python 3.9+
- Azure CLI
- Azure AI Foundry project
- Azure OpenAI Service
- Docker (optional)

### 🏗️ Azure Infrastructure Deployment

We provide comprehensive infrastructure-as-code using Azure Bicep:

#### New Deployment (All Resources)
Creates a complete GenAIOps platform with:
- Azure AI Foundry Project
- Azure OpenAI Service (GPT-4, GPT-3.5-Turbo, embeddings)
- Azure AI Search (vector + semantic search)
- Azure Storage (documents, models, data)
- Azure Container Apps (application hosting)
- Azure Monitor (observability)
- Azure Key Vault (secure configuration)

```bash
# Interactive deployment
./infrastructure/scripts/deploy-new.sh

# Or with parameters
./infrastructure/scripts/deploy-new.sh \
  --resource-group "my-genaiops-rg" \
  --location "East US" \
  --environment "dev"
```

#### Existing Resources Deployment
Uses your existing Azure AI services and adds minimal new infrastructure:

```bash
# Interactive deployment
./infrastructure/scripts/deploy-existing.sh

# Or with parameters  
./infrastructure/scripts/deploy-existing.sh \
  --ai-foundry "my-ai-foundry" \
  --openai "my-openai" \
  --search "my-search" \
  --storage "mystorage"
```

#### PowerShell Alternative
```powershell
# Deploy new infrastructure
.\infrastructure\scripts\deploy.ps1 -DeploymentType new

# Deploy with existing resources
.\infrastructure\scripts\deploy.ps1 -DeploymentType existing
```

#### GitHub Actions Integration
Deploy via GitHub Actions with automated CI/CD:

1. Set up Azure service principal secrets
2. Use workflow dispatch to deploy infrastructure
3. Supports dev/staging/prod environments
4. Includes validation and security scanning

For secure secret management, follow the [GitHub Secrets Integration Guide](GITHUB_SECRETS_GUIDE.md).

See [Infrastructure README](infrastructure/README.md) for detailed documentation.

### 🔧 Manual Installation (Alternative)

If you prefer manual setup:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/korkridake/AzureGenAIOps.git
   cd AzureGenAIOps
   ```

2. **Create virtual environment:**
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

4. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your Azure AI Foundry configuration
   ```

### 🔑 Configuration

After deployment, you'll have:

#### Generated Files:
- `.env.deployed` or `.env.existing` - Copy to `.env`
- `deployment-outputs-*.json` - Resource details
- Azure resources ready for immediate use

#### Key Environment Variables:
```bash
AZURE_AI_PROJECT_NAME=your-ai-foundry-project
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_STORAGE_ACCOUNT_NAME=your-storage-account
AZURE_KEY_VAULT_NAME=your-key-vault
```

## 🚀 Usage

### Start the API Server

```bash
# Start the comprehensive LLM operations API
uvicorn src.app:app --host 0.0.0.0 --port 8000

# Or use the make command
make run
```

### API Endpoints

#### 🟩 Inference & Completions
```bash
# Chat completion
curl -X POST "http://localhost:8000/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Explain machine learning"}
    ],
    "max_tokens": 1000,
    "temperature": 0.7
  }'

# Text completion
curl -X POST "http://localhost:8000/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "The future of AI is",
    "max_tokens": 500
  }'
```

#### 🩸 RAG (Retrieval-Augmented Generation)
```bash
# RAG query with document retrieval
curl -X POST "http://localhost:8000/rag/query" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the benefits of using Azure AI?",
    "top_k": 5,
    "score_threshold": 0.7
  }'
```

#### 💠 Embeddings
```bash
# Generate embeddings
curl -X POST "http://localhost:8000/embeddings" \
  -H "Content-Type: application/json" \
  -d '{
    "texts": ["Hello world", "Azure AI is powerful"]
  }'
```

#### 🛑 Safety & Security
```bash
# Content safety check
curl -X POST "http://localhost:8000/safety/check" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "How to build a machine learning model?",
    "check_type": "both"
  }'
```

#### 🔍 Monitoring
```bash
# Get system metrics
curl "http://localhost:8000/metrics"

# Health check
curl "http://localhost:8000/health"
```

### Python SDK Usage

```python
from src.common import AzureFoundryClient, LLMConfig
from src.inference import InferenceEngine
from src.rag import RAGPipeline
from src.embeddings import EmbeddingGenerator

# Initialize components
config = LLMConfig()
foundry_client = AzureFoundryClient()
inference_engine = InferenceEngine(config)
rag_pipeline = RAGPipeline(config)

# Generate chat completion
response = inference_engine.chat_completion([
    {"role": "user", "content": "Explain quantum computing"}
])

# Perform RAG query
rag_response = rag_pipeline.query(
    question="What is Azure AI Foundry?",
    top_k=3
)

# Generate embeddings
embeddings = EmbeddingGenerator(config)
vectors = embeddings.generate_embeddings_batch([
    "Text to embed",
    "Another text sample"
])
```

## 🧪 Testing & Development

```bash
# Run comprehensive test suite
make test

# Run with coverage
make test-coverage

# Lint and format code
make lint
make format

# Security scanning
make security-scan

# Type checking
make type-check
```

## 📊 CI/CD Pipeline

The project includes GitHub Actions workflows for:

### Main CI/CD Pipeline (`.github/workflows/ci-cd.yml`)
- **Testing**: Unit tests, integration tests, safety checks
- **Building**: Docker images with multi-stage builds
- **Security**: Bandit security scanning, dependency checks
- **Deployment**: Azure Container Instances, Azure Container Apps
- **Quality**: Code coverage, type checking, linting

### LLM Operations Pipeline (`.github/workflows/llm-ops.yml`)
- **Model Training**: Automated fine-tuning workflows
- **Model Evaluation**: Performance testing and validation
- **RAG Indexing**: Automated document processing and indexing
- **Safety Testing**: Content filtering and jailbreak testing
- **Monitoring**: Model performance and drift detection

## 🔧 Configuration

### Environment Variables

Key configuration in `.env`:

```bash
# Azure AI Foundry
AZURE_AI_PROJECT_NAME=your-ai-foundry-project
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=your-resource-group

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

# Azure AI Search (RAG)
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_SEARCH_API_KEY=your-search-key

# Safety & Security
CONTENT_FILTER_ENABLED=true
PII_DETECTION_ENABLED=true
JAILBREAK_DETECTION_ENABLED=true
```

## 📈 Monitoring and Observability

- **Azure Monitor**: Application insights and custom metrics
- **OpenTelemetry**: Distributed tracing and performance monitoring
- **Custom Dashboards**: Model performance, usage analytics, safety metrics
- **Alerting**: Automated alerts for model drift, performance issues, safety violations

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-llm-feature`)
3. Commit your changes (`git commit -m 'Add amazing LLM feature'`)
4. Push to the branch (`git push origin feature/amazing-llm-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Azure AI Foundry](https://azure.microsoft.com/en-us/products/ai-foundry) for the comprehensive AI platform
- [Azure OpenAI Service](https://azure.microsoft.com/en-us/products/ai-services/openai-service) for GPT model access
- [LangChain](https://python.langchain.com/) for AI application development frameworks
- [FastAPI](https://fastapi.tiangolo.com/) for the high-performance API framework

## 📞 Support

For support, please open an issue on GitHub or contact the maintainers.

---

**Built with ❤️ for Comprehensive LLM Operations on Azure AI Foundry**