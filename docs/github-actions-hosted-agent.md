---
title: GitHub Actions deployment
description: Configure OIDC deployment for the root custom-image hosted agent.
permalink: /github-actions-hosted-agent/
section: reference
---

# GitHub Actions deployment for the root hosted agent

`.github/workflows/deploy-hosted-agent.yml` rebuilds and deploys only the root
`custom-image-hosted-agent-lab` after qualifying pushes to `main` or a manual
run. It uses the root `azure.yaml`; it does not deploy the prebuilt-image
example. The workflow serializes releases, validates the root agent image and
checked-in Bicep, deploys with `azd`, displays agent status, and sends a fixed
Responses-protocol smoke prompt.

The workflow is intentionally excluded from documentation-only and
infrastructure-only changes. It runs only when `azure.yaml`, `src/agent/`, or
the workflow itself changes.

## Required GitHub Actions variables

Create the following non-secret repository-level GitHub Actions variables. Do
not put these values in repository files.

| Variable | Required value |
| --- | --- |
| `AZURE_CLIENT_ID` | Client ID output for the GitHub Actions user-assigned managed identity. |
| `AZURE_TENANT_ID` | Microsoft Entra tenant ID that owns the identity. |
| `AZURE_SUBSCRIPTION_ID` | Subscription ID containing the existing Foundry project and ACR. |
| `AZURE_LOCATION` | Location of the existing Foundry environment. |
| `AZURE_RESOURCE_GROUP` | Resource group containing the existing Foundry account, project, and ACR. |
| `AZURE_CONTAINER_REGISTRY_ENDPOINT` | Existing ACR login server endpoint, such as `<registry>.azurecr.io`. |
| `AZURE_CONTAINER_REGISTRY_RESOURCE_ID` | Existing ACR resource ID. |
| `FOUNDRY_PROJECT_ENDPOINT` | Existing Foundry project endpoint. |
| `AZURE_AI_PROJECT_ID` | Existing Foundry project resource ID. |
| `FOUNDRY_MODEL_DEPLOYMENT_NAME` | Existing model deployment name used by the root agent. It must match the deployed project configuration. |
| `AZD_ENV_NAME` | Stable `azd` environment name reserved for this workflow. |

These identifiers are not credentials. The workflow has `id-token: write` and
uses GitHub's short-lived OIDC token with `azure/login`; it requires no Azure
client secret.

## One-time Azure bootstrap

The checked-in Bicep can create the deployment identity without changing the
existing local developer principal path. Use a principal that can create
managed identities and role assignments, such as an Owner or Role Based Access
Control Administrator at the required scopes.

1. Select the existing `azd` environment and set `ENABLE_GITHUB_ACTIONS_IDENTITY=true`.
2. Run `azd provision` from the repository root. This is idempotent for the existing environment and creates `id-<environment>-github-actions`.
3. Copy the `GITHUB_ACTIONS_CLIENT_ID` output to `AZURE_CLIENT_ID` and record the tenant and subscription IDs as the corresponding Actions variables.
4. Add the remaining existing-environment values to the Actions variables table above, then run the workflow manually once.

The bootstrap creates a user-assigned managed identity with one federated
credential constrained to `repo:ericchansen@5395779/foundry-agents@1333280174:ref:refs/heads/main`.
It trusts only issuer `https://token.actions.githubusercontent.com` and audience
`api://AzureADTokenExchange`.

The identity receives **Foundry Project Manager** on the Foundry project and
**Container Registry Tasks Contributor** on the associated ACR. Those are the
same narrowly scoped build-and-agent roles already used by this infrastructure;
the bootstrap does not grant subscription or resource-group Contributor and
does not replace local developer role assignments.

## Operating model and limitation

`azd deploy` can create and activate the hosted-agent version in one operation.
The workflow's fixed smoke request verifies the active Responses endpoint
after that operation, so it is automatic demo promotion rather than a genuine
pre-activation approval gate. Use a staged SDK or REST release process if a
production policy requires a candidate version to be tested before activation.

The workflow assumes the existing project, model deployment, ACR connection,
and quota are healthy. It deliberately does not run `azd provision`, so it
cannot repair missing infrastructure or grant additional permissions during a
release.

The root `custom-image-agent` service is a Docker source-build service. Each
successful `azd deploy --no-prompt` rebuilds the image from `src/agent/`,
publishes it to the configured existing ACR, and deploys the resulting image as
the hosted-agent version. The ACR endpoint and resource ID variables are
therefore required even though the workflow does not provision or modify the
registry itself.

Review the workflow source in
[`deploy-hosted-agent.yml`](https://github.com/ericchansen/foundry-agents/blob/main/.github/workflows/deploy-hosted-agent.yml).

## References

- [Hosted agent CI/CD template](https://learn.microsoft.com/azure/foundry/agents/quickstarts/set-up-cicd-hosted-agent)
- [Authenticate GitHub Actions to Azure with OIDC](https://learn.microsoft.com/azure/developer/github/connect-from-azure-openid-connect)
- [Federated credential Bicep resource](https://learn.microsoft.com/azure/templates/microsoft.managedidentity/userassignedidentities/federatedidentitycredentials)
