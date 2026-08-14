import re
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]


class CourseStructureTests(unittest.TestCase):
    def test_all_modules_exist(self):
        for module in range(13):
            matches = list((ROOT / "lessons").glob(f"{module:02d}-*/README.md"))
            self.assertEqual(1, len(matches), f"Module {module} is missing or duplicated.")

    def test_each_module_has_active_learning_sections(self):
        required_sections = {
            "diagnose",
            "predict",
            "perform",
            "teach back",
            "checkpoint",
        }

        for lesson in sorted((ROOT / "lessons").glob("[0-9][0-9]-*/README.md")):
            text = lesson.read_text(encoding="utf-8")
            headings = {
                match.group(1).strip().lower()
                for match in re.finditer(r"^##\s+(.+)$", text, re.MULTILINE)
            }
            missing = {
                section
                for section in required_sections
                if not any(heading.startswith(section) for heading in headings)
            }
            self.assertTrue(
                not missing,
                f"{lesson} is missing {sorted(missing)}.",
            )

    def test_incremental_examples_exist(self):
        expected = {
            ROOT / "examples" / "01-echo-agent" / "main.py",
            ROOT / "examples" / "01-echo-agent" / "Dockerfile",
            ROOT / "examples" / "02-model-agent" / "main.py",
            ROOT / "examples" / "02-model-agent" / "Dockerfile",
            ROOT / "examples" / "03-prebuilt-image" / "azure.yaml",
            ROOT / "examples" / "04-python-sdk-deployment" / "deploy.py",
            ROOT / "examples" / "05-rest-deployment" / "deploy-hosted-agent.ps1",
            ROOT / "examples" / "06-source-code-deployment" / "azure.yaml",
            ROOT / "examples" / "06-source-code-deployment" / "agent" / "main.py",
        }
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing course example: {path}")

    def test_course_references_every_module(self):
        course = (ROOT / "COURSE.md").read_text(encoding="utf-8")
        for module in range(13):
            self.assertRegex(course, rf"lessons/{module:02d}-[^)]+/README\.md")

    def test_reversible_failure_fixtures_exist(self):
        expected = {
            ROOT / "failures" / "wrong-architecture" / "Dockerfile",
            ROOT / "failures" / "wrong-port" / "Dockerfile",
            ROOT / "failures" / "missing-readiness" / "Dockerfile",
            ROOT / "scripts" / "run-failure-lab.ps1",
        }
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing failure fixture: {path}")

    def test_missing_configuration_fixture_waits_for_container_exit(self):
        fixture = (ROOT / "scripts" / "run-failure-lab.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("function Wait-DockerContainerExit", fixture)
        self.assertIn(
            'Wait-DockerContainerExit -Name $containerName',
            fixture,
        )
        self.assertIn("$inspectOutput = & docker inspect", fixture)
        self.assertIn("last observed state: $state", fixture)

    def test_toolchain_selector_exists(self):
        selector = ROOT / "scripts" / "use-latest-azd.ps1"
        self.assertTrue(selector.is_file())
        prerequisites = (ROOT / "scripts" / "check-prerequisites.ps1").read_text(
            encoding="utf-8"
        )
        self.assertIn("use-latest-azd.ps1", prerequisites)

    def test_all_deployment_interfaces_have_runnable_examples(self):
        sdk = (ROOT / "examples" / "04-python-sdk-deployment" / "deploy.py").read_text(
            encoding="utf-8"
        )
        rest = (
            ROOT / "examples" / "05-rest-deployment" / "deploy-hosted-agent.ps1"
        ).read_text(encoding="utf-8")
        source_manifest = (
            ROOT / "examples" / "06-source-code-deployment" / "azure.yaml"
        ).read_text(encoding="utf-8")

        self.assertIn("project.agents.create_version", sdk)
        self.assertIn("project.agents.get_version", sdk)
        self.assertIn("/agents?api-version=", rest)
        self.assertIn("/endpoint/protocols/openai/responses", rest)
        self.assertIn("codeConfiguration:", source_manifest)
        self.assertIn("dependencyResolution: remote_build", source_manifest)


if __name__ == "__main__":
    unittest.main()
