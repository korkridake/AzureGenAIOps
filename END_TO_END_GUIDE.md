# 🚀 AzureGenAIOps End-to-End Guide

This comprehensive guide follows the **Getting Started → Customization → Experimentation → Production** workflow to help you master the complete AzureGenAIOps lifecycle.

## 📋 Navigation

| Stage | Focus | Key Activities |
|-------|-------|----------------|
| **[🚀 Getting Started](#-getting-started)** | Foundation | Resource setup, Playground exploration |
| **[🎨 Customization](#-customization)** | Domain-specific | RAG implementation, Fine-tuning |
| **[🔬 Experimentation](#-experimentation)** | Optimization | Prompt management, Evaluation & debugging |
| **[🚀 Production](#-production)** | Scale & Operations | Orchestration, Automation, Monitoring |

---

## 🚀 Getting Started

Build your foundational GenAI infrastructure and explore capabilities.

### 🏗️ Resource Set-up

Choose your deployment path based on your Azure environment:

#### 🌱 Greenfield Deployment (New Resources)

**For completely new Azure infrastructure:**

##### Step 1: Prerequisites Check
```bash
# Verify Azure CLI installation (requires 2.50.0+)
az version

# Login and set subscription
az login
az account set --subscription "your-subscription-id"

# Verify permissions
az role assignment list --assignee $(az account show --query user.name -o tsv) \
  --scope "/subscriptions/$(az account show --query id -o tsv)"
```

##### Step 2: Automated Azure Deployment
```bash
# Clone repository
git clone https://github.com/korkridake/AzureGenAIOps.git
cd AzureGenAIOps

# Deploy with guided prompts
./infrastructure/scripts/deploy-new.sh

# Or specify parameters directly
./infrastructure/scripts/deploy-new.sh \
  --resource-group "azuregenaiops-rg" \
  --location "East US" \
  --environment "dev" \
  --admin-email "your-email@company.com"
```

**📦 What Gets Created:**
- ✅ **Azure AI Foundry Project** - Central AI development hub
- ✅ **Azure OpenAI Service** - GPT-4, GPT-3.5-Turbo, text-embedding-ada-002
- ✅ **Azure AI Search** - Vector and semantic search capabilities
- ✅ **Azure Storage Account** - Document storage and model artifacts
- ✅ **Azure Container Apps** - Scalable application hosting
- ✅ **Azure Monitor** - Logging, metrics, and alerting
- ✅ **Azure Key Vault** - Secure credential management
- ✅ **GitHub Actions Secrets** - CI/CD integration

#### 🏢 Brownfield Deployment (Existing Resources)

**For environments with existing Azure AI services:**

##### Step 1: Inventory Existing Resources
```bash
# List existing AI resources
az cognitiveservices account list --query '[].{Name:name, Kind:kind, Location:location}' -o table

# List existing search services
az search service list --query '[].{Name:name, Location:location, Sku:sku.name}' -o table

# List storage accounts
az storage account list --query '[].{Name:name, Location:location, Kind:kind}' -o table
```

##### Step 2: Deploy with Existing Infrastructure
```bash
# Interactive deployment with existing resources
./infrastructure/scripts/deploy-existing.sh

# Or specify existing resources
./infrastructure/scripts/deploy-existing.sh \
  --ai-foundry "existing-ai-foundry" \
  --openai-service "existing-openai" \
  --search-service "existing-search" \
  --storage-account "existingstorage"
```

##### Step 3: Configuration Validation
```bash
# Test connectivity to existing resources
python scripts/test_keyvault_access.py --mode validate-existing

# Verify model deployments
az cognitiveservices account deployment list \
  --name "your-openai-service" \
  --resource-group "your-rg"
```

### 🎮 Playground: Interactive Exploration

Before diving into code, explore your AI capabilities interactively.

#### Step 1: Start the Development Environment
```bash
# Activate your environment
source venv/bin/activate

# Start the API server
uvicorn src.app:app --host 0.0.0.0 --port 8000 --reload

# Access interactive documentation
open http://localhost:8000/docs
```

#### Step 2: Explore Core Capabilities

**💬 Test Chat Completions:**
```python
# Via Python
from src.inference import InferenceEngine
from src.config import get_config

config = get_config()
engine = InferenceEngine(config)

response = engine.chat_completion([
    {"role": "system", "content": "You are a helpful AI assistant."},
    {"role": "user", "content": "Explain the difference between AI, ML, and Deep Learning"}
])
print(response.content)
```

**🔍 Try Document Search:**
```python
# Upload sample documents and test search
from src.rag import RAGPipeline

rag = RAGPipeline(config)

# Add sample documents
rag.add_documents([
    "docs/sample_policy.pdf",
    "docs/technical_guide.docx"
])

# Test semantic search
results = rag.search("What is our data retention policy?", top_k=3)
for result in results:
    print(f"Score: {result.score:.3f} - {result.content[:200]}...")
```

**🛡️ Test Safety Features:**
```python
# Test content filtering
from src.safety_security import ContentFilter

filter = ContentFilter(config)
safety_result = filter.check_content(
    "How do I build a secure authentication system?",
    check_type="both"
)
print(f"Safety Status: {safety_result.is_safe}")
```

#### Step 3: Playground Exercises

**Exercise 1: Model Comparison**
Test the same prompt across different models:
```bash
curl -X POST "http://localhost:8000/playground/compare-models" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Write a technical summary of blockchain technology",
    "models": ["gpt-4", "gpt-35-turbo"],
    "parameters": {"temperature": 0.7, "max_tokens": 300}
  }'
```

**Exercise 2: Parameter Exploration**
Experiment with different temperature and token settings:
```python
# Temperature impact on creativity
for temp in [0.1, 0.5, 0.9]:
    response = engine.chat_completion([
        {"role": "user", "content": "Write a creative product description for a smart water bottle"}
    ], temperature=temp)
    print(f"Temperature {temp}: {response.content[:100]}...")
```

---

## 🎨 Customization

Enhance your AI applications with domain-specific knowledge and specialized capabilities.

### 🩸 RAG: Retrieval-Augmented Generation

Add your organization's knowledge to AI responses using vector search and embeddings.

#### Step 1: Document Preparation and Indexing

**Prepare Your Knowledge Base:**
```bash
# Create document directory structure
mkdir -p data/documents/{policies,technical,training}

# Supported formats: PDF, DOCX, TXT, HTML, MD
cp your-documents/* data/documents/
```

**Index Documents for Search:**
```python
from src.rag import RAGPipeline, DocumentProcessor

# Initialize RAG pipeline
rag = RAGPipeline(config)
processor = DocumentProcessor()

# Process and index documents
documents = processor.process_directory("data/documents/")
rag.index_documents(documents)

# Verify indexing
index_stats = rag.get_index_stats()
print(f"Indexed {index_stats['document_count']} documents")
print(f"Total chunks: {index_stats['chunk_count']}")
```

#### Step 2: Advanced RAG Configuration

**Optimize Chunking Strategy:**
```python
# Configure chunking for different document types
chunking_config = {
    "pdf": {
        "chunk_size": 1000,
        "chunk_overlap": 200,
        "respect_sentence_boundaries": True
    },
    "code": {
        "chunk_size": 500,
        "chunk_overlap": 50,
        "preserve_code_blocks": True
    }
}

rag.configure_chunking(chunking_config)
```

**Implement Hybrid Search:**
```python
# Combine semantic and keyword search
hybrid_results = rag.hybrid_search(
    query="machine learning deployment best practices",
    semantic_weight=0.7,
    keyword_weight=0.3,
    top_k=5
)
```

#### Step 3: Production RAG Implementation

**Create Domain-Specific RAG Endpoints:**
```python
# Custom RAG for HR policies
@app.post("/rag/hr-policy")
async def query_hr_policy(query: str):
    results = rag.query(
        question=query,
        filters={"document_type": "policy", "department": "hr"},
        top_k=3
    )
    return results

# Technical documentation RAG
@app.post("/rag/technical-docs")
async def query_technical_docs(query: str, product: str):
    results = rag.query(
        question=query,
        filters={"document_type": "technical", "product": product},
        top_k=5,
        rerank=True
    )
    return results
```

### 🎯 Fine-tuning: Custom Model Training

Train models with your specific data for improved performance on domain tasks.

#### Step 1: Data Preparation for Fine-tuning

**Prepare Training Data:**
```python
from src.llm_training import FineTuningDataProcessor

# Format data for fine-tuning
processor = FineTuningDataProcessor()

# For classification tasks
classification_data = processor.prepare_classification_data(
    input_file="data/training/customer_intent.csv",
    text_column="customer_message",
    label_column="intent",
    output_file="data/processed/intent_classification.jsonl"
)

# For instruction following
instruction_data = processor.prepare_instruction_data(
    input_file="data/training/company_qa.csv", 
    instruction_column="question",
    response_column="answer",
    output_file="data/processed/company_qa.jsonl"
)
```

#### Step 2: Model Fine-tuning Process

**Start Fine-tuning Job:**
```python
from src.llm_training import FineTuningPipeline

# Initialize fine-tuning pipeline
ft_pipeline = FineTuningPipeline(config)

# Start training job
training_job = ft_pipeline.start_fine_tuning(
    training_file="data/processed/company_qa.jsonl",
    validation_file="data/processed/company_qa_val.jsonl",
    model="gpt-35-turbo",
    task_type="instruction_following",
    hyperparameters={
        "n_epochs": 3,
        "learning_rate": 5e-6,
        "batch_size": 4
    }
)

# Monitor training progress
progress = ft_pipeline.monitor_training(training_job.id)
print(f"Training Status: {progress.status}")
print(f"Current Loss: {progress.current_loss}")
```

#### Step 3: Model Deployment and Testing

**Deploy Fine-tuned Model:**
```python
# Deploy the fine-tuned model
deployment = ft_pipeline.deploy_model(
    model_id=training_job.fine_tuned_model,
    deployment_name="company-qa-model-v1",
    instance_type="Standard_DS3_v2"
)

# Test the deployed model
test_response = ft_pipeline.test_deployment(
    deployment_name="company-qa-model-v1",
    test_prompt="What is our company's vacation policy?"
)
print(f"Fine-tuned response: {test_response}")
```

---

## 🔬 Experimentation

Systematically optimize your AI solutions through structured experimentation and evaluation.

### 📝 Prompt Management: Systematic Optimization

Organize, version, and optimize prompts for consistent, high-quality results.

#### Step 1: Prompt Template Management

**Create Prompt Library:**
```python
from src.prompts import PromptManager, PromptTemplate

# Initialize prompt manager
prompt_manager = PromptManager()

# Create versioned prompt templates
customer_support_template = PromptTemplate(
    name="customer_support_v1",
    template="""
You are a helpful customer support representative for {company_name}.

Customer Context:
- Name: {customer_name}
- Tier: {customer_tier}
- Previous Issues: {previous_issues}

Customer Message: {customer_message}

Respond professionally and provide actionable solutions. If you cannot resolve the issue, escalate appropriately.
""",
    variables=["company_name", "customer_name", "customer_tier", "previous_issues", "customer_message"],
    metadata={
        "use_case": "customer_support",
        "model_recommendations": ["gpt-4", "gpt-35-turbo"],
        "temperature_range": [0.3, 0.7]
    }
)

prompt_manager.save_template(customer_support_template)
```

#### Step 2: A/B Testing Prompts

**Compare Prompt Variations:**
```python
# Define prompt variations
variations = {
    "formal": {
        "tone": "professional and formal",
        "style": "corporate communication style"
    },
    "friendly": {
        "tone": "warm and approachable", 
        "style": "conversational and friendly"
    },
    "concise": {
        "tone": "direct and efficient",
        "style": "brief and to-the-point"
    }
}

# Run A/B test
test_results = prompt_manager.run_ab_test(
    template_name="customer_support_v1",
    variations=variations,
    test_data="data/customer_messages_sample.json",
    models=["gpt-4", "gpt-35-turbo"],
    evaluation_metrics=["relevance", "helpfulness", "tone_appropriateness"]
)

# Analyze results
best_variation = prompt_manager.analyze_ab_results(test_results)
print(f"Best performing variation: {best_variation.name}")
print(f"Performance score: {best_variation.score:.3f}")
```

#### Step 3: Automated Prompt Optimization

**Dynamic Prompt Improvement:**
```python
# Set up automated optimization
optimizer = prompt_manager.create_optimizer(
    template_name="customer_support_v1",
    optimization_goals=["accuracy", "customer_satisfaction", "response_time"],
    constraints={"max_tokens": 500, "min_politeness_score": 0.8}
)

# Run optimization cycles
optimized_prompt = optimizer.optimize(
    training_data="data/customer_interactions.json",
    iterations=5,
    validation_split=0.2
)

# Deploy optimized prompt
prompt_manager.deploy_prompt(
    template=optimized_prompt,
    environment="production",
    rollout_percentage=10  # Gradual rollout
)
```

### ⚖️ Evaluation & Debugging: Quality Assurance

Systematically test and improve model outputs for reliability and quality.

#### Step 1: Comprehensive Model Evaluation

**Set Up Evaluation Framework:**
```python
from src.evaluation import ModelEvaluator, EvaluationMetrics

# Initialize evaluator
evaluator = ModelEvaluator(config)

# Define evaluation metrics
metrics = EvaluationMetrics([
    "accuracy",
    "relevance", 
    "factual_consistency",
    "safety_compliance",
    "response_time",
    "cost_efficiency"
])

# Load test dataset
test_dataset = evaluator.load_test_data("data/evaluation/comprehensive_test_set.json")
```

**Run Comprehensive Evaluation:**
```python
# Evaluate across multiple models
evaluation_results = evaluator.evaluate_models(
    models=["gpt-4", "gpt-35-turbo", "company-qa-model-v1"],
    test_dataset=test_dataset,
    metrics=metrics,
    batch_size=10
)

# Generate detailed report
report = evaluator.generate_evaluation_report(
    results=evaluation_results,
    output_format="html",
    include_examples=True,
    output_path="reports/model_evaluation_report.html"
)
```

#### Step 2: Safety and Robustness Testing

**Jailbreak and Safety Testing:**
```python
from src.evaluation import SafetyEvaluator

# Initialize safety evaluator
safety_evaluator = SafetyEvaluator(config)

# Test against known jailbreak attempts
jailbreak_results = safety_evaluator.test_jailbreak_resistance(
    model="gpt-4",
    jailbreak_dataset="data/safety/jailbreak_attempts.json",
    severity_levels=["low", "medium", "high"]
)

# Test content filtering
content_safety_results = safety_evaluator.test_content_filtering(
    test_inputs="data/safety/content_safety_tests.json",
    filter_categories=["hate", "violence", "self_harm", "sexual"]
)

# Generate safety report
safety_report = safety_evaluator.generate_safety_report(
    jailbreak_results=jailbreak_results,
    content_results=content_safety_results,
    output_path="reports/safety_evaluation.pdf"
)
```

#### Step 3: Debugging and Improvement

**Trace and Debug Model Behavior:**
```python
from src.evaluation import ModelDebugger

# Initialize debugger
debugger = ModelDebugger(config)

# Trace problematic responses
problematic_inputs = [
    "Why did the model give an incorrect answer about our pricing?",
    "How can I improve responses for technical questions?"
]

for input_text in problematic_inputs:
    trace = debugger.trace_response(
        input_text=input_text,
        model="gpt-4",
        include_intermediate_steps=True,
        capture_attention_weights=True
    )
    
    # Analyze trace
    analysis = debugger.analyze_trace(trace)
    print(f"Input: {input_text}")
    print(f"Issues found: {analysis.issues}")
    print(f"Suggestions: {analysis.improvement_suggestions}")
```

**Automated Issue Detection:**
```python
# Set up monitoring for common issues
issue_detector = debugger.create_issue_detector([
    "hallucination_detection",
    "factual_inconsistency", 
    "off_topic_responses",
    "unsafe_content"
])

# Monitor production responses
production_issues = issue_detector.scan_production_logs(
    log_file="logs/production_responses.jsonl",
    time_range="24h",
    confidence_threshold=0.8
)

# Generate improvement recommendations
recommendations = debugger.generate_improvement_plan(production_issues)
```

---

## 🚀 Production

Scale your AI solutions with enterprise-grade orchestration, automation, and monitoring.

### 🔗 Orchestration: Workflow Management

Build complex AI workflows that coordinate multiple models, tools, and APIs.

#### Step 1: Multi-Agent Workflows

**Design Complex AI Workflows:**
```python
from src.agents import WorkflowOrchestrator, WorkflowStep

# Initialize orchestrator
orchestrator = WorkflowOrchestrator(config)

# Define document processing workflow
document_workflow = orchestrator.create_workflow("document_analysis_pipeline", [
    WorkflowStep(
        name="content_extraction",
        type="document_intelligence",
        config={"extract_tables": True, "extract_forms": True}
    ),
    WorkflowStep(
        name="content_classification", 
        type="llm_analysis",
        model="gpt-4",
        config={"classify_document_type": True, "extract_key_info": True}
    ),
    WorkflowStep(
        name="data_validation",
        type="validation_rules",
        config={"required_fields": ["title", "date", "summary"]}
    ),
    WorkflowStep(
        name="quality_check",
        type="llm_evaluation",
        model="gpt-35-turbo", 
        config={"check_completeness": True, "verify_accuracy": True}
    ),
    WorkflowStep(
        name="database_storage",
        type="data_storage",
        config={"table": "processed_documents", "include_metadata": True}
    )
])
```

**Execute Workflows with Error Handling:**
```python
# Execute workflow with monitoring
execution_result = orchestrator.execute_workflow(
    workflow_name="document_analysis_pipeline",
    input_data={
        "document_path": "data/incoming/contract_2024.pdf",
        "priority": "high",
        "requester": "legal_team"
    },
    execution_options={
        "parallel_execution": True,
        "retry_failed_steps": True,
        "max_retries": 3,
        "timeout_minutes": 30
    }
)

# Monitor execution
status = orchestrator.get_execution_status(execution_result.execution_id)
print(f"Workflow Status: {status.current_step} - {status.progress}%")
```

#### Step 2: Advanced Orchestration Patterns

**Conditional Workflows:**
```python
# Create conditional branching workflow
conditional_workflow = orchestrator.create_conditional_workflow(
    name="smart_customer_routing",
    conditions=[
        {
            "condition": "customer_tier == 'premium'",
            "workflow": "premium_support_workflow"
        },
        {
            "condition": "issue_type == 'technical'", 
            "workflow": "technical_support_workflow"
        },
        {
            "condition": "sentiment_score < 0.3",
            "workflow": "escalation_workflow"
        }
    ],
    default_workflow="standard_support_workflow"
)
```

**Parallel Processing Workflows:**
```python
# Process multiple documents simultaneously
parallel_results = orchestrator.execute_parallel_workflows([
    {"workflow": "document_analysis_pipeline", "input": "doc1.pdf"},
    {"workflow": "document_analysis_pipeline", "input": "doc2.pdf"},
    {"workflow": "document_analysis_pipeline", "input": "doc3.pdf"}
], max_parallel=5)
```

### 🤖 Automation: Streamlined Operations

Automate repetitive tasks and operational workflows for efficient LLM operations.

#### Step 1: Automated Data Pipelines

**Set Up Continuous Data Processing:**
```bash
# Configure automated data ingestion
cat > .github/workflows/data-pipeline.yml << EOF
name: Automated Data Pipeline

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM
  workflow_dispatch:

jobs:
  data_pipeline:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Process New Documents
        run: |
          python scripts/process_new_documents.py \
            --source-path "\${{ secrets.DOCUMENT_SOURCE_PATH }}" \
            --batch-size 100
            
      - name: Update RAG Index
        run: |
          python scripts/update_rag_index.py \
            --incremental true \
            --verify-integrity true
            
      - name: Run Quality Checks
        run: |
          python scripts/validate_processed_data.py \
            --threshold 0.95
EOF
```

**Implement Automated Model Retraining:**
```python
from src.automation import ModelRetrainingPipeline

# Set up automated retraining
retraining_pipeline = ModelRetrainingPipeline(config)

# Configure retraining triggers
retraining_pipeline.configure_triggers([
    {
        "trigger_type": "performance_degradation",
        "threshold": 0.85,  # Retrain if accuracy drops below 85%
        "evaluation_window": "7d"
    },
    {
        "trigger_type": "data_drift",
        "threshold": 0.3,   # Retrain if data drift exceeds 30%
        "check_frequency": "daily"
    },
    {
        "trigger_type": "scheduled",
        "schedule": "weekly",  # Weekly retraining regardless
        "day": "sunday"
    }
])

# Start automated monitoring
retraining_pipeline.start_monitoring()
```

#### Step 2: CI/CD Pipeline Automation

**Implement MLOps Pipeline:**
```yaml
# .github/workflows/llm-ops.yml
name: LLM Operations Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test_models:
    runs-on: ubuntu-latest
    steps:
      - name: Model Performance Testing
        run: |
          python scripts/test_model_performance.py \
            --benchmark-dataset data/benchmarks/test_set.json \
            --performance-threshold 0.9
            
      - name: Safety Testing
        run: |
          python scripts/test_model_safety.py \
            --jailbreak-tests data/safety/jailbreak_tests.json \
            --content-safety-tests data/safety/content_tests.json
            
  deploy_models:
    needs: test_models
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Staging
        run: |
          python scripts/deploy_model.py \
            --environment staging \
            --model-version \${{ github.sha }}
            
      - name: Run Integration Tests
        run: |
          python scripts/integration_tests.py \
            --endpoint \${{ secrets.STAGING_ENDPOINT }}
            
      - name: Deploy to Production
        if: success()
        run: |
          python scripts/deploy_model.py \
            --environment production \
            --model-version \${{ github.sha }} \
            --rollout-strategy gradual
```

### 📊 Monitoring: Production Observability

Track performance, costs, and system health with comprehensive monitoring and alerting.

#### Step 1: Comprehensive Monitoring Setup

**Initialize Production Monitoring:**
```python
from src.monitoring import ProductionMonitor, AlertManager

# Set up comprehensive monitoring
monitor = ProductionMonitor(config)

# Configure key metrics
monitor.configure_metrics([
    {
        "name": "request_latency",
        "type": "histogram",
        "buckets": [0.1, 0.5, 1.0, 2.0, 5.0],
        "labels": ["model", "endpoint", "customer_tier"]
    },
    {
        "name": "model_accuracy",
        "type": "gauge", 
        "evaluation_window": "1h",
        "labels": ["model", "task_type"]
    },
    {
        "name": "cost_per_request",
        "type": "counter",
        "labels": ["model", "token_count", "customer"]
    },
    {
        "name": "safety_violations",
        "type": "counter",
        "labels": ["violation_type", "severity", "model"]
    }
])

# Start monitoring
monitor.start_monitoring()
```

**Set Up Intelligent Alerting:**
```python
# Configure alert manager
alert_manager = AlertManager(config)

# Define alert rules
alert_rules = [
    {
        "name": "high_latency_alert",
        "condition": "request_latency_p95 > 5.0",
        "duration": "5m",
        "severity": "warning",
        "actions": ["email", "slack", "auto_scale"]
    },
    {
        "name": "accuracy_degradation",
        "condition": "model_accuracy < 0.85",
        "duration": "15m", 
        "severity": "critical",
        "actions": ["email", "page_oncall", "trigger_retraining"]
    },
    {
        "name": "cost_spike_alert",
        "condition": "daily_cost_increase > 50%",
        "duration": "1h",
        "severity": "warning",
        "actions": ["email", "slack", "cost_analysis"]
    }
]

alert_manager.configure_alerts(alert_rules)
```

#### Step 2: Advanced Analytics and Insights

**Model Performance Analytics:**
```python
from src.monitoring import PerformanceAnalyzer

# Initialize performance analyzer
analyzer = PerformanceAnalyzer(config)

# Generate performance insights
insights = analyzer.generate_insights(
    time_range="7d",
    models=["gpt-4", "gpt-35-turbo", "company-qa-model-v1"],
    include_comparisons=True
)

# Performance breakdown by use case
use_case_analysis = analyzer.analyze_by_use_case([
    "customer_support",
    "document_analysis", 
    "content_generation",
    "technical_qa"
])

# Generate optimization recommendations
recommendations = analyzer.generate_optimization_recommendations(
    performance_data=insights,
    cost_constraints={"max_daily_budget": 500},
    latency_requirements={"p95_latency": 2.0}
)
```

**Cost Optimization Dashboard:**
```python
from src.monitoring import CostAnalyzer

# Set up cost monitoring
cost_analyzer = CostAnalyzer(config)

# Track costs by dimension
cost_breakdown = cost_analyzer.analyze_costs(
    time_range="30d",
    group_by=["model", "customer", "use_case", "region"],
    include_predictions=True
)

# Generate cost optimization suggestions
cost_optimizations = cost_analyzer.suggest_optimizations([
    "model_selection",      # Suggest cheaper models for simple tasks
    "caching_opportunities", # Identify repeated queries
    "batch_processing",     # Suggest batching for efficiency
    "tier_optimization"     # Optimize customer tier assignments
])

# Set up cost alerts
cost_analyzer.setup_budget_alerts([
    {"budget": 1000, "period": "monthly", "threshold": 0.8},
    {"budget": 50, "period": "daily", "threshold": 0.9}
])
```

#### Step 3: Model Drift and Quality Monitoring

**Continuous Quality Monitoring:**
```python
from src.monitoring import QualityMonitor

# Set up quality monitoring
quality_monitor = QualityMonitor(config)

# Monitor for data drift
drift_detection = quality_monitor.setup_drift_detection(
    reference_dataset="data/reference/production_baseline.json",
    monitoring_window="24h",
    drift_threshold=0.3,
    features_to_monitor=["input_length", "topic_distribution", "sentiment"]
)

# Monitor model performance in production
performance_monitoring = quality_monitor.setup_performance_monitoring(
    evaluation_schedule="hourly",
    sample_size=100,
    evaluation_metrics=["accuracy", "relevance", "safety"],
    quality_threshold=0.9
)

# Set up automated quality reports
quality_monitor.schedule_quality_reports(
    frequency="weekly",
    recipients=["ml-team@company.com", "product-team@company.com"],
    include_trending=True,
    include_recommendations=True
)
```

**Production Health Dashboard:**
```python
# Create comprehensive health dashboard
dashboard = monitor.create_dashboard(
    name="AzureGenAIOps Production Health",
    widgets=[
        {"type": "latency_trends", "time_range": "24h"},
        {"type": "accuracy_by_model", "time_range": "7d"},
        {"type": "cost_breakdown", "time_range": "30d"},
        {"type": "safety_metrics", "time_range": "24h"},
        {"type": "error_rate_trends", "time_range": "7d"},
        {"type": "throughput_metrics", "time_range": "24h"}
    ],
    refresh_interval="5m",
    export_options=["pdf", "png", "json"]
)

# Share dashboard
dashboard.share_with([
    "engineering-team",
    "product-team", 
    "leadership-team"
], permissions="read")
```

---

## 🔧 Troubleshooting

Common issues and solutions for each stage of the workflow.

### Getting Started Issues
- **Azure CLI Authentication**: `az login --use-device-code`
- **Permission Errors**: Verify Contributor access to subscription
- **Resource Creation Failures**: Check Azure quotas and service availability

### Customization Issues  
- **RAG Index Errors**: Verify Azure AI Search service and API keys
- **Fine-tuning Failures**: Check data format and model availability
- **Document Processing Issues**: Verify Azure Document Intelligence service

### Experimentation Issues
- **Evaluation Timeouts**: Reduce batch size or increase timeout limits
- **Prompt Template Errors**: Validate template variables and syntax
- **Safety Test Failures**: Review content filtering configuration

### Production Issues
- **Monitoring Gaps**: Verify Azure Monitor configuration and permissions
- **Alert Fatigue**: Tune alert thresholds and aggregation windows
- **Performance Degradation**: Review scaling configuration and resource limits

For additional support, consult the [GitHub Issues](https://github.com/korkridake/AzureGenAIOps/issues) or contact the maintainers.

---

**🎯 Next Steps**: Choose your starting point based on your needs and begin your AzureGenAIOps journey!
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