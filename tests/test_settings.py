import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

AGENT_SOURCE = Path(__file__).parents[1] / "src" / "agent"
sys.path.insert(0, str(AGENT_SOURCE))

from settings import Settings  # noqa: E402


class SettingsTests(unittest.TestCase):
    def test_echo_mode_does_not_require_azure_configuration(self):
        with patch.dict(os.environ, {"LOCAL_ECHO_MODE": "true"}, clear=True):
            settings = Settings.from_env()

        self.assertTrue(settings.local_echo_mode)
        self.assertEqual("", settings.project_endpoint)
        self.assertEqual("", settings.model_deployment_name)

    def test_model_aliases_are_supported(self):
        for name in (
            "MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME",
            "FOUNDRY_MODEL_NAME",
            "AZURE_AI_MODEL_DEPLOYMENT_NAME",
        ):
            with self.subTest(name=name):
                environment = {
                    "FOUNDRY_PROJECT_ENDPOINT": "https://example.test/api/projects/lab",
                    name: "test-model",
                }

                with patch.dict(os.environ, environment, clear=True):
                    settings = Settings.from_env()

                self.assertEqual("test-model", settings.model_deployment_name)

    def test_missing_project_endpoint_is_reported(self):
        with patch.dict(
            os.environ,
            {"MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME": "test-model"},
            clear=True,
        ):
            with self.assertRaisesRegex(RuntimeError, "FOUNDRY_PROJECT_ENDPOINT"):
                Settings.from_env()

    def test_missing_model_is_reported(self):
        environment = {
            "FOUNDRY_PROJECT_ENDPOINT": "https://example.test/api/projects/lab",
        }

        with patch.dict(os.environ, environment, clear=True):
            with self.assertRaisesRegex(
                RuntimeError,
                "MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME",
            ):
                Settings.from_env()

    def test_invalid_echo_mode_is_reported(self):
        with patch.dict(os.environ, {"LOCAL_ECHO_MODE": "sometimes"}, clear=True):
            with self.assertRaisesRegex(RuntimeError, "LOCAL_ECHO_MODE"):
                Settings.from_env()


if __name__ == "__main__":
    unittest.main()
