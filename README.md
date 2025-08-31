# AzureGenAIOps - Comprehensive LLM Operations Platform

A comprehensive GenAIOps (Generative AI Operations) platform built on Azure AI Foundry, providing end-to-end LLM lifecycle management with industry best practices.

## 📖 Documentation & Quick Navigation

- **🎯 [END-TO-END GUIDE](END_TO_END_GUIDE.md)** - Complete lifecycle guide following this structure
- **🔐 [GitHub Secrets Guide](GITHUB_SECRETS_GUIDE.md)** - Secure credential management  
- **🔄 [Migration Guide](MIGRATION_GUIDE.md)** - Migrate from .env files to GitHub secrets
- **🏗️ [Infrastructure Guide](infrastructure/README.md)** - Deployment details

## 🚀 Getting Started

Start your GenAI journey with these foundational steps:

### 🏗️ Resource Set-up
Set up compute, storage, dependencies, and API keys for your Azure AI environment.

**Quick Deployment Options:**

#### Option 1: New Azure Resources (Greenfield)
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fkorkridake%2FAzureGenAIOps%2Fmain%2Finfrastructure%2Fazuredeploy.json)

```bash
# Automated deployment creates all Azure resources
git clone https://github.com/korkridake/AzureGenAIOps.git
cd AzureGenAIOps
./infrastructure/scripts/deploy-new.sh
```

#### Option 2: Existing Azure Resources (Brownfield)
```bash
# Use your existing Azure AI services
./infrastructure/scripts/deploy-existing.sh
```

**What You Get:**
- ✅ Azure AI Foundry Project with GPT-4 & embeddings
- ✅ Azure AI Search for vector/semantic search
- ✅ Azure Storage for documents and models
- ✅ Azure Monitor for observability
- ✅ Azure Key Vault for secure credentials
- ✅ FastAPI application with all LLM operations

### 🎮 Playground
Try out model capabilities interactively before diving into code.

```bash
# Start the interactive API server
uvicorn src.app:app --host 0.0.0.0 --port 8000

# Access interactive playground
open http://localhost:8000/docs
```

**Key Playground Features:**
- **💬 Chat Completions**: Test conversational AI capabilities
- **📝 Text Generation**: Experiment with creative writing and content generation
- **🔍 Search & RAG**: Query your documents with semantic search
- **💠 Embeddings**: Generate vector representations for similarity search
- **🛡️ Safety Testing**: Test content filtering and security measures

## 🎨 Customization

Enhance your AI applications with domain-specific capabilities:

### 🩸 RAG (Retrieval-Augmented Generation)
Add domain-specific knowledge via embeddings and vector databases.

```python
from src.rag import RAGPipeline

# Initialize RAG with your documents
rag = RAGPipeline(config)

# Query with context retrieval
response = rag.query(
    question="What are the key features of our product?",
    top_k=5,
    score_threshold=0.7
)
```

**RAG Capabilities:**
- **📄 Document Processing**: PDF, Word, PowerPoint, and web content
- **🔍 Vector Search**: Semantic similarity and hybrid search
- **🧠 Contextual Responses**: Grounded answers from your knowledge base
- **⚡ Real-time Indexing**: Dynamic document updates and search

### 🎯 Fine-tuning
Train models further with custom datasets for specialized tasks.

```python
from src.llm_training import FineTuningPipeline

# Prepare your training data
training_pipeline = FineTuningPipeline(config)

# Fine-tune on domain-specific data
job = training_pipeline.start_fine_tuning(
    training_file="path/to/training_data.jsonl",
    model="gpt-3.5-turbo",
    task_type="classification"
)
```

**Fine-tuning Features:**
- **📊 Custom Datasets**: Support for classification, generation, and instruction-following
- **🔄 Training Pipelines**: Automated data preparation and model training
- **📈 Performance Tracking**: Monitor training metrics and validation accuracy
- **🚀 Model Deployment**: Seamless deployment of fine-tuned models

## 🔬 Experimentation

Systematically develop and refine your AI solutions:

### 📝 Prompt Management
Organize and iterate on prompts systematically for optimal performance.

```python
from src.prompts import PromptManager

# Manage prompts with versioning
prompt_manager = PromptManager()

# Create prompt templates
prompt_manager.create_template(
    name="customer_support",
    template="You are a helpful customer support agent. {context}\n\nCustomer: {question}\nAgent:",
    version="1.0"
)

# Test prompt variations
results = prompt_manager.test_variations(
    template_name="customer_support",
    test_cases=test_data,
    models=["gpt-4", "gpt-3.5-turbo"]
)
```

