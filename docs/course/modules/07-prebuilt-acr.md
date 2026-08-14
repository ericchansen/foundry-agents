---
title: "Module 7: Deploy a prebuilt ACR image"
description: Deploy a customer-supplied, digest-pinned image from Azure Container Registry.
permalink: /course/modules/07-prebuilt-acr/
section: course
module: 7
course_order: 7
previous_title: "Module 6: Lifecycle"
previous_url: /course/modules/06-lifecycle/
next_title: "Module 10: Python SDK"
next_url: /course/modules/10-python-sdk/
---

# Module 7: Deploy a prebuilt ACR image

## Objective

Separate image production from hosted-agent deployment and deploy an immutable
image by digest.

## Example

Use [`examples/03-prebuilt-image`](https://github.com/ericchansen/foundry-hosted-agents/tree/main/examples/03-prebuilt-image).

## Diagnose

Name the two actors involved in ACR authorization and the minimum action each
must perform.

## Predict

Before pushing, explain why a tag is convenient but a digest is reproducible.

## Perform

Build and push:

```powershell
az acr login --name <registry-name>

docker build --platform linux/amd64 `
  --tag <registry>.azurecr.io/agents/custom-image-agent:v1 `
  .\src\agent

docker push <registry>.azurecr.io/agents/custom-image-agent:v1
```

Resolve the digest:

```powershell
docker buildx imagetools inspect `
  <registry>.azurecr.io/agents/custom-image-agent:v1
```

Set the example environment values and deploy:

```powershell
azd env set FOUNDRY_PROJECT_ENDPOINT <project-endpoint>
azd env set MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME <model-deployment>
azd env set PREBUILT_AGENT_IMAGE `
  <registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>
azd env set AZD_AGENT_SKIP_ACR true
azd deploy
```

## Inspect

Confirm the deployed agent version references the digest, not only the tag.
Confirm which principal has pull access.
Confirm that the release pipeline has ACR push permission, uses OIDC workload
identity federation, and has the **Foundry Project Manager** role required to
create and promote the agent version.

For a local Docker data-plane push to this lab's Legacy/RBAC Registry Permissions
registry, the release identity needs `AcrPush`; `Tasks Contributor` is for ACR
Tasks and does not authorize that push. For an ABAC-enabled registry, use
`Container Registry Repository Writer`. See the [GitHub Actions deployment
guide]({{ '/github-actions-hosted-agent/#choose-the-acr-data-plane-role' | relative_url }})
before assigning the CI identity.

## Exercise

Move the `v1` tag to a different image without changing the digest-pinned
deployment. Explain why the running version remains reproducible.

## Debug

Remove neither role. Instead, inspect the role assignments and predict the
different error produced when the developer cannot push versus when the Foundry
project identity cannot pull.

## Teach back

Explain when a customer should choose a prebuilt image and which supply-chain
responsibilities remain outside Foundry.

## Checkpoint

Advance only when the digest-pinned version is active, you can distinguish
developer push access from project identity pull access, and you can select the
correct CI role for the registry permissions mode.
