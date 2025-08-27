#!/bin/bash

# Azure GenAIOps - Deploy with Existing Resources
# This script deploys GenAIOps infrastructure using existing Azure resources

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="$(dirname "$SCRIPT_DIR")/bicep"
DEPLOYMENT_NAME="genaiops-existing-$(date +%Y%m%d-%H%M%S)"
LOCATION="East US"
RESOURCE_GROUP=""
PROJECT_NAME="genaiops"
ENVIRONMENT="dev"
USER_OBJECT_ID=""

# Existing resources
EXISTING_AI_FOUNDRY=""
EXISTING_AI_FOUNDRY_RG=""
EXISTING_OPENAI=""
EXISTING_OPENAI_RG=""
EXISTING_SEARCH=""
EXISTING_SEARCH_RG=""
EXISTING_STORAGE=""
EXISTING_STORAGE_RG=""
EXISTING_KEYVAULT=""
EXISTING_KEYVAULT_RG=""
DEPLOY_NEW_MONITORING="true"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Azure GenAIOps - Existing Resources Deployment${NC}"
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

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    
    # Check if user is logged in
    if ! az account show &> /dev/null; then
        print_error "You are not logged in to Azure. Please run 'az login' first."
        exit 1
    fi
    
    # Check if Bicep is installed
    if ! az bicep version &> /dev/null; then
        print_warning "Bicep is not installed. Installing Bicep..."
        az bicep install
    fi
    
    print_success "Prerequisites check completed."
}

get_user_input() {
    print_step "Gathering deployment parameters..."
    
    # Get resource group name for new resources
    if [ -z "$RESOURCE_GROUP" ]; then
        read -p "Enter resource group name for new resources (will be created if it doesn't exist): " RESOURCE_GROUP
    fi
    
    # Get project name
    read -p "Enter project name (default: $PROJECT_NAME): " input_project_name
    PROJECT_NAME=${input_project_name:-$PROJECT_NAME}
    
    # Get environment
    read -p "Enter environment (dev/staging/prod, default: $ENVIRONMENT): " input_environment
    ENVIRONMENT=${input_environment:-$ENVIRONMENT}
    
    # Get location
    read -p "Enter location for new resources (default: $LOCATION): " input_location
    LOCATION=${input_location:-$LOCATION}
    
    echo
    print_info "Now let's configure your existing Azure resources:"
    echo
    
    # Get existing AI Foundry project
    read -p "Enter existing Azure AI Foundry project name: " EXISTING_AI_FOUNDRY
    read -p "Enter Azure AI Foundry project resource group (default: $RESOURCE_GROUP): " input_ai_foundry_rg
    EXISTING_AI_FOUNDRY_RG=${input_ai_foundry_rg:-$RESOURCE_GROUP}
    
    # Get existing OpenAI service
    read -p "Enter existing Azure OpenAI service name: " EXISTING_OPENAI
    read -p "Enter Azure OpenAI service resource group (default: $EXISTING_AI_FOUNDRY_RG): " input_openai_rg
    EXISTING_OPENAI_RG=${input_openai_rg:-$EXISTING_AI_FOUNDRY_RG}
    
    # Get existing Search service
    read -p "Enter existing Azure AI Search service name: " EXISTING_SEARCH
    read -p "Enter Azure AI Search service resource group (default: $EXISTING_OPENAI_RG): " input_search_rg
    EXISTING_SEARCH_RG=${input_search_rg:-$EXISTING_OPENAI_RG}
    
    # Get existing Storage account
    read -p "Enter existing Azure Storage account name: " EXISTING_STORAGE
    read -p "Enter Azure Storage account resource group (default: $EXISTING_SEARCH_RG): " input_storage_rg
    EXISTING_STORAGE_RG=${input_storage_rg:-$EXISTING_SEARCH_RG}
    
    # Get existing Key Vault (optional)
    read -p "Enter existing Azure Key Vault name (optional, leave empty to create new): " EXISTING_KEYVAULT
    if [ ! -z "$EXISTING_KEYVAULT" ]; then
        read -p "Enter Azure Key Vault resource group (default: $EXISTING_STORAGE_RG): " input_keyvault_rg
        EXISTING_KEYVAULT_RG=${input_keyvault_rg:-$EXISTING_STORAGE_RG}
    fi
    
    # Ask about monitoring
    read -p "Deploy new monitoring resources (Log Analytics, Application Insights)? (Y/n): " deploy_monitoring
    if [[ $deploy_monitoring == [nN] || $deploy_monitoring == [nN][oO] ]]; then
        DEPLOY_NEW_MONITORING="false"
        read -p "Enter existing Log Analytics workspace name: " EXISTING_LOG_ANALYTICS
        read -p "Enter existing Application Insights name: " EXISTING_APP_INSIGHTS
    fi
    
    # Get user object ID if not provided
    if [ -z "$USER_OBJECT_ID" ]; then
        print_info "Getting your Azure AD user object ID..."
        USER_SIGNED_IN=$(az account show --query user.name -o tsv)
        USER_OBJECT_ID=$(az ad user show --id "$USER_SIGNED_IN" --query id -o tsv)
        print_info "User Object ID: $USER_OBJECT_ID"
    fi
    
    echo
    print_info "Deployment Configuration:"
    print_info "  New Resource Group: $RESOURCE_GROUP"
    print_info "  Project Name: $PROJECT_NAME"
    print_info "  Environment: $ENVIRONMENT"
    print_info "  Location: $LOCATION"
    print_info "  AI Foundry: $EXISTING_AI_FOUNDRY (in $EXISTING_AI_FOUNDRY_RG)"
    print_info "  OpenAI: $EXISTING_OPENAI (in $EXISTING_OPENAI_RG)"
    print_info "  Search: $EXISTING_SEARCH (in $EXISTING_SEARCH_RG)"
    print_info "  Storage: $EXISTING_STORAGE (in $EXISTING_STORAGE_RG)"
    print_info "  Key Vault: ${EXISTING_KEYVAULT:-'[New]'}"
    print_info "  Deploy New Monitoring: $DEPLOY_NEW_MONITORING"
    echo
    
    read -p "Continue with deployment? (y/N): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
}

