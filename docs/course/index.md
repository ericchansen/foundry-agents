---
title: Course
description: Learn to build, deploy, and operate Microsoft Foundry hosted agents through an instructor-led course.
permalink: /course/
section: course
---

# Learn custom-image Foundry hosted agents

This is not a copy-and-run tutorial. It is an instructor-led apprenticeship
whose capstone is a real, long-lived Microsoft Foundry hosted agent.

The repository is the textbook, lab bench, example library, and reference. In
the Copilot conversation, the instructor controls the sequence, asks questions,
reviews evidence, and withholds answer keys until you have attempted the work.

## Target competency

At the end of the course, you can independently:

1. Explain when a hosted agent is appropriate.
2. Explain the container, protocol, identity, and infrastructure boundaries.
3. Build and inspect a Linux `amd64` agent image.
4. Provision the Azure resources with Bicep.
5. Provision and deploy the same system with `azd`.
6. Invoke, observe, version, and roll back the hosted agent.
7. Deploy a prebuilt ACR image by digest.
8. Deploy a container directly with the Python SDK.
9. Deploy a container directly with the REST API.
10. Deploy source code without building a container.
11. Troubleshoot failures from image build through agent identity.
12. Lead a customer discovery and architecture discussion.

## How each lesson works

Every lesson uses the same learning loop:

1. **Diagnose** -- answer a question before reading the explanation.
2. **Explain** -- learn one small mental model.
3. **Predict** -- state what you expect a command or change to do.
4. **Perform** -- make the important edit or run the important command yourself.
5. **Inspect** -- collect observable evidence rather than trusting "success."
6. **Debug** -- encounter or analyze a realistic failure.
7. **Teach back** -- explain the concept in your own words.
8. **Checkpoint** -- demonstrate the lesson outcome before advancing.

The instructor should not run the learner's key command, reveal the answer key,
or repair an intentional exercise before the learner has made an attempt.

## Start here

Tell Copilot:

```text
Start Module 0. Teach me interactively and do not skip the prediction or
teach-back steps.
```

Then follow the instructor rather than reading ahead.

## Course map

| Module | Subject | You produce |
| --- | --- | --- |
| [0]({{ '/course/modules/00-baseline/' | relative_url }}) | Baseline and vocabulary | A correct architecture sketch and vocabulary explanation |
| [1]({{ '/course/modules/01-runtime-contract/' | relative_url }}) | Responses runtime contract | A locally invoked echo image and raw protocol evidence |
| [2]({{ '/course/modules/02-model-and-identity/' | relative_url }}) | Model calls and identity | An identity-flow explanation and model-backed response |
| [3]({{ '/course/modules/03-custom-image/' | relative_url }}) | Custom image construction | A verified Linux `amd64`, non-root image |
| [4]({{ '/course/modules/04-bicep/' | relative_url }}) | Direct Bicep provisioning | A durable demo resource group and resource graph |
| [5]({{ '/course/modules/05-azd/' | relative_url }}) | `azd` provisioning and deployment | The same environment operated through `azd` |
| [6]({{ '/course/modules/06-lifecycle/' | relative_url }}) | Invoke, observe, and version | Endpoint evidence, logs, traces, and a second version |
| [7]({{ '/course/modules/07-prebuilt-acr/' | relative_url }}) | Prebuilt ACR image | A digest-pinned deployment without rebuilding |
| [10]({{ '/course/modules/10-python-sdk/' | relative_url }}) | Python SDK deployment | A version created, polled, and invoked from Python |
| [11]({{ '/course/modules/11-rest-api/' | relative_url }}) | REST API deployment | A version created, polled, and invoked from PowerShell |
| [12]({{ '/course/modules/12-source-code/' | relative_url }}) | Source-code deployment | A Docker-less version using remote dependency resolution |
| [8]({{ '/course/modules/08-troubleshooting/' | relative_url }}) | Failure lab | A completed diagnostic evidence table |
| [9]({{ '/course/modules/09-capstone/' | relative_url }}) | Independent capstone | A clean deployment and no-notes teach-back |

## Progress evidence

Completion is based on evidence, not on reading.

| Module | Required evidence |
| --- | --- |
| 0 | You can draw and narrate the request path and identity path. |
| 1 | `/readiness` returns 200 and `/responses` returns the expected echo. |
| 2 | A real Foundry model responds and you identify which principal authorized it. |
| 3 | Image inspection shows Linux, `amd64`, user `agent`, port `8088`, and a health check. |
| 4 | Bicep deployment outputs identify every demo resource. |
| 5 | `azd` can provision idempotently and deploy the agent. |
| 6 | You invoke two versions, inspect telemetry, and explain rollback. |
| 7 | Foundry pulls a digest-pinned image from ACR. |
| 10 | Python creates an active version and invokes its endpoint. |
| 11 | REST creates an active version and invokes its endpoint. |
| 12 | A source-code version becomes active without a container image. |
| 8 | You diagnose each failure by layer before looking at the answer. |
| 9 | You complete the capstone and customer simulation without procedural help. |

## Durable references

- [Hosted agent requirements]({{ '/hosted-agent-requirements/' | relative_url }}) -- read this
  checklist before building or deploying an image
- [Mental model]({{ '/mental-model/' | relative_url }})
- [Command cheat sheet]({{ '/cheat-sheet/' | relative_url }})
- [GitHub Actions deployment]({{ '/github-actions-hosted-agent/' | relative_url }}) -- use this before automating a release
- [Troubleshooting playbook]({{ '/troubleshooting-playbook/' | relative_url }})
- [Customer walkthrough]({{ '/customer-walkthrough/' | relative_url }})
- [Answer key]({{ '/course/answer-key/' | relative_url }}) -- use only after attempting an exercise

## Hosted agent requirements

Before Module 3, be able to explain the hosted-agent boundary: a Linux `amd64`
OCI image, Responses 2.0 (for this lab) plus its protocol handler, internal
port `8088`, and the SDK-provided `/readiness` endpoint. The image belongs in
ACR, the Foundry project or platform identity needs pull authorization, and the
dedicated runtime identity needs least-privilege RBAC for downstream resources.

Configuration and secrets stay outside the image: preserve platform-reserved
`FOUNDRY_*` names and use Foundry connections where supported. Plan
observability before deploying, and pin production releases to an image
`@sha256` digest. You do not need a public web server, a custom health endpoint,
or API keys embedded in the container. See [Hosted agent
requirements]({{ '/hosted-agent-requirements/' | relative_url }}) for the complete checklist and
the distinction between mutable release tags and immutable deployment digests.

## Ground rules for the Azure environment

- The demo environment is intentionally long-lived.
- Infrastructure names and locations are parameterized.
- Secrets never enter source control, Bicep parameters, Docker layers, or
  `azure.yaml`.
- Deployments must be idempotent.
- Every resource that can incur cost is identified in the infrastructure
  lesson.
- Cleanup remains documented even though routine course completion does not
  delete the demo environment.
