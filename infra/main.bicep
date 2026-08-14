targetScope = 'subscription'

@description('Short name used to create stable demo resource names.')
@minLength(2)
@maxLength(20)
param environmentName string

@description('Azure region for the Foundry demo environment.')
param location string

@description('Optional resource group name. Defaults to rg-<environmentName>.')
param resourceGroupName string = ''

@description('Object ID of the developer or CI principal that deploys the hosted agent.')
param principalId string = ''

@description('Type of the deploying principal.')
@allowed([
  'User'
  'ServicePrincipal'
])
param principalType string = 'User'

@description('JSON model-deployment array supplied by the Foundry azd extension.')
param aiProjectDeploymentsJson string = '''
[
  {
    "name": "gpt-5.4-mini",
    "model": {
      "format": "OpenAI",
      "name": "gpt-5.4-mini",
      "version": "2026-03-17"
    },
    "sku": {
      "name": "GlobalStandard",
      "capacity": 10
    }
  }
]
'''

@description('Create Log Analytics and Application Insights for the demo.')
param enableMonitoring bool = true

@description('Optional salt used to create a different set of globally unique names.')
param resourceTokenSalt string = ''

@description('Create the GitHub Actions OIDC deployment identity and its scoped role assignments.')
param enableGithubActionsIdentity bool = false

var effectiveResourceGroupName = empty(resourceGroupName)
  ? 'rg-${environmentName}'
  : resourceGroupName
var deployments = json(aiProjectDeploymentsJson)
var tags = {
  'azd-env-name': environmentName
  'foundry-course': 'custom-image-hosted-agent'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: effectiveResourceGroupName
  location: location
  tags: tags
}

module resources './modules/resources.bicep' = {
  scope: resourceGroup
  name: 'foundry-course-resources'
  params: {
    environmentName: environmentName
    location: location
    tags: tags
    deployments: deployments
    principalId: principalId
    principalType: principalType
    enableMonitoring: enableMonitoring
    resourceTokenSalt: resourceTokenSalt
  }
}

module githubActionsIdentity './modules/github-actions-identity.bicep' = if (enableGithubActionsIdentity) {
  scope: resourceGroup
  name: 'github-actions-identity'
  params: {
    name: 'id-${take(environmentName, 20)}-github-actions'
    location: location
    tags: tags
    foundryAccountName: resources.outputs.accountName
    foundryProjectName: resources.outputs.projectName
    registryName: resources.outputs.acrName
  }
}

output AZURE_RESOURCE_GROUP string = resourceGroup.name
output AZURE_FOUNDRY_RESOURCE_GROUP string = resourceGroup.name
output AZURE_AI_ACCOUNT_ID string = resources.outputs.accountId
output AZURE_AI_ACCOUNT_NAME string = resources.outputs.accountName
output AZURE_AI_PROJECT_ID string = resources.outputs.projectId
output AZURE_AI_FOUNDRY_PROJECT_ID string = resources.outputs.projectId
output AZURE_AI_PROJECT_NAME string = resources.outputs.projectName
output AZURE_AI_PROJECT_ENDPOINT string = resources.outputs.projectEndpoint
output FOUNDRY_PROJECT_ENDPOINT string = resources.outputs.projectEndpoint
output AZURE_OPENAI_ENDPOINT string = resources.outputs.openAiEndpoint
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.acrName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.acrLoginServer
output AZURE_CONTAINER_REGISTRY_RESOURCE_ID string = resources.outputs.acrId
output AZURE_AI_PROJECT_ACR_CONNECTION_NAME string = resources.outputs.acrConnectionName
output APPLICATIONINSIGHTS_RESOURCE_ID string = resources.outputs.appInsightsId
output APPLICATIONINSIGHTS_CONNECTION_NAME string = resources.outputs.appInsightsConnectionName
output AZURE_AI_PROJECT_CONNECTION_NAMES string = resources.outputs.connectionNames
output GITHUB_ACTIONS_CLIENT_ID string = enableGithubActionsIdentity ? githubActionsIdentity!.outputs.clientId : ''
output GITHUB_ACTIONS_PRINCIPAL_ID string = enableGithubActionsIdentity ? githubActionsIdentity!.outputs.principalId : ''

@secure()
output APPLICATIONINSIGHTS_CONNECTION_STRING string = resources.outputs.appInsightsConnectionString
