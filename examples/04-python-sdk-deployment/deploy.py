"""Deploy and verify a container-based hosted agent with the Python SDK."""

import argparse
import os
import sys
import time

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    AgentEndpointProtocol,
    ContainerConfiguration,
    HostedAgentDefinition,
    ProtocolVersionRecord,
)
from azure.identity import DefaultAzureCredential


def required_environment(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise RuntimeError(f"{name} must be set.")
    return value


def wait_for_active(project: AIProjectClient, agent_name: str, version: str) -> None:
    while True:
        version_info = project.agents.get_version(
            agent_name=agent_name,
            agent_version=version,
        )
        status = version_info["status"]
        print(f"Version {version}: {status}")
        if status == "active":
            return
        if status == "failed":
            raise RuntimeError(f"Provisioning failed: {version_info.get('error')}")
        time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--agent-name",
        default="python-sdk-hosted-agent-lab",
        help="Stable agent name; each run creates a new version.",
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Delete the named agent and all of its versions instead of deploying.",
    )
    args = parser.parse_args()

    project = AIProjectClient(
        endpoint=required_environment("FOUNDRY_PROJECT_ENDPOINT"),
        credential=DefaultAzureCredential(),
    )

    if args.delete:
        project.agents.delete(agent_name=args.agent_name)
        print(f"Deleted {args.agent_name}.")
        return

    image = required_environment("HOSTED_AGENT_IMAGE")
    model_deployment = required_environment("MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME")
    agent = project.agents.create_version(
        agent_name=args.agent_name,
        definition=HostedAgentDefinition(
            protocol_versions=[
                ProtocolVersionRecord(
                    protocol=AgentEndpointProtocol.RESPONSES,
                    version="2.0.0",
                )
            ],
            cpu="0.5",
            memory="1Gi",
            container_configuration=ContainerConfiguration(image=image),
            environment_variables={
                "MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME": model_deployment,
            },
        ),
    )
    print(f"Created {agent.name} version {agent.version}.")
    wait_for_active(project, args.agent_name, agent.version)

    response = project.get_openai_client(agent_name=args.agent_name).responses.create(
        input="Which deployment interface created you?",
    )
    print(response.output_text)


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(error, file=sys.stderr)
        raise SystemExit(1) from error
