---
title: "Module 6: Invoke, observe, and version"
description: Invoke, monitor, version, promote, and roll back a hosted agent.
permalink: /course/modules/06-lifecycle/
section: course
module: 6
course_order: 6
previous_title: "Module 5: azd"
previous_url: /course/modules/05-azd/
next_title: "Module 7: Prebuilt ACR image"
next_url: /course/modules/07-prebuilt-acr/
---

# Module 6: Invoke, observe, and version

## Objective

Operate the deployed hosted agent as a versioned service rather than treating
deployment as the finish line.

## Diagnose

Answer:

1. What is the difference between an agent, an agent version, and an endpoint?
2. What should happen to the previous version after `azd deploy`?
3. Where would you look for a handler exception?

## Predict

Before invoking, predict which version receives traffic and what telemetry a
single request should produce.

## Perform

```powershell
azd ai agent show --output table
azd ai agent invoke "Explain your container and platform boundaries."
azd ai agent monitor --follow
```

Open Application Insights and locate the request, dependencies, and trace
context for the same invocation.

## Exercise

Change `AGENT_INSTRUCTIONS`, deploy again, and invoke the same prompt.

Record:

| Evidence | Version 1 | Version 2 |
| --- | --- | --- |
| Agent version | | |
| Image digest | | |
| Response behavior | | |
| Deployment status | | |
| Trace evidence | | |

## CI/CD release lifecycle

A new image pushed to ACR does **not** automatically update an agent. The
pipeline must resolve the image digest, create a Foundry agent version that
references it, smoke test that version, and explicitly activate or promote it.
`azd`, the SDK, and REST are equivalent control-plane clients for this lifecycle.

After promotion, monitor the version. To roll back, explicitly reactivate the
previous known-good version; do not rebuild its image. The pipeline identity
needs ACR push permission and the **Foundry Project Manager** role. Authenticate
the pipeline through workload identity federation (OIDC), not a stored client
secret. See the [hosted agent requirements]({{ '/hosted-agent-requirements/#cicd-release-lifecycle' | relative_url }})
for the full release checklist and official references.

## Debug

Introduce a harmless startup configuration failure in a new version. Observe
that the version does not become active. Revert the change and explain how
version preservation reduces rollback risk.

## Teach back

Explain the lifecycle from image digest to version creation to endpoint
routing. Include how you would roll back without rebuilding an older image.

## Checkpoint

Advance only when two versions exist, both are understood, and you can locate
logs and traces for a specific invocation.
