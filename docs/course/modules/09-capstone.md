---
title: "Module 9: Independent capstone"
description: Complete an independent deployment, incident, and customer teach-back.
permalink: /course/modules/09-capstone/
section: course
module: 9
course_order: 12
previous_title: "Module 8: Troubleshooting"
previous_url: /course/modules/08-troubleshooting/
---

# Module 9: Independent capstone

## Objective

Prove you can explain, deploy, invoke, and troubleshoot a custom-image hosted
agent without procedural help.

## Diagnose

Before touching the repository, narrate the architecture, resource graph,
deployment lifecycle, and diagnostic ladder without notes. The instructor
records any weak areas but does not teach them yet.

## Predict

Write the sequence of infrastructure, image, deployment, invocation, and
observation operations you expect to perform. Include the evidence that will
prove each operation succeeded.

## Instructor rules

The instructor may:

- Ask clarifying questions.
- Request evidence.
- Point out an unsafe action.
- Provide one hint after a documented attempt.

The instructor may not:

- Supply the next command unprompted.
- Make the learner's edit.
- Interpret evidence before the learner.
- Open the answer key.

## Perform: challenge

From a clean `azd` environment:

1. Explain the target architecture.
2. Select the existing long-lived demo resource group.
3. Preview and reconcile the Bicep infrastructure.
4. Select a deployment interface: `azd`, Python SDK, or REST API.
5. Select the matching artifact path: container source, prebuilt image, or
   source-code archive.
6. Deploy a new hosted-agent version.
7. Invoke the Responses endpoint.
8. Locate the request in logs and traces.
9. Explain the active identity and its permissions.
10. Deploy a behavior change as another version.
11. Demonstrate the rollback plan.

## Injected incident

The instructor selects one failure from Module 8 or creates an equivalent new
failure. Diagnose it using the evidence ladder.

## Teach back: customer simulation

Lead a discovery call for a customer who:

- Has an existing private ACR.
- Builds and scans images in a separate pipeline.
- Wants to use a custom image with a Foundry model.
- Is unsure which identity needs which role.
- Needs logs and a rollback story.

You must explain the design, ask the missing questions, and propose the
deployment sequence.

## Checkpoint: graduation evidence

- Architecture explanation is correct without notes.
- Deployment reaches an active version.
- A real invocation succeeds.
- Telemetry is located.
- The injected failure is diagnosed by layer.
- The customer simulation covers image, protocol, identity, networking,
  operations, and ownership.
