targetScope = 'resourceGroup'

type deploymentType = {
  name: string
  model: {
    format: string
    name: string
    version: string
  }
  sku: {
    name: string
    capacity: int
  }
}

@description('Short environment name used in resource names.')
param environmentName string

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Tags applied to all resources.')
param tags object = {}

@description('Model deployments declared in azure.yaml.')
param deployments deploymentType[]

@description('Object ID of the developer or CI principal.')
param principalId string = ''

@description('Developer or CI principal type.')
@allowed([
  'User'
  'ServicePrincipal'
])
param principalType string = 'User'

@description('Create Log Analytics and Application Insights.')
param enableMonitoring bool = true

@description('Optional salt used to create a different set of globally unique names.')
param resourceTokenSalt string = ''

var resourceToken = empty(resourceTokenSalt)
  ? uniqueString(subscription().id, resourceGroup().id, location)
  : uniqueString(subscription().id, resourceGroup().id, location, resourceTokenSalt)
var foundryAccountName = 'aif-${take(environmentName, 12)}-${resourceToken}'
var foundryProjectName = 'proj-${take(environmentName, 20)}'
var registryName = 'cr${resourceToken}'
var workspaceName = 'log-${take(environmentName, 12)}-${resourceToken}'
var appInsightsName = 'appi-${take(environmentName, 12)}-${resourceToken}'
var foundryProjectManagerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'eadc314b-1a2d-4efa-be10-5d325db5065e'
)

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: foundryAccountName
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }

  @batchSize(1)
  resource modelDeployments 'deployments' = [
    for deployment in deployments: {
      name: deployment.name
      properties: {
        model: deployment.model
      }
      sku: deployment.sku
    }
  ]

  resource project 'projects' = {
    name: foundryProjectName
    location: location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: 'Custom image hosted agent demo'
      description: 'Long-lived learning and customer demonstration project.'
    }
    dependsOn: [
      modelDeployments
    ]
  }
}

resource developerProjectManager 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (!empty(principalId)) {
    name: guid(foundryAccount::project.id, principalId, foundryProjectManagerRoleId)
    scope: foundryAccount::project
    properties: {
      principalId: principalId
      principalType: principalType
      roleDefinitionId: foundryProjectManagerRoleId
    }
  }

module registry './acr.bicep' = {
  name: 'container-registry'
  params: {
    location: location
    tags: tags
    name: registryName
    foundryAccountName: foundryAccount.name
    foundryProjectName: foundryAccount::project.name
    foundryProjectPrincipalId: foundryAccount::project.identity.principalId
    developerPrincipalId: principalId
    developerPrincipalType: principalType
  }
}

module monitoring './monitoring.bicep' = if (enableMonitoring) {
  name: 'monitoring'
  params: {
    location: location
    tags: tags
    workspaceName: workspaceName
    appInsightsName: appInsightsName
    foundryProjectPrincipalId: foundryAccount::project.identity.principalId
  }
}

resource appInsightsConnection 'Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview' =
  if (enableMonitoring) {
    parent: foundryAccount::project
    name: appInsightsName
    properties: {
      category: 'AppInsights'
      target: monitoring!.outputs.id
      authType: 'ApiKey'
      isSharedToAll: true
      credentials: {
        key: monitoring!.outputs.connectionString
      }
      metadata: {
        ApiType: 'Azure'
        ResourceId: monitoring!.outputs.id
      }
    }
  }

output accountId string = foundryAccount.id
output accountName string = foundryAccount.name
output projectId string = foundryAccount::project.id
output projectName string = foundryAccount::project.name
output projectEndpoint string = foundryAccount::project.properties.endpoints['AI Foundry API']
output openAiEndpoint string = foundryAccount.properties.endpoints['OpenAI Language Model Instance API']
output acrName string = registry.outputs.name
output acrLoginServer string = registry.outputs.loginServer
output acrId string = registry.outputs.resourceId
output acrConnectionName string = registry.outputs.connectionName
output appInsightsId string = enableMonitoring ? monitoring!.outputs.id : ''
output appInsightsConnectionName string = enableMonitoring ? appInsightsConnection!.name : ''
output appInsightsConnectionString string = enableMonitoring ? monitoring!.outputs.connectionString : ''
output connectionNames string = string(
  enableMonitoring
    ? [
        registry.outputs.connectionName
        appInsightsConnection!.name
      ]
    : [
        registry.outputs.connectionName
      ]
)
