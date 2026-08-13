import re
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
INFRA = ROOT / "infra"


class InfrastructureTests(unittest.TestCase):
    def test_azure_yaml_uses_checked_in_bicep(self):
        manifest = (ROOT / "azure.yaml").read_text(encoding="utf-8")
        self.assertRegex(
            manifest,
            r"(?m)^infra:\n  provider: bicep\n  path: \./infra\n  module: main$",
        )

    def test_expected_resource_graph_is_declared(self):
        source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(INFRA.rglob("*.bicep"))
        )
        expected_types = {
            "Microsoft.CognitiveServices/accounts@2025-06-01",
            "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview",
            "Microsoft.ContainerRegistry/registries@2025-04-01",
            "Microsoft.OperationalInsights/workspaces@2025-07-01",
            "Microsoft.Insights/components@2020-02-02",
        }
        for resource_type in expected_types:
            self.assertIn(resource_type, source)

    def test_identity_roles_are_scoped_to_the_correct_principals(self):
        acr = (INFRA / "modules" / "acr.bicep").read_text(encoding="utf-8")
        resources = (INFRA / "modules" / "resources.bicep").read_text(
            encoding="utf-8"
        )
        self.assertIn("foundryProjectPrincipalId", acr)
        self.assertIn("projectAcrPull", acr)
        self.assertIn("developerAcrTasks", acr)
        self.assertIn("developerProjectManager", resources)

    def test_outputs_cover_azd_deployment_inputs(self):
        source = (INFRA / "main.bicep").read_text(encoding="utf-8")
        output_names = set(
            re.findall(r"^output\s+([A-Z0-9_]+)\s+", source, re.MULTILINE)
        )
        expected = {
            "AZURE_RESOURCE_GROUP",
            "AZURE_AI_ACCOUNT_ID",
            "AZURE_AI_PROJECT_ID",
            "AZURE_AI_PROJECT_NAME",
            "FOUNDRY_PROJECT_ENDPOINT",
            "AZURE_OPENAI_ENDPOINT",
            "AZURE_CONTAINER_REGISTRY_ENDPOINT",
            "AZURE_CONTAINER_REGISTRY_RESOURCE_ID",
            "AZURE_AI_PROJECT_ACR_CONNECTION_NAME",
            "APPLICATIONINSIGHTS_RESOURCE_ID",
            "APPLICATIONINSIGHTS_CONNECTION_STRING",
        }
        self.assertTrue(expected <= output_names)

    def test_bicep_does_not_model_agent_versions(self):
        source = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(INFRA.rglob("*.bicep"))
        ).lower()
        self.assertNotIn("azure.ai.agent", source)
        self.assertNotIn("agent version", source)


if __name__ == "__main__":
    unittest.main()
