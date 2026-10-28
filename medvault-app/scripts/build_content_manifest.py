#!/usr/bin/env python3
"""Build a versioned Clinical Crumbs content ZIP without modifying its source."""

import argparse
import hashlib
import json
import io
import zipfile
from pathlib import Path


MANIFEST_PATH = "content-manifest.json"
PACK_PATH = "curriculum-pack.json"
RESOURCE_METADATA_PATH = "resources/metadata.json"


def canonical_json(value):
    return json.dumps(
        value,
        ensure_ascii=False,
        sort_keys=True,
        separators=(",", ":"),
    ).encode("utf-8")


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def read_json(archive, path):
    try:
        return json.loads(archive.read(path).decode("utf-8"))
    except (KeyError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ValueError(f"Cannot read valid JSON from {path}: {exc}") from exc


def build_manifest(source, content_version):
    with zipfile.ZipFile(source, "r") as archive:
        names = archive.namelist()

        if len(names) != len(set(names)):
            raise ValueError("Source ZIP contains duplicate entry names.")

        pack = read_json(archive, PACK_PATH)
        resources = read_json(archive, RESOURCE_METADATA_PATH)

        if not isinstance(pack, dict) or not isinstance(pack.get("manifest"), dict):
            raise ValueError("Invalid curriculum-pack manifest.")
        if not isinstance(pack.get("taxonomyNodes"), list):
            raise ValueError("curriculum-pack.json has no taxonomyNodes list.")
        if not isinstance(resources, list):
            raise ValueError("resources/metadata.json must contain a list.")

        taxonomy_entries = []
        seen_taxonomy = set()

        for node in pack["taxonomyNodes"]:
            if not isinstance(node, dict) or not isinstance(node.get("uuid"), str):
                raise ValueError("Invalid taxonomy node or missing UUID.")
            uuid = node["uuid"]
            if uuid in seen_taxonomy:
                raise ValueError(f"Duplicate taxonomy UUID: {uuid}")
            seen_taxonomy.add(uuid)
            taxonomy_entries.append({
                "uuid": uuid,
                "sha256": sha256(canonical_json(node)),
            })

        resource_entries = []
        seen_resources = set()

        for resource in resources:
            if not isinstance(resource, dict):
                raise ValueError("Invalid resource metadata entry.")

            uuid = resource.get("uuid")
            path = resource.get("archivePath")
            topic_uuid = resource.get("topicUuid")
            resource_format = resource.get("format")

            if not isinstance(uuid, str) or not isinstance(topic_uuid, str):
                raise ValueError("Resource is missing a UUID or topic UUID.")
            if uuid in seen_resources:
                raise ValueError(f"Duplicate resource UUID: {uuid}")

            if resource_format == "pdf":
                expected_path = f"resources/pdfs/{uuid}.pdf"
            elif resource_format == "htmlLesson":
                expected_path = f"resources/html_lessons/{uuid}.zip"
            else:
                raise ValueError(
                    f"Unsupported resource format for {uuid}: {resource_format!r}."
                )

            if path != expected_path:
                raise ValueError(f"Unexpected archive path for resource {uuid}.")
            if path not in names:
                raise ValueError(f"Missing resource file for {uuid}: {path}.")

            resource_bytes = archive.read(path)
            if resource_format == "pdf":
                if not resource_bytes.startswith(b"%PDF-"):
                    raise ValueError(f"Invalid PDF signature for resource {uuid}.")
            else:
                try:
                    with zipfile.ZipFile(io.BytesIO(resource_bytes), "r") as lesson:
                        lesson_names = lesson.namelist()
                        if len(lesson_names) != len(set(lesson_names)):
                            raise ValueError(
                                f"HTML lesson {uuid} contains duplicate ZIP entries."
                            )
                        if "index.html" not in lesson_names:
                            raise ValueError(
                                f"HTML lesson {uuid} has no index.html entry."
                            )
                        lesson.read("index.html")
                except (zipfile.BadZipFile, OSError, KeyError) as exc:
                    raise ValueError(
                        f"Invalid HTML lesson ZIP for resource {uuid}: {exc}"
                    ) from exc

            seen_resources.add(uuid)
            resource_entries.append({
                "uuid": uuid,
                "topicUuid": topic_uuid,
                "title": resource.get("title"),
                "archivePath": path,
                "fileSizeBytes": len(resource_bytes),
                "sha256": sha256(resource_bytes),
            })

        if len(names) != len(set(names)):
            raise ValueError("Duplicate ZIP entries detected.")

        resource_paths = {entry["archivePath"] for entry in resource_entries}
        allowed_paths = {
            PACK_PATH,
            RESOURCE_METADATA_PATH,
            *resource_paths,
        }
        unexpected = set(names) - allowed_paths
        missing = allowed_paths - set(names)

        if unexpected or missing:
            raise ValueError(
                f"Unexpected entries: {sorted(unexpected)}; "
                f"missing entries: {sorted(missing)}"
            )

        return {
            "schemaVersion": 1,
            "contentVersion": content_version,
            "sourcePackUuid": pack["manifest"].get("packUuid"),
            "sourcePackVersion": pack["manifest"].get("version"),
            "taxonomy": sorted(taxonomy_entries, key=lambda item: item["uuid"]),
            "resources": sorted(resource_entries, key=lambda item: item["uuid"]),
        }


def main():
    parser = argparse.ArgumentParser(
        description="Add a generated versioned content manifest to a candidate ZIP."
    )
    parser.add_argument("source_zip", type=Path)
    parser.add_argument("output_zip", type=Path)
    parser.add_argument(
        "--content-version",
        type=int,
        default=1,
        help="Positive content release version (default: 1).",
    )
    args = parser.parse_args()

    if args.content_version < 1:
        parser.error("--content-version must be at least 1.")
    if not args.source_zip.is_file():
        parser.error(f"Source ZIP does not exist: {args.source_zip}")
    if args.source_zip.resolve() == args.output_zip.resolve():
        parser.error("Output must differ from source; source ZIP is never overwritten.")
    if args.output_zip.exists():
        parser.error(f"Output already exists; refusing to overwrite: {args.output_zip}")

    manifest = build_manifest(args.source_zip, args.content_version)
    manifest_bytes = json.dumps(
        manifest,
        ensure_ascii=False,
        indent=2,
        sort_keys=True,
    ).encode("utf-8") + b"\n"

    args.output_zip.parent.mkdir(parents=True, exist_ok=True)

    with zipfile.ZipFile(args.source_zip, "r") as source:
        with zipfile.ZipFile(args.output_zip, "x", compression=zipfile.ZIP_DEFLATED) as output:
            for entry in source.infolist():
                output.writestr(entry, source.read(entry.filename))
            output.writestr(MANIFEST_PATH, manifest_bytes)

    print(f"Candidate ZIP: {args.output_zip}")
    print(f"Content version: {manifest['contentVersion']}")
    print(f"Taxonomy entries: {len(manifest['taxonomy'])}")
    print(f"Resource entries: {len(manifest['resources'])}")
    print(f"Manifest SHA-256: {sha256(manifest_bytes)}")
    print("Source ZIP was not modified.")


if __name__ == "__main__":
    main()
