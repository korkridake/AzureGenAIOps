# AzureGenAIOps

A comprehensive GenAIOps pipeline for Generative AI projects using Azure services and GitHub Actions. This project follows the cookiecutter-data-science template structure and implements best practices for MLOps with Generative AI models.

## 🚀 Features

- **Azure Integration**: Seamless integration with Azure OpenAI, Azure Machine Learning, Azure Storage, and Azure Key Vault
- **CI/CD Pipeline**: Automated testing, building, and deployment using GitHub Actions
- **Data Processing**: Robust data preprocessing and management pipelines
- **Model Training**: Automated model training and evaluation workflows
- **Containerization**: Docker support for consistent deployments
- **Monitoring**: Built-in logging and monitoring capabilities
- **Security**: Secure credential management with Azure Key Vault

## 🏗️ Architecture

```
├── data/
│   ├── external/        # Data from third party sources
│   ├── interim/         # Intermediate data that has been transformed
│   ├── processed/       # The final, canonical data sets for modeling
│   └── raw/            # The original, immutable data dump
├── models/             # Trained and serialized models, model predictions
├── notebooks/          # Jupyter notebooks for exploration and analysis
├── references/         # Data dictionaries, manuals, and explanatory materials
├── reports/            # Generated analysis as HTML, PDF, LaTeX, etc.
├── src/                # Source code for use in this project
│   ├── data/           # Scripts to download or generate data
│   ├── features/       # Scripts to turn raw data into features for modeling
│   ├── models/         # Scripts to train models and make predictions
│   └── visualization/  # Scripts to create exploratory and results visualizations
├── tests/              # Unit tests
├── .github/workflows/  # GitHub Actions CI/CD pipelines
└── scripts/            # Deployment and utility scripts
```

## 🛠️ Setup

### Prerequisites

- Python 3.9+
- Azure CLI
- Docker (optional)
- Git

### Installation

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
   # Edit .env with your Azure configuration
   ```

### Azure Setup

1. **Create Azure Resources:**
   ```bash
   # Login to Azure
   az login
   
   # Create resource group
   az group create --name your-resource-group --location eastus
   
   # Create Azure OpenAI service
   az cognitiveservices account create \
     --name your-openai-service \
     --resource-group your-resource-group \
     --kind OpenAI \
     --sku S0 \
     --location eastus
   
   # Create Azure ML workspace
   az ml workspace create \
     --name your-ml-workspace \
     --resource-group your-resource-group
   ```

2. **Configure GitHub Secrets:**
   - `AZURE_CREDENTIALS`: Service principal credentials
   - `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID
   - `AZURE_RESOURCE_GROUP`: Your resource group name
   - `AZURE_OPENAI_ENDPOINT`: Your OpenAI service endpoint
   - `AZURE_OPENAI_API_KEY`: Your OpenAI API key
   - Additional secrets as needed

## 🚀 Usage

### Data Processing

```bash
# Process raw data
make data

# Or manually
python -m src.data.make_dataset data/raw/input.csv data/processed/
```

### Model Training

```bash
# Train model
make train

# Or manually
python -m src.models.train_model \
  --train-data data/processed/train.csv \
  --val-data data/processed/validation.csv \
  --output-dir models/
```

### Running the API

```bash
# Start the FastAPI server
make run

# Or with uvicorn directly
uvicorn src.app:app --host 0.0.0.0 --port 8000
```

### Docker Deployment

```bash
# Build Docker image
make docker-build

# Run container
make docker-run
```

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Lint code
make lint

# Format code
make format
```

## 📊 CI/CD Pipeline

The project includes comprehensive GitHub Actions workflows:

### Main CI/CD Pipeline (`.github/workflows/ci-cd.yml`)
- **Testing**: Runs unit tests, linting, and security scans
- **Building**: Creates Docker images
- **Deployment**: Deploys to Azure services

### Model Training Pipeline (`.github/workflows/model-training.yml`)
- **Scheduled Training**: Automated daily model training
- **Data Processing**: Automated data preprocessing
- **Model Evaluation**: Performance validation
- **Deployment**: Conditional model deployment based on performance

## 🔧 Configuration

### Environment Variables

Key configuration variables in `.env`:

```bash
# Azure Configuration
AZURE_SUBSCRIPTION_ID=your-subscription-id
AZURE_RESOURCE_GROUP=your-resource-group
AZURE_LOCATION=eastus

# Azure OpenAI
AZURE_OPENAI_ENDPOINT=https://your-openai-service.openai.azure.com/
AZURE_OPENAI_API_KEY=your-api-key
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo

# Azure Machine Learning
AZURE_ML_WORKSPACE_NAME=your-ml-workspace

# Azure Storage
AZURE_STORAGE_ACCOUNT_NAME=your-storage-account
```

## 📈 Monitoring and Logging

- **MLflow**: Experiment tracking and model registry
- **Azure Monitor**: Application insights and logging
- **Custom Metrics**: Model performance and usage metrics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Cookiecutter Data Science](https://drivendata.github.io/cookiecutter-data-science/) for the project structure
- [Azure OpenAI Service](https://azure.microsoft.com/en-us/products/ai-services/openai-service) for GenAI capabilities
- [Azure Machine Learning](https://azure.microsoft.com/en-us/products/machine-learning) for MLOps platform

## 📞 Support

For support, please open an issue on GitHub or contact the maintainers.

---

**Built with ❤️ by Korkrid Kyle Akepanidtaworn**