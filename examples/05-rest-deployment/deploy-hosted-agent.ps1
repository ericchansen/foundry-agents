[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $FoundryProjectEndpoint,

    [Parameter(Mandatory)]
    [string] $Image,

    [Parameter(Mandatory)]
    [string] $ModelDeploymentName,

    [string] $AgentName = "rest-hosted-agent-lab",

    [switch] $Delete,

    [int] $TimeoutSeconds = 300
)

$ErrorActionPreference = "Stop"
$apiVersion = "v1"
$token = az account get-access-token `
    --resource "https://ai.azure.com" `
    --query accessToken `
    --output tsv

if (-not $token) {
    throw "Azure CLI did not return an Azure AI access token."
}

$headers = @{
    Authorization = "Bearer $token"
    "Content-Type" = "application/json"
}
$baseUri = $FoundryProjectEndpoint.TrimEnd("/")
$agentUri = "$baseUri/agents/$AgentName"

if ($Delete) {
    Invoke-RestMethod -Method Delete `
        -Uri "$agentUri`?api-version=$apiVersion" `
        -Headers $headers
    Write-Host "Deleted $AgentName."
    exit 0
}

$definition = @{
    kind = "hosted"
    container_configuration = @{
        image = $Image
    }
    cpu = "0.5"
    memory = "1Gi"
    protocol_versions = @(
        @{
            protocol = "responses"
            version = "2.0.0"
        }
    )
    environment_variables = @{
        MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME = $ModelDeploymentName
    }
}

try {
    $existing = Invoke-RestMethod -Method Get `
        -Uri "$agentUri`?api-version=$apiVersion" `
        -Headers $headers
}
catch {
    if ($_.Exception.Response.StatusCode -ne [System.Net.HttpStatusCode]::NotFound) {
        throw
    }
}

if ($existing) {
    $created = Invoke-RestMethod -Method Post `
        -Uri "$agentUri/versions?api-version=$apiVersion" `
        -Headers $headers `
        -Body (@{ definition = $definition } | ConvertTo-Json -Depth 10)
}
else {
    $created = Invoke-RestMethod -Method Post `
        -Uri "$baseUri/agents?api-version=$apiVersion" `
        -Headers $headers `
        -Body (@{
            name = $AgentName
            definition = $definition
        } | ConvertTo-Json -Depth 10)
}

$version = [string] $created.version
if (-not $version) {
    $version = [string] $created.versions.latest.version
}
if (-not $version) {
    throw "Create-agent response did not include a version."
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
do {
    Start-Sleep -Seconds 5
    $versionInfo = Invoke-RestMethod -Method Get `
        -Uri "$agentUri/versions/$version`?api-version=$apiVersion" `
        -Headers $headers
    Write-Host "Version $version status: $($versionInfo.status)"
    if ($versionInfo.status -eq "failed") {
        throw "Provisioning failed: $($versionInfo.error | ConvertTo-Json -Depth 10)"
    }
} while ($versionInfo.status -ne "active" -and (Get-Date) -lt $deadline)

if ($versionInfo.status -ne "active") {
    throw "Version $version did not become active within $TimeoutSeconds seconds."
}

$response = Invoke-RestMethod -Method Post `
    -Uri "$agentUri/endpoint/protocols/openai/responses?api-version=$apiVersion" `
    -Headers $headers `
    -Body (@{
        input = "Which deployment interface created you?"
        store = $true
    } | ConvertTo-Json)

$response | ConvertTo-Json -Depth 20
