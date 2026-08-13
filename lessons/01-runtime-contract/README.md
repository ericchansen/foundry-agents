# Module 1: The Responses runtime contract

## Objective

Prove the hosted-agent protocol contract locally before adding Azure or model
complexity.

## Example

Use [`examples/01-echo-agent`](../../examples/01-echo-agent).

## Diagnose

Before opening `main.py`, answer:

1. What is the minimum code needed to become a hosted agent?
2. Who creates `/readiness`?
3. Does a valid protocol response require a model?

## Predict

Inspect only the filenames, not their contents. Predict:

- Which package owns the HTTP server.
- Which process listens on port `8088`.
- What JSON will come back from an echo request.

Record the prediction in the Copilot conversation.

## Perform

Read `main.py`, `requirements.txt`, and `Dockerfile` in that order. Then build:

```powershell
docker build --platform linux/amd64 `
  --tag foundry-course-echo:local `
  .\examples\01-echo-agent
```

Run:

```powershell
docker run --detach --name foundry-course-echo `
  --publish 18088:8088 `
  foundry-course-echo:local
```

Collect evidence:

```powershell
Invoke-WebRequest http://127.0.0.1:18088/readiness

$body = @{ input = "What boundary are you testing?"; stream = $false } |
  ConvertTo-Json
Invoke-RestMethod http://127.0.0.1:18088/responses `
  -Method Post -ContentType application/json -Body $body |
  ConvertTo-Json -Depth 20
```

Clean up only your course container:

```powershell
docker rm --force foundry-course-echo
```

## Inspect

Find these protocol events in the response:

- Response created
- Output item
- Output text
- Response completed

Explain why returning only `{"answer":"..."}` would not satisfy the Responses
contract.

## Exercise

Change the echo prefix to include the process user and one environment variable.
Rebuild and prove the response changed.

Do not use the answer key until the new response is visible.

## Debug

Send the same payload to `/invocations`. Predict the status code before running
the request. Explain which layer rejected it.

Then stop the container and predict what happens to `/readiness`.

## Teach back

Explain why the echo image is a valid hosted-agent image even though it has no
model, tools, or Azure credentials.

## Checkpoint

Advance only when:

- `/readiness` returns HTTP 200.
- `/responses` returns a completed protocol response.
- You can identify the code that handles business logic versus protocol logic.
