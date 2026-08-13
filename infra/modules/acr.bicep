targetScope = 'resourceGroup'

@description('Azure region for the container registry.')
param location string

@description('Tags applied to the registry.')
param tags object = {}

@description('Globally unique registry name.')
@minLength(5)
@maxLength(50)
param name string

@description('Foundry account that owns the project connection.')
param foundryAccountName string

@description('Foundry project that owns the project connection.')
param foundryProjectName string

@description('Object ID of the Foundry project managed identity.')
param foundryProjectPrincipalId string

@description('Object ID of the developer or CI principal.')
param developerPrincipalId string = ''

@description('Developer or CI principal type.')
@allowed([
  'User'
  'ServicePrincipal'
])
param developerPrincipalType string = 'User'

var acrPullRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)
var acrTasksContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'fb382eab-e894-4461-af04-94435c366c3f'
)

resource registry 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
    policies: {
      azureADAuthenticationAsArmPolicy: {
        status: 'enabled'
      }
    }
  }
}

resource projectAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, foundryProjectPrincipalId, acrPullRoleId)
  scope: registry
  properties: {
    principalId: foundryProjectPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
  }
}

resource developerAcrTasks 'Microsoft.Authorization/roleAssignments@2022-04-01' =
  if (!empty(developerPrincipalId)) {
    name: guid(registry.id, developerPrincipalId, acrTasksContributorRoleId)
    scope: registry
    properties: {
      principalId: developerPrincipalId
      principalType: developerPrincipalType
      roleDefinitionId: acrTasksContributorRoleId
    }
  }

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: foundryAccountName

  resource project 'projects' existing = {
    name: foundryProjectName

    resource connection 'connections' = {
      name: '${name}-conn'
      properties: {
        category: 'ContainerRegistry'
        target: registry.properties.loginServer
        authType: 'ManagedIdentity'
        credentials: {
          clientId: foundryProjectPrincipalId
          resourceId: registry.id
        }
        isSharedToAll: true
        metadata: {
          ResourceId: registry.id
        }
      }
      dependsOn: [
        projectAcrPull
      ]
    }
  }
}

output name string = registry.name
output loginServer string = registry.properties.loginServer
output resourceId string = registry.id
output connectionName string = foundryAccount::project::connection.name
