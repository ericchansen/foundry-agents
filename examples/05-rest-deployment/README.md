# REST API container deployment

This PowerShell example deploys a prebuilt ACR image with the Foundry data-plane
REST API. It obtains a short-lived Azure AI bearer token through Azure CLI and
does not write the token to disk.

```powershell
.\deploy-hosted-agent.ps1 `
  -FoundryProjectEndpoint "https://<account>.services.ai.azure.com/api/projects/<project>" `
  -Image "<registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>" `
  -ModelDeploymentName "<model-deployment>"
```

It creates the named agent (or a new version when it already exists), polls its
version to `active`, then invokes its Responses endpoint. To remove only this
lab's agent:

```powershell
.\deploy-hosted-agent.ps1 `
  -FoundryProjectEndpoint "https://<account>.services.ai.azure.com/api/projects/<project>" `
  -Image ignored `
  -ModelDeploymentName ignored `
  -Delete
```

The deploying identity needs **Foundry Project Manager** on the project. Before
running the script, ensure the Foundry project managed identity has
**Container Registry Repository Reader** access to the image repository.
