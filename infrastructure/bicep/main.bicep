@description('Main template for deploying Azure GenAIOps platform with new resources')
@minLength(2)
@maxLength(12)
param projectName string = 'genaiops'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Environment name (dev, staging, prod)')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Your Azure AD user object ID for role assignments')
param userObjectId string

@description('Tags to apply to all resources')
param tags object = {
  project: 'AzureGenAIOps'
  environment: environment
  managedBy: 'bicep'
}

// Generate unique suffix for resource names
var suffix = uniqueString(resourceGroup().id)
var uniqueName = '${projectName}${environment}${suffix}'

// Resource names
var aiFoundryProjectName = 'aif-${uniqueName}'
var openAiAccountName = 'openai-${uniqueName}'
var searchServiceName = 'srch-${uniqueName}'
var storageAccountName = 'st${replace(uniqueName, '-', '')}'
var containerAppsEnvironmentName = 'cae-${uniqueName}'
var containerAppName = 'ca-${uniqueName}'
var logAnalyticsWorkspaceName = 'log-${uniqueName}'
var applicationInsightsName = 'ai-${uniqueName}'
var keyVaultName = 'kv-${uniqueName}'

// Deploy Azure AI Foundry project
module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'aiFoundryDeployment'
  params: {
    projectName: aiFoundryProjectName
    location: location
    tags: tags
    userObjectId: userObjectId
  }
}

// Deploy Azure OpenAI service
module openAi 'modules/openai.bicep' = {
  name: 'openAiDeployment'
  params: {
    accountName: openAiAccountName
    location: location
    tags: tags
    aiFoundryProjectId: aiFoundry.outputs.projectId
  }
}

// Deploy Azure AI Search
module search 'modules/search.bicep' = {
  name: 'searchDeployment'
  params: {
    serviceName: searchServiceName
    location: location
    tags: tags
  }
}

// Deploy Azure Storage
module storage 'modules/storage.bicep' = {
  name: 'storageDeployment'
  params: {
    accountName: storageAccountName
    location: location
    tags: tags
  }
}

// Deploy monitoring infrastructure
module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoringDeployment'
  params: {
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
    location: location
    tags: tags
  }
}

// Deploy Key Vault
module keyVault 'modules/key-vault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    keyVaultName: keyVaultName
    location: location
    tags: tags
    userObjectId: userObjectId
    openAiEndpoint: openAi.outputs.endpoint
    openAiApiKey: openAi.outputs.apiKey
    searchEndpoint: search.outputs.endpoint
    searchApiKey: search.outputs.primaryKey
    storageConnectionString: storage.outputs.connectionString
  }
}

// Deploy Container Apps environment and application
module containerApps 'modules/container-apps.bicep' = {
  name: 'containerAppsDeployment'
  params: {
    environmentName: containerAppsEnvironmentName
    containerAppName: containerAppName
    location: location
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
    keyVaultName: keyVault.outputs.keyVaultName
    openAiEndpoint: openAi.outputs.endpoint
    searchEndpoint: search.outputs.endpoint
  }
}

// Outputs for reference
output resourceGroupName string = resourceGroup().name
output aiFoundryProjectName string = aiFoundry.outputs.projectName
output aiFoundryProjectId string = aiFoundry.outputs.projectId
output openAiEndpoint string = openAi.outputs.endpoint
output searchEndpoint string = search.outputs.endpoint
output storageAccountName string = storage.outputs.accountName
output keyVaultName string = keyVault.outputs.keyVaultName
output containerAppUrl string = containerApps.outputs.applicationUrl
output applicationInsightsConnectionString string = monitoring.outputs.applicationInsightsConnectionString

// Configuration outputs for application
output environmentVariables object = {
  AZURE_AI_PROJECT_NAME: aiFoundry.outputs.projectName
  AZURE_OPENAI_ENDPOINT: openAi.outputs.endpoint
  AZURE_SEARCH_ENDPOINT: search.outputs.endpoint
  AZURE_STORAGE_ACCOUNT_NAME: storage.outputs.accountName
  AZURE_KEY_VAULT_NAME: keyVault.outputs.keyVaultName
  APPLICATIONINSIGHTS_CONNECTION_STRING: monitoring.outputs.applicationInsightsConnectionString
}