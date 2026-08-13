---
title: Customer walkthrough
description: Run hosted-agent discovery and demonstration conversations with customers.
---

# Customer walkthrough guide

Use this guide to turn a vague "deploy our custom image as an agent" request
into a concrete hosted-agent plan.

## Open the meeting

State the boundary clearly:

> A hosted agent runs your container on Foundry-managed infrastructure. You own
> the image, dependencies, protocol adapter, and agent logic. Foundry owns the
> endpoint, agent identity, scaling, session lifecycle, and version deployment.

Then confirm that the customer needs a hosted agent rather than a prompt agent
because they need to control the runtime or supply a container image.

## Discovery questions

### Image and build

- Where is the Dockerfile or prebuilt image?
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
2. Show the Dockerfile and identify `linux/amd64`, port `8088`, dependencies,
   non-root user, and `$HOME`.
3. Run `scripts/test-image.ps1` to prove the image contract locally.
4. Show `azure.yaml` and identify the project, image build context, protocol,
   environment variables, and resources.
5. Run `azd deploy`.
6. Run `azd ai agent show --output table`.
7. Invoke the deployed agent.
8. Stream logs with `azd ai agent monitor --follow`.
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