**Prompt Management Features:**
- **📚 Template Library**: Reusable prompt templates with versioning
- **🔄 A/B Testing**: Compare prompt performance across models
- **📊 Analytics**: Track prompt effectiveness and model responses
- **🎯 Optimization**: Automated prompt tuning and improvement suggestions

### ⚖️ Evaluation / Debugging
Test outputs, improve reliability, and validate quality systematically.

```python
from src.evaluation import ModelEvaluator

# Comprehensive model evaluation
evaluator = ModelEvaluator(config)

# Run evaluation suite
results = evaluator.evaluate_model(
    model_name="gpt-4",
    test_dataset="eval_data.json",
    metrics=["accuracy", "relevance", "safety", "hallucination"]
)

# Generate evaluation report
evaluator.generate_report(results, output_path="evaluation_report.html")
```

**Evaluation Capabilities:**
- **🎯 Quality Metrics**: Accuracy, relevance, coherence, and factuality
- **🛡️ Safety Testing**: Content filtering, bias detection, and jailbreak resistance
- **📊 Performance Analysis**: Latency, throughput, and cost optimization
- **🔍 Debugging Tools**: Error analysis, trace visualization, and improvement recommendations

## 🚀 Production

Scale your AI solutions with enterprise-grade operations:

### 🔗 Orchestration
Build pipelines and workflows that combine models, tools, and APIs.

```python
from src.agents import WorkflowOrchestrator

# Create multi-step AI workflows
orchestrator = WorkflowOrchestrator(config)

# Define complex workflows
workflow = orchestrator.create_workflow([
    {"step": "document_analysis", "model": "gpt-4"},
    {"step": "data_extraction", "tool": "document_intelligence"},
    {"step": "summary_generation", "model": "gpt-3.5-turbo"},
    {"step": "quality_check", "validator": "content_safety"}
])

# Execute workflow
result = orchestrator.run_workflow(workflow, input_data)
```

**Orchestration Features:**
- **🔄 Multi-Agent Workflows**: Coordinate multiple AI models and tools
- **⚡ Parallel Processing**: Optimize performance with concurrent execution
- **🛡️ Error Handling**: Robust error recovery and retry mechanisms
- **📊 Workflow Analytics**: Monitor execution metrics and optimize performance

### 🤖 Automation
Streamline tasks like data ingestion, retraining, and deployment.

```bash
# Automated CI/CD pipeline
make deploy-production

# Scheduled model retraining
make schedule-training

# Automated data pipeline
make run-data-pipeline
```

**Automation Capabilities:**
- **🔄 CI/CD Pipelines**: Automated testing, building, and deployment
- **📅 Scheduled Operations**: Automatic model retraining and data updates
- **🔍 Monitoring Integration**: Automated alerting and response workflows
- **📈 Scaling**: Auto-scaling based on demand and performance metrics

### 📊 Monitoring
Track performance, latency, costs, and drift over time for production reliability.

```python
from src.monitoring import ProductionMonitor

# Set up comprehensive monitoring
monitor = ProductionMonitor(config)

# Track key metrics
monitor.track_metrics([
    "request_latency",
    "model_accuracy", 
    "cost_per_request",
    "safety_violations",
    "model_drift"
])

# Set up alerting
monitor.configure_alerts({
    "latency_threshold": "2s",
    "accuracy_threshold": "0.85",
    "cost_threshold": "$0.01"
})
```

**Monitoring Features:**
- **📈 Performance Metrics**: Real-time latency, throughput, and accuracy tracking
- **💰 Cost Management**: Detailed cost analysis and budget alerts
- **🚨 Alerting**: Proactive notifications for performance issues and anomalies
- **📊 Dashboards**: Comprehensive visualizations with Azure Monitor integration

## 🏗️ Platform Architecture

```
src/
├── common/                # 🔧 Azure AI Foundry client and shared utilities
├── llm_training/          # 🎯 Model fine-tuning and custom training
├── rag/                   # 🩸 Retrieval-Augmented Generation
├── prompts/               # 📝 Prompt engineering and management
├── evaluation/            # ⚖️ Model evaluation and testing
├── agents/                # 🔗 AI workflows and orchestration
├── monitoring/            # 📊 Production monitoring and observability
├── inference/             # 🟩 Model inference and completions
├── serving/               # 🚧 Model serving and deployment
├── safety_security/       # 🛡️ Content filtering and security
├── embeddings/            # 💠 Vector operations and similarity
├── app_development/       # 🧱 Application development frameworks
├── data_extraction/       # 📤 Document processing and extraction
├── data_generation/       # 🌠 Synthetic data creation
├── structured_outputs/    # 📋 JSON, XML, and schema-based generation
└── app.py                 # 🚀 FastAPI application with all endpoints
```

