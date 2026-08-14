targetScope = 'resourceGroup'

@description('Name of the GitHub Actions user-assigned managed identity.')
param name string

@description('Azure region for the managed identity.')
param location string

@description('Tags applied to the managed identity.')
param tags object = {}

@description('Foundry account that owns the hosted-agent project.')
param foundryAccountName string

@description('Foundry project that the workflow deploys to.')
param foundryProjectName string

@description('Container registry used for hosted-agent image builds.')
param registryName string

var foundryProjectManagerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'eadc314b-1a2d-4efa-be10-5d325db5065e'
)
var acrTasksContributorRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'fb382eab-e894-4461-af04-94435c366c3f'
)

resource githubActionsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

resource githubMainFederatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {
  parent: githubActionsIdentity
  name: 'github-main'
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:ericchansen@5395779/foundry-agents@1333280174:ref:refs/heads/main'
  }
}

resource foundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' existing = {
  name: foundryAccountName

  resource project 'projects' existing = {
    name: foundryProjectName
  }
}

resource githubActionsProjectManager 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(foundryAccount::project.id, githubActionsIdentity.id, foundryProjectManagerRoleId)
  scope: foundryAccount::project
  properties: {
    principalId: githubActionsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: foundryProjectManagerRoleId
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2025-04-01' existing = {
  name: registryName
}

resource githubActionsAcrTasksContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, githubActionsIdentity.id, acrTasksContributorRoleId)
  scope: registry
  properties: {
    principalId: githubActionsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrTasksContributorRoleId
  }
}

output clientId string = githubActionsIdentity.properties.clientId
output principalId string = githubActionsIdentity.properties.principalId
