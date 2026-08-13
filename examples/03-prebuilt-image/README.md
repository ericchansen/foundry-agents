# Prebuilt-image deployment example

This example deploys an image that already exists in ACR. It does not build a
Dockerfile.

Set:

```powershell
azd env set FOUNDRY_PROJECT_ENDPOINT <project-endpoint>
azd env set MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME <model-deployment-name>
azd env set PREBUILT_AGENT_IMAGE `
  <registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>
azd env set AZD_AGENT_SKIP_ACR true
```

Then run:

```powershell
azd deploy
```

Use a digest rather than a mutable tag for a reproducible agent version.
