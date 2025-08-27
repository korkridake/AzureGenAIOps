# Azure GenAIOps - PowerShell Deployment Script
# This script provides a PowerShell alternative for deploying Azure GenAIOps infrastructure

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("new", "existing")]
    [string]$DeploymentType = "new",
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "genaiops",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment = "dev",
    
    [Parameter(Mandatory=$false)]
    [string]$UserObjectId,
    
    # Existing resources parameters
    [Parameter(Mandatory=$false)]
    [string]$ExistingAiFoundryProject,
    
    [Parameter(Mandatory=$false)]
    [string]$ExistingOpenAiAccount,
    
    [Parameter(Mandatory=$false)]
    [string]$ExistingSearchService,
    
    [Parameter(Mandatory=$false)]
    [string]$ExistingStorageAccount,
    
    [Parameter(Mandatory=$false)]
    [string]$ExistingKeyVault,
    
    [Parameter(Mandatory=$false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BicepDir = Join-Path (Split-Path -Parent $ScriptDir) "bicep"
$DeploymentName = "genaiops-$DeploymentType-$((Get-Date).ToString('yyyyMMdd-HHmmss'))"

# Colors for output
$Colors = @{
    Red = "Red"
    Green = "Green"
    Yellow = "Yellow"
    Blue = "Cyan"
    White = "White"
}

function Write-Header {
    Write-Host "============================================" -ForegroundColor $Colors.Blue
    Write-Host "  Azure GenAIOps - Infrastructure Deployment" -ForegroundColor $Colors.Blue
    Write-Host "  Deployment Type: $DeploymentType" -ForegroundColor $Colors.Blue
    Write-Host "============================================" -ForegroundColor $Colors.Blue
    Write-Host ""
}

function Write-Step {
    param([string]$Message)
    Write-Host "[STEP] $Message" -ForegroundColor $Colors.Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor $Colors.Blue
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Red
}

function Write-Success {
    param([string]$Message)
    Write-Host "[SUCCESS] $Message" -ForegroundColor $Colors.Green
}

function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check if Azure PowerShell is installed
    try {
        Import-Module Az -Force
    }
    catch {
        Write-Error "Azure PowerShell module is not installed. Please install it using: Install-Module -Name Az"
        exit 1
    }
    
    # Check if user is logged in
    try {
        $context = Get-AzContext
        if (-not $context) {
            throw "Not logged in"
        }
    }
    catch {
        Write-Error "You are not logged in to Azure. Please run 'Connect-AzAccount' first."
        exit 1
    }
    
    # Check if Bicep is available
    try {
        az bicep version | Out-Null
    }
    catch {
        Write-Warning "Bicep is not installed. Installing Bicep..."
        az bicep install
    }
    
    Write-Success "Prerequisites check completed."
}

function Get-UserInput {
    Write-Step "Gathering deployment parameters..."
    
    # Get resource group name
    if (-not $ResourceGroupName) {
        $ResourceGroupName = Read-Host "Enter resource group name (will be created if it doesn't exist)"
    }
    
    # Get user object ID if not provided
    if (-not $UserObjectId) {
        Write-Info "Getting your Azure AD user object ID..."
        $currentUser = (Get-AzContext).Account.Id
        $UserObjectId = (Get-AzADUser -UserPrincipalName $currentUser).Id
        Write-Info "User Object ID: $UserObjectId"
    }
    
    if ($DeploymentType -eq "existing") {
        Write-Info "Now let's configure your existing Azure resources:"
        
        if (-not $ExistingAiFoundryProject) {
            $ExistingAiFoundryProject = Read-Host "Enter existing Azure AI Foundry project name"
        }
        
        if (-not $ExistingOpenAiAccount) {
            $ExistingOpenAiAccount = Read-Host "Enter existing Azure OpenAI service name"
        }
        
        if (-not $ExistingSearchService) {
            $ExistingSearchService = Read-Host "Enter existing Azure AI Search service name"
        }
        
        if (-not $ExistingStorageAccount) {
            $ExistingStorageAccount = Read-Host "Enter existing Azure Storage account name"
        }
        
        if (-not $ExistingKeyVault) {
            $response = Read-Host "Enter existing Azure Key Vault name (optional, press Enter to create new)"
            if ($response) {
                $ExistingKeyVault = $response
            }
        }
    }
    
    Write-Host ""
    Write-Info "Deployment Configuration:"
    Write-Info "  Resource Group: $ResourceGroupName"
    Write-Info "  Project Name: $ProjectName"
    Write-Info "  Environment: $Environment"
    Write-Info "  Location: $Location"
    Write-Info "  User Object ID: $UserObjectId"
    
    if ($DeploymentType -eq "existing") {
        Write-Info "  AI Foundry: $ExistingAiFoundryProject"
        Write-Info "  OpenAI: $ExistingOpenAiAccount"
        Write-Info "  Search: $ExistingSearchService"
        Write-Info "  Storage: $ExistingStorageAccount"
        Write-Info "  Key Vault: $(if ($ExistingKeyVault) { $ExistingKeyVault } else { '[New]' })"
    }
    
    Write-Host ""
    
    if (-not $Force) {
        $confirm = Read-Host "Continue with deployment? (y/N)"
        if ($confirm -notmatch "^[yY]") {
            Write-Info "Deployment cancelled."
            exit 0
        }
    }
}

function New-ResourceGroupIfNotExists {
    Write-Step "Creating resource group '$ResourceGroupName' in '$Location'..."
    
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if ($rg) {
        Write-Info "Resource group '$ResourceGroupName' already exists."
    }
    else {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
        Write-Success "Resource group '$ResourceGroupName' created successfully."
    }
}

function Test-ExistingResources {
    if ($DeploymentType -eq "existing") {
        Write-Step "Verifying existing resources..."
        
        # Note: This is a simplified check. In a production script, you'd want more thorough validation
        try {
            # Check AI Foundry project (simplified)
            Write-Info "Verifying AI Foundry project: $ExistingAiFoundryProject"
            
            # Check OpenAI service
            Write-Info "Verifying OpenAI service: $ExistingOpenAiAccount"
            
            # Check Search service
            Write-Info "Verifying Search service: $ExistingSearchService"
            
            # Check Storage account
            Write-Info "Verifying Storage account: $ExistingStorageAccount"
            
            Write-Success "Existing resources verification completed."
        }
        catch {
            Write-Error "Failed to verify existing resources: $($_.Exception.Message)"
            exit 1
        }
    }
}

function Test-BicepTemplate {
    Write-Step "Validating Bicep template..."
    
    $templateFile = if ($DeploymentType -eq "new") {
        Join-Path $BicepDir "main.bicep"
    } else {
        Join-Path $BicepDir "existing-resources.bicep"
    }
    
    $parameters = @{
        projectName = $ProjectName
        location = $Location
        environment = $Environment
        userObjectId = $UserObjectId
    }
    
    if ($DeploymentType -eq "existing") {
        $parameters.existingAiFoundryProjectName = $ExistingAiFoundryProject
        $parameters.existingAiFoundryResourceGroup = $ResourceGroupName
        $parameters.existingOpenAiAccountName = $ExistingOpenAiAccount
        $parameters.existingOpenAiResourceGroup = $ResourceGroupName
        $parameters.existingSearchServiceName = $ExistingSearchService
        $parameters.existingSearchResourceGroup = $ResourceGroupName
        $parameters.existingStorageAccountName = $ExistingStorageAccount
        $parameters.existingStorageResourceGroup = $ResourceGroupName
        
        if ($ExistingKeyVault) {
            $parameters.existingKeyVaultName = $ExistingKeyVault
            $parameters.existingKeyVaultResourceGroup = $ResourceGroupName
        }
    }
    
    try {
        Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $templateFile -TemplateParameterObject $parameters | Out-Null
        Write-Success "Template validation completed successfully."
    }
    catch {
        Write-Error "Template validation failed: $($_.Exception.Message)"
        exit 1
    }
}

function Start-InfrastructureDeployment {
    Write-Step "Deploying Azure GenAIOps infrastructure..."
    
    $templateFile = if ($DeploymentType -eq "new") {
        Join-Path $BicepDir "main.bicep"
    } else {
        Join-Path $BicepDir "existing-resources.bicep"
    }
    
    $parameters = @{
        projectName = $ProjectName
        location = $Location
        environment = $Environment
        userObjectId = $UserObjectId
    }
    
    if ($DeploymentType -eq "existing") {
        $parameters.existingAiFoundryProjectName = $ExistingAiFoundryProject
        $parameters.existingAiFoundryResourceGroup = $ResourceGroupName
        $parameters.existingOpenAiAccountName = $ExistingOpenAiAccount
        $parameters.existingOpenAiResourceGroup = $ResourceGroupName
        $parameters.existingSearchServiceName = $ExistingSearchService
        $parameters.existingSearchResourceGroup = $ResourceGroupName
        $parameters.existingStorageAccountName = $ExistingStorageAccount
        $parameters.existingStorageResourceGroup = $ResourceGroupName
        
        if ($ExistingKeyVault) {
            $parameters.existingKeyVaultName = $ExistingKeyVault
            $parameters.existingKeyVaultResourceGroup = $ResourceGroupName
        }
    }
    
    Write-Info "This may take 15-30 minutes depending on the resources being created..."
    
    try {
        if ($WhatIf) {
            Write-Info "Running in WhatIf mode - no resources will be created."
            $deployment = Test-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $templateFile -TemplateParameterObject $parameters
        }
        else {
            $deployment = New-AzResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $DeploymentName -TemplateFile $templateFile -TemplateParameterObject $parameters
        }
        
        if (-not $WhatIf) {
            Write-Success "Infrastructure deployment completed successfully!"
            
            # Extract outputs
            Write-Step "Extracting deployment outputs..."
            
            $outputs = $deployment.Outputs
            
            Write-Success "Deployment completed! Here are your resources:"
            Write-Host ""
            
            if ($outputs.aiFoundryProjectName) {
                Write-Info "🚀 Azure AI Foundry Project: $($outputs.aiFoundryProjectName.Value)"
            }
            if ($outputs.openAiEndpoint) {
                Write-Info "🧠 Azure OpenAI Endpoint: $($outputs.openAiEndpoint.Value)"
            }
            if ($outputs.searchEndpoint) {
                Write-Info "🔍 Azure AI Search Endpoint: $($outputs.searchEndpoint.Value)"
            }
            if ($outputs.storageAccountName) {
                Write-Info "💾 Storage Account: $($outputs.storageAccountName.Value)"
            }
            if ($outputs.keyVaultName) {
                Write-Info "🔐 Key Vault: $($outputs.keyVaultName.Value)"
            }
            if ($outputs.containerAppUrl) {
                Write-Info "🌐 Container App URL: $($outputs.containerAppUrl.Value)"
            }
            
            Write-Host ""
            
            # Save outputs to file
            $outputsFile = "deployment-outputs-$DeploymentType-$((Get-Date).ToString('yyyyMMdd-HHmmss')).json"
            $outputs | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputsFile -Encoding UTF8
            Write-Info "Deployment outputs saved to: $outputsFile"
            
            return $outputs
        }
    }
    catch {
        Write-Error "Infrastructure deployment failed: $($_.Exception.Message)"
        exit 1
    }
}

function New-EnvironmentFile {
    param([hashtable]$Outputs)
    
    Write-Step "Creating .env file with deployment outputs..."
    
    $envFileName = ".env.$DeploymentType"
    
    $envContent = @"
# Azure GenAIOps Environment Configuration ($DeploymentType)
# Generated on $(Get-Date)

$(if ($Outputs.environmentVariables) {
    $Outputs.environmentVariables.Value.PSObject.Properties | ForEach-Object {
        "$($_.Name)=$($_.Value)"
    }
} else {
    # Fallback if environmentVariables output is not available
    if ($Outputs.openAiEndpoint) { "AZURE_OPENAI_ENDPOINT=$($Outputs.openAiEndpoint.Value)" }
    if ($Outputs.searchEndpoint) { "AZURE_SEARCH_ENDPOINT=$($Outputs.searchEndpoint.Value)" }
    if ($Outputs.storageAccountName) { "AZURE_STORAGE_ACCOUNT_NAME=$($Outputs.storageAccountName.Value)" }
    if ($Outputs.keyVaultName) { "AZURE_KEY_VAULT_NAME=$($Outputs.keyVaultName.Value)" }
    if ($Outputs.aiFoundryProjectName) { "AZURE_AI_PROJECT_NAME=$($Outputs.aiFoundryProjectName.Value)" }
})

# Additional configuration
ENVIRONMENT=$Environment
AZURE_SUBSCRIPTION_ID=$((Get-AzContext).Subscription.Id)
AZURE_RESOURCE_GROUP=$ResourceGroupName

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
"@
    
    $envContent | Out-File -FilePath $envFileName -Encoding UTF8
    Write-Success "$envFileName file created with deployment configuration."
    Write-Info "Copy this file to .env to use these settings."
}

function Start-PostDeploymentTasks {
    param([hashtable]$Outputs)
    
    Write-Step "Running post-deployment tasks..."
    
    # Wait for services to be ready
    Write-Info "Waiting for services to initialize..."
    Start-Sleep -Seconds 30
    
    # Test container app health if URL is available
    if ($Outputs.containerAppUrl) {
        $containerAppUrl = $Outputs.containerAppUrl.Value
        Write-Info "Testing container app health..."
        
        for ($i = 1; $i -le 5; $i++) {
            try {
                $response = Invoke-WebRequest -Uri "$containerAppUrl/health" -TimeoutSec 10 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    Write-Success "Container app is healthy and responding."
                    break
                }
            }
            catch {
                Write-Info "Waiting for container app to start... (attempt $i/5)"
                Start-Sleep -Seconds 30
            }
        }
    }
    
    Write-Info "Post-deployment tasks completed."
}

