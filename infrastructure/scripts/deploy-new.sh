#!/bin/bash

# Azure GenAIOps - Deploy New Infrastructure
# This script deploys a complete new GenAIOps infrastructure using Bicep templates

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BICEP_DIR="$(dirname "$SCRIPT_DIR")/bicep"
DEPLOYMENT_NAME="genaiops-new-$(date +%Y%m%d-%H%M%S)"
LOCATION="East US"
RESOURCE_GROUP=""
PROJECT_NAME="genaiops"
ENVIRONMENT="dev"
USER_OBJECT_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  Azure GenAIOps - New Infrastructure Deployment${NC}"
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
    
    # Get resource group name
    if [ -z "$RESOURCE_GROUP" ]; then
        read -p "Enter resource group name (will be created if it doesn't exist): " RESOURCE_GROUP
    fi
    
    # Get project name
    read -p "Enter project name (default: $PROJECT_NAME): " input_project_name
    PROJECT_NAME=${input_project_name:-$PROJECT_NAME}
    
    # Get environment
    read -p "Enter environment (dev/staging/prod, default: $ENVIRONMENT): " input_environment
    ENVIRONMENT=${input_environment:-$ENVIRONMENT}
    
    # Get location
    read -p "Enter location (default: $LOCATION): " input_location
    LOCATION=${input_location:-$LOCATION}
    
    # Get user object ID if not provided
    if [ -z "$USER_OBJECT_ID" ]; then
        print_info "Getting your Azure AD user object ID..."
        USER_SIGNED_IN=$(az account show --query user.name -o tsv)
        USER_OBJECT_ID=$(az ad user show --id "$USER_SIGNED_IN" --query id -o tsv)
        print_info "User Object ID: $USER_OBJECT_ID"
    fi
    
    echo
    print_info "Deployment Configuration:"
    print_info "  Resource Group: $RESOURCE_GROUP"
    print_info "  Project Name: $PROJECT_NAME"
    print_info "  Environment: $ENVIRONMENT"
    print_info "  Location: $LOCATION"
    print_info "  User Object ID: $USER_OBJECT_ID"
    echo
    
    read -p "Continue with deployment? (y/N): " confirm
    if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
        print_info "Deployment cancelled."
        exit 0
    fi
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
        --template-file "$BICEP_DIR/main.bicep" \
        --parameters \
            projectName="$PROJECT_NAME" \
            location="$LOCATION" \
            environment="$ENVIRONMENT" \
            userObjectId="$USER_OBJECT_ID"
    
    print_success "Template validation completed successfully."
}

deploy_infrastructure() {
    print_step "Deploying Azure GenAIOps infrastructure..."
    print_info "This may take 15-30 minutes depending on the resources being created..."
    
    # Start deployment
    deployment_output=$(az deployment group create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$DEPLOYMENT_NAME" \
        --template-file "$BICEP_DIR/main.bicep" \
        --parameters \
            projectName="$PROJECT_NAME" \
            location="$LOCATION" \
            environment="$ENVIRONMENT" \
            userObjectId="$USER_OBJECT_ID" \
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
        
        print_success "Deployment completed! Here are your resources:"
        echo
        print_info "🚀 Azure AI Foundry Project: $ai_foundry_project"
        print_info "🧠 Azure OpenAI Endpoint: $openai_endpoint"
        print_info "🔍 Azure AI Search Endpoint: $search_endpoint"
        print_info "💾 Storage Account: $storage_account"
        print_info "🔐 Key Vault: $key_vault"
        print_info "🌐 Container App URL: $container_app_url"
        echo
        
        # Save outputs to file
        outputs_file="deployment-outputs-$(date +%Y%m%d-%H%M%S).json"
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
        
        cat > ".env.deployed" << EOF
# Azure GenAIOps Environment Configuration
# Generated on $(date)

$env_vars

# Additional configuration
ENVIRONMENT=$ENVIRONMENT
AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
AZURE_RESOURCE_GROUP=$RESOURCE_GROUP

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
        
        print_success ".env.deployed file created with deployment configuration."
        print_info "Copy this file to .env to use these settings."
    fi
}

post_deployment_tasks() {
    print_step "Running post-deployment tasks..."
    
    # Wait for services to be ready
    print_info "Waiting for services to initialize..."
    sleep 30
    
    # Test container app health
    if [ ! -z "$container_app_url" ]; then
        print_info "Testing container app health..."
        for i in {1..5}; do
            if curl -f "$container_app_url/health" &> /dev/null; then
                print_success "Container app is healthy and responding."
                break
            else
                print_info "Waiting for container app to start... (attempt $i/5)"
                sleep 30
            fi
        done
    fi
    
    print_info "Post-deployment tasks completed."
}

main() {
    print_header
    
    check_prerequisites
    get_user_input
    create_resource_group
    validate_template
    deploy_infrastructure
    create_env_file
    post_deployment_tasks
    
    echo
    print_success "🎉 Azure GenAIOps platform deployed successfully!"
    print_info "Next steps:"
    print_info "1. Copy .env.deployed to .env"
    print_info "2. Update your application configuration as needed"
    print_info "3. Deploy your application code to the container app"
    print_info "4. Upload documents to the storage account for RAG"
    print_info "5. Configure monitoring and alerting"
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
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -g, --resource-group      Resource group name"
            echo "  -l, --location           Azure region (default: East US)"
            echo "  -p, --project-name       Project name (default: genaiops)"
            echo "  -e, --environment        Environment (dev/staging/prod, default: dev)"
            echo "  -u, --user-object-id     Azure AD user object ID"
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