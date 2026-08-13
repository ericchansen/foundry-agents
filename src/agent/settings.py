import os
from dataclasses import dataclass

_TRUE_VALUES = {"1", "true", "yes", "on"}
_FALSE_VALUES = {"0", "false", "no", "off"}


def _read_bool(name: str, default: bool = False) -> bool:
    raw = os.getenv(name)
    if raw is None:
        return default

    normalized = raw.strip().lower()
    if normalized in _TRUE_VALUES:
        return True
    if normalized in _FALSE_VALUES:
        return False

    choices = ", ".join(sorted(_TRUE_VALUES | _FALSE_VALUES))
    raise RuntimeError(f"{name} must be one of: {choices}.")


def _first_value(*names: str) -> str:
    for name in names:
        value = os.getenv(name, "").strip()
        if value:
            return value
    return ""


@dataclass(frozen=True)
class Settings:
    project_endpoint: str
    model_deployment_name: str
    agent_instructions: str
    local_echo_mode: bool

    @classmethod
    def from_env(cls) -> "Settings":
        local_echo_mode = _read_bool("LOCAL_ECHO_MODE")
        project_endpoint = _first_value("FOUNDRY_PROJECT_ENDPOINT")
        model_deployment_name = _first_value(
            "FOUNDRY_MODEL_NAME",
            "MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME",
            "AZURE_AI_MODEL_DEPLOYMENT_NAME",
        )

        if not local_echo_mode:
            missing = []
            if not project_endpoint:
                missing.append("FOUNDRY_PROJECT_ENDPOINT")
            if not model_deployment_name:
                missing.append("FOUNDRY_MODEL_NAME")
            if missing:
                joined = ", ".join(missing)
                raise RuntimeError(f"Missing required environment variable(s): {joined}.")

        return cls(
            project_endpoint=project_endpoint,
            model_deployment_name=model_deployment_name,
            agent_instructions=os.getenv(
                "AGENT_INSTRUCTIONS",
                "You are a concise assistant running inside a Microsoft Foundry "
                "hosted-agent container.",
            ),
            local_echo_mode=local_echo_mode,
        )