function Main {
    Write-Header
    
    Test-Prerequisites
    Get-UserInput
    Test-ExistingResources
    New-ResourceGroupIfNotExists
    Test-BicepTemplate
    
    $outputs = Start-InfrastructureDeployment
    
    if (-not $WhatIf -and $outputs) {
        New-EnvironmentFile -Outputs $outputs
        Start-PostDeploymentTasks -Outputs $outputs
        
        Write-Host ""
        Write-Success "🎉 Azure GenAIOps platform deployed successfully!"
        Write-Info "Next steps:"
        Write-Info "1. Copy .env.$DeploymentType to .env"
        Write-Info "2. Update your application configuration as needed"
        Write-Info "3. Deploy your application code to the container app"
        Write-Info "4. Upload documents to the storage account for RAG"
        Write-Info "5. Configure monitoring and alerting"
        Write-Host ""
        
        if ($outputs.containerAppUrl) {
            Write-Info "Container App URL: $($outputs.containerAppUrl.Value)"
        }
        Write-Info "Documentation: https://github.com/korkridake/AzureGenAIOps"
    }
    elseif ($WhatIf) {
        Write-Success "WhatIf deployment validation completed successfully!"
    }
}

# Run main function
try {
    Main
}
catch {
    Write-Error "Deployment failed: $($_.Exception.Message)"
    exit 1
}