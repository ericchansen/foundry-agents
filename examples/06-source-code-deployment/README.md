# Docker-less source-code deployment

This example deploys the Python agent in `agent/` as a source archive. Foundry
performs the dependency installation specified by `agent/requirements.txt`; no
Docker build or ACR image is required.

```powershell
azd env new source-code-hosted-agent-lab
azd env set AZURE_LOCATION <location>
azd up
azd ai agent show --output table
azd ai agent invoke "Which artifact deployed you?"
```

Run these commands from this example directory. The `codeConfiguration` uses
`remote_build`; use `bundled` only when the archive must contain prebuilt Linux
dependencies. To adopt an existing project, set the same `AZURE_RESOURCE_GROUP`,
`AI_PROJECT_DEPLOYMENTS`, and deploying-principal values used by the main lab,
then run `azd provision` before `azd deploy`.
