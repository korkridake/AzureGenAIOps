@description('Azure AI Search service deployment module')
param serviceName string
param location string
param tags object

@description('SKU for the search service')
@allowed(['free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2'])
param sku string = 'standard'

@description('Number of search units (replicas * partitions)')
param searchUnits int = 1

@description('Number of replicas')
param replicaCount int = 1

@description('Number of partitions')
param partitionCount int = 1

// Create Azure AI Search service
resource searchService 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: serviceName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    replicaCount: replicaCount
    partitionCount: partitionCount
    hostingMode: 'default'
    publicNetworkAccess: 'enabled'
    networkRuleSet: {
      ipRules: []
      bypass: 'None'
    }
    encryptionWithCmk: {
      enforcement: 'Unspecified'
    }
    disableLocalAuth: false
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    semanticSearch: sku != 'free' ? 'standard' : 'disabled'
  }
}

// Data source for Azure Blob Storage (will be configured later)
resource dataSource 'Microsoft.Search/searchServices/dataConnections@2024-05-01-preview' = {
  parent: searchService
  name: 'genaiops-blob-datasource'
  properties: {
    type: 'azureblob'
    description: 'Data source for GenAIOps document storage'
    connectionString: '@Microsoft.KeyVault(SecretUri=https://placeholder-keyvault.vault.azure.net/secrets/storage-connection-string/)'
    container: {
      name: 'documents'
      query: null
    }
    dataChangeDetectionPolicy: {
      '@odata.type': '#Microsoft.Azure.Search.HighWaterMarkChangeDetectionPolicy'
      highWaterMarkColumnName: '_ts'
    }
    dataDeletionDetectionPolicy: {
      '@odata.type': '#Microsoft.Azure.Search.SoftDeleteColumnDeletionDetectionPolicy'
      softDeleteColumnName: 'isDeleted'
      softDeleteMarkerValue: 'true'
    }
  }
}

// Index for document search with vector capabilities
resource documentIndex 'Microsoft.Search/searchServices/indexes@2024-05-01-preview' = {
  parent: searchService
  name: 'genaiops-documents'
  properties: {
    fields: [
      {
        name: 'id'
        type: 'Edm.String'
        key: true
        searchable: false
        filterable: true
        retrievable: true
        sortable: false
        facetable: false
      }
      {
        name: 'title'
        type: 'Edm.String'
        searchable: true
        filterable: true
        retrievable: true
        sortable: true
        facetable: false
        analyzer: 'standard.lucene'
      }
      {
        name: 'content'
        type: 'Edm.String'
        searchable: true
        filterable: false
        retrievable: true
        sortable: false
        facetable: false
        analyzer: 'standard.lucene'
      }
      {
        name: 'contentVector'
        type: 'Collection(Edm.Single)'
        searchable: true
        filterable: false
        retrievable: false
        sortable: false
        facetable: false
        dimensions: 1536
        vectorSearchProfile: 'default-vector-profile'
      }
      {
        name: 'metadata'
        type: 'Edm.ComplexType'
        fields: [
          {
            name: 'source'
            type: 'Edm.String'
            filterable: true
            retrievable: true
          }
          {
            name: 'created'
            type: 'Edm.DateTimeOffset'
            filterable: true
            retrievable: true
            sortable: true
          }
          {
            name: 'size'
            type: 'Edm.Int64'
            filterable: true
            retrievable: true
            sortable: true
          }
        ]
      }
      {
        name: 'tags'
        type: 'Collection(Edm.String)'
        searchable: true
        filterable: true
        retrievable: true
        facetable: true
      }
    ]
    vectorSearch: {
      algorithms: [
        {
          name: 'default-hnsw'
          kind: 'hnsw'
          hnswParameters: {
            metric: 'cosine'
            m: 4
            efConstruction: 400
            efSearch: 500
          }
        }
      ]
      profiles: [
        {
          name: 'default-vector-profile'
          algorithm: 'default-hnsw'
          vectorizer: 'default-openai-vectorizer'
        }
      ]
      vectorizers: [
        {
          name: 'default-openai-vectorizer'
          kind: 'azureOpenAI'
          azureOpenAIParameters: {
            resourceUri: '@Microsoft.KeyVault(SecretUri=https://placeholder-keyvault.vault.azure.net/secrets/openai-endpoint/)'
            apiKey: '@Microsoft.KeyVault(SecretUri=https://placeholder-keyvault.vault.azure.net/secrets/openai-api-key/)'
            deploymentId: 'text-embedding-ada-002'
            modelName: 'text-embedding-ada-002'
          }
        }
      ]
    }
    semantic: {
      configurations: [
        {
          name: 'default-semantic-config'
          prioritizedFields: {
            titleField: {
              fieldName: 'title'
            }
            prioritizedContentFields: [
              {
                fieldName: 'content'
              }
            ]
            prioritizedKeywordsFields: [
              {
                fieldName: 'tags'
              }
            ]
          }
        }
      ]
    }
  }
}

