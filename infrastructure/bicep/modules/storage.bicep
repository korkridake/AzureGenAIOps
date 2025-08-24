@description('Azure Storage account deployment module')
param accountName string
param location string
param tags object

@description('Storage account SKU')
@allowed(['Standard_LRS', 'Standard_GRS', 'Standard_RAGRS', 'Standard_ZRS', 'Premium_LRS'])
param sku string = 'Standard_LRS'

@description('Storage account access tier')
@allowed(['Hot', 'Cool'])
param accessTier string = 'Hot'

// Create storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: accountName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    accessTier: accessTier
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowCrossTenantReplication: false
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
    }
  }
}

// Blob service configuration
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: [
        {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'HEAD', 'POST', 'PUT', 'DELETE']
          allowedHeaders: ['*']
          exposedHeaders: ['*']
          maxAgeInSeconds: 86400
        }
      ]
    }
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    versioning: {
      enabled: false
    }
    changeFeed: {
      enabled: false
    }
    restorePolicy: {
      enabled: false
    }
  }
}

// Container for documents (RAG data)
resource documentsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'documents'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'RAG document storage'
      project: 'AzureGenAIOps'
    }
  }
}

// Container for model artifacts
resource modelsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'models'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Model artifacts and checkpoints'
      project: 'AzureGenAIOps'
    }
  }
}

// Container for training data
resource trainingDataContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'training-data'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Training datasets and synthetic data'
      project: 'AzureGenAIOps'
    }
  }
}

// Container for evaluation results
resource evaluationContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'evaluation'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Model evaluation results and reports'
      project: 'AzureGenAIOps'
    }
  }
}

// Container for application logs and data
resource logsContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'logs'
  properties: {
    publicAccess: 'None'
    metadata: {
      purpose: 'Application logs and telemetry data'
      project: 'AzureGenAIOps'
    }
  }
}

// File service configuration
resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Queue service configuration
resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

// Queue for async processing
resource processingQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  parent: queueService
  name: 'processing-queue'
  properties: {
    metadata: {
      purpose: 'Async LLM processing tasks'
      project: 'AzureGenAIOps'
    }
  }
}

// Queue for evaluation tasks
resource evaluationQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-05-01' = {
  parent: queueService
  name: 'evaluation-queue'
  properties: {
    metadata: {
      purpose: 'Model evaluation and testing tasks'
      project: 'AzureGenAIOps'
    }
  }
}

// Table service configuration
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-05-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    cors: {
      corsRules: []
    }
  }
}

// Table for metrics and monitoring data
resource metricsTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'metrics'
}

// Table for user sessions and feedback
resource sessionsTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  parent: tableService
  name: 'sessions'
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: storageAccount
  name: 'default'
  properties: {
    metrics: [
      {
        category: 'Transaction'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Capacity'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output accountName string = storageAccount.name
output accountId string = storageAccount.id
output primaryEndpoints object = storageAccount.properties.primaryEndpoints
output connectionString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
output containerNames array = [
  documentsContainer.name
  modelsContainer.name
  trainingDataContainer.name
  evaluationContainer.name
  logsContainer.name
]