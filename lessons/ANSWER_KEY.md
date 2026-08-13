# Exercise answer key

Use this only after recording a prediction and an attempt. The instructor
should ask for your evidence before discussing an answer.

## Module 0

| Item | Boundary |
| --- | --- |
| `/responses` request schema | Protocol |
| Python package versions | Image |
| Agent version routing | Platform |
| Model inference authorization | Identity |
| Port `8088` listener | Protocol inside the image |
| Image pull from ACR | Platform using Foundry project identity authorization |
| Session context | Platform, surfaced through protocol context |
| Native operating-system library | Image |

The first boundary for the four symptoms is respectively startup/readiness,
identity/dependency, protocol declaration, and registry authorization/network.

## Module 1

`ResponsesAgentServerHost` owns the web server, `/responses`, `/readiness`, and
the Responses event lifecycle. The decorated handler owns the echo behavior.
Posting to undeclared `/invocations` should not succeed because that protocol
adapter was never registered.

## Module 2

The project endpoint and model deployment name are configuration. The token is
a credential and must never be stored in the image or manifest.
`DefaultAzureCredential` checks an ordered credential chain. Locally, the Azure
CLI or developer credential can satisfy it. In the hosted runtime, the
dedicated agent identity satisfies it. External resources need an explicit
role assignment at the narrowest useful scope.

## Module 3

- `PYTHONDONTWRITEBYTECODE` prevents runtime cache writes.
- `PYTHONUNBUFFERED` emits logs immediately.
- `PIP_NO_CACHE_DIR` avoids retaining package caches in the image.
- A non-root user reduces process privilege.
- `$HOME` is the platform-persisted writable location.
- The package index argument supports approved enterprise mirrors without
  embedding a credential.

`EXPOSE` is metadata; it does not cause the process to listen. A successful
build proves Dockerfile execution, not protocol, startup, architecture,
identity, or dependency behavior.

## Module 4

The infrastructure deployment owns stable Azure resources. The hosted-agent
extension creates agent versions because versions are application/data-plane
lifecycle objects tied to image releases, not stable resource-group
infrastructure.

## Module 5

- `provision` applies infrastructure.
- `deploy` builds or selects the image and creates the agent version.
- `up` performs both.
- `ai agent run` starts the local agent development experience.
- `ai agent invoke` calls the local or deployed agent.

An instruction-only code change requires `azd deploy`, not infrastructure
provisioning.

## Module 6

An agent is the stable named service. A version is an immutable deployment of
code/image and configuration. The endpoint routes requests to selected
versions. Preserving older versions enables traffic rerouting without
rebuilding an old artifact.

## Module 7

The developer or build pipeline needs permission to build/push. The Foundry
project identity needs permission to pull and is the credential on the ACR
project connection. The dedicated agent identity is instead used by runtime
code. Digest pinning remains stable even if a mutable tag moves.

## Module 8

| Scenario | First failing layer | Typical first evidence |
| --- | --- | --- |
| Wrong architecture | Image | Image manifest inspection |
| Wrong port | Process/health | Container listener and readiness probe |
| Missing readiness | Protocol | Direct `/readiness` request |
| Missing model configuration | Code/startup | Container stderr |
| Model 403 | Identity/dependency | Principal and role assignment |
| Developer push 403 | Build/registry authorization | Push response and developer role |
| Runtime pull failure | Platform/registry authorization | Version status, project connection, and project identity role |
