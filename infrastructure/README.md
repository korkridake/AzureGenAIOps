# Azure GenAIOps Infrastructure Deployment

This directory contains Azure infrastructure-as-code (IaC) templates and deployment scripts for the Azure GenAIOps platform using Azure Bicep.

## 🏗️ Architecture Overview

The infrastructure supports two deployment scenarios:

1. **New Deployment**: Deploy a complete new GenAIOps platform with all Azure services
2. **Existing Resources**: Deploy GenAIOps platform using your existing Azure AI services

## 📁 Directory Structure

```
infrastructure/
├── bicep/                          # Bicep templates
│   ├── main.bicep                  # Main template for new deployments
│   ├── existing-resources.bicep    # Template for existing resources
│   ├── modules/                    # Modular Bicep templates
│   │   ├── ai-foundry.bicep        # Azure AI Foundry project
│   │   ├── openai.bicep            # Azure OpenAI service
│   │   ├── search.bicep            # Azure AI Search
│   │   ├── storage.bicep           # Azure Storage
│   │   ├── container-apps.bicep    # Azure Container Apps
│   │   ├── monitoring.bicep        # Azure Monitor
│   │   ├── key-vault.bicep         # Azure Key Vault
│   │   ├── app-config.json         # Application configuration
│   │   └── model-config.json       # Model configuration
│   └── parameters/                 # Parameter files
│       ├── main.parameters.json    # Parameters for new deployment
│       └── existing.parameters.json # Parameters for existing resources
├── scripts/                        # Deployment scripts
│   ├── deploy-new.sh               # Bash script for new deployment
│   ├── deploy-existing.sh          # Bash script for existing resources
│   └── deploy.ps1                  # PowerShell deployment script
└── README.md                       # This file
```

## 🚀 Quick Start

### Option 1: New Deployment (Recommended for new projects)

Deploy a complete new GenAIOps platform with all Azure services:

```bash
# Make scripts executable
chmod +x infrastructure/scripts/deploy-new.sh

# Run deployment
./infrastructure/scripts/deploy-new.sh
```

Or use PowerShell:

```powershell
.\infrastructure\scripts\deploy.ps1 -DeploymentType new
```

### Option 2: Existing Resources (Use your current Azure services)

Deploy GenAIOps platform using your existing Azure AI services:

```bash
# Make scripts executable  
chmod +x infrastructure/scripts/deploy-existing.sh

# Run deployment
./infrastructure/scripts/deploy-existing.sh
```

Or use PowerShell:

```powershell
.\infrastructure\scripts\deploy.ps1 -DeploymentType existing
```

## 📋 Prerequisites

### Required Tools

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) 2.50.0 or later
- [Azure Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) (auto-installed with Azure CLI)
- For PowerShell: [Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps) 9.0.0 or later

### Azure Permissions

Your account needs the following Azure RBAC roles:

- **Contributor** on the target subscription or resource group
- **User Access Administrator** for role assignments
- **Key Vault Administrator** for Key Vault operations

### Required Information

Before deployment, gather:

- **Azure Subscription ID**
- **Resource Group Name** (will be created if it doesn't exist)
- **Azure AD User Object ID** (auto-detected in scripts)
- **Azure Region** (default: East US)

For existing resources deployment, also gather:
- Existing Azure AI Foundry project name and resource group
- Existing Azure OpenAI service name and resource group  
- Existing Azure AI Search service name and resource group
- Existing Azure Storage account name and resource group
- (Optional) Existing Azure Key Vault name and resource group

## 🔧 Detailed Deployment Options

### New Deployment

Creates all Azure resources from scratch:

#### Resources Created:
- **Azure AI Foundry Project** with supporting infrastructure
- **Azure OpenAI Service** with GPT-4, GPT-3.5-Turbo, and embedding models
- **Azure AI Search** with vector search and semantic search capabilities
- **Azure Storage Account** with containers for documents, models, and data
- **Azure Key Vault** for secure credential management
- **Azure Container Apps** for hosting the GenAIOps application
- **Azure Monitor** (Log Analytics + Application Insights) for observability

#### Command Line Options:

```bash
./infrastructure/scripts/deploy-new.sh \
  --resource-group "my-genaiops-rg" \
  --location "East US" \
  --project-name "mygenaiops" \
  --environment "dev" \
  --user-object-id "12345678-1234-1234-1234-123456789012"
```

#### PowerShell Options:

```powershell
.\infrastructure\scripts\deploy.ps1 `
  -DeploymentType new `
  -ResourceGroupName "my-genaiops-rg" `
  -Location "East US" `
  -ProjectName "mygenaiops" `
  -Environment dev `
  -UserObjectId "12345678-1234-1234-1234-123456789012"
```

### Existing Resources Deployment

Uses your existing Azure AI services and creates minimal additional infrastructure:

#### Resources Created:
- **Azure Container Apps** for hosting the GenAIOps application
- **Azure Key Vault** (if not using existing)
- **Azure Monitor** (optional, if not using existing)

#### Resources Referenced:
- Your existing Azure AI Foundry project
- Your existing Azure OpenAI service
- Your existing Azure AI Search service
- Your existing Azure Storage account
- (Optional) Your existing Azure Key Vault

#### Command Line Options:

```bash
./infrastructure/scripts/deploy-existing.sh \
  --resource-group "my-new-resources-rg" \
  --ai-foundry "my-existing-ai-foundry" \
  --openai "my-existing-openai" \
  --search "my-existing-search" \
  --storage "my-existing-storage"
```

## 🎛️ Configuration

### Parameter Files

Customize deployments by editing parameter files:

#### New Deployment Parameters (`bicep/parameters/main.parameters.json`):

```json
{
  "projectName": "genaiops",
  "location": "East US", 
  "environment": "dev",
  "userObjectId": "YOUR_USER_OBJECT_ID"
}
```

#### Existing Resources Parameters (`bicep/parameters/existing.parameters.json`):

```json
{
  "projectName": "genaiops",
  "existingAiFoundryProjectName": "YOUR_AI_FOUNDRY_PROJECT",
  "existingOpenAiAccountName": "YOUR_OPENAI_ACCOUNT",
  "existingSearchServiceName": "YOUR_SEARCH_SERVICE",
  "existingStorageAccountName": "YOUR_STORAGE_ACCOUNT"
}
```

### Application Configuration

The deployment creates application configuration files:

- **app-config.json**: LLM settings, RAG configuration, safety settings
- **model-config.json**: Model deployments, fine-tuning settings, evaluation metrics

### Environment Variables

**⚠️ Security Notice**: For production use, avoid storing secrets in `.env` files. Instead, use the [GitHub Secrets Integration Guide](../GITHUB_SECRETS_GUIDE.md) for secure secret management.

After deployment, you have several options for configuration:

#### Option 1: GitHub Secrets (Recommended for Production)
Follow the [GitHub Secrets Guide](../GITHUB_SECRETS_GUIDE.md) to securely manage secrets using GitHub secrets and Azure Key Vault.

#### Option 2: Local Development with .env Files
Copy the generated `.env` file for local development:

```bash
# For new deployment
cp .env.deployed .env

# For existing resources
cp .env.existing .env
```

**Note**: Never commit `.env` files to version control.

## 🧪 Testing and Validation

### Validate Templates

Test templates without deploying:

```bash
# Validate new deployment template
az deployment group validate \
  --resource-group "test-rg" \
  --template-file bicep/main.bicep \
  --parameters @bicep/parameters/main.parameters.json

# Validate existing resources template  
az deployment group validate \
  --resource-group "test-rg" \
  --template-file bicep/existing-resources.bicep \
  --parameters @bicep/parameters/existing.parameters.json
```

### WhatIf Deployment

Preview changes with PowerShell:

```powershell
.\infrastructure\scripts\deploy.ps1 -DeploymentType new -WhatIf
```

### Test Deployment

After deployment, test the GenAIOps API:

```bash
# Health check
curl "$CONTAINER_APP_URL/health"

# API documentation
curl "$CONTAINER_APP_URL/docs"

# Test chat completion
curl -X POST "$CONTAINER_APP_URL/chat/completions" \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "Hello!"}]}'
```

## 🔐 Security Considerations

### Network Security

- All services use HTTPS/TLS encryption
- Azure services communicate over Azure backbone
- Container Apps use system-assigned managed identity
- Key Vault stores all sensitive configuration

### Access Control

- Role-based access control (RBAC) configured for all services
- Managed identities eliminate credential management
- Key Vault access policies restrict secret access
- Application Insights provides audit logging

### Data Protection

- Storage accounts disable public blob access
- Key Vault enables soft delete and purge protection
- All data encrypted at rest and in transit
- Content filtering enabled for Azure OpenAI

### GitHub Secrets Integration

For secure CI/CD pipelines and production deployments:

- **Service Principal Authentication**: Use dedicated service principals for GitHub Actions
- **GitHub Secrets Storage**: Store sensitive values as GitHub repository secrets
- **Key Vault Integration**: Application can retrieve secrets directly from Key Vault at runtime
- **Zero .env Files**: Eliminate the need for environment files in production

See the [GitHub Secrets Integration Guide](../GITHUB_SECRETS_GUIDE.md) for detailed setup instructions.

## 📊 Monitoring and Observability

### Azure Monitor Integration

- **Application Insights** tracks API performance and usage
- **Log Analytics** centralizes all platform logs
- **Custom metrics** for LLM operations and token usage
- **Automated alerts** for errors and performance issues

### Dashboards

The deployment creates:

- GenAIOps monitoring workbook
- Custom metrics for token usage, response times, safety scores
- Alert rules for high error rates and token usage

### Telemetry

Application telemetry includes:

- Request/response tracking
- Model performance metrics
- Safety and content filtering results
- RAG retrieval effectiveness
- User session analytics

## 🛠️ Troubleshooting

### Common Issues

#### Deployment Failures

1. **Insufficient permissions**
   ```bash
   # Check your Azure role assignments
   az role assignment list --assignee $(az account show --query user.name -o tsv)
   ```

2. **Resource name conflicts**
   - Use different project names
   - Ensure globally unique names for storage accounts

3. **Azure OpenAI quota limits**
   - Check your subscription's Azure OpenAI quota
   - Request quota increases if needed

#### Post-Deployment Issues

1. **Container app not starting**
   ```bash
   # Check container app logs
   az containerapp logs show --name $CONTAINER_APP_NAME --resource-group $RESOURCE_GROUP
   ```

2. **Key Vault access denied**
   ```bash
   # Verify managed identity permissions
   az keyvault show --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP
   ```

3. **OpenAI API errors**
   - Verify API keys in Key Vault
   - Check model deployment status
   - Confirm quota availability

### Getting Help

1. **Check deployment outputs**
   ```bash
   az deployment group show --name $DEPLOYMENT_NAME --resource-group $RESOURCE_GROUP
   ```

2. **Review Azure Activity Log**
   ```bash
   az monitor activity-log list --resource-group $RESOURCE_GROUP
   ```

3. **Enable diagnostic logging**
   - All services have diagnostic settings configured
   - Check Log Analytics workspace for detailed logs

## 🔄 Updates and Maintenance

### Updating Infrastructure

1. **Modify Bicep templates** for infrastructure changes
2. **Test changes** with validation and WhatIf
3. **Deploy updates** using the same scripts
4. **Monitor deployments** for successful completion

### Scaling Resources

- **Azure OpenAI**: Adjust model deployment capacity
- **Azure AI Search**: Scale search units and replicas  
- **Container Apps**: Modify replica count and scaling rules
- **Storage**: Enable premium tiers for high-performance scenarios

### Cost Optimization

- **Use existing resources** when possible
- **Right-size deployments** based on usage
- **Monitor costs** with Azure Cost Management
- **Implement auto-scaling** to optimize resource utilization

## 📞 Support

For issues with infrastructure deployment:

1. **Check this documentation** for common solutions
2. **Review Azure documentation** for service-specific issues
3. **Open GitHub issues** for template bugs or improvements
4. **Contact Azure support** for platform-specific problems

## 🤝 Contributing

To contribute to the infrastructure templates:

1. **Fork the repository**
2. **Create a feature branch** for your changes
3. **Test changes** thoroughly with validation
4. **Submit a pull request** with detailed description
5. **Update documentation** as needed

---

**Built with ❤️ for Azure GenAIOps Platform Infrastructure**