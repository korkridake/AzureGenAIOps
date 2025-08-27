@description('Azure Container Apps deployment module')
param environmentName string
param containerAppName string
param location string
param tags object
param logAnalyticsWorkspaceId string
param keyVaultName string
param openAiEndpoint string
param searchEndpoint string

@description('Container image to deploy')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

@description('Container registry server (if using private registry)')
param containerRegistry string = ''

@description('Container registry username')
param containerRegistryUsername string = ''

@description('Container registry password')
@secure()
param containerRegistryPassword string = ''

@description('Number of CPU cores')
param cpuCores string = '1.0'

@description('Memory size')
param memorySize string = '2Gi'

@description('Minimum replicas')
param minReplicas int = 1

@description('Maximum replicas')
param maxReplicas int = 10

// Create Container Apps environment
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: null
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: reference(logAnalyticsWorkspaceId, '2023-09-01').customerId
        sharedKey: listKeys(logAnalyticsWorkspaceId, '2023-09-01').primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

// Managed identity for the container app
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${containerAppName}-identity'
  location: location
  tags: tags
}

// Key Vault access policy for the managed identity
resource keyVaultAccessPolicy 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  name: 'add'
  parent: keyVaultReference
  properties: {
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: userAssignedIdentity.properties.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
  }
}

// Reference to existing Key Vault
resource keyVaultReference 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8000
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      registries: !empty(containerRegistry) ? [
        {
          server: containerRegistry
          username: containerRegistryUsername
          passwordSecretRef: 'registry-password'
        }
      ] : []
      secrets: concat([
        {
          name: 'openai-api-key'
          keyVaultUrl: '${keyVaultReference.properties.vaultUri}secrets/openai-api-key'
          identity: userAssignedIdentity.id
        }
        {
          name: 'search-api-key'
          keyVaultUrl: '${keyVaultReference.properties.vaultUri}secrets/search-api-key'
          identity: userAssignedIdentity.id
        }
        {
          name: 'storage-connection-string'
          keyVaultUrl: '${keyVaultReference.properties.vaultUri}secrets/storage-connection-string'
          identity: userAssignedIdentity.id
        }
        {
          name: 'jwt-signing-key'
          keyVaultUrl: '${keyVaultReference.properties.vaultUri}secrets/jwt-signing-key'
          identity: userAssignedIdentity.id
        }
      ], !empty(containerRegistry) ? [
        {
          name: 'registry-password'
          value: containerRegistryPassword
        }
      ] : [])
    }
    template: {
      containers: [
        {
          name: containerAppName
          image: containerImage
          resources: {
            cpu: json(cpuCores)
            memory: memorySize
          }
          env: [
            {
              name: 'AZURE_OPENAI_ENDPOINT'
              value: openAiEndpoint
            }
            {
              name: 'AZURE_OPENAI_API_KEY'
              secretRef: 'openai-api-key'
            }
            {
              name: 'AZURE_SEARCH_ENDPOINT'
              value: searchEndpoint
            }
            {
              name: 'AZURE_SEARCH_API_KEY'
              secretRef: 'search-api-key'
            }
            {
              name: 'AZURE_STORAGE_CONNECTION_STRING'
              secretRef: 'storage-connection-string'
            }
            {
              name: 'AZURE_KEY_VAULT_NAME'
              value: keyVaultName
            }
            {
              name: 'JWT_SIGNING_KEY'
              secretRef: 'jwt-signing-key'
            }
            {
              name: 'ENVIRONMENT'
              value: 'production'
            }
            {
              name: 'LOG_LEVEL'
              value: 'INFO'
            }
            {
              name: 'ENABLE_MONITORING'
              value: 'true'
            }
            {
              name: 'ENABLE_TELEMETRY'
              value: 'true'
            }
            {
              name: 'API_VERSION'
              value: 'v1'
            }
            {
              name: 'CORS_ORIGINS'
              value: '*'
            }
            {
              name: 'MAX_TOKENS_DEFAULT'
              value: '1000'
            }
            {
              name: 'TEMPERATURE_DEFAULT'
              value: '0.7'
            }
            {
              name: 'CONTENT_FILTER_ENABLED'
              value: 'true'
            }
            {
              name: 'RATE_LIMITING_ENABLED'
              value: 'true'
            }
            {
              name: 'CACHE_TTL_SECONDS'
              value: '3600'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 8000
                scheme: 'HTTP'
              }
              initialDelaySeconds: 30
              periodSeconds: 10
              timeoutSeconds: 5
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health/ready'
                port: 8000
                scheme: 'HTTP'
              }
              initialDelaySeconds: 10
              periodSeconds: 5
              timeoutSeconds: 3
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scale-rule'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
          {
            name: 'cpu-scale-rule'
            custom: {
              type: 'cpu'
              metadata: {
                type: 'Utilization'
                value: '70'
              }
            }
          }
          {
            name: 'memory-scale-rule'
            custom: {
              type: 'memory'
              metadata: {
                type: 'Utilization'
                value: '80'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    keyVaultAccessPolicy
  ]
}

// Diagnostic settings for monitoring
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: containerApp
  name: 'default'
  properties: {
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'ContainerAppSystemLogs'
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

output environmentName string = containerAppsEnvironment.name
output environmentId string = containerAppsEnvironment.id
output applicationName string = containerApp.name
output applicationId string = containerApp.id
output applicationUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output identityPrincipalId string = userAssignedIdentity.properties.principalId
output identityClientId string = userAssignedIdentity.properties.clientId