import re
import unittest
from pathlib import Path

ROOT = Path(__file__).parents[1]


class CourseStructureTests(unittest.TestCase):
    def test_all_modules_exist(self):
        for module in range(10):
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
        }
        for path in expected:
            self.assertTrue(path.is_file(), f"Missing course example: {path}")

    def test_course_references_every_module(self):
        course = (ROOT / "COURSE.md").read_text(encoding="utf-8")
        for module in range(10):
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


if __name__ == "__main__":
    unittest.main()
