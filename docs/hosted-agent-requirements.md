---
title: Hosted agent requirements
description: A beginner-friendly deployment checklist for custom-image Microsoft Foundry hosted agents.
---

# Hosted agent requirements

Use this checklist before deploying a custom-image Microsoft Foundry hosted
agent. It separates the small runtime contract your container must meet from
the platform services Foundry manages for you.

## Required before deployment

1. **Linux `amd64` OCI image.** Build and publish a Linux `amd64` OCI container
   image. This is the artifact Foundry starts.
2. **Supported protocol and handler.** Declare a protocol that Foundry supports
   and run the matching handler in the container. This lab declares
   **Responses 2.0** in `azure.yaml` and uses the
   `azure-ai-agentserver-responses` SDK package as its protocol handler.
3. **Internal readiness port.** Listen on internal port `8088`. The SDK exposes
   `/readiness`, which Foundry uses to determine whether the container is ready.
   Do not configure a public inbound port for the container.
4. **ACR image and pull authorization.** Store the image in Azure Container
   Registry (ACR). Give the Foundry project or platform identity the pull access
   required by the managed ACR connection.
5. **Runtime identity and RBAC.** The dedicated agent identity inside the
   running container needs least-privilege roles for downstream Azure resources
   such as storage, search, or other services. Image-pull permission does not
   grant those runtime permissions.
6. **Configuration, secrets, and connections.** Pass application configuration
   securely instead of building it into the image. Do not use platform-reserved
   `FOUNDRY_*` environment variable names for application settings; Foundry uses
   those names for injected values such as `FOUNDRY_PROJECT_ENDPOINT`. Use
   Foundry connections for supported service integrations.
7. **Observability.** Configure and use the provided monitoring resources so
   deployment status, request activity, logs, traces, and failures are
   inspectable.
8. **Production image pin.** Deploy production versions by a fixed image digest,
   not only a tag.

## What Foundry removes from your checklist

You do **not** need to build a public web server, hand-build a health endpoint,
or embed API keys in the container image. Foundry owns the public agent
endpoint, and the Responses SDK provides `/readiness`. Use the dedicated agent
identity and Foundry connections instead of shipping credentials with the
artifact.

## Tags label releases; digests select artifacts

Tags such as `v1.4.0` are human-friendly release labels. They can be mutable:
the same tag may later point to a different image. SemVer tags can still be
useful release labels, but a deployment should pin the immutable artifact
digest:

```text
myregistry.azurecr.io/agents/lab:v1.4.0@sha256:<digest>
```

The shorter form below is also digest-pinned:

```text
myregistry.azurecr.io/agents/lab@sha256:<digest>
```

The `sha256` value makes the production artifact selection repeatable even if
someone moves or reuses a release tag.

## CI/CD release lifecycle

Pushing a new image to ACR does **not** update an existing agent. Foundry does
not watch an image tag for changes. A release pipeline must deliberately create
and promote a new agent version that references the resolved digest.

Use `azd`, the Foundry SDK, or the REST API as equivalent control-plane clients:
each can create and manage the Foundry agent version. `azd` automates more of
the workflow, while SDK and REST integrations let a pipeline manage the same
version lifecycle directly.

1. Authenticate the pipeline to Azure with workload identity federation (OIDC),
   not a stored client secret.
2. Build a Linux `amd64` image, then test, scan, sign, and push it to ACR.
3. Resolve the pushed image digest and create a Foundry agent version that
   references that exact digest.
4. Invoke the candidate version for a smoke test.
5. Explicitly activate or promote the tested version, then monitor its logs,
   traces, and deployment status.
6. If the release fails, roll back by explicitly reactivating the previous
   known-good version. Do not rebuild the old image just to roll back.

The pipeline identity needs an ACR **data-plane** push role for the image
repository and the **Foundry Project Manager** role for agent lifecycle
operations. For this lab's local Docker push and Legacy/RBAC Registry Permissions
mode, use `AcrPush`. For an ABAC-enabled registry, use `Container Registry
Repository Writer` and scope it to the repository when required. `Tasks
Contributor` manages ACR Tasks and does not authorize a local Docker data-plane
push. Configure a federated identity credential that trusts the pipeline's OIDC
tokens; do not store a client secret in the CI system.

### Root demo automation

The root `custom-image-hosted-agent-lab` has an automatic main-branch workflow
in [`deploy-hosted-agent.yml`](https://github.com/ericchansen/foundry-hosted-agents/blob/main/.github/workflows/deploy-hosted-agent.yml).
It runs `azd deploy`, which can create and activate the new version as one
operation, then invokes the active Responses endpoint. Its smoke test is a
post-deployment confirmation, not a pre-activation approval gate. Use a staged
SDK or REST release flow when production policy requires candidate testing and
an explicit promotion decision before traffic changes. Setup details, including a safe identity-only bootstrap for existing
environments, repository OIDC subject configuration, a copyable workflow, and
direct Responses diagnostics, are in [the GitHub Actions deployment guide]({{ '/github-actions-hosted-agent/' | relative_url }}).

## Learn more

- [Deploy a hosted agent](https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent)
- [Deploy a hosted agent with a private Azure Container Registry](https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent-private-azure-container-registry)
- [azure.yaml reference for hosted agents](https://learn.microsoft.com/azure/foundry/agents/concepts/azure-yaml-reference)
- [Hosted agents in Foundry Agent Service](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents)
- [Authenticate to Azure from GitHub Actions by OpenID Connect](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
