# Python SDK container deployment

This example deploys the shared Responses container without `azd`. It requires
a Foundry project, a Linux `amd64` image already pushed to ACR, and pull access
for the Foundry project managed identity.

```powershell
python -m pip install -r requirements.txt
$env:FOUNDRY_PROJECT_ENDPOINT = "https://<account>.services.ai.azure.com/api/projects/<project>"
$env:HOSTED_AGENT_IMAGE = "<registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>"
$env:MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME = "<model-deployment>"
python deploy.py
```

The script uses `DefaultAzureCredential`, creates a version, waits for
`active`, and invokes the Responses endpoint. Run the following only to remove
the lab agent and all its versions:

```powershell
python deploy.py --delete
```

The deploying identity needs **Foundry Project Manager** on the project. The
Foundry project managed identity needs **Container Registry Repository Reader**
on the repository containing the image.
