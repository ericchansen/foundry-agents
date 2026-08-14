using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME')
param location = readEnvironmentVariable('AZURE_LOCATION')
param resourceGroupName = readEnvironmentVariable('AZURE_RESOURCE_GROUP', '')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param principalType = readEnvironmentVariable('AZURE_PRINCIPAL_TYPE', 'User')
param enableMonitoring = bool(readEnvironmentVariable('ENABLE_MONITORING', 'true'))
param resourceTokenSalt = readEnvironmentVariable('AZD_RESOURCE_TOKEN_SALT', '')
param enableGithubActionsIdentity = bool(readEnvironmentVariable('ENABLE_GITHUB_ACTIONS_IDENTITY', 'false'))
param githubActionsFederatedSubject = readEnvironmentVariable('GITHUB_ACTIONS_FEDERATED_SUBJECT', 'repo:ericchansen@5395779/foundry-hosted-agents@1333280174:ref:refs/heads/main')
