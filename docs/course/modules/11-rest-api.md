---
title: "Module 11: Deploy with the REST API"
description: Create, poll, invoke, and delete a hosted-agent version through the REST API.
permalink: /course/modules/11-rest-api/
section: course
module: 11
course_order: 9
previous_title: "Module 10: Python SDK"
previous_url: /course/modules/10-python-sdk/
next_title: "Module 12: Source code"
next_url: /course/modules/12-source-code/
---

# Module 11: Deploy with the REST API

## Objective

Create and operate a container-based hosted-agent version with the Foundry
data-plane REST API.

## Diagnose

Name the minimum REST lifecycle: acquire a token, create the agent/version,
poll the version, invoke its protocol endpoint, and delete the explicit demo
agent when finished.

## Predict

Before running the script, identify which request contains the image,
protocol, CPU, memory, and application environment variables.

## Perform

From [`examples/05-rest-deployment`](https://github.com/ericchansen/foundry-agents/tree/main/examples/05-rest-deployment), run:

```powershell
.\deploy-hosted-agent.ps1 `
  -FoundryProjectEndpoint "https://<account>.services.ai.azure.com/api/projects/<project>" `
  -Image "<registry>.azurecr.io/agents/custom-image-agent@sha256:<digest>" `
  -ModelDeploymentName "<model-deployment>"
```

The script gets a short-lived Azure AI token, posts the hosted-agent
definition, polls until the version is `active`, and posts to the Responses
endpoint.

## Inspect

Capture the create response, version status transitions, and invocation output.
Verify that no bearer token was written to a repository file.

## Debug

Use an intentionally invalid image reference in a separate agent name. Record
the failed version error, then delete only that agent with the script's
`-Delete` option.

## Teach back

Explain why REST is appropriate for language-agnostic automation and why it
requires the caller to implement polling and error handling.

## Checkpoint

Advance only when the REST-created version is active, its endpoint has been
invoked, and the explicit cleanup scope is clear.
