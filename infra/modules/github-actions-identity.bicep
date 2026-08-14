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

@description('Container registry used for local Docker builds and data-plane image pushes.')
param registryName string

@description('Exact GitHub Actions OIDC subject trusted by this federated credential. Re-query and update it after a repository rename, transfer, or GitHub OIDC trust-model change.')
param federatedSubject string

var foundryProjectManagerRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  'eadc314b-1a2d-4efa-be10-5d325db5065e'
)
var acrPushRoleId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '8311e382-0749-4cb8-b61a-304f252e45ec'
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
    subject: federatedSubject
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

resource githubActionsAcrPush 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, githubActionsIdentity.id, acrPushRoleId)
  scope: registry
  properties: {
    principalId: githubActionsIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPushRoleId
  }
}

output clientId string = githubActionsIdentity.properties.clientId
output principalId string = githubActionsIdentity.properties.principalId
