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

## Learn more

- [Deploy a hosted agent](https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent)
- [Deploy a hosted agent with a private Azure Container Registry](https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent-private-azure-container-registry)
- [azure.yaml reference for hosted agents](https://learn.microsoft.com/azure/foundry/agents/concepts/azure-yaml-reference)
- [Hosted agents in Foundry Agent Service](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents)
