---
title: "Module 12: Deploy source code without Docker"
description: Deploy a Python source archive with Foundry remote dependency resolution.
permalink: /course/modules/12-source-code/
section: course
module: 12
course_order: 10
previous_title: "Module 11: REST API"
previous_url: /course/modules/11-rest-api/
next_title: "Module 8: Troubleshooting"
next_url: /course/modules/08-troubleshooting/
---

# Module 12: Deploy source code without Docker

## Objective

Deploy the Python agent as a source archive using Foundry remote dependency
resolution rather than a container image.

## Diagnose

Explain why `codeConfiguration` and `container_configuration` are mutually
exclusive for a version. Name the difference between `remote_build` and
`bundled` dependency resolution.

## Predict

Inspect [`examples/06-source-code-deployment/azure.yaml`](https://github.com/ericchansen/foundry-hosted-agents/blob/main/examples/06-source-code-deployment/azure.yaml).
Predict the archive entry point, runtime, protocol, and where dependencies
come from.

## Perform

From `examples/06-source-code-deployment`, configure the existing project and
run:

```powershell
azd env new source-code-hosted-agent-lab
azd env set AZURE_LOCATION <location>
azd up
azd ai agent invoke "Which artifact deployed you?"
```

## Inspect

Verify the version reaches `active`. Explain why this path has no image digest
and identify the source archive and SHA-256 as the release artifact instead.

## Debug

Introduce a dependency that cannot be resolved remotely. Determine whether to
correct `requirements.txt` or use `bundled` dependencies, then restore the
remote-build configuration.

## Teach back

Describe when source-code deployment is faster than container deployment and
when a customer still needs a Dockerfile or a prebuilt image.

## Checkpoint

Advance only when a source-code version is active, responds to an invocation,
and its artifact boundary is correctly explained.
