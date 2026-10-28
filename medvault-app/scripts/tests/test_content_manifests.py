import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BUILD_SCRIPT = PROJECT_ROOT / "scripts" / "build_content_manifest.py"
COMPARE_SCRIPT = PROJECT_ROOT / "scripts" / "compare_content_manifests.py"


def run_script(script, *args):
    return subprocess.run(
        [sys.executable, str(script), *(str(arg) for arg in args)],
        text=True,
        capture_output=True,
        check=False,
    )


def resource(uuid, checksum, title="Example PDF"):
    return {
        "uuid": uuid,
        "topicUuid": "topic-1",
        "title": title,
        "archivePath": f"resources/pdfs/{uuid}.pdf",
        "fileSizeBytes": 5,
        "sha256": checksum,
    }


def taxonomy(uuid, checksum):
    return {"uuid": uuid, "sha256": checksum}


def manifest(version, resources, taxonomy_nodes=None):
    return {
        "schemaVersion": 1,
        "contentVersion": version,
        "taxonomy": taxonomy_nodes or [],
        "resources": resources,
    }


class ContentManifestTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="cc-content-manifest-tests-")
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def write_json(self, name, value):
        path = self.root / name
        path.write_text(json.dumps(value), encoding="utf-8")
        return path

    def test_compare_classifies_all_four_resource_changes(self):
        old = self.write_json(
            "old.json",
            manifest(1, [
                resource("same", "aaa"),
                resource("change", "bbb", "Old title"),
                resource("retire", "ccc"),
            ]),
        )
        new = self.write_json(
            "new.json",
            manifest(2, [
                resource("same", "aaa"),
                resource("change", "ddd", "New title"),
                resource("add", "eee"),
            ]),
        )

        result = run_script(COMPARE_SCRIPT, old, new)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(
            report["summary"]["resources"],
            {"added": 1, "changed": 1, "unchanged": 1, "retired": 1},
        )
        self.assertEqual(
            report["resources"]["changed"][0]["uuid"],
            "change",
        )
        self.assertEqual(
            report["retirementPolicy"],
            {
                "meaning": "Retired items are no longer published in the new release.",
                "deleteExistingLocalContent": False,
                "preserveBookmarksAndReadingProgress": True,
                "requiresExplicitUserActionToDelete": True,
            },
        )

    def test_markdown_release_review_includes_changes_and_retirement_warning(self):
        old = self.write_json(
            "old.json",
            manifest(1, [
                resource("change", "old-checksum", "Old title"),
                resource("retire", "retired-checksum", "Retired PDF"),
            ]),
        )
        new = self.write_json(
            "new.json",
            manifest(2, [
                resource("change", "new-checksum", "New title"),
                resource("add", "added-checksum", "Added PDF"),
            ]),
        )
        output = self.root / "release-review.md"

        result = run_script(
            COMPARE_SCRIPT,
            old,
            new,
            "--markdown-output",
            output,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        review = output.read_text(encoding="utf-8")
        self.assertIn("Previous content version:** 1", review)
        self.assertIn("New content version:** 2", review)
        self.assertIn("Retirement safety", review)
        self.assertIn("does not authorize deleting existing local content", review)
        self.assertIn("Added PDF", review)
        self.assertIn("Retired PDF", review)
        self.assertIn("Old title", review)
        self.assertIn("New title", review)
        self.assertIn("old-checksum", review)
        self.assertIn("new-checksum", review)

    def test_markdown_output_refuses_to_overwrite_existing_review(self):
        old = self.write_json("old.json", manifest(1, []))
        new = self.write_json("new.json", manifest(2, []))
        output = self.root / "existing-review.md"
        original = "# Preserve this review\\n"
        output.write_text(original, encoding="utf-8")

        result = run_script(
            COMPARE_SCRIPT, old, new, "--markdown-output", output
        )

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Refusing to overwrite Markdown report", result.stderr)
        self.assertEqual(output.read_text(encoding="utf-8"), original)


    def test_compare_classifies_taxonomy_changes(self):
        old = self.write_json(
            "old.json",
            manifest(1, [], [taxonomy("same", "aaa"), taxonomy("retire", "bbb")]),
        )
        new = self.write_json(
            "new.json",
            manifest(2, [], [taxonomy("same", "aaa"), taxonomy("add", "ccc")]),
        )

        result = run_script(COMPARE_SCRIPT, old, new)
        self.assertEqual(result.returncode, 0, result.stderr)
        report = json.loads(result.stdout)
        self.assertEqual(
            report["summary"]["taxonomy"],
            {"added": 1, "changed": 0, "unchanged": 1, "retired": 1},
        )

    def test_compare_rejects_non_increasing_version(self):
        old = self.write_json("old.json", manifest(2, []))
        new = self.write_json("new.json", manifest(2, []))

        result = run_script(COMPARE_SCRIPT, old, new)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("must be greater", result.stderr)

    def test_compare_rejects_duplicate_uuids(self):
        old = self.write_json(
            "old.json",
            manifest(1, [resource("duplicate", "aaa"), resource("duplicate", "bbb")]),
        )
        new = self.write_json("new.json", manifest(2, []))

        result = run_script(COMPARE_SCRIPT, old, new)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Duplicate UUID", result.stderr)

    def test_builder_generates_manifest_without_changing_source(self):
        source = self.root / "source.zip"
        output = self.root / "candidate.zip"
        pdf = b"%PDF-test"

        pack = {
            "manifest": {"packUuid": "pack-1", "version": 1},
            "taxonomyNodes": [{"uuid": "topic-1", "title": "Example"}],
            "notes": [],
            "citations": [],
        }
        html_bytes_io = __import__("io").BytesIO()
        with zipfile.ZipFile(html_bytes_io, "w") as lesson:
            lesson.writestr("index.html", "<html><body>Example lesson</body></html>")
        html_lesson = html_bytes_io.getvalue()

        metadata = [
            {
                "uuid": "pdf-1",
                "topicUuid": "topic-1",
                "title": "Example PDF",
                "format": "pdf",
                "archivePath": "resources/pdfs/pdf-1.pdf",
            },
            {
                "uuid": "lesson-1",
                "topicUuid": "topic-1",
                "title": "Example HTML lesson",
                "format": "htmlLesson",
                "archivePath": "resources/html_lessons/lesson-1.zip",
            },
        ]

        with zipfile.ZipFile(source, "w") as archive:
            archive.writestr("curriculum-pack.json", json.dumps(pack))
            archive.writestr("resources/metadata.json", json.dumps(metadata))
            archive.writestr("resources/pdfs/pdf-1.pdf", pdf)
            archive.writestr("resources/html_lessons/lesson-1.zip", html_lesson)

        original_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        result = run_script(
            BUILD_SCRIPT, source, output, "--content-version", "1"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            hashlib.sha256(source.read_bytes()).hexdigest(),
            original_hash,
        )

        with zipfile.ZipFile(output) as archive:
            generated = json.loads(archive.read("content-manifest.json"))
            self.assertEqual(generated["contentVersion"], 1)
            self.assertEqual(len(generated["taxonomy"]), 1)
            self.assertEqual(len(generated["resources"]), 2)
            by_uuid = {item["uuid"]: item for item in generated["resources"]}
            self.assertEqual(by_uuid["pdf-1"]["sha256"], hashlib.sha256(pdf).hexdigest())
            self.assertEqual(
                by_uuid["lesson-1"]["sha256"],
                hashlib.sha256(html_lesson).hexdigest(),
            )
            self.assertEqual(
                by_uuid["lesson-1"]["archivePath"],
                "resources/html_lessons/lesson-1.zip",
            )

    def test_builder_refuses_to_overwrite_source_or_existing_output(self):
        source = self.root / "source.zip"
        with zipfile.ZipFile(source, "w") as archive:
            archive.writestr("unused.txt", "test")

        same_path = run_script(BUILD_SCRIPT, source, source)
        self.assertNotEqual(same_path.returncode, 0)

        existing = self.root / "existing.zip"
        existing.write_bytes(b"keep me")
        result = run_script(BUILD_SCRIPT, source, existing)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(existing.read_bytes(), b"keep me")


if __name__ == "__main__":
    unittest.main(verbosity=2)
