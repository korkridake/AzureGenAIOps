#!/bin/bash

# Azure GenAIOps - Extract Secrets to GitHub
# This script extracts secrets from Azure Key Vault and sets them as GitHub repository secrets

set -euo pipefail

# Configuration
RESOURCE_GROUP=""
GITHUB_REPO=""
GITHUB_TOKEN=""
KEY_VAULT_NAME=""
DRY_RUN=false
VERBOSE=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Azure GenAIOps - GitHub Secrets Setup${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
}

print_step() {
    echo -e "${GREEN}[STEP]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Extract secrets from Azure Key Vault and set them as GitHub repository secrets."
    echo
    echo "Options:"
    echo "  -g, --resource-group GROUP    Azure Resource Group name (required)"
    echo "  -r, --github-repo REPO        GitHub repository (owner/repo format) (required)"
    echo "  -t, --github-token TOKEN      GitHub Personal Access Token (required)"
    echo "  -k, --key-vault VAULT         Key Vault name (auto-detected if not provided)"
    echo "  -d, --dry-run                 Show what would be done without making changes"
    echo "  -v, --verbose                 Enable verbose output"
    echo "  -h, --help                    Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -g myresourcegroup -r owner/repo -t ghp_token123"
    echo "  $0 --resource-group mygroup --github-repo user/repo --github-token ghp_xyz --dry-run"
    echo
    echo "Required GitHub Token Permissions:"
    echo "  - repo (Full control of private repositories)"
    echo "  - Or secrets (if available as fine-grained permission)"
}

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Azure CLI is installed and logged in
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check Azure login
    if ! az account show &> /dev/null; then
        print_error "Not logged into Azure CLI. Please run 'az login' first."
        exit 1
    fi
    
    # Check if GitHub CLI is installed
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI is not installed. Please install it first."
        print_info "Install from: https://cli.github.com/"
        exit 1
    fi
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

get_key_vault_name() {
    if [ -z "$KEY_VAULT_NAME" ]; then
        print_step "Auto-detecting Key Vault name..."
        
        # Get Key Vault from the resource group
        KEY_VAULT_NAME=$(az keyvault list --resource-group "$RESOURCE_GROUP" --query "[0].name" -o tsv 2>/dev/null || echo "")
        
        if [ -z "$KEY_VAULT_NAME" ]; then
            print_error "Could not find Key Vault in resource group '$RESOURCE_GROUP'"
            print_info "Please specify Key Vault name using --key-vault option"
            exit 1
        fi
        
        print_info "Found Key Vault: $KEY_VAULT_NAME"
    fi
}

authenticate_github() {
    print_step "Authenticating with GitHub..."
    
    # Set GitHub token
    echo "$GITHUB_TOKEN" | gh auth login --with-token
    
    # Verify authentication
    if ! gh auth status &> /dev/null; then
        print_error "GitHub authentication failed"
        exit 1
    fi
    
    print_success "GitHub authentication successful"
}

extract_and_set_secrets() {
    print_step "Extracting secrets from Key Vault and setting GitHub secrets..."
    
    # Define secret mappings (Key Vault secret name -> GitHub secret name)
    declare -A secret_mappings=(
        ["openai-endpoint"]="AZURE_OPENAI_ENDPOINT"
        ["openai-api-key"]="AZURE_OPENAI_API_KEY"
        ["search-endpoint"]="AZURE_SEARCH_ENDPOINT"
        ["search-api-key"]="AZURE_SEARCH_API_KEY"
        ["storage-connection-string"]="AZURE_STORAGE_CONNECTION_STRING"
        ["doc-intelligence-endpoint"]="AZURE_DOC_INTELLIGENCE_ENDPOINT"
        ["doc-intelligence-api-key"]="AZURE_DOC_INTELLIGENCE_API_KEY"
        ["monitor-connection-string"]="AZURE_MONITOR_CONNECTION_STRING"
        ["jwt-signing-key"]="JWT_SIGNING_KEY"
        ["subscription-id"]="AZURE_SUBSCRIPTION_ID"
        ["resource-group"]="AZURE_RESOURCE_GROUP"
        ["ai-project-name"]="AZURE_AI_PROJECT_NAME"
        ["storage-account-name"]="AZURE_STORAGE_ACCOUNT_NAME"
        ["key-vault-name"]="AZURE_KEY_VAULT_NAME"
    )
    
    # Track success/failure
    local secrets_set=0
    local secrets_failed=0
    local secrets_skipped=0
    
    echo
    print_info "Processing secrets..."
    echo
    
    for kv_secret in "${!secret_mappings[@]}"; do
        github_secret="${secret_mappings[$kv_secret]}"
        
        print_verbose "Processing: $kv_secret -> $github_secret"
        
        # Try to get secret from Key Vault
        secret_value=$(az keyvault secret show \
            --vault-name "$KEY_VAULT_NAME" \
            --name "$kv_secret" \
            --query "value" \
            -o tsv 2>/dev/null || echo "")
        
        if [ -z "$secret_value" ]; then
            print_warning "Secret '$kv_secret' not found in Key Vault, skipping"
            ((secrets_skipped++))
            continue
        fi
        
        # Mask sensitive values in output
        if [[ "$kv_secret" == *"key"* ]] || [[ "$kv_secret" == *"connection"* ]] || [[ "$kv_secret" == *"jwt"* ]]; then
            masked_value="***MASKED***"
        else
            masked_value="$secret_value"
        fi
        
        if [ "$DRY_RUN" = true ]; then
            print_info "Would set GitHub secret '$github_secret' with value: $masked_value"
            ((secrets_set++))
        else
            # Set GitHub secret
            if echo "$secret_value" | gh secret set "$github_secret" --repo "$GITHUB_REPO"; then
                print_success "Set GitHub secret: $github_secret"
                ((secrets_set++))
            else
                print_error "Failed to set GitHub secret: $github_secret"
                ((secrets_failed++))
            fi
        fi
    done
    
    echo
    print_info "Summary:"
    print_info "  Secrets processed: $((secrets_set + secrets_failed + secrets_skipped))"
    print_info "  Secrets set: $secrets_set"
    print_info "  Secrets failed: $secrets_failed"
    print_info "  Secrets skipped: $secrets_skipped"
    
    if [ $secrets_failed -gt 0 ]; then
        print_error "Some secrets failed to be set. Please check the errors above."
        exit 1
    fi
}

