# Module 5: Operate the environment with azd

## Objective

Use `azd` as the repeatable developer workflow while retaining visibility into
the Bicep and agent deployment layers.

## Diagnose

Explain the difference among:

- `azd provision`
- `azd deploy`
- `azd up`
- `azd ai agent run`
- `azd ai agent invoke`

Do not consult the cheat sheet until you have committed to an answer.

## Predict

Inspect `azure.yaml`. For every field, classify it as:

- Tool version contract
- Infrastructure configuration
- Service dependency
- Image build configuration
- Hosted-agent definition
- Runtime environment

## Perform

Upgrade the local toolchain if Module 0 reported a mismatch:

```powershell
winget upgrade Microsoft.Azd
azd ext install microsoft.foundry
azd ext upgrade microsoft.foundry
```

Create and configure an environment:

```powershell
azd auth login
azd env new <environment-name>
azd env set AZURE_LOCATION <location>
azd env set AZURE_SUBSCRIPTION_ID <subscription-id>
```

Run:

```powershell
azd provision
```

Compare its deployment with Module 4. Explain which Bicep deployment `azd`
invoked and where outputs were persisted.

Then deploy the agent:

```powershell
azd deploy
```

## Inspect

```powershell
azd env get-values
azd ai agent show --output table
```

Identify which outputs describe infrastructure and which describe the hosted
agent version.

## Exercise

Make an instruction-only change in `src/agent/settings.py`. Predict whether
`azd provision`, `azd deploy`, or both are required. Apply only the minimum
operation and prove the answer.

## Debug

Run the prerequisite script against an intentionally outdated tool-version
description from Module 0. Explain why version gating should fail before any
Azure mutation.

## Teach back

Explain why `azd` is an orchestrator rather than an alternative to Bicep.

## Checkpoint

Advance only when a second `azd provision` is idempotent and `azd deploy`
creates an active hosted-agent version.
