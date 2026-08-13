---
title: Troubleshooting playbook
description: Diagnose Foundry hosted-agent failures from code through endpoint routing.
---

# Hosted-agent troubleshooting playbook

## Principle

Do not start with the portal error message and guess. Identify the failing
boundary, collect one piece of evidence, and move outward only when that layer
is healthy.

## Diagnostic ladder

| Layer | Question | Evidence |
| --- | --- | --- |
| Code | Does Python import and validate configuration? | `python -m compileall`, process stderr |
| Image | Is the artifact Linux `amd64` with the expected command? | `docker image inspect`, `docker history` |
| Process | Does the container stay running? | `docker ps -a`, `docker logs <id>` |
| Health | Does `/readiness` return 200 on container port 8088? | `Invoke-WebRequest` |
| Protocol | Does the declared endpoint accept the declared schema? | Raw `/responses` request |
| Identity | Can `DefaultAzureCredential` obtain the intended principal? | Azure SDK identity logs, principal inspection |
| Dependency | Does that principal have RBAC and network access? | Role assignment, dependency response |
| Version | Did Foundry create an active agent version? | `azd ai agent show` |
| Routing | Does the agent endpoint select that version? | Endpoint configuration and invocation |
| Observability | What failed inside the deployed request? | `azd ai agent monitor`, Application Insights |

## Symptom guide

### Image build fails while installing Python packages

Likely boundaries: build network, certificate trust, or package index.

Evidence:

```powershell
python -m pip config debug
docker build --progress plain --platform linux/amd64 .\src\agent
```

Do not use `--trusted-host` to hide a TLS problem. Use the approved
credential-free package proxy or install the required trust chain.

### Image runs locally but exits immediately

Likely boundaries: import, configuration, startup command.

Evidence:

```powershell
docker run --name agent-diagnostic `
  --env LOCAL_ECHO_MODE=true `
  custom-image-hosted-agent-lab:local

docker logs agent-diagnostic
docker rm --force agent-diagnostic
```

### `/readiness` never becomes healthy

Likely boundaries: wrong port, process crash, protocol server not started.

Check the container port, not only the host-published port. Foundry expects the
protocol server on container port `8088`.

### `/readiness` is healthy but `/responses` fails

Likely boundaries: request schema, handler exception, model call, or
authorization. Send a nonstreaming request locally and inspect the container
logs before escalating to Foundry.

### Model call returns 401 or 403

Likely boundaries: wrong principal, missing role, wrong resource scope.

Answer these separately:

1. Which principal acquired the token?
2. What resource audience is the token for?
3. What role does that principal have?
4. At what scope is the role assigned?

### Agent version remains provisioning

Likely boundaries: image pull, architecture, startup, or readiness.

Evidence:

```powershell
azd ai agent show
azd ai agent monitor --follow
```

Inspect the ACR project connection and pull access for the Foundry project
identity. Also confirm the image manifest includes Linux `amd64`.

### ACR returns 403

Separate the actors:

- The developer or build service needs push or ACR Tasks permissions.
- The Foundry project identity needs pull access and must be the credential on
  the ACR project connection.

Do not grant broad roles before identifying which actor failed.

## Evidence record

For each incident, record:

| Field | Value |
| --- | --- |
| Symptom | |
| First failing layer | |
| Command or query | |
| Observable evidence | |
| Root cause | |
| Smallest corrective action | |
| Prevention | |