// Indexer for automated document processing
resource documentIndexer 'Microsoft.Search/searchServices/indexers@2024-05-01-preview' = {
  parent: searchService
  name: 'genaiops-documents-indexer'
  properties: {
    description: 'Indexer for GenAIOps documents with AI enrichment'
    dataSourceName: dataSource.name
    targetIndexName: documentIndex.name
    skillsetName: documentSkillset.name
    schedule: {
      interval: 'PT1H' // Run hourly
    }
    parameters: {
      batchSize: 10
      maxFailedItems: 5
      maxFailedItemsPerBatch: 5
      configuration: {
        dataToExtract: 'contentAndMetadata'
        parsingMode: 'default'
      }
    }
    fieldMappings: [
      {
        sourceFieldName: 'metadata_storage_path'
        targetFieldName: 'id'
        mappingFunction: {
          name: 'base64Encode'
        }
      }
      {
        sourceFieldName: 'metadata_storage_name'
        targetFieldName: 'title'
      }
      {
        sourceFieldName: 'content'
        targetFieldName: 'content'
      }
    ]
    outputFieldMappings: [
      {
        sourceFieldName: '/document/content_vector'
        targetFieldName: 'contentVector'
      }
    ]
  }
  dependsOn: [
    dataSource
    documentIndex
    documentSkillset
  ]
}

// AI skillset for document enrichment
resource documentSkillset 'Microsoft.Search/searchServices/skillsets@2024-05-01-preview' = {
  parent: searchService
  name: 'genaiops-documents-skillset'
  properties: {
    description: 'Skillset for GenAIOps document processing and vectorization'
    skills: [
      {
        '@odata.type': '#Microsoft.Skills.Text.SplitSkill'
        name: 'SplitSkill'
        context: '/document'
        inputs: [
          {
            name: 'text'
            source: '/document/content'
          }
          {
            name: 'languageCode'
            source: '/document/languageCode'
          }
        ]
        outputs: [
          {
            name: 'textItems'
            targetName: 'pages'
          }
        ]
        defaultLanguageCode: 'en'
        textSplitMode: 'pages'
        maximumPageLength: 4000
        pageOverlapLength: 500
      }
      {
        '@odata.type': '#Microsoft.Skills.Text.AzureOpenAIEmbeddingSkill'
        name: 'AzureOpenAIEmbedding'
        context: '/document'
        inputs: [
          {
            name: 'text'
            source: '/document/content'
          }
        ]
        outputs: [
          {
            name: 'embedding'
            targetName: 'content_vector'
          }
        ]
        resourceUri: '@Microsoft.KeyVault(SecretUri=https://placeholder-keyvault.vault.azure.net/secrets/openai-endpoint/)'
        apiKey: '@Microsoft.KeyVault(SecretUri=https://placeholder-keyvault.vault.azure.net/secrets/openai-api-key/)'
        deploymentId: 'text-embedding-ada-002'
        modelName: 'text-embedding-ada-002'
      }
    ]
  }
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: searchService
  name: 'default'
  properties: {
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
    logs: [
      {
        category: 'OperationLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output serviceName string = searchService.name
output endpoint string = 'https://${searchService.name}.search.windows.net'
output primaryKey string = searchService.listAdminKeys().primaryKey
output searchServiceId string = searchService.id
output indexName string = documentIndex.name