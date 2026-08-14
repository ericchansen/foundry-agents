import re
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]
MODULES = ROOT / "docs" / "course" / "modules"
COURSE_SEQUENCE = [
    "00-baseline",
    "01-runtime-contract",
    "02-model-and-identity",
    "03-custom-image",
    "04-bicep",
    "05-azd",
    "06-lifecycle",
    "07-prebuilt-acr",
    "10-python-sdk",
    "11-rest-api",
    "12-source-code",
    "08-troubleshooting",
    "09-capstone",
]


def read_front_matter(path):
    text = path.read_text(encoding="utf-8")
    parts = text.split("---", 2)
    if len(parts) != 3 or parts[0].strip():
        raise AssertionError(f"{path} is missing YAML front matter.")

    metadata = {}
    for line in parts[1].splitlines():
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        metadata[key.strip()] = value.strip().strip('"')
    return metadata, parts[2]


class CourseStructureTests(unittest.TestCase):
    def test_all_modules_exist(self):
        actual = {path.stem for path in MODULES.glob("*.md")}
        self.assertEqual(set(COURSE_SEQUENCE), actual)

    def test_each_module_has_active_learning_sections(self):
        required_sections = {
            "diagnose",
            "predict",
            "perform",
            "teach back",
            "checkpoint",
        }

        for module_name in COURSE_SEQUENCE:
            lesson = MODULES / f"{module_name}.md"
            _, text = read_front_matter(lesson)
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
        course = (ROOT / "docs" / "course" / "index.md").read_text(encoding="utf-8")
        for module_name in COURSE_SEQUENCE:
            self.assertIn(f"/course/modules/{module_name}/", course)

    def test_module_navigation_matches_learning_sequence(self):
        for order, module_name in enumerate(COURSE_SEQUENCE):
            path = MODULES / f"{module_name}.md"
            metadata, _ = read_front_matter(path)
            self.assertEqual(str(order), metadata.get("course_order"), path)
            self.assertEqual(
                f"/course/modules/{module_name}/",
                metadata.get("permalink"),
                path,
            )

            previous_url = metadata.get("previous_url")
            expected_previous = (
                f"/course/modules/{COURSE_SEQUENCE[order - 1]}/"
                if order
                else None
            )
            self.assertEqual(expected_previous, previous_url, path)

            next_url = metadata.get("next_url")
            expected_next = (
                f"/course/modules/{COURSE_SEQUENCE[order + 1]}/"
                if order + 1 < len(COURSE_SEQUENCE)
                else None
            )
            self.assertEqual(expected_next, next_url, path)

    def test_internal_pages_links_resolve(self):
        permalinks = {"/"}
        docs = ROOT / "docs"
        for path in docs.rglob("*.md"):
            metadata, _ = read_front_matter(path)
            permalink = metadata.get("permalink")
            if permalink:
                permalinks.add(permalink)
            elif path.parent == docs:
                permalinks.add(f"/{path.stem}/")

        link_pattern = re.compile(
            r"\{\{\s*'([^']+)'\s*\|\s*relative_url\s*\}\}"
        )
        for path in docs.rglob("*.md"):
            text = path.read_text(encoding="utf-8")
            for match in link_pattern.finditer(text):
                target = match.group(1).split("#", 1)[0]
                self.assertIn(target, permalinks, f"{path} links to {target}")

    def test_pages_do_not_link_to_unpublished_repository_paths(self):
        docs = ROOT / "docs"
        for path in docs.rglob("*.md"):
            text = path.read_text(encoding="utf-8")
            self.assertNotRegex(
                text,
                r"\]\(\.\./",
                f"{path} links outside the published docs source",
            )

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