set_additional_secrets() {
    print_step "Setting additional required GitHub secrets..."
    
    # Get current Azure subscription and tenant info
    local subscription_id=$(az account show --query id -o tsv)
    local tenant_id=$(az account show --query tenantId -o tsv)
    
    # Additional secrets that aren't in Key Vault but are needed
    declare -A additional_secrets=(
        ["AZURE_SUBSCRIPTION_ID"]="$subscription_id"
        ["AZURE_TENANT_ID"]="$tenant_id"
        ["AZURE_RESOURCE_GROUP"]="$RESOURCE_GROUP"
        ["AZURE_KEY_VAULT_NAME"]="$KEY_VAULT_NAME"
    )
    
    for secret_name in "${!additional_secrets[@]}"; do
        secret_value="${additional_secrets[$secret_name]}"
        
        if [ "$DRY_RUN" = true ]; then
            print_info "Would set GitHub secret '$secret_name' with value: $secret_value"
        else
            if echo "$secret_value" | gh secret set "$secret_name" --repo "$GITHUB_REPO"; then
                print_success "Set GitHub secret: $secret_name"
            else
                print_error "Failed to set GitHub secret: $secret_name"
            fi
        fi
    done
}

show_next_steps() {
    echo
    print_step "Next Steps:"
    echo
    print_info "1. Set up service principal secrets (if not already done):"
    echo "   - AZURE_CLIENT_ID"
    echo "   - AZURE_CLIENT_SECRET"
    echo "   - AZURE_TENANT_ID"
    echo
    print_info "2. Create service principal with Key Vault access:"
    echo "   az ad sp create-for-rbac --name 'github-actions-genaiops' \\"
    echo "     --role contributor \\"
    echo "     --scopes /subscriptions/$subscription_id/resourceGroups/$RESOURCE_GROUP \\"
    echo "     --sdk-auth"
    echo
    print_info "3. Grant Key Vault access to service principal:"
    echo "   az keyvault set-policy --name $KEY_VAULT_NAME \\"
    echo "     --spn {client-id-from-step-2} \\"
    echo "     --secret-permissions get list"
    echo
    print_info "4. Test your GitHub Actions workflow:"
    echo "   gh workflow run infrastructure.yml \\"
    echo "     --field deployment_type=existing \\"
    echo "     --field environment=dev \\"
    echo "     --field resource_group=$RESOURCE_GROUP \\"
    echo "     --field whatif=true"
    echo
    print_info "5. Review the GitHub Secrets Guide for more details:"
    echo "   cat GITHUB_SECRETS_GUIDE.md"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -r|--github-repo)
            GITHUB_REPO="$2"
            shift 2
            ;;
        -t|--github-token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -k|--key-vault)
            KEY_VAULT_NAME="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$RESOURCE_GROUP" ] || [ -z "$GITHUB_REPO" ] || [ -z "$GITHUB_TOKEN" ]; then
    print_error "Missing required arguments"
    echo
    show_usage
    exit 1
fi

# Main execution
print_header

if [ "$DRY_RUN" = true ]; then
    print_warning "Running in DRY RUN mode - no changes will be made"
    echo
fi

check_prerequisites
get_key_vault_name
authenticate_github
extract_and_set_secrets
set_additional_secrets

if [ "$DRY_RUN" = false ]; then
    show_next_steps
fi

echo
print_success "GitHub secrets setup completed successfully!"

if [ "$DRY_RUN" = true ]; then
    echo
    print_info "Re-run without --dry-run to actually set the secrets"
fi