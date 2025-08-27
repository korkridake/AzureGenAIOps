@description('Azure AI Foundry project deployment module')
param projectName string
param location string
param tags object
param userObjectId string

@description('SKU for the AI Foundry project')
@allowed(['Basic', 'Standard'])
param sku string = 'Standard'

// Create Azure AI Foundry project (Machine Learning workspace with AI capabilities)
resource aiFoundryProject 'Microsoft.MachineLearningServices/workspaces@2024-04-01' = {
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    friendlyName: projectName
    description: 'Azure AI Foundry project for GenAIOps platform'
    keyVault: keyVault.id
    storageAccount: storageAccount.id
    applicationInsights: applicationInsights.id
    containerRegistry: containerRegistry.id
    workspaceHubConfig: {
      additionalWorkspaceStorageAccounts: []
    }
    publicNetworkAccess: 'Enabled'
    allowPublicAccessWhenBehindVnet: false
    v1LegacyMode: false
  }
  kind: 'Project'
  
  // Wait for supporting resources
  dependsOn: [
    keyVault
    storageAccount
    applicationInsights
    containerRegistry
  ]
}

// Supporting resources for AI Foundry project
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'kv-${replace(projectName, '-', '')}'
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: userObjectId
        permissions: {
          keys: ['all']
          secrets: ['all']
          certificates: ['all']
        }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enableRbacAuthorization: false
    publicNetworkAccess: 'Enabled'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: 'st${replace(projectName, '-', '')}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: 'ai-${projectName}'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: 'log-${projectName}'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: 'acr${replace(projectName, '-', '')}'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// Role assignments for AI Foundry project
resource aiFoundryContributorRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiFoundryProject
  name: guid(aiFoundryProject.id, userObjectId, 'AzureML Data Scientist')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f6c7c914-8db3-469d-8ca1-694a8f32e121') // AzureML Data Scientist
    principalId: userObjectId
    principalType: 'User'
  }
}

// Grant AI Foundry project access to Key Vault
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVault
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: aiFoundryProject.identity.principalId
        permissions: {
          keys: ['get', 'list']
          secrets: ['get', 'list']
          certificates: ['get', 'list']
        }
      }
    ]
  }
}

output projectName string = aiFoundryProject.name
output projectId string = aiFoundryProject.id
output keyVaultName string = keyVault.name
output storageAccountName string = storageAccount.name
output applicationInsightsName string = applicationInsights.name