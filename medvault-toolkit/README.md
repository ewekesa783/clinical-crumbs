# MedVault Toolkit

Author-side and maintainer-side tooling for producing and validating curriculum content packs consumed by `medvault-app`.

## Requirements

- Dart SDK compatible with `pubspec.yaml`.
- The sibling `medvault-shared` package.

## Setup

Run `dart pub get` from this directory.

## Commands

Show help:

`dart run bin/medvault_toolkit.dart help`

Validate a curriculum pack:

`dart run bin/medvault_toolkit.dart validate path/to/pack.json`

Validation reads the JSON file and reports whether its structure and references satisfy the shared curriculum-pack contract. The input file is not modified.

## What validation checks

- Supported pack-format version and required manifest fields.
- Taxonomy identifiers, node types, parent references, and hierarchy cycles.
- Note identifiers, supported modes, topic references, tags, and citation references.
- Citation identifiers, source types, publication years, and URL format.

Structural validation does **not** assess medical accuracy, completeness, or clinical safety. Content authors remain responsible for reviewing and approving their material.

## Exit codes

| Code | Meaning |
| ---: | --- |
| `0` | Pack is structurally valid. |
| `1` | Pack content is invalid or malformed. |
| `64` | Invalid command usage. |
| `66` | Pack file not found. |
| `74` | Pack file could not be read. |

## Development checks

- Run tests: `dart test`
- Run static analysis: `dart analyze`

The CLI tests use synthetic, non-medical fixtures.

## Current scope

The current implementation provides the versioned shared pack contract, structural validation, and a validation CLI. Pack authoring workflows, app-side import and persistence, and publishing infrastructure are separate steps and are not implemented by this CLI yet.
