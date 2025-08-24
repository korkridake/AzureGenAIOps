@description('Azure Key Vault deployment module')
param keyVaultName string
param location string
param tags object
param userObjectId string

@description('Azure OpenAI endpoint to store as secret')
param openAiEndpoint string

@description('Azure OpenAI API key to store as secret')
@secure()
param openAiApiKey string

@description('Azure AI Search endpoint to store as secret')
param searchEndpoint string

@description('Azure AI Search API key to store as secret')
@secure()
param searchApiKey string

@description('Storage connection string to store as secret')
@secure()
param storageConnectionString string

@description('Key Vault SKU')
@allowed(['standard', 'premium'])
param sku string = 'standard'

// Create Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sku
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
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store Azure OpenAI configuration
resource openAiEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-endpoint'
  properties: {
    value: openAiEndpoint
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

resource openAiApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'openai-api-key'
  properties: {
    value: openAiApiKey
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store Azure AI Search configuration
resource searchEndpointSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'search-endpoint'
  properties: {
    value: searchEndpoint
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

resource searchApiKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'search-api-key'
  properties: {
    value: searchApiKey
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Store Storage configuration
resource storageConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storage-connection-string'
  properties: {
    value: storageConnectionString
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Additional configuration secrets
resource appConfigSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'app-config'
  properties: {
    value: loadTextContent('./app-config.json')
    contentType: 'application/json'
    attributes: {
      enabled: true
    }
  }
}

// JWT signing key for API authentication
resource jwtSigningKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'jwt-signing-key'
  properties: {
    value: uniqueString(keyVault.id, 'jwt-key')
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// Database connection string (if using external database)
resource databaseConnectionStringSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-connection-string'
  properties: {
    value: ''
    contentType: 'text/plain'
    attributes: {
      enabled: true
    }
  }
}

// External API keys for third-party services
resource externalApiKeysSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'external-api-keys'
  properties: {
    value: '{}'
    contentType: 'application/json'
    attributes: {
      enabled: true
    }
  }
}

// Model configuration settings
resource modelConfigSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'model-config'
  properties: {
    value: loadTextContent('./model-config.json')
    contentType: 'application/json'
    attributes: {
      enabled: true
    }
  }
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: keyVault
  name: 'default'
  properties: {
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output secretNames array = [
  openAiEndpointSecret.name
  openAiApiKeySecret.name
  searchEndpointSecret.name
  searchApiKeySecret.name
  storageConnectionStringSecret.name
  appConfigSecret.name
  jwtSigningKeySecret.name
  databaseConnectionStringSecret.name
  externalApiKeysSecret.name
  modelConfigSecret.name
]