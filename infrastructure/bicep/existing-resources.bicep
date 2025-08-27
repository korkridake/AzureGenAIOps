@description('Template for deploying Azure GenAIOps platform using existing Azure resources')
@minLength(2)
@maxLength(12)
param projectName string = 'genaiops'

@description('Location for new resources (container apps, monitoring)')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

// Existing Resource Configuration
@description('Name of existing Azure AI Foundry project')
param existingAiFoundryProjectName string

@description('Resource group of existing Azure AI Foundry project')
param existingAiFoundryResourceGroup string = resourceGroup().name

@description('Name of existing Azure OpenAI service')
param existingOpenAiAccountName string

@description('Resource group of existing Azure OpenAI service')
param existingOpenAiResourceGroup string = resourceGroup().name

@description('Name of existing Azure AI Search service')
param existingSearchServiceName string

@description('Resource group of existing Azure AI Search service')
param existingSearchResourceGroup string = resourceGroup().name

@description('Name of existing Azure Storage account')
param existingStorageAccountName string

@description('Resource group of existing Azure Storage account')
param existingStorageResourceGroup string = resourceGroup().name

@description('Name of existing Azure Key Vault (optional - will create new if not provided)')
param existingKeyVaultName string = ''

@description('Resource group of existing Azure Key Vault')
param existingKeyVaultResourceGroup string = resourceGroup().name

@description('Your Azure AD user object ID for role assignments')
param userObjectId string

@description('Whether to deploy new monitoring resources or use existing')
param deployNewMonitoring bool = true

@description('Existing Log Analytics Workspace name (if deployNewMonitoring is false)')
param existingLogAnalyticsWorkspaceName string = ''

@description('Existing Application Insights name (if deployNewMonitoring is false)')
param existingApplicationInsightsName string = ''

@description('Tags to apply to new resources')
param tags object = {
  project: 'AzureGenAIOps'
  environment: environment
  managedBy: 'bicep-existing'
}

// Generate unique suffix for new resource names
var suffix = uniqueString(resourceGroup().id)
var uniqueName = '${projectName}${environment}${suffix}'

// New resource names
var containerAppsEnvironmentName = 'cae-${uniqueName}'
var containerAppName = 'ca-${uniqueName}'
var logAnalyticsWorkspaceName = deployNewMonitoring ? 'log-${uniqueName}' : existingLogAnalyticsWorkspaceName
var applicationInsightsName = deployNewMonitoring ? 'ai-${uniqueName}' : existingApplicationInsightsName
var keyVaultName = empty(existingKeyVaultName) ? 'kv-${uniqueName}' : existingKeyVaultName

// Reference existing Azure AI Foundry project
resource existingAiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' existing = {
  name: existingAiFoundryProjectName
  scope: resourceGroup(existingAiFoundryResourceGroup)
}

// Reference existing Azure OpenAI service
resource existingOpenAiAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' existing = {
  name: existingOpenAiAccountName
  scope: resourceGroup(existingOpenAiResourceGroup)
}

// Reference existing Azure AI Search service
resource existingSearchService 'Microsoft.Search/searchServices@2024-06-01-preview' existing = {
  name: existingSearchServiceName
  scope: resourceGroup(existingSearchResourceGroup)
}

// Reference existing Azure Storage account
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: existingStorageAccountName
  scope: resourceGroup(existingStorageResourceGroup)
}

// Reference existing Key Vault if provided
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = if (!empty(existingKeyVaultName)) {
  name: existingKeyVaultName
  scope: resourceGroup(existingKeyVaultResourceGroup)
}

// Deploy monitoring infrastructure if requested
module monitoring 'modules/monitoring.bicep' = if (deployNewMonitoring) {
  name: 'monitoringDeployment'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    location: location
    tags: tags
  }
}

// Deploy Key Vault if not using existing
module keyVault 'modules/key-vault.bicep' = if (empty(existingKeyVaultName)) {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    userObjectId: userObjectId
    openAiEndpoint: existingOpenAiAccount.properties.endpoint
    openAiApiKey: existingOpenAiAccount.listKeys().key1
    searchEndpoint: 'https://${existingSearchService.name}.search.windows.net'
    searchApiKey: existingSearchService.listAdminKeys().primaryKey
    storageConnectionString: 'DefaultEndpointsProtocol=https;AccountName=${existingStorageAccount.name};AccountKey=${existingStorageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
  }
}

// Get Log Analytics Workspace ID
var logAnalyticsWorkspaceId = deployNewMonitoring ? monitoring.outputs.logAnalyticsWorkspaceId : resourceId(resourceGroup().name, 'Microsoft.OperationalInsights/workspaces', existingLogAnalyticsWorkspaceName)

// Deploy Container Apps environment and application
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerAppsDeployment'
  params: {
    environmentName: containerAppsEnvironmentName
    containerAppName: containerAppName
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalyticsWorkspaceId
    keyVaultName: empty(existingKeyVaultName) ? keyVault.outputs.keyVaultName : existingKeyVaultName
    openAiEndpoint: existingOpenAiAccount.properties.endpoint
    searchEndpoint: 'https://${existingSearchService.name}.search.windows.net'
  }
}

// Outputs for reference
output resourceGroupName string = resourceGroup().name
output aiFoundryProjectName string = existingAiFoundryProject.name
output aiFoundryProjectId string = existingAiFoundryProject.id
output openAiEndpoint string = existingOpenAiAccount.properties.endpoint
output searchEndpoint string = 'https://${existingSearchService.name}.search.windows.net'
output storageAccountName string = existingStorageAccount.name
output keyVaultName string = empty(existingKeyVaultName) ? keyVault.outputs.keyVaultName : existingKeyVaultName
output containerAppUrl string = containerApps.outputs.applicationUrl

// Configuration outputs for application
output environmentVariables object = {
  AZURE_AI_PROJECT_NAME: existingAiFoundryProject.name
  AZURE_OPENAI_ENDPOINT: existingOpenAiAccount.properties.endpoint
  AZURE_SEARCH_ENDPOINT: 'https://${existingSearchService.name}.search.windows.net'
  AZURE_STORAGE_ACCOUNT_NAME: existingStorageAccount.name
  AZURE_KEY_VAULT_NAME: empty(existingKeyVaultName) ? keyVault.outputs.keyVaultName : existingKeyVaultName
  APPLICATIONINSIGHTS_CONNECTION_STRING: deployNewMonitoring ? monitoring.outputs.applicationInsightsConnectionString : ''
}