verify_existing_resources() {
    print_step "Verifying existing resources..."
    
    # Verify AI Foundry project
    if ! az ml workspace show --name "$EXISTING_AI_FOUNDRY" --resource-group "$EXISTING_AI_FOUNDRY_RG" &> /dev/null; then
        print_error "Azure AI Foundry project '$EXISTING_AI_FOUNDRY' not found in resource group '$EXISTING_AI_FOUNDRY_RG'"
        exit 1
    fi
    
    # Verify OpenAI service
    if ! az cognitiveservices account show --name "$EXISTING_OPENAI" --resource-group "$EXISTING_OPENAI_RG" &> /dev/null; then
        print_error "Azure OpenAI service '$EXISTING_OPENAI' not found in resource group '$EXISTING_OPENAI_RG'"
        exit 1
    fi
    
    # Verify Search service
    if ! az search service show --name "$EXISTING_SEARCH" --resource-group "$EXISTING_SEARCH_RG" &> /dev/null; then
        print_error "Azure AI Search service '$EXISTING_SEARCH' not found in resource group '$EXISTING_SEARCH_RG'"
        exit 1
    fi
    
    # Verify Storage account
    if ! az storage account show --name "$EXISTING_STORAGE" --resource-group "$EXISTING_STORAGE_RG" &> /dev/null; then
        print_error "Azure Storage account '$EXISTING_STORAGE' not found in resource group '$EXISTING_STORAGE_RG'"
        exit 1
    fi
    
    # Verify Key Vault if provided
    if [ ! -z "$EXISTING_KEYVAULT" ]; then
        if ! az keyvault show --name "$EXISTING_KEYVAULT" --resource-group "$EXISTING_KEYVAULT_RG" &> /dev/null; then
            print_error "Azure Key Vault '$EXISTING_KEYVAULT' not found in resource group '$EXISTING_KEYVAULT_RG'"
            exit 1
        fi
    fi
    
    print_success "All existing resources verified successfully."
}

create_resource_group() {
    print_step "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
    
    if az group show --name "$RESOURCE_GROUP" &> /dev/null; then
        print_info "Resource group '$RESOURCE_GROUP' already exists."
    else
        az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
        print_success "Resource group '$RESOURCE_GROUP' created successfully."
    fi
}

validate_template() {
    print_step "Validating Bicep template..."
    
    az deployment group validate \
        --resource-group "$RESOURCE_GROUP" \
        --template-file "$BICEP_DIR/existing-resources.bicep" \
        --parameters \
            projectName="$PROJECT_NAME" \
            location="$LOCATION" \
            environment="$ENVIRONMENT" \
            userObjectId="$USER_OBJECT_ID" \
            existingAiFoundryProjectName="$EXISTING_AI_FOUNDRY" \
            existingAiFoundryResourceGroup="$EXISTING_AI_FOUNDRY_RG" \
            existingOpenAiAccountName="$EXISTING_OPENAI" \
            existingOpenAiResourceGroup="$EXISTING_OPENAI_RG" \
            existingSearchServiceName="$EXISTING_SEARCH" \
            existingSearchResourceGroup="$EXISTING_SEARCH_RG" \
            existingStorageAccountName="$EXISTING_STORAGE" \
            existingStorageResourceGroup="$EXISTING_STORAGE_RG" \
            existingKeyVaultName="$EXISTING_KEYVAULT" \
            existingKeyVaultResourceGroup="$EXISTING_KEYVAULT_RG" \
            deployNewMonitoring="$DEPLOY_NEW_MONITORING"
    
    print_success "Template validation completed successfully."
}

deploy_infrastructure() {
    print_step "Deploying Azure GenAIOps infrastructure with existing resources..."
    print_info "This may take 10-20 minutes depending on the new resources being created..."
    
    # Start deployment
    deployment_output=$(az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$BICEP_DIR/existing-resources.bicep" \
        --parameters \
            projectName="$PROJECT_NAME" \
            location="$LOCATION" \
            environment="$ENVIRONMENT" \
            userObjectId="$USER_OBJECT_ID" \
            existingAiFoundryProjectName="$EXISTING_AI_FOUNDRY" \
            existingAiFoundryResourceGroup="$EXISTING_AI_FOUNDRY_RG" \
            existingOpenAiAccountName="$EXISTING_OPENAI" \
            existingOpenAiResourceGroup="$EXISTING_OPENAI_RG" \
            existingSearchServiceName="$EXISTING_SEARCH" \
            existingSearchResourceGroup="$EXISTING_SEARCH_RG" \
            existingStorageAccountName="$EXISTING_STORAGE" \
            existingStorageResourceGroup="$EXISTING_STORAGE_RG" \
            existingKeyVaultName="$EXISTING_KEYVAULT" \
            existingKeyVaultResourceGroup="$EXISTING_KEYVAULT_RG" \
            deployNewMonitoring="$DEPLOY_NEW_MONITORING" \
        --output json)
    
    if [ $? -eq 0 ]; then
        print_success "Infrastructure deployment completed successfully!"
        
        # Extract outputs
        print_step "Extracting deployment outputs..."
        
        ai_foundry_project=$(echo "$deployment_output" | jq -r '.properties.outputs.aiFoundryProjectName.value')
        openai_endpoint=$(echo "$deployment_output" | jq -r '.properties.outputs.openAiEndpoint.value')
        search_endpoint=$(echo "$deployment_output" | jq -r '.properties.outputs.searchEndpoint.value')
        storage_account=$(echo "$deployment_output" | jq -r '.properties.outputs.storageAccountName.value')
        key_vault=$(echo "$deployment_output" | jq -r '.properties.outputs.keyVaultName.value')
        container_app_url=$(echo "$deployment_output" | jq -r '.properties.outputs.containerAppUrl.value')
        
        print_success "Deployment completed! Here are your configured resources:"
        echo
        print_info "🚀 Azure AI Foundry Project: $ai_foundry_project (existing)"
        print_info "🧠 Azure OpenAI Endpoint: $openai_endpoint (existing)"
        print_info "🔍 Azure AI Search Endpoint: $search_endpoint (existing)"
        print_info "💾 Storage Account: $storage_account (existing)"
        print_info "🔐 Key Vault: $key_vault"
        print_info "🌐 Container App URL: $container_app_url (new)"
        echo
        
        # Save outputs to file
        outputs_file="deployment-outputs-existing-$(date +%Y%m%d-%H%M%S).json"
        echo "$deployment_output" | jq '.properties.outputs' > "$outputs_file"
        print_info "Deployment outputs saved to: $outputs_file"
        
    else
        print_error "Infrastructure deployment failed!"
        exit 1
    fi
}

create_env_file() {
    print_step "Creating .env file with deployment outputs..."
    
    if [ -f "$deployment_output" ]; then
        env_vars=$(echo "$deployment_output" | jq -r '.properties.outputs.environmentVariables.value | to_entries[] | "\(.key)=\(.value)"')
        
        cat > ".env.existing" << EOF
# Azure GenAIOps Environment Configuration (Existing Resources)
# Generated on $(date)

$env_vars

# Additional configuration
ENVIRONMENT=$ENVIRONMENT
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP

# Existing Resources
EXISTING_AI_FOUNDRY=$EXISTING_AI_FOUNDRY
EXISTING_OPENAI=$EXISTING_OPENAI
EXISTING_SEARCH=$EXISTING_SEARCH
EXISTING_STORAGE=$EXISTING_STORAGE
EXISTING_KEYVAULT=$EXISTING_KEYVAULT

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000
API_VERSION=v1

# Security
ENABLE_AUTHENTICATION=true
ENABLE_RATE_LIMITING=true
ENABLE_CORS=true

# Features
ENABLE_RAG=true
ENABLE_AGENTS=true
ENABLE_MONITORING=true
ENABLE_SAFETY=true

EOF
        
        print_success ".env.existing file created with deployment configuration."
        print_info "Copy this file to .env to use these settings."
    fi
}

main() {
    print_header
    
    check_prerequisites
    get_user_input
    verify_existing_resources
    create_resource_group
    validate_template
    deploy_infrastructure
    create_env_file
    
    echo
    print_success "🎉 Azure GenAIOps platform deployed successfully with existing resources!"
    print_info "Next steps:"
    print_info "1. Copy .env.existing to .env"
    print_info "2. Update your application configuration as needed"
    print_info "3. Deploy your application code to the container app"
    print_info "4. Configure existing resources if needed (storage containers, search indexes)"
    print_info "5. Set up monitoring and alerting"
    echo
    print_info "Container App URL: $container_app_url"
    print_info "Documentation: https://github.com/korkridake/AzureGenAIOps"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -g|--resource-group)
            RESOURCE_GROUP="$2"
            shift 2
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -p|--project-name)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -u|--user-object-id)
            USER_OBJECT_ID="$2"
            shift 2
            ;;
        --ai-foundry)
            EXISTING_AI_FOUNDRY="$2"
            shift 2
            ;;
        --openai)
            EXISTING_OPENAI="$2"
            shift 2
            ;;
        --search)
            EXISTING_SEARCH="$2"
            shift 2
            ;;
        --storage)
            EXISTING_STORAGE="$2"
            shift 2
            ;;
        --keyvault)
            EXISTING_KEYVAULT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -g, --resource-group      Resource group name for new resources"
            echo "  -l, --location           Azure region (default: East US)"
            echo "  -p, --project-name       Project name (default: genaiops)"
            echo "  -e, --environment        Environment (dev/staging/prod, default: dev)"
            echo "  -u, --user-object-id     Azure AD user object ID"
            echo "  --ai-foundry             Existing AI Foundry project name"
            echo "  --openai                 Existing OpenAI service name"
            echo "  --search                 Existing Search service name"
            echo "  --storage                Existing Storage account name"
            echo "  --keyvault               Existing Key Vault name (optional)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main function
main