# 🔐 GitHub Secrets Integration Guide

This guide provides detailed instructions on how to securely manage environment variables using GitHub secrets instead of storing them in `.env` files, and how to establish proper authentication between Azure and GitHub after deployment.

## 🎯 Overview

Instead of storing sensitive Azure credentials in `.env` files, this guide shows you how to:
1. Set up GitHub secrets to store sensitive values
2. Configure GitHub Actions to retrieve secrets from Azure Key Vault
3. Establish secure authentication between Azure and GitHub
4. Migrate from `.env` files to GitHub secrets workflow

## 📋 Prerequisites

- Azure subscription with deployed AzureGenAIOps infrastructure
- GitHub repository with admin access
- Azure CLI installed locally
- Proper Azure RBAC permissions (Contributor, Key Vault Administrator)

## 🚀 Step 1: Set Up Azure Service Principal for GitHub

### 1.1 Create Service Principal

Create a service principal for GitHub Actions to authenticate with Azure:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-genaiops" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{your-resource-group} \
  --sdk-auth

# Save the output - you'll need it for GitHub secrets
```

The output will look like:
```json
{
  "clientId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "clientSecret": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  "subscriptionId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "tenantId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

### 1.2 Grant Key Vault Access

Grant the service principal access to your Key Vault:

```bash
# Get your Key Vault name from deployment
KEY_VAULT_NAME=$(az keyvault list --resource-group {your-resource-group} --query "[0].name" -o tsv)

# Grant Key Vault access to service principal
az keyvault set-policy \
  --name $KEY_VAULT_NAME \
  --spn {clientId-from-above} \
  --secret-permissions get list
```

## 🔑 Step 2: Configure GitHub Secrets

### 2.1 Required GitHub Secrets

Set up the following secrets in your GitHub repository (Settings → Secrets and variables → Actions):

| Secret Name | Description | Source |
|-------------|-------------|---------|
| `AZURE_CLIENT_ID` | Service Principal Client ID | From step 1.1 output |
| `AZURE_CLIENT_SECRET` | Service Principal Secret | From step 1.1 output |
| `AZURE_TENANT_ID` | Azure Tenant ID | From step 1.1 output |
| `AZURE_SUBSCRIPTION_ID` | Azure Subscription ID | From step 1.1 output |
| `AZURE_RESOURCE_GROUP` | Resource Group Name | Your deployment resource group |
| `AZURE_KEY_VAULT_NAME` | Key Vault Name | From your deployment |

### 2.2 Optional GitHub Secrets

For additional security, you can also set these secrets directly in GitHub:

| Secret Name | Description | Source |
|-------------|-------------|---------|
| `AZURE_OPENAI_API_KEY` | OpenAI API Key | From Azure Portal or Key Vault |
| `AZURE_SEARCH_API_KEY` | AI Search API Key | From Azure Portal or Key Vault |
| `AZURE_STORAGE_CONNECTION_STRING` | Storage Connection String | From Azure Portal or Key Vault |

## 🛠️ Step 3: Extract Secrets from Key Vault

Use the provided helper script to extract secrets from Azure Key Vault and set them as GitHub secrets:

```bash
# Run the secret extraction script
./scripts/extract-secrets-to-github.sh \
  --resource-group "{your-resource-group}" \
  --github-repo "{owner/repository-name}" \
  --github-token "{your-github-token}"
```

Or manually extract secrets:

```bash
# Get Key Vault name
KEY_VAULT_NAME=$(az keyvault list --resource-group {your-resource-group} --query "[0].name" -o tsv)

# Extract secrets
OPENAI_KEY=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name "openai-api-key" --query "value" -o tsv)
SEARCH_KEY=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name "search-api-key" --query "value" -o tsv)
STORAGE_CONN=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name "storage-connection-string" --query "value" -o tsv)

# Set GitHub secrets using GitHub CLI
gh secret set AZURE_OPENAI_API_KEY --body "$OPENAI_KEY"
gh secret set AZURE_SEARCH_API_KEY --body "$SEARCH_KEY"
gh secret set AZURE_STORAGE_CONNECTION_STRING --body "$STORAGE_CONN"
```

## 📝 Step 4: Update Application Configuration

### 4.1 Enhanced Configuration Class

The application now supports Key Vault integration. Update your configuration:

```python
# In your application startup or config
from src.common.keyvault_config import KeyVaultConfig

# Use Key Vault configuration instead of environment variables
config = KeyVaultConfig(
    key_vault_name=os.getenv("AZURE_KEY_VAULT_NAME"),
    use_managed_identity=True  # When running in Azure
)
```

### 4.2 Environment Variables Priority

The application follows this priority order:
1. Azure Key Vault secrets (if configured)
2. GitHub secrets (in CI/CD)
3. Environment variables (local development)
4. Default values

## 🔄 Step 5: Update GitHub Actions Workflows

Your workflows are already configured to use the required Azure secrets. For additional secrets, update your workflow files:

```yaml
env:
  AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  AZURE_RESOURCE_GROUP: ${{ secrets.AZURE_RESOURCE_GROUP }}
  AZURE_KEY_VAULT_NAME: ${{ secrets.AZURE_KEY_VAULT_NAME }}
  # Add other secrets as needed
  AZURE_OPENAI_API_KEY: ${{ secrets.AZURE_OPENAI_API_KEY }}
  AZURE_SEARCH_API_KEY: ${{ secrets.AZURE_SEARCH_API_KEY }}
```

## 🧪 Step 6: Test the Setup

### 6.1 Test GitHub Actions Authentication

Trigger a workflow run to verify authentication:

```bash
# Trigger infrastructure workflow
gh workflow run infrastructure.yml \
  --field deployment_type=existing \
  --field environment=dev \
  --field resource_group="{your-resource-group}" \
  --field whatif=true
```

### 6.2 Test Key Vault Access

Run a test to verify Key Vault access:

```bash
# Test script provided in the repository
python scripts/test_keyvault_access.py
```

## 🔄 Step 7: Migration from .env Files

### 7.1 Remove .env Files

1. **Backup existing .env files** (if any)
2. **Remove .env files** from your repository
3. **Update .gitignore** to prevent future .env commits:

```gitignore
# Environment variables
.env
.env.local
.env.*.local
.env.deployed
.env.existing
```

### 7.2 Update Documentation

Update any documentation that references `.env` files to point to this GitHub secrets guide.

## 🛡️ Security Best Practices

### 7.1 Service Principal Security

- **Limit scope**: Grant minimal required permissions
- **Rotate secrets**: Regularly rotate client secrets
- **Monitor access**: Use Azure Monitor to track service principal usage

### 7.2 GitHub Secrets Security

- **Environment protection**: Use environment protection rules for production
- **Secret rotation**: Regularly rotate GitHub secrets
- **Access control**: Limit who can view/edit repository secrets

### 7.3 Key Vault Security

- **Access policies**: Use least-privilege access policies
- **Audit logging**: Enable Key Vault logging
- **Network isolation**: Consider private endpoints for production

## 🔧 Troubleshooting

### Authentication Issues

```bash
# Test Azure authentication
az account show

# Test service principal authentication
az login --service-principal \
  --username {clientId} \
  --password {clientSecret} \
  --tenant {tenantId}

# Test Key Vault access
az keyvault secret list --vault-name {your-key-vault}
```

### GitHub Actions Issues

1. **Check secret values**: Ensure all required secrets are set
2. **Verify permissions**: Check service principal has correct RBAC roles
3. **Review logs**: Check GitHub Actions logs for detailed error messages

### Key Vault Access Issues

```bash
# Check Key Vault access policies
az keyvault show --name {your-key-vault} --query properties.accessPolicies

# Test secret retrieval
az keyvault secret show --vault-name {your-key-vault} --name "openai-api-key"
```

## 📚 Additional Resources

- [Azure Service Principal Authentication](https://docs.microsoft.com/en-us/azure/developer/github/connect-from-azure)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Azure Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Azure RBAC Documentation](https://docs.microsoft.com/en-us/azure/role-based-access-control/)

## ❓ Support

For issues with this setup:
1. Check the troubleshooting section above
2. Review GitHub Actions logs
3. Verify Azure permissions and configurations
4. Open an issue in the repository with detailed error information

---

**🔒 Remember**: Never store sensitive credentials in code or configuration files. Always use secure secret management solutions like GitHub secrets and Azure Key Vault.