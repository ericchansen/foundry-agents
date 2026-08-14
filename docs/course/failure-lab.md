---
title: Reversible local failure fixtures
description: Run isolated local fixtures for the hosted-agent troubleshooting module.
permalink: /course/failure-lab/
section: course
---

# Reversible local failure fixtures

These fixtures create evidence for the inner troubleshooting boundaries without
changing Azure resources. Run one scenario at a time:

```powershell
.\scripts\run-failure-lab.ps1 -Scenario wrong-architecture
.\scripts\run-failure-lab.ps1 -Scenario wrong-port
.\scripts\run-failure-lab.ps1 -Scenario missing-readiness
.\scripts\run-failure-lab.ps1 -Scenario missing-configuration
```

The script uses a unique image and container name, confirms the expected
failure, and removes only those temporary Docker objects. Predict the failing
layer and first evidence command before running it.

The authorization scenarios in Module 8 use the deployed environment. They are
inspection exercises rather than fixtures because removing live role
assignments would make a shared long-lived demo unreliable.
