# Module 8: Troubleshooting lab

## Objective

Diagnose failures by boundary and evidence rather than by guesswork.

## Diagnose

Recreate the diagnostic ladder from memory. For each layer, name one command or
query that produces observable evidence.

## Predict

Before opening the playbook, rank the seven scenarios below from innermost
failure boundary to outermost failure boundary.

## Rules

For every scenario:

1. Predict the failing layer.
2. Write the first command you will run.
3. Collect evidence.
4. State the smallest corrective action.
5. Reproduce success after the correction.
6. Consult the answer key only after recording an attempt.

Use the [troubleshooting playbook](../../docs/troubleshooting-playbook.md).
The first four scenarios have opt-in, reversible local fixtures:

```powershell
.\scripts\run-failure-lab.ps1 -Scenario wrong-architecture
.\scripts\run-failure-lab.ps1 -Scenario wrong-port
.\scripts\run-failure-lab.ps1 -Scenario missing-readiness
.\scripts\run-failure-lab.ps1 -Scenario missing-configuration
```

Each run creates uniquely named Docker objects, checks for the expected
evidence, and cleans up only those objects.

## Perform

Work through every scenario and complete the evidence table.

## Scenario A: Wrong architecture

An image tag contains only an ARM manifest. Foundry cannot start it.

Prove the manifest architecture, explain why emulation on a developer
workstation can hide the problem, and identify the corrected build command.

## Scenario B: Wrong port

The process listens on `9090`, while the hosted runtime probes `8088`.

Identify the difference between a Docker host-port mapping and the container
listener. State why changing `EXPOSE` alone does not change the process port.

## Scenario C: Missing readiness

The process is running on `8088`, but `/readiness` returns 404.

Determine whether the business logic or protocol adapter owns the missing
endpoint.

## Scenario D: Missing model configuration

The container exits with a missing `MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME`
error.

Find where the value should be declared for local runs and deployed runs.

## Scenario E: Model authorization failure

Readiness is healthy, but the model call returns 403.

Identify the principal, resource, role, and scope before changing RBAC.

## Scenario F: Developer cannot push

The image build succeeds, but ACR push returns 403.

Identify the developer role required by the selected local or remote build
path.

## Scenario G: Runtime cannot pull

The agent version remains provisioning because Foundry cannot pull the image.

Identify the Foundry project identity, its ACR pull role, and the project
connection that uses it.

## Evidence table

| Scenario | First failing layer | First command | Evidence | Correction |
| --- | --- | --- | --- | --- |
| A | | | | |
| B | | | | |
| C | | | | |
| D | | | | |
| E | | | | |
| F | | | | |
| G | | | | |

## Teach back

Given a new symptom, narrate the diagnostic ladder before suggesting a fix.

## Checkpoint

Advance only when every row contains evidence and the instructor can substitute
one new failure without changing your method.
