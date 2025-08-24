@description('Azure OpenAI service deployment module')
param accountName string
param location string
param tags object
param aiFoundryProjectId string

@description('SKU for the OpenAI service')
@allowed(['S0'])
param sku string = 'S0'

@description('Model deployments to create')
param modelDeployments array = [
  {
    name: 'gpt-4'
    model: {
      format: 'OpenAI'
      name: 'gpt-4'
      version: '1106-Preview'
    }
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
  {
    name: 'gpt-35-turbo'
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '1106'
    }
    sku: {
      name: 'Standard'
      capacity: 30
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-ada-002'
      version: '2'
    }
    sku: {
      name: 'Standard'
      capacity: 30
    }
  }
  {
    name: 'text-embedding-3-large'
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-large'
      version: '1'
    }
    sku: {
      name: 'Standard'
      capacity: 30
    }
  }
]

// Create Azure OpenAI service
resource openAiAccount 'Microsoft.CognitiveServices/accounts@2024-06-01-preview' = {
  name: accountName
  location: location
  tags: tags
  kind: 'OpenAI'
  sku: {
    name: sku
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: accountName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
    }
    restrictOutboundNetworkAccess: false
    allowedFqdnList: []
    disableLocalAuth: false
  }
}

// Deploy models
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2024-06-01-preview' = [for deployment in modelDeployments: {
  parent: openAiAccount
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: deployment.sku
}]

// Content filter policies for safety
resource contentFilter 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-06-01-preview' = {
  parent: openAiAccount
  name: 'genaiops-content-filter'
  properties: {
    mode: 'Default'
    contentFilters: [
      {
        name: 'hate'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Prompt'
      }
      {
        name: 'hate'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Completion'
      }
      {
        name: 'sexual'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Prompt'
      }
      {
        name: 'sexual'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Completion'
      }
      {
        name: 'violence'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Prompt'
      }
      {
        name: 'violence'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Completion'
      }
      {
        name: 'selfharm'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Prompt'
      }
      {
        name: 'selfharm'
        blocking: true
        enabled: true
        severityThreshold: 'medium'
        source: 'Completion'
      }
    ]
  }
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: openAiAccount
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
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'RequestResponse'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Trace'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output accountName string = openAiAccount.name
output endpoint string = openAiAccount.properties.endpoint
output apiKey string = openAiAccount.listKeys().key1
output accountId string = openAiAccount.id
output deploymentNames array = [for deployment in modelDeployments: deployment.name]