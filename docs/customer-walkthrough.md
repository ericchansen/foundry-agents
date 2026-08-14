---
title: Customer walkthrough
description: Run hosted-agent discovery and demonstration conversations with customers.
---

# Customer walkthrough guide

Use this guide to turn a vague "deploy our code as an agent" request into a
concrete hosted-agent plan.

## Open the meeting

State the boundary clearly:

> A hosted agent runs your container on Foundry-managed infrastructure. You own
> the image, dependencies, protocol adapter, and agent logic. Foundry owns the
> endpoint, agent identity, scaling, session lifecycle, and version deployment.

Then confirm that the customer needs a hosted agent rather than a prompt agent
because they need custom runtime behavior, a controlled container image, or a
source-code deployment path.

## Choose the deployment interface

| Interface | Use when |
| --- | --- |
| `azd` | The team wants guided provisioning, deployment, and RBAC automation. |
| Python SDK | A Python application or automation owns the release workflow. |
| REST API | Existing delivery tooling is language-agnostic or must call HTTP directly. |

The deployment interface is independent of the artifact: Foundry can receive
an `azd`-built image, a prebuilt ACR image, or a Docker-less source archive.

## Discovery questions

### Image and build

- Where is the Dockerfile or prebuilt image?
- Is a Docker-less source-code deployment acceptable?
- Is the image Linux `amd64`?
- Is it built in the customer's pipeline or should `azd` build it?
- Which ACR contains the image?
- Is the image pinned by tag or digest?
- What scanning, signing, and base-image requirements apply?

### Runtime contract

- Which protocol does the workload implement: Responses, Invocations, or A2A?
- Does it listen on port `8088`?
- Does the selected protocol library expose `/readiness`?
- What starts the server?
- What CPU and memory does it need?
- Does it write state outside `$HOME`?

### Dependencies and identity

- Which Foundry project and model deployment will it use?
- Which downstream Azure resources must the agent call?
- Which RBAC roles must be assigned to the dedicated agent identity?
- Does the Foundry project identity have pull access to the image registry?
- Are there non-Azure APIs that require project connections or secrets?
- Does the runtime require outbound internet or private network access?

### Operations

- What is the success criterion for the first deployment?
- Who owns ACR push permissions and hosted-agent deployment permissions?
- Where should logs and traces be reviewed?
- What is the rollback plan if a new agent version fails?

## Demonstration sequence

1. Show `main.py` and identify the protocol adapter and agent logic.
2. Choose `azd`, the Python SDK, or REST API and explain why that interface
   fits the customer's release workflow.
3. For a container path, show the Dockerfile and identify `linux/amd64`, port
   `8088`, dependencies, non-root user, and `$HOME`.
4. Run `scripts/test-image.ps1` to prove the image contract locally.
5. Show the interface-specific definition: `azure.yaml`, the Python SDK
   `HostedAgentDefinition`, or the REST request body.
6. Deploy and poll the version to `active`.
7. Invoke the deployed agent.
8. Stream logs or inspect Application Insights.
9. Explain that the next deployment creates a new version.

## Prebuilt-image decision

Use the checked-in Dockerfile path when the agent team owns both source and
deployment. Use a prebuilt ACR image when another pipeline owns building,
scanning, signing, and publishing the artifact.

For a prebuilt image, add an `image` field to the `azure.ai.agent` service and
prefer a digest:

```yaml
image: myregistry.azurecr.io/agents/my-agent@sha256:<digest>
```

The customer must arrange:

- Developer access for the selected build or push path.
- Pull access for the Foundry project identity and a managed-identity ACR
  project connection.
- Network reachability from the Foundry runtime to a private ACR.

## Source-code decision

Choose source-code deployment when the team wants a Docker-less inner loop and
can use Foundry's supported runtime and dependency-resolution model. With
`remote_build`, Foundry installs dependencies from the uploaded source archive;
with `bundled`, the team ships prebuilt Linux dependencies. Source-code and
container configurations cannot coexist on the same agent version.

See [Microsoft's ACR deployment guide][acr-docs] for the current role matrix and
network constraints.

## Definition of done

Do not end at "deployment succeeded." Confirm:

- The version status is active.
- The agent endpoint invokes successfully with a real prompt.
- The expected model and downstream tools are reached through the agent
  identity.
- Logs and traces are visible to the operations team.
- A second version can be deployed without deleting the first.
- The team knows how to roll back or reroute traffic.

[acr-docs]: https://learn.microsoft.com/azure/foundry/agents/how-to/deploy-hosted-agent-private-azure-container-registry
