@description('Azure monitoring infrastructure deployment module')
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param location string
param tags object

@description('Log Analytics workspace SKU')
@allowed(['Free', 'Standalone', 'PerNode', 'PerGB2018'])
param workspaceSku string = 'PerGB2018'

@description('Data retention in days')
param retentionInDays int = 30

// Create Log Analytics workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: workspaceSku
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
      legacy: 0
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Create Application Insights
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'rest'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Custom tables for LLM-specific metrics
resource customTable 'Microsoft.OperationalInsights/workspaces/tables@2022-10-01' = {
  parent: logAnalyticsWorkspace
  name: 'GenAIOpsMetrics_CL'
  properties: {
    totalRetentionInDays: retentionInDays
    plan: 'Analytics'
    schema: {
      name: 'GenAIOpsMetrics_CL'
      columns: [
        {
          name: 'TimeGenerated'
          type: 'datetime'
        }
        {
          name: 'OperationType'
          type: 'string'
        }
        {
          name: 'ModelName'
          type: 'string'
        }
        {
          name: 'TokensUsed'
          type: 'int'
        }
        {
          name: 'ResponseTime'
          type: 'real'
        }
        {
          name: 'StatusCode'
          type: 'int'
        }
        {
          name: 'ErrorMessage'
          type: 'string'
        }
        {
          name: 'UserId'
          type: 'string'
        }
        {
          name: 'SessionId'
          type: 'string'
        }
        {
          name: 'ContentLength'
          type: 'int'
        }
        {
          name: 'SafetyScore'
          type: 'real'
        }
        {
          name: 'RAGDocuments'
          type: 'int'
        }
        {
          name: 'EmbeddingDimensions'
          type: 'int'
        }
      ]
    }
  }
}

// Workbook for GenAIOps monitoring
resource genAIOpsWorkbook 'Microsoft.Insights/workbooks@2023-06-01' = {
  name: guid(resourceGroup().id, 'genaiops-workbook')
  location: location
  tags: tags
  kind: 'shared'
  properties: {
    displayName: 'GenAIOps Platform Monitoring'
    description: 'Comprehensive monitoring dashboard for GenAIOps platform'
    serializedData: loadTextContent('./workbook-template.json')
    version: '1.0'
    sourceId: applicationInsights.id
    category: 'workbook'
  }
}

// Alert rules for critical metrics
resource tokenUsageAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'High Token Usage Alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when token usage exceeds threshold'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'TokenUsage'
          metricName: 'customMetrics/TokensUsed'
          operator: 'GreaterThan'
          threshold: 10000
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

resource errorRateAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'High Error Rate Alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when error rate exceeds 5%'
    severity: 1
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ErrorRate'
          metricName: 'requests/failed'
          operator: 'GreaterThan'
          threshold: 5
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

resource responseTimeAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'High Response Time Alert'
  location: 'global'
  tags: tags
  properties: {
    description: 'Alert when average response time exceeds 10 seconds'
    severity: 2
    enabled: true
    scopes: [
      applicationInsights.id
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT15M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'ResponseTime'
          metricName: 'requests/duration'
          operator: 'GreaterThan'
          threshold: 10000
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: []
  }
}

// Action group for notifications
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'GenAIOps Alerts'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'GenAIOps'
    enabled: true
    emailReceivers: []
    smsReceivers: []
    webhookReceivers: []
    azureAppPushReceivers: []
    itsmReceivers: []
    azureAppPushReceivers: []
    automationRunbookReceivers: []
    voiceReceivers: []
    logicAppReceivers: []
    azureFunctionReceivers: []
    armRoleReceivers: []
    eventHubReceivers: []
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.name
output logAnalyticsCustomerId string = logAnalyticsWorkspace.properties.customerId
output applicationInsightsId string = applicationInsights.id
output applicationInsightsName string = applicationInsights.name
output applicationInsightsConnectionString string = applicationInsights.properties.ConnectionString
output applicationInsightsInstrumentationKey string = applicationInsights.properties.InstrumentationKey
output workbookId string = genAIOpsWorkbook.id