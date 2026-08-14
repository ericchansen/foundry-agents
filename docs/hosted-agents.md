---
title: Hosted agents
description: A concise introduction to Microsoft Foundry hosted agents and their operating model.
---

# Hosted agents in Microsoft Foundry

Hosted agents let you run your own containerized agent code on
Foundry-managed infrastructure. You choose the framework, runtime dependencies,
and orchestration logic; the platform supplies the agent endpoint, lifecycle,
scaling, telemetry, and a dedicated Microsoft Entra identity.

## When they fit

Choose a hosted agent when a prompt-only agent is not enough:

- You need to bring custom code or a framework such as Agent Framework,
  LangGraph, Semantic Kernel, or your own implementation.
- The workload needs a defined runtime, native dependencies, or controlled CPU
  and memory.
- The agent needs persistent session files or state.
- An integration needs a custom HTTP payload, webhook, or bidirectional
  streaming protocol.

## What Foundry manages and what you own

| Foundry manages | You own |
| --- | --- |
| Agent endpoint, versions, routing, scaling, sessions, and telemetry | Container image, dependencies, startup command, protocol adapter, and agent logic |
| Dedicated agent identity for runtime access | RBAC for the agent's external dependencies |
| Per-session sandbox lifecycle and persistent session state | Secure application configuration and responsible-AI controls |

Each session runs in an isolated sandbox. The platform can scale inactive
sessions to zero while preserving the session filesystem, then restore that
state when the session resumes.

## Protocol choice

Start with **Responses** for a conversational agent: Foundry manages
conversation history, streaming, and background execution through an
OpenAI-compatible contract. Use **Invocations** when the caller sends a custom
JSON payload, such as a webhook or non-conversational workflow. Use
**Invocations (WebSocket)** for bidirectional real-time scenarios such as voice.
One hosted agent can expose more than one supported protocol.

## Deployment checklist

Before you deploy a custom image, work through the
[hosted agent requirements]({{ '/hosted-agent-requirements/' | relative_url }}).
The checklist covers the image, protocol handler, internal readiness endpoint,
ACR pull authorization, runtime RBAC, configuration, observability, and
digest-pinned production deployments.

## Identity model

Two identities have distinct jobs:

| Identity | Job |
| --- | --- |
| Dedicated agent identity | Authenticates code running inside the container to Foundry models, tools, and downstream Azure resources. |
| Foundry project managed identity | Performs platform operations such as pulling the image through a managed ACR connection. |

Grant the agent identity only the additional roles it needs for external
resources. Do not use the image-pull identity as a substitute for runtime
authorization.

## Practical next step

Read the [mental model]({{ '/mental-model/' | relative_url }}), then validate
the container contract locally with the
[command cheat sheet]({{ '/cheat-sheet/' | relative_url }}). For the complete,
current product surface and limits, use the official
[hosted-agents documentation](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents).
