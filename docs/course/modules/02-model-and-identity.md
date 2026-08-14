---
title: "Module 2: Model-backed logic and identity"
description: Connect hosted-agent logic to a Foundry model with the correct identity.
permalink: /course/modules/02-model-and-identity/
section: course
module: 2
course_order: 2
previous_title: "Module 1: Runtime contract"
previous_url: /course/modules/01-runtime-contract/
next_title: "Module 3: Custom image"
next_url: /course/modules/03-custom-image/
---

# Module 2: Model-backed logic and identity

## Objective

Replace deterministic echo logic with a real Foundry model call and explain how
authentication changes between local and hosted execution.

## Example

Use [`examples/02-model-agent`](https://github.com/ericchansen/foundry-agents/tree/main/examples/02-model-agent).

## Diagnose

Answer before comparing the examples:

1. Which new dependency is needed to call a Foundry project model?
2. Which values are configuration and which value is a credential?
3. Should an access token appear in `azure.yaml`?

## Predict

Diff the two examples:

```powershell
git diff --no-index `
  .\examples\01-echo-agent\main.py `
  .\examples\02-model-agent\main.py
```

Before reading the full diff, predict:

- Where the model client is created.
- How a synchronous SDK call can run inside an asynchronous protocol handler.
- What happens if `FOUNDRY_PROJECT_ENDPOINT` is missing.

## Learn

Trace these values:

| Value | Local source | Hosted source |
| --- | --- | --- |
| Project endpoint | Shell or `azd ai agent run` | Platform injection (`FOUNDRY_PROJECT_ENDPOINT`) |
| Model deployment name | Shell or `azd` environment | Safe agent environment configuration (`MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME`) |
| Credential | Developer credential chain | Dedicated agent identity |

The image contains code that asks for a credential. It does not contain the
credential itself.

## Perform

Set the project and model values in the current shell:

```powershell
$env:FOUNDRY_PROJECT_ENDPOINT = "https://<account>.services.ai.azure.com/api/projects/<project>"
$env:MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME = "<model-deployment-name>"
```

Authenticate:

```powershell
az login
```

Run the example with Python first so `DefaultAzureCredential` can use the local
Azure CLI credential:

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install `
  -r .\examples\02-model-agent\requirements.txt
.\.venv\Scripts\python .\examples\02-model-agent\main.py
```

Invoke `/responses` and record the output plus the signed-in account shown by:

```powershell
az account show --query "{subscription:name,user:user.name}" --output table
```

## Exercise

Change the system instructions and prove the model behavior changes without
changing the protocol response shape.

## Debug

Run once with `FOUNDRY_PROJECT_ENDPOINT` removed:

```powershell
Remove-Item Env:FOUNDRY_PROJECT_ENDPOINT
```

Predict whether the failure occurs at import, startup, readiness, or request
time. Explain why failing early is preferable here.

Then restore the variable.

## Teach back

Explain how the exact same `DefaultAzureCredential` call represents a developer
locally and the agent identity after deployment. Include what must happen before
the agent can access an external Storage account.

## Checkpoint

Advance only when:

- A real model response is visible.
- You can identify the active local principal.
- You can explain why no secret belongs in the image.
