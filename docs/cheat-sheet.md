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

docker image inspect custom-image-hosted-agent-lab:local `
  --format "OS={{.Os}} Arch={{.Architecture}} User={{.Config.User}}"
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
