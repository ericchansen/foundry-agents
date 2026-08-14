---
title: Overview
description: Build, deploy, and operate custom-image Microsoft Foundry hosted agents.
---

# Foundry hosted-agent lab

This site is the practical reference for the custom-image hosted-agent lab. It
distills the deployment contract, identity boundaries, commands, and diagnostic
workflow that accompany the hands-on course.

## Start with the right page

| Goal | Read |
| --- | --- |
| Check a custom image before deployment | [Hosted agent requirements]({{ '/hosted-agent-requirements/' | relative_url }}) |
| Decide whether hosted agents fit the workload | [Hosted agents]({{ '/hosted-agents/' | relative_url }}) |
| Understand platform, image, protocol, and identity responsibilities | [Mental model]({{ '/mental-model/' | relative_url }}) |
| Build, provision, deploy, invoke, and inspect an agent | [Command cheat sheet]({{ '/cheat-sheet/' | relative_url }}) |
| Diagnose a failed build, deployment, or request | [Troubleshooting playbook]({{ '/troubleshooting-playbook/' | relative_url }}) |
| Lead a customer discovery and demonstration | [Customer walkthrough]({{ '/customer-walkthrough/' | relative_url }}) |

## Lab source

The [repository](https://github.com/ericchansen/foundry-agents) includes the
instructor-led course, runnable custom-image sample, Bicep infrastructure, and
deployment scripts. Start the guided sequence from
[COURSE.md](https://github.com/ericchansen/foundry-agents/blob/main/COURSE.md).

## Official sources

- [Hosted agents in Foundry Agent Service](https://learn.microsoft.com/azure/foundry/agents/concepts/hosted-agents)
- [Introducing hosted agents in Foundry Agent Service](https://devblogs.microsoft.com/foundry/introducing-the-new-hosted-agents-in-foundry-agent-service-secure-scalable-compute-built-for-agents/)