## 🛠️ Development Setup

### 📋 Prerequisites
- Python 3.9+
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 2.50.0+
- Azure subscription with **Contributor** access
- Docker (optional)

### 🔧 Local Development

```bash
# Clone and set up the repository
git clone https://github.com/korkridake/AzureGenAIOps.git
cd AzureGenAIOps

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e .

# Copy configuration template
cp .env.example .env
# Edit .env with your Azure AI Foundry configuration
```

### 🔑 Configuration

Key environment variables in `.env`:

```bash
# Azure AI Foundry
AZURE_AI_PROJECT_NAME=your-ai-foundry-project
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=your-resource-group

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-openai.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4

# Azure AI Search (for RAG)
AZURE_SEARCH_ENDPOINT=https://your-search.search.windows.net
AZURE_SEARCH_API_KEY=your-search-key

# Safety & Security
CONTENT_FILTER_ENABLED=true
PII_DETECTION_ENABLED=true
JAILBREAK_DETECTION_ENABLED=true
```

For secure production setup, see the [GitHub Secrets Integration Guide](GITHUB_SECRETS_GUIDE.md).

## 🚀 Usage

### Start the Platform

```bash
# Start the comprehensive LLM operations API
uvicorn src.app:app --host 0.0.0.0 --port 8000

# Or use the make command
make run

# Access interactive documentation
open http://localhost:8000/docs
```

### Core API Examples

#### 💬 Chat Completions (Getting Started)
```bash
curl -X POST "http://localhost:8000/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{
    "messages": [
      {"role": "user", "content": "Explain machine learning"}
    ],
    "max_tokens": 1000,
    "temperature": 0.7
  }'
```

#### 🩸 RAG Query (Customization)
```bash
curl -X POST "http://localhost:8000/rag/query" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the benefits of using Azure AI?",
    "top_k": 5,
    "score_threshold": 0.7
  }'
```

#### 📝 Prompt Testing (Experimentation)
```bash
curl -X POST "http://localhost:8000/prompts/test" \
  -H "Content-Type: application/json" \
  -d '{
    "template": "You are a {role}. {context}\n\nUser: {question}",
    "variables": {
      "role": "helpful assistant",
      "context": "Focus on being accurate and concise",
      "question": "How does fine-tuning work?"
    }
  }'
```

#### 📊 Monitoring Metrics (Production)
```bash
# Get system metrics
curl "http://localhost:8000/metrics"

# Health check
curl "http://localhost:8000/health"

# Model performance
curl "http://localhost:8000/monitoring/model-performance"
```

### Python SDK Usage

#### Getting Started
```python
from src.common import AzureFoundryClient, LLMConfig
from src.inference import InferenceEngine

# Initialize with your configuration
config = LLMConfig()
client = AzureFoundryClient()
inference = InferenceEngine(config)

# Basic chat completion
response = inference.chat_completion([
    {"role": "user", "content": "Hello, how can you help me?"}
])
print(response.content)
```

#### Customization with RAG
```python
from src.rag import RAGPipeline

# Initialize RAG pipeline
rag = RAGPipeline(config)

# Add your documents
rag.add_documents([
    "path/to/document1.pdf",
    "path/to/document2.docx"
])

# Query with context
response = rag.query(
    question="What is our company policy on remote work?",
    top_k=3
)
print(f"Answer: {response.answer}")
print(f"Sources: {response.sources}")
```

#### Experimentation with Prompts
```python
from src.prompts import PromptManager
from src.evaluation import ModelEvaluator

# Set up prompt testing
prompt_manager = PromptManager()
evaluator = ModelEvaluator(config)

# Create and test prompt variations
prompt_manager.create_template(
    name="summarization",
    template="Summarize the following text in {style} style:\n\n{text}",
    version="1.0"
)

# Evaluate different styles
test_results = evaluator.evaluate_prompt_variations(
    template_name="summarization",
    test_data=sample_texts,
    variations={"style": ["formal", "casual", "technical"]}
)
```

#### Production Monitoring
```python
from src.monitoring import ProductionMonitor

# Set up monitoring
monitor = ProductionMonitor(config)

# Track custom metrics
monitor.log_request_metrics({
    "model": "gpt-4",
    "tokens_used": 150,
    "latency_ms": 1200,
    "cost_usd": 0.003
})

# Get performance insights
insights = monitor.get_performance_insights(
    time_range="24h",
    metrics=["latency", "accuracy", "cost"]
)
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