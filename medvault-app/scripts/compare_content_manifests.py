#!/usr/bin/env python3
"""Compare two Clinical Crumbs content manifests by stable UUID."""

import argparse
import json
from pathlib import Path


def load_manifest(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"Cannot read manifest {path}: {exc}") from exc

    if not isinstance(data, dict) or data.get("schemaVersion") != 1:
        raise ValueError(f"Unsupported or invalid manifest: {path}")

    version = data.get("contentVersion")
    if not isinstance(version, int) or isinstance(version, bool) or version < 1:
        raise ValueError(f"Invalid contentVersion in {path}")

    for collection in ("resources", "taxonomy"):
        entries = data.get(collection)
        if not isinstance(entries, list):
            raise ValueError(f"Manifest {path} has no valid {collection} list")

        seen = set()
        for entry in entries:
            if not isinstance(entry, dict):
                raise ValueError(f"Invalid {collection} entry in {path}")
            uuid = entry.get("uuid")
            if not isinstance(uuid, str) or not uuid:
                raise ValueError(f"Missing UUID in {collection} entry in {path}")
            if uuid in seen:
                raise ValueError(f"Duplicate UUID {uuid} in {collection} of {path}")
            seen.add(uuid)

    return data


def compare_entries(old_entries, new_entries):
    old_by_uuid = {entry["uuid"]: entry for entry in old_entries}
    new_by_uuid = {entry["uuid"]: entry for entry in new_entries}

    added = []
    changed = []
    unchanged = []
    retired = []

    for uuid in sorted(new_by_uuid.keys() - old_by_uuid.keys()):
        added.append({"uuid": uuid, "new": new_by_uuid[uuid]})

    for uuid in sorted(old_by_uuid.keys() & new_by_uuid.keys()):
        old = old_by_uuid[uuid]
        new = new_by_uuid[uuid]
        if old == new:
            unchanged.append({"uuid": uuid})
        else:
            changed.append({"uuid": uuid, "old": old, "new": new})

    for uuid in sorted(old_by_uuid.keys() - new_by_uuid.keys()):
        retired.append({"uuid": uuid, "old": old_by_uuid[uuid]})

    return {
        "added": added,
        "changed": changed,
        "unchanged": unchanged,
        "retired": retired,
    }


def summarize(result):
    return {
        status: len(entries)
        for status, entries in result.items()
    }


def render_markdown_report(report):
    lines = [
        "# Clinical Crumbs Content Release Review",
        "",
        f"- **Previous content version:** {report['oldContentVersion']}",
        f"- **New content version:** {report['newContentVersion']}",
        "",
        "> **Retirement safety:** Retired items are no longer published in the new release. "
        "This report does not authorize deleting existing local content, bookmarks, or reading progress.",
        "",
    ]

    for collection in ("resources", "taxonomy"):
        title = "Resources (PDFs)" if collection == "resources" else "Taxonomy"
        lines.extend([f"## {title}", ""])
        summary = report["summary"][collection]
        lines.append(
            " | ".join(
                f"**{status.title()}:** {summary[status]}"
                for status in ("added", "changed", "unchanged", "retired")
            )
        )
        lines.append("")

        entries = report[collection]
        for status in ("added", "changed", "retired"):
            items = entries[status]
            if not items:
                continue
            lines.extend([f"### {status.title()}", ""])
            for item in items:
                uuid = item["uuid"]
                details = item.get("new", item.get("old", {}))
                label = details.get("title") or details.get("slug") or uuid
                lines.append(f"- **{label}** (`{uuid}`)")
                if status == "changed":
                    old_details = item["old"]
                    new_details = item["new"]
                    for field in sorted(set(old_details) | set(new_details)):
                        if old_details.get(field) != new_details.get(field):
                            lines.append(
                                f"  - `{field}`: `{old_details.get(field, '(absent)')}` "
                                f"→ `{new_details.get(field, '(absent)')}`"
                            )
            lines.append("")

    return "\n".join(lines).rstrip() + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Classify content changes between two versioned manifests."
    )
    parser.add_argument("old_manifest", type=Path)
    parser.add_argument("new_manifest", type=Path)
    parser.add_argument(
        "--output",
        type=Path,
        help="Optional path for a JSON report; refuses to overwrite an existing file.",
    )
    parser.add_argument(
        "--markdown-output",
        type=Path,
        help="Optional path for a human-readable Markdown release review; refuses to overwrite.",
    )
    args = parser.parse_args()

    try:
        old = load_manifest(args.old_manifest)
        new = load_manifest(args.new_manifest)

        if new["contentVersion"] <= old["contentVersion"]:
            raise ValueError(
                "The new manifest's contentVersion must be greater than the old "
                "manifest's version."
            )

        report = {
            "schemaVersion": 1,
            "oldContentVersion": old["contentVersion"],
            "newContentVersion": new["contentVersion"],
            "retirementPolicy": {
                "meaning": "Retired items are no longer published in the new release.",
                "deleteExistingLocalContent": False,
                "preserveBookmarksAndReadingProgress": True,
                "requiresExplicitUserActionToDelete": True,
            },
            "resources": compare_entries(old["resources"], new["resources"]),
            "taxonomy": compare_entries(old["taxonomy"], new["taxonomy"]),
        }
        report["summary"] = {
            "resources": summarize(report["resources"]),
            "taxonomy": summarize(report["taxonomy"]),
        }

        rendered = json.dumps(report, indent=2, ensure_ascii=False) + "\n"

        if args.output:
            if args.output.exists():
                raise ValueError(f"Refusing to overwrite report: {args.output}")
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(rendered, encoding="utf-8")

        if args.markdown_output:
            if args.markdown_output.exists():
                raise ValueError(
                    f"Refusing to overwrite Markdown report: {args.markdown_output}"
                )
            args.markdown_output.parent.mkdir(parents=True, exist_ok=True)
            args.markdown_output.write_text(
                render_markdown_report(report), encoding="utf-8"
            )

        print(rendered, end="")

    except ValueError as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
