# Module 0: Baseline and vocabulary

## Objective

Build the mental model needed to reason about every later command.

## Diagnose before reading

Answer these in the Copilot conversation without searching:

1. What makes a hosted agent different from a prompt agent?
2. Which parts of a hosted deployment are inside your image?
3. Which principal calls the model after deployment?
4. Why does Foundry need to know the agent protocol?
5. What would make a customer require a prebuilt-image workflow?

The instructor records misconceptions but does not correct them yet.

## Predict

Draw a box-and-arrow architecture with these labels:

- Caller
- Foundry agent endpoint
- Container
- Responses adapter
- Agent logic
- Model deployment
- Agent identity
- ACR

Predict which arrows carry HTTP, image bytes, and Entra authorization.

## Learn

Read [the mental model](../../docs/mental-model.md), then compare it with your
drawing. Correct your diagram in a different color or with annotations so the
change in understanding remains visible.

## Perform

Classify each item as **platform**, **image**, **protocol**, or **identity**:

| Item | Your classification |
| --- | --- |
| `/responses` request schema | |
| Python package versions | |
| Agent version routing | |
| Model inference authorization | |
| Port `8088` listener | |
| Image pull from ACR | |
| Session context | |
| Native operating-system library | |

## Debug

For each symptom, predict the first boundary you would inspect:

1. The image builds, but the agent version never becomes active.
2. `/readiness` is healthy, but model calls return 403.
3. The agent works locally but Foundry reports no compatible protocol.
4. Foundry cannot pull the image.

## Teach back

Explain the complete request path in fewer than ten sentences. You must use the
terms **agent version**, **protocol adapter**, **container**, and **agent
identity** correctly.

## Checkpoint

Advance only when you can:

- Draw the request path without the reference.
- Explain the three deployment paths.
- Identify the first troubleshooting boundary for all four symptoms.
