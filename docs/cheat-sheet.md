---
title: Command cheat sheet
description: Commands for building, deploying, invoking, and diagnosing a Foundry hosted agent.
---

# Hosted-agent command cheat sheet

Use this after completing the relevant lesson. During a lesson, predict the
command before consulting this file.

## Toolchain

```powershell
python --version
az --version
azd version
azd ext list --installed
docker version
.\scripts\use-latest-azd.ps1
.\scripts\check-prerequisites.ps1
```

## Local image

```powershell
docker build --platform linux/amd64 `
  --tag custom-image-hosted-agent-lab:local `
  .\src\agent

.\scripts\test-image.ps1

{% raw %}
docker image inspect custom-image-hosted-agent-lab:local `
  --format "OS={{.Os}} Arch={{.Architecture}} User={{.Config.User}}"
{% endraw %}
```

## Direct Bicep

```powershell
az deployment sub what-if `
  --location <location> `
  --template-file .\infra\main.bicep `
  --parameters environmentName=<name> location=<location>

az deployment sub create `
  --location <location> `
  --template-file .\infra\main.bicep `
  --parameters environmentName=<name> location=<location>
```

## azd

```powershell
azd auth login
azd env new <environment-name>
azd env set AZURE_LOCATION <location>
azd provision
azd deploy
azd up
azd ai agent show --output table
azd ai agent invoke "Explain the hosted-agent container boundary."
azd ai agent monitor --follow
```

## Python SDK deployment

```powershell
Set-Location .\examples\04-python-sdk-deployment
python -m pip install -r requirements.txt
$env:FOUNDRY_PROJECT_ENDPOINT = "https://<account>.services.ai.azure.com/api/projects/<project>"
$env:HOSTED_AGENT_IMAGE = "<registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>"
$env:MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME = "<model-deployment>"
python deploy.py
```

## REST deployment

```powershell
Set-Location .\examples\05-rest-deployment
.\deploy-hosted-agent.ps1 `
  -FoundryProjectEndpoint "https://<account>.services.ai.azure.com/api/projects/<project>" `
  -Image "<registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>" `
  -ModelDeploymentName "<model-deployment>"
```

## Source-code deployment

```powershell
Set-Location .\examples\06-source-code-deployment
azd env new source-code-hosted-agent-lab
azd env set AZURE_LOCATION <location>
azd up
```

## Responses protocol

```powershell
$body = @{
  input = "Hello"
  stream = $false
} | ConvertTo-Json

Invoke-RestMethod http://127.0.0.1:8088/responses `
  -Method Post `
  -ContentType application/json `
  -Body $body |
  ConvertTo-Json -Depth 20
```

## ACR

```powershell
az acr login --name <registry-name>

docker build --platform linux/amd64 `
  --tag <registry>.azurecr.io/agents/custom-image-agent:<tag> `
  .\src\agent

docker push <registry>.azurecr.io/agents/custom-image-agent:<tag>

docker buildx imagetools inspect `
  <registry>.azurecr.io/agents/custom-image-agent:<tag>
```

## Evidence order

When troubleshooting, collect evidence in this order:

1. Python import and startup
2. Image build
3. Container process
4. `/readiness`
5. Declared protocol endpoint
6. Credential acquisition
7. Dependency authorization and network
8. Agent version state
9. Endpoint routing
