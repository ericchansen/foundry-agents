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
        parameters = (INFRA / "main.bicepparam").read_text(encoding="utf-8")
        self.assertNotIn("AI_PROJECT_DEPLOYMENTS", parameters)
        self.assertIn("readEnvironmentVariable('AZURE_LOCATION')", parameters)
        self.assertFalse((INFRA / "main.parameters.json").exists())

    def test_agent_manifests_use_safe_model_configuration(self):
        manifests = {
            ROOT / "azure.yaml",
            ROOT / "examples" / "03-prebuilt-image" / "azure.yaml",
        }
        for manifest in manifests:
            source = manifest.read_text(encoding="utf-8")
            self.assertIn(
                "MICROSOFT_FOUNDRY_MODEL_DEPLOYMENT_NAME:",
                source,
            )
            self.assertNotIn("FOUNDRY_MODEL_NAME:", source)

    def test_prebuilt_and_source_examples_have_complete_manifests(self):
        prebuilt = (
            ROOT / "examples" / "03-prebuilt-image" / "azure.yaml"
        ).read_text(encoding="utf-8")
        source = (
            ROOT / "examples" / "06-source-code-deployment" / "azure.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("path: ../../infra", prebuilt)
        self.assertIn("path: ../../infra", source)
        self.assertIn("entryPoint: main.py", source)

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

    def test_optional_github_actions_identity_is_constrained_to_main(self):
        identity = (
            INFRA / "modules" / "github-actions-identity.bicep"
        ).read_text(encoding="utf-8")
        main = (INFRA / "main.bicep").read_text(encoding="utf-8")

        self.assertIn("Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31", identity)
        self.assertIn(
            "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30",
            identity,
        )
        self.assertIn("https://token.actions.githubusercontent.com", identity)
        self.assertIn(
            "repo:ericchansen@5395779/foundry-agents@1333280174:ref:refs/heads/main",
            identity,
        )
        self.assertIn("api://AzureADTokenExchange", identity)
        self.assertIn("enableGithubActionsIdentity", main)
        self.assertIn("GITHUB_ACTIONS_CLIENT_ID", main)
        self.assertIn("GITHUB_ACTIONS_PRINCIPAL_ID", main)
        self.assertIn("githubActionsAcrPush", identity)
        self.assertIn("acrPushRoleId", identity)
        self.assertIn("8311e382-0749-4cb8-b61a-304f252e45ec", identity)
        self.assertNotIn("githubActionsAcrTasksContributor", identity)
        self.assertNotIn("fb382eab-e894-4461-af04-94435c366c3f", identity)

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

    def test_root_hosted_agent_workflow_is_scoped_and_uses_oidc(self):
        workflow = (
            ROOT / ".github" / "workflows" / "deploy-hosted-agent.yml"
        ).read_text(encoding="utf-8")
        required_variables = (
            "AZURE_CLIENT_ID",
            "AZURE_TENANT_ID",
            "AZURE_SUBSCRIPTION_ID",
            "AZURE_LOCATION",
            "AZURE_RESOURCE_GROUP",
            "AZURE_CONTAINER_REGISTRY_ENDPOINT",
            "AZURE_CONTAINER_REGISTRY_RESOURCE_ID",
            "FOUNDRY_PROJECT_ENDPOINT",
            "AZURE_AI_PROJECT_ID",
            "FOUNDRY_MODEL_DEPLOYMENT_NAME",
            "AZD_ENV_NAME",
        )

        self.assertIn("branches: [main]", workflow)
        self.assertIn("      - azure.yaml", workflow)
        self.assertIn("      - src/agent/**", workflow)
        self.assertIn("      - .github/workflows/deploy-hosted-agent.yml", workflow)
        self.assertNotIn("      - infra/**", workflow)
        self.assertNotIn("      - docs/**", workflow)
        self.assertIn("workflow_dispatch:", workflow)
        self.assertIn("id-token: write", workflow)
        self.assertNotIn("environment: foundry-hosted-agent", workflow)
        self.assertIn("name: Validate required repository variables", workflow)
        self.assertIn("Missing required GitHub Actions repository variables", workflow)
        self.assertLess(
            workflow.index("name: Validate required repository variables"),
            workflow.index("name: Sign in to Azure with OIDC"),
        )
        for variable_name in required_variables:
            self.assertIn(f"{variable_name}: ${{{{ vars.{variable_name} }}}}", workflow)
            self.assertIn(f"            {variable_name}", workflow)
        self.assertIn(
            'azd env set AZURE_CONTAINER_REGISTRY_ENDPOINT "${{ vars.AZURE_CONTAINER_REGISTRY_ENDPOINT }}"',
            workflow,
        )
        self.assertIn(
            'azd env set AZURE_CONTAINER_REGISTRY_RESOURCE_ID "${{ vars.AZURE_CONTAINER_REGISTRY_RESOURCE_ID }}"',
            workflow,
        )
        self.assertIn("azure/login@v2", workflow)
        self.assertIn("auth.useAzCliAuth true", workflow)
        self.assertIn("azd deploy --no-prompt", workflow)
        self.assertIn("azd ai agent show --no-prompt --output table", workflow)
        self.assertNotIn("azd ai agent invoke", workflow)
        self.assertIn(
            "az account get-access-token --resource https://ai.azure.com",
            workflow,
        )
        self.assertIn(
            '${FOUNDRY_PROJECT_ENDPOINT%/}/agents/${AGENT_NAME}/endpoint/protocols/openai/responses?api-version=v1',
            workflow,
        )
        self.assertIn('jq --null-input --arg input "$AGENT_SMOKE_PROMPT"', workflow)
        self.assertIn("curl --silent --show-error", workflow)
        self.assertIn('.status == "completed"', workflow)
        self.assertIn('.type == "output_text"', workflow)


if __name__ == "__main__":
    unittest.main()
