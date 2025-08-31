# 🚀 AzureGenAIOps End-to-End Guide

This comprehensive guide covers the complete lifecycle of deploying, configuring, and operating AzureGenAIOps from initial setup to production monitoring.

## 📋 Table of Contents

1. [🏗️ Resource Setup](#️-resource-setup)
2. [🔐 GitHub Secrets Integration](#-github-secrets-integration)
3. [🔬 Experimentation & Development](#-experimentation--development)
4. [🧪 Unit Testing & Development Workflows](#-unit-testing--development-workflows)
5. [🚀 CI/CD for LLM Operations Pipeline](#-cicd-for-llm-operations-pipeline)
6. [📊 Monitoring and Observability](#-monitoring-and-observability)
7. [🔧 Troubleshooting](#-troubleshooting)

---

## 🏗️ Resource Setup

Choose your deployment scenario:

### 🌱 Greenfield Deployment (New Resources)

**For completely new Azure infrastructure:**

#### Step 1: Prerequisites
```bash
# Install required tools
# Azure CLI 2.50.0+
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# GitHub CLI (optional but recommended)
sudo apt install gh

# Login to Azure
az login
az account set --subscription "your-subscription-id"
```

#### Step 2: Deploy New Infrastructure
```bash
# Clone the repository
git clone https://github.com/korkridake/AzureGenAIOps.git
cd AzureGenAIOps

# Run automated deployment (creates all Azure resources)
./infrastructure/scripts/deploy-new.sh
```

**What gets created:**
- ✅ Azure AI Foundry Project
- ✅ Azure OpenAI Service (GPT-4, GPT-3.5-Turbo, embeddings)
- ✅ Azure AI Search (vector + semantic search)
- ✅ Azure Storage (documents, models, data)
- ✅ Azure Container Apps (application hosting)
- ✅ Azure Monitor (observability)
- ✅ Azure Key Vault (secure configuration)

#### Step 3: Post-Deployment Configuration
```bash
# Copy generated environment file
cp .env.deployed .env

# Verify deployment
python scripts/test_keyvault_access.py
```

### 🏢 Brownfield Deployment (Existing Resources)

**For using existing Azure AI services:**

#### Step 1: Inventory Existing Resources
```bash
# List your existing Azure AI resources
az cognitiveservices account list --query "[].{Name:name,Kind:kind,Location:location}" -o table

# List existing AI Foundry projects
az ml workspace list --query "[].{Name:name,ResourceGroup:resourceGroup,Location:location}" -o table
```

#### Step 2: Configure Existing Resources
```bash
# Deploy using your existing Azure AI services
./infrastructure/scripts/deploy-existing.sh \
  --ai-foundry "my-existing-ai-foundry" \
  --openai "my-existing-openai" \
  --search "my-existing-search" \
  --storage "myexistingstorage"
```

#### Step 3: Update Configuration
```bash
# Copy generated environment file for existing resources
cp .env.existing .env

# Validate existing resource connectivity
python scripts/test_keyvault_access.py --validate-existing
```

---

## 🔐 GitHub Secrets Integration

Connect your Azure subscription and resources to GitHub for secure CI/CD.

### Step 1: Create Service Principal for GitHub Actions

```bash
# Create service principal with proper permissions
az ad sp create-for-rbac \
  --name "github-actions-genaiops" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{your-resource-group} \
  --sdk-auth

# Save the output for GitHub secrets
```

### Step 2: Configure GitHub Repository Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

**Core Azure Authentication:**
```
AZURE_CLIENT_ID=<from service principal output>
AZURE_CLIENT_SECRET=<from service principal output>
AZURE_TENANT_ID=<from service principal output>
AZURE_SUBSCRIPTION_ID=<your subscription id>
```

**Azure Resource Configuration:**
```
AZURE_RESOURCE_GROUP=<your resource group>
AZURE_AI_PROJECT_NAME=<your ai foundry project>
AZURE_OPENAI_ENDPOINT=<your openai endpoint>
AZURE_SEARCH_ENDPOINT=<your search endpoint>
AZURE_STORAGE_ACCOUNT_NAME=<your storage account>
AZURE_KEY_VAULT_NAME=<your key vault name>
```

### Step 3: Automated Secret Extraction

```bash
# Extract secrets from Key Vault to GitHub (if using existing deployment)
./scripts/extract-secrets-to-github.sh \
  --resource-group "your-resource-group" \
  --github-repo "owner/repository" \
  --github-token "your-github-token"
```

**📖 For detailed instructions, see:** [GITHUB_SECRETS_GUIDE.md](GITHUB_SECRETS_GUIDE.md)

---

## 🔬 Experimentation & Development

### Setting Up Development Environment

#### Step 1: Local Development Setup
```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e .

# Set up environment
cp .env.example .env
# Edit .env with your Azure configuration
```

#### Step 2: Start Development Server
```bash
# Start the API server
uvicorn src.app:app --host 0.0.0.0 --port 8000 --reload

# Or use the make command
make dev
```

### 🧱 RAG (Retrieval-Augmented Generation)

#### Step 1: Document Upload and Indexing
```python
from src.rag import RAGPipeline
from src.common import LLMConfig

# Initialize RAG pipeline
config = LLMConfig()
rag = RAGPipeline(config)

# Upload documents
documents = [
    {"content": "Azure AI Foundry is a comprehensive platform...", "metadata": {"source": "docs"}},
    {"content": "Machine learning models can be deployed...", "metadata": {"source": "guides"}}
]

# Index documents
rag.index_documents(documents)
```

#### Step 2: Query with RAG
```python
# Perform RAG query
response = rag.query(
    question="What is Azure AI Foundry?",
    top_k=3,
    score_threshold=0.7
)

print(f"Answer: {response['answer']}")
print(f"Sources: {response['sources']}")
```

#### Step 3: API Usage
```bash
# RAG query via API
curl -X POST "http://localhost:8000/rag/query" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "What are the benefits of using Azure AI?",
    "top_k": 5,
    "score_threshold": 0.7
  }'
```

### 🚀 Fine-Tuning

#### Step 1: Prepare Training Data
```python
from src.llm_training import FineTuningPipeline

# Prepare training data in JSONL format
training_data = [
    {"messages": [
        {"role": "user", "content": "What is Azure?"},
        {"role": "assistant", "content": "Azure is Microsoft's cloud platform..."}
    ]},
    # More training examples...
]

# Save training data
with open("training_data.jsonl", "w") as f:
    for item in training_data:
        f.write(json.dumps(item) + "\n")
```

#### Step 2: Start Fine-Tuning Job
```python
# Initialize fine-tuning pipeline
ft_pipeline = FineTuningPipeline(config)

# Create fine-tuning job
job = ft_pipeline.create_fine_tuning_job(
    training_file="training_data.jsonl",
    model="gpt-3.5-turbo",
    suffix="custom-model-v1"
)

# Monitor training progress
status = ft_pipeline.get_job_status(job.id)
print(f"Training status: {status}")
```

### 📅 Prompt Management

#### Step 1: Create Prompt Templates
```python
from src.prompts import PromptManager

prompt_manager = PromptManager(config)

# Create prompt template
template = prompt_manager.create_template(
    name="customer_support",
    template="""You are a helpful customer support agent.
    Customer question: {question}
    Product context: {context}
    
    Please provide a helpful response:""",
    variables=["question", "context"]
)
```

#### Step 2: Use Prompt Templates
```python
# Generate response using template
response = prompt_manager.generate_from_template(
    template_name="customer_support",
    variables={
        "question": "How do I reset my password?",
        "context": "Azure portal authentication"
    }
)
```

### ⚖️ Evaluation & Debugging

#### Step 1: Set Up Evaluation Pipeline
```python
from src.evaluation import EvaluationPipeline

# Initialize evaluation
evaluator = EvaluationPipeline(config)

# Create test dataset
test_cases = [
    {
        "input": "Explain machine learning",
        "expected_output": "Machine learning is a subset of AI...",
        "category": "technical_explanation"
    }
]
```

#### Step 2: Run Evaluations
```python
# Run comprehensive evaluation
results = evaluator.evaluate_model(
    model_name="gpt-4",
    test_cases=test_cases,
    metrics=["accuracy", "relevance", "safety", "latency"]
)

# Generate evaluation report
evaluator.generate_report(results, output_file="evaluation_report.json")
```

#### Step 3: Azure AI Foundry Integration
```python
# Use Azure AI Foundry SDK for advanced evaluation
from azure.ai.evaluation import evaluate
from azure.ai.foundry import AzureAIClient

# Initialize Azure AI client
ai_client = AzureAIClient()

# Run evaluation using Azure AI Foundry
evaluation_result = evaluate(
    data=test_cases,
    task_type="question_answering",
    metrics=["groundedness", "relevance", "coherence"]
)
```

---

## 🧪 Unit Testing & Development Workflows

### Test Structure

```
tests/
├── unit/                    # Unit tests for individual components
│   ├── test_rag.py
│   ├── test_inference.py
│   └── test_config.py
├── integration/             # Integration tests with Azure services
│   ├── test_azure_openai.py
│   └── test_keyvault.py
├── e2e/                     # End-to-end workflow tests
│   └── test_complete_pipeline.py
└── fixtures/                # Test data and fixtures
    └── sample_documents.json
```

### Step 1: Run Unit Tests

```bash
# Run all tests
make test

# Run specific test modules
python -m pytest tests/unit/test_rag.py -v

# Run with coverage
make test-coverage
```

### Step 2: Integration Testing with Azure

```bash
# Test Azure connectivity
python scripts/test_keyvault_access.py

# Test specific Azure services
python -m pytest tests/integration/ -v --azure-live
```

### Step 3: Pre-commit Hooks Setup

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install

# Run all checks
pre-commit run --all-files
```

### Step 4: Development Workflow

```bash
# Lint and format code
make lint
make format

# Type checking
make type-check

# Security scanning
make security-scan
```

---

## 🚀 CI/CD for LLM Operations Pipeline

### GitHub Actions Workflows

The project includes comprehensive CI/CD workflows:

#### 1. Main CI/CD Pipeline (`.github/workflows/ci-cd.yml`)

**Triggers:** Push to main, pull requests
**Features:**
- Automated testing (unit, integration, e2e)
- Docker image building with multi-stage builds
- Security scanning (Bandit, dependency checks)
- Azure deployment (Container Instances, Container Apps)
- Quality gates (coverage, type checking, linting)

#### 2. LLM Operations Pipeline (`.github/workflows/llm-ops.yml`)

**Triggers:** Workflow dispatch, scheduled runs
**Features:**
- Model training automation
- Model evaluation and validation
- RAG indexing and updates
- Safety testing and content filtering
- Model performance monitoring

### Step 1: Configure CI/CD Environment

```yaml
# .github/workflows/ci-cd.yml example
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

env:
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install -e .
    
    - name: Run tests
      run: make test-coverage
    
    - name: Security scan
      run: make security-scan
```

### Step 2: Model Training Pipeline

```yaml
# .github/workflows/llm-ops.yml example
name: LLM Operations Pipeline

on:
  workflow_dispatch:
    inputs:
      training_data:
        description: 'Training data file path'
        required: true
        default: 'data/training/latest.jsonl'

jobs:
  train-model:
    runs-on: ubuntu-latest
    steps:
    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
    
    - name: Fine-tune model
      run: |
        python scripts/deploy_ml_pipeline.py \
          --training-data ${{ github.event.inputs.training_data }} \
          --model-name "custom-model-${{ github.sha }}"
    
    - name: Evaluate model
      run: |
        python -m src.evaluation.evaluate_model \
          --model-name "custom-model-${{ github.sha }}" \
          --test-data "data/test/evaluation_set.jsonl"
```

### Step 3: Deployment Automation

```bash
# Deploy to different environments
# Development
gh workflow run deploy.yml -f environment=dev

# Staging
gh workflow run deploy.yml -f environment=staging

# Production (requires approval)
gh workflow run deploy.yml -f environment=prod
```

### Step 4: Environment-Specific Configuration

```yaml
# Configure different environments
environments:
  dev:
    secrets:
      AZURE_RESOURCE_GROUP: "genaiops-dev-rg"
      AZURE_AI_PROJECT_NAME: "genaiops-dev-project"
  
  staging:
    secrets:
      AZURE_RESOURCE_GROUP: "genaiops-staging-rg"
      AZURE_AI_PROJECT_NAME: "genaiops-staging-project"
  
  prod:
    secrets:
      AZURE_RESOURCE_GROUP: "genaiops-prod-rg"
      AZURE_AI_PROJECT_NAME: "genaiops-prod-project"
```

---

## 📊 Monitoring and Observability

### Step 1: Azure Monitor Integration

#### Application Insights Setup
```python
from src.monitoring import MonitoringConfig, setup_monitoring

# Initialize monitoring
monitoring = setup_monitoring(
    instrumentation_key=config.app_insights_key,
    service_name="azuregenaiops",
    environment=config.environment
)

# Custom metrics tracking
monitoring.track_llm_request(
    model="gpt-4",
    tokens_used=150,
    latency_ms=250,
    success=True
)
```

#### Custom Metrics Dashboard
```python
# Track custom business metrics
from src.monitoring import MetricsCollector

metrics = MetricsCollector()

# Track model performance
metrics.gauge("model.accuracy", 0.95, tags={"model": "gpt-4", "task": "rag"})
metrics.increment("requests.total", tags={"endpoint": "/chat/completions"})
metrics.histogram("request.duration", 250, tags={"model": "gpt-4"})
```

### Step 2: Logging Configuration

```python
# Structured logging setup
import logging
from src.monitoring import StructuredLogger

logger = StructuredLogger(
    service_name="azuregenaiops",
    log_level=logging.INFO,
    azure_app_insights=True
)

# Usage in application
logger.info("RAG query processed", 
    extra={
        "question": "What is Azure?",
        "num_results": 5,
        "processing_time_ms": 150,
        "user_id": "user123"
    })
```

### Step 3: Health Checks and Alerts

```python
# Health check endpoint
from src.monitoring import HealthChecker

health_checker = HealthChecker()

@app.get("/health")
async def health_check():
    checks = {
        "azure_openai": health_checker.check_openai_connection(),
        "azure_search": health_checker.check_search_connection(),
        "key_vault": health_checker.check_keyvault_access(),
        "storage": health_checker.check_storage_connection()
    }
    
    overall_health = all(checks.values())
    return {
        "status": "healthy" if overall_health else "unhealthy",
        "checks": checks,
        "timestamp": datetime.utcnow().isoformat()
    }
```

### Step 4: Azure Monitor Queries and Alerts

```kusto
// Monitor LLM request patterns
requests
| where cloud_RoleName == "azuregenaiops"
| where name contains "chat/completions"
| summarize 
    RequestCount = count(),
    AvgDuration = avg(duration),
    P95Duration = percentile(duration, 95),
    ErrorRate = countif(success == false) * 100.0 / count()
    by bin(timestamp, 5m)
| render timechart

// Track model performance metrics
customMetrics
| where name == "model.accuracy"
| summarize avg(value) by bin(timestamp, 1h), tostring(customDimensions.model)
| render timechart
```

### Step 5: Cost Monitoring

```python
# Cost tracking for LLM operations
from src.monitoring import CostTracker

cost_tracker = CostTracker()

# Track token usage and costs
cost_tracker.track_token_usage(
    model="gpt-4",
    input_tokens=100,
    output_tokens=50,
    cost_usd=0.03
)

# Generate cost reports
monthly_cost = cost_tracker.get_monthly_cost_report()
```

---

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Authentication Issues
```bash
# Check Azure CLI authentication
az account show

# Refresh token
az account get-access-token --refresh

# Verify service principal permissions
az role assignment list --assignee {service-principal-id}
```

#### 2. Key Vault Access Issues
```bash
# Test Key Vault connectivity
python scripts/test_keyvault_access.py --debug

# Check Key Vault permissions
az keyvault check-name --name {vault-name}
```

#### 3. Model Deployment Issues
```bash
# Check Azure OpenAI deployment status
az cognitiveservices account deployment list \
  --name {openai-service-name} \
  --resource-group {resource-group}
```

#### 4. GitHub Actions Failures
```bash
# Validate GitHub secrets
gh secret list

# Test workflow locally with act
act -j test --secret-file .env
```

### Debugging Steps

1. **Check Configuration**
   ```python
   from src.config import get_config
   config = get_config(debug=True)
   config.validate_configuration()
   ```

2. **Verify Azure Connectivity**
   ```bash
   python scripts/test_keyvault_access.py --validate-all
   ```

3. **Monitor Logs**
   ```bash
   # Stream application logs
   az containerapp logs show --name {app-name} --resource-group {rg} --follow
   ```

---

## 📚 Additional Resources

- **[GITHUB_SECRETS_GUIDE.md](GITHUB_SECRETS_GUIDE.md)** - Detailed GitHub secrets setup
- **[MIGRATION_GUIDE.md](MIGRATION_GUIDE.md)** - Migration from .env files
- **[Infrastructure README](infrastructure/README.md)** - Deployment details
- **[Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-foundry/)**
- **[Azure OpenAI Service](https://docs.microsoft.com/azure/cognitive-services/openai/)**

---

## 🎯 Quick Reference Checklist

### Initial Setup ✅
- [ ] Choose deployment type (Greenfield/Brownfield)
- [ ] Deploy Azure infrastructure
- [ ] Configure GitHub secrets
- [ ] Set up local development environment
- [ ] Verify connectivity with test scripts

### Development ✅
- [ ] Set up RAG pipeline with document indexing
- [ ] Configure fine-tuning workflows
- [ ] Implement prompt management
- [ ] Set up evaluation framework
- [ ] Create unit and integration tests

### Production ✅
- [ ] Configure CI/CD pipelines
- [ ] Set up monitoring and alerts
- [ ] Implement health checks
- [ ] Configure cost tracking
- [ ] Deploy to production environment

### Ongoing Operations ✅
- [ ] Monitor model performance
- [ ] Review cost reports
- [ ] Update training data
- [ ] Evaluate model drift
- [ ] Security and compliance reviews

---

**🚀 You're now ready to build, deploy, and operate comprehensive LLM solutions with AzureGenAIOps!**