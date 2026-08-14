---
title: "Module 10: Deploy with the Python SDK"
description: Create, poll, and invoke a container-based hosted-agent version from Python.
permalink: /course/modules/10-python-sdk/
section: course
module: 10
course_order: 8
previous_title: "Module 7: Prebuilt ACR image"
previous_url: /course/modules/07-prebuilt-acr/
next_title: "Module 11: REST API"
next_url: /course/modules/11-rest-api/
---

# Module 10: Deploy with the Python SDK

## Objective

Create and operate a container-based hosted-agent version directly from Python,
without `azd` creating the version.

## Diagnose

Explain which responsibilities remain yours when `azd` is removed: image build
and push, image-pull authorization, version creation, status polling, and
invocation.

## Predict

Before reading the example, predict which identity uploads the image, which
identity pulls it, and which identity the container uses after it starts.

## Perform

From [`examples/04-python-sdk-deployment`](https://github.com/ericchansen/foundry-agents/tree/main/examples/04-python-sdk-deployment),
set the project endpoint, digest-pinned image reference, and model deployment.
Then run:

```powershell
python -m pip install -r requirements.txt
python deploy.py
```

The script calls `AIProjectClient.agents.create_version`, polls the version to
`active`, and invokes the agent through a project-bound OpenAI client.

## Inspect

Record the agent name, version, source image digest, final status, and
Responses output. Compare the version with one created through `azd deploy`.

## Debug

Remove neither role. Instead, inspect and explain the different failures when
the developer cannot push the image and when the Foundry project identity
cannot pull it.

## Teach back

Explain why the SDK creates the version but does not replace the need for an
image pipeline or project-managed-identity registry access.

## Checkpoint

Advance only when the SDK-created version is active, invoked successfully, and
its cleanup command is understood.
