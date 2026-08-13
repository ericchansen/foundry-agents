# Module 3: Build the custom image

## Objective

Understand and verify every property of the artifact that Foundry will run.

## Diagnose

Without opening the capstone Dockerfile, list the properties you think Foundry
requires from an image.

## Predict

Read [`src/agent/Dockerfile`](../../src/agent/Dockerfile) one instruction at a
time. Before moving to the next instruction, state:

- What filesystem or metadata change it makes.
- Whether the change affects build time or runtime.
- Which user owns the resulting files.
- Whether the value can safely appear in image history.

## Perform

Run the capstone smoke test:

```powershell
.\scripts\test-image.ps1
```

Then inspect the artifact yourself:

```powershell
docker image inspect custom-image-hosted-agent-lab:local `
  --format "OS={{.Os}} Arch={{.Architecture}} User={{.Config.User}}"

docker image inspect custom-image-hosted-agent-lab:local `
  --format "Ports={{json .Config.ExposedPorts}} Health={{json .Config.Healthcheck}}"

docker history custom-image-hosted-agent-lab:local
```

## Inspect

Confirm:

- OS is `linux`.
- Architecture is `amd64`.
- Runtime user is `agent`.
- Port `8088` is exposed.
- The health check calls `/readiness`.
- No credential or access token appears in image history.

## Exercise

Explain why each of these choices exists:

1. `PYTHONDONTWRITEBYTECODE=1`
2. `PYTHONUNBUFFERED=1`
3. `PIP_NO_CACHE_DIR=1`
4. A non-root runtime user
5. `HOME=/home/agent`
6. An explicit package index build argument

Use the answer key only for items you cannot explain after inspecting the
resulting image.

## Debug

For each change, predict the failure before trying it:

- Build without `--platform linux/amd64` on an ARM workstation.
- Change the published host port but not the container port.
- Remove the protocol package.
- Put a credential in `ARG` or `ENV`.

Do not commit an intentionally insecure Dockerfile.

## Teach back

Explain the difference between "the image built successfully" and "the image
satisfies the hosted-agent runtime contract."

## Checkpoint

Advance only when you can reproduce all six inspection facts and explain where
each is declared.
