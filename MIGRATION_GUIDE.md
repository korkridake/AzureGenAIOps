# 🔄 Migration Guide: From .env Files to GitHub Secrets

This guide helps you migrate from using `.env` files to the secure GitHub secrets workflow.

## 📋 Before You Start

- [ ] Complete Azure infrastructure deployment
- [ ] Have admin access to your GitHub repository
- [ ] Install Azure CLI and GitHub CLI locally

## 🚀 Quick Migration Steps

### Step 1: Extract Current Secrets

If you already have a deployed infrastructure, extract secrets from Key Vault:

```bash
# Make sure you're logged into Azure
az login

# Run the extraction script
./scripts/extract-secrets-to-github.sh \
  --resource-group "your-resource-group" \
  --github-repo "owner/repository" \
  --github-token "your-github-token" \
  --dry-run  # Remove this to actually set secrets
```

### Step 2: Set Up Service Principal

Create a service principal for GitHub Actions:

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-genaiops" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth

# Copy the output and set these GitHub secrets:
# - AZURE_CLIENT_ID
# - AZURE_CLIENT_SECRET  
# - AZURE_TENANT_ID
```

### Step 3: Update Application Code

Update your application to use the enhanced configuration:

```python
# Before (using regular config)
from src.config import config

# After (using enhanced config with Key Vault support)
from src.config import get_config
config = get_config(use_key_vault=True)
```

### Step 4: Clean Up .env Files

```bash
# Remove .env files from repository (keep .env.example)
git rm .env .env.deployed .env.existing
git commit -m "Remove .env files - migrated to GitHub secrets"

# Update .gitignore to prevent future commits
echo ".env*" >> .gitignore
git add .gitignore
git commit -m "Update .gitignore to exclude .env files"
```

### Step 5: Test the Setup

```bash
# Test Key Vault access
python scripts/test_keyvault_access.py

# Test GitHub Actions workflow
gh workflow run infrastructure.yml \
  --field deployment_type=existing \
  --field environment=dev \
  --field resource_group="your-resource-group" \
  --field whatif=true
```

## 📝 Configuration Comparison

| Aspect | .env Files | GitHub Secrets |
|--------|------------|----------------|
| **Security** | ❌ Secrets in plaintext | ✅ Encrypted secrets |
| **Version Control** | ❌ Risk of committing secrets | ✅ Secrets never in code |
| **CI/CD** | ⚠️ Manual secret management | ✅ Automatic secret injection |
| **Rotation** | ❌ Manual updates needed | ✅ Centralized rotation |
| **Audit** | ❌ No audit trail | ✅ Full audit logs |
| **Team Access** | ❌ Shared files | ✅ Role-based access |

## 🔧 Environment-Specific Setup

### Development
- Use Key Vault integration with your development Azure credentials
- Secrets retrieved directly from Key Vault

### Staging/Production
- Use GitHub secrets in CI/CD pipelines
- Key Vault access via service principal
- No .env files needed

## 🛡️ Security Benefits

1. **No Secrets in Code**: Secrets never stored in repository
2. **Encrypted Storage**: GitHub secrets are encrypted at rest
3. **Access Control**: GitHub repository permissions control access
4. **Audit Trail**: Full logging of secret access
5. **Automatic Rotation**: Easy to update secrets centrally

## ❓ Troubleshooting

### Issue: Key Vault Access Denied
```bash
# Check service principal permissions
az keyvault show --name your-keyvault --query properties.accessPolicies

# Grant access if needed
az keyvault set-policy \
  --name your-keyvault \
  --spn your-client-id \
  --secret-permissions get list
```

### Issue: GitHub Secrets Not Working
1. Verify secrets are set in repository settings
2. Check service principal credentials are correct
3. Ensure repository has correct permissions

### Issue: Application Can't Find Secrets
1. Verify `AZURE_KEY_VAULT_NAME` is set
2. Check Azure authentication is working
3. Test with the Key Vault access script

## 📚 Additional Resources

- [Complete GitHub Secrets Guide](GITHUB_SECRETS_GUIDE.md)
- [Azure Key Vault Documentation](https://docs.microsoft.com/en-us/azure/key-vault/)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)

## ✅ Migration Checklist

- [ ] Extract secrets from Key Vault to GitHub
- [ ] Create and configure service principal
- [ ] Update application code to use enhanced config
- [ ] Remove .env files from repository
- [ ] Update .gitignore
- [ ] Test Key Vault access
- [ ] Test GitHub Actions workflow
- [ ] Verify application works in all environments
- [ ] Document new workflow for team

---

**🎉 Congratulations!** You've successfully migrated to a secure secret management workflow.