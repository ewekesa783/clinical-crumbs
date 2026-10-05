# MedVault — Jules Handover

> Status: RECONSTRUCTED HANDOVER
>
> This is a newly reconstructed handover document. The original historical
> docs/MedVault_Jules_Handover.md was lost during an environment reset.
> This document is not the original recovered handover.

## 1. Purpose

This document provides Jules with the verified state of the reconstructed
MedVault source tree and defines the boundary between completed work,
intentional absences, known gaps, and future implementation.

---

## 2. Repository Structure

The reconstructed project root is:


text
MedVault/
├── medvault-app/
├── medvault-shared/
├── medvault-toolkit/
├── medvault-infrastructure/
├── RECONSTRUCTION_MANIFEST.md
├── FINAL_DIRECTORY_INVENTORY.md
└── docs/
    └── MedVault_Jules_Handover.md



---

## 3. Reconstruction Status

### Completed

- Phase 0 / MV-IP-000 project skeleton
- MV-IP-001 / Core Data and Reading / Task Group A
- MV-IP-002 / Domain Services / Task Group A
- Generated Isar Dart files
- Dependency resolution
- Build-runner generation
- Static analysis
- Automated test execution
- Reconstruction manifest documentation
- Post-reconstruction validation record

### Not completed

- Full application build (flutter build)
- Non-library feature modules beyond the existing Phase 0 home placeholder
- Future application composition/root wiring
- Future features not represented in the reconstructed project

---

## 4. MV-IP-001 — Core Data and Reading

MV-IP-001 Task Group A is complete and frozen.

The library data layer contains five core collections:

1. TaxonomyNode
2. Note
3. Citation
4. Bookmark
5. History

Each follows the reconstructed domain/data/repository layering.

### 4.1 TaxonomyNode

Present:

- Domain entity
- Isar model
- Mapper
- Repository interface
- Isar repository
- Mapper/repository tests

Important implementation detail:

The repository intentionally uses Isar .filter() queries rather than .where() queries. This was preserved during validation.

Sibling slug uniqueness is enforced through a Dart-side duplicate check because the required generated equality helper was not available in the .filter() query section.

There is intentionally no getSiblings() method.

### 4.2 Note

Present:

- Domain entity
- Isar model
- Mapper
- Repository interface
- Isar repository
- Tests

The reconstructed model uses a composite unique index on (topicUuid, mode).

The mapper defensively copies list values when converting between domain and persistence representations.

### 4.3 Citation

Present:

- Domain entity
- SourceType
- Isar model
- Mapper
- Repository interface
- Isar repository
- Tests

getByUuids preserves input order and multiplicity while silently omitting missing UUIDs.

### 4.4 Bookmark

Present:

- Domain entity
- Isar model
- Mapper
- Repository interface
- Isar repository
- Tests

The noteUuid index is intentionally non-unique because a note may have multiple bookmark records in the reconstructed data model.

### 4.5 History

Present:

- Domain entity
- Isar model
- Mapper
- Repository interface
- Isar repository
- Tests

The noteUuid index is unique.

The repository method is getByNoteUuid.

The former name getMostRecentByNoteUuid is intentionally absent.

---

## 5. MV-IP-002 — Domain Services

MV-IP-002 Task Group A is complete and frozen.

There is currently no Task Group B defined in the governing project context.

### 5.1 LibraryService

The service depends on the five repository abstractions and uses injected:

- UUID generation
- Sync metadata generation
- Current time

Identity and synchronization metadata resolution are deliberately split into _uuidFor and _syncFor.

There is intentionally no combined _resolveIdentity helper.

The service provides the reconstructed library operations including:

- Retrieving topic notes
- Retrieving a note with citations
- Recording a note as viewed
- Checking bookmark state
- Bookmarking a note

### 5.2 TaxonomyNavigationService

The reconstructed service currently provides getBreadcrumbPath.

There is intentionally no getSiblings() method.

### 5.3 RecentlyViewedService

The service resolves a recently-viewed note to the narrowed DTO:


text
RecentlyViewedEntry {
  Note note
  DateTime viewedAt
}



The DTO intentionally does not expose the History entity.

---

## 6. Current Library File Inventory

The current library feature contains:


text
lib/features/library/
├── data/
│   ├── models/
│   │   ├── bookmark_mapper.dart
│   │   ├── bookmark_model.dart
│   │   ├── bookmark_model.g.dart
│   │   ├── citation_mapper.dart
│   │   ├── citation_model.dart
│   │   ├── citation_model.g.dart
│   │   ├── history_mapper.dart
│   │   ├── history_model.dart
│   │   ├── history_model.g.dart
│   │   ├── note_mapper.dart
│   │   ├── note_model.dart
│   │   ├── note_model.g.dart
│   │   ├── taxonomy_node_mapper.dart
│   │   ├── taxonomy_node_model.dart
│   │   └── taxonomy_node_model.g.dart
│   └── repositories/
│       ├── isar_bookmark_repository.dart
│       ├── isar_citation_repository.dart
│       ├── isar_history_repository.dart
│       ├── isar_note_repository.dart
│       └── isar_taxonomy_repository.dart
└── domain/
    ├── entities/
    │   ├── bookmark.dart
    │   ├── citation.dart
    │   ├── history.dart
    │   ├── note.dart
    │   └── taxonomy_node.dart
    ├── repositories/
    │   ├── bookmark_repository.dart
    │   ├── citation_repository.dart
    │   ├── history_repository.dart
    │   ├── note_repository.dart
    │   └── taxonomy_repository.dart
    └── services/
        ├── dto/
        │   ├── note_with_citations.dart
        │   ├── recently_viewed_entry.dart
        │   └── topic_notes.dart
        ├── library_service.dart
        ├── recently_viewed_service.dart
        └── taxonomy_navigation_service.dart



---

## 7. Explicit Exclusions — DO NOT REINTRODUCE

The following are explicit exclusions, not missing implementation tasks.

### 7.1 Library provider module

Do not create:

lib/features/library/di/library_providers.dart

This was withdrawn as a scope violation during MV-IP-002 Task A.4A.

### 7.2 Composition-root wiring

There is intentionally no reconstructed Riverpod composition-root wiring for the five repositories or three services.

Do not add this merely because it appears architecturally convenient.

### 7.3 Hand-rolled UUID generation

No custom UUID generator was reconstructed.

UUID generation remains an injected dependency at the service boundary.

### 7.4 Device identity

No device-identity placeholder was reconstructed.

### 7.5 Sibling lookup

Do not add getSiblings() to TaxonomyNavigationService.

### 7.6 _resolveIdentity

Do not restore a combined _resolveIdentity helper.

The accepted shape is the separate _uuidFor and _syncFor helpers.

### 7.7 Old History repository method

Do not restore getMostRecentByNoteUuid.

The accepted method name is getByNoteUuid.

### 7.8 History in RecentlyViewedEntry

Do not widen RecentlyViewedEntry to expose the History entity.

Its accepted shape is { Note note, DateTime viewedAt }.

### 7.9 MV-IP-002 Task Group B

There is no Task Group B in the governing project context.

Do not invent one.

---

## 8. Correct Absences / Known Gaps

The following are absent by design or because they were never implemented in the project history:

- Attachment
- AppSettings
- Taxonomy sibling lookup
- Additional feature modules beyond the reconstructed Phase 0 home placeholder and the library feature
- Full application composition-root implementation

These should not automatically be interpreted as reconstruction failures.

---

## 9. Phase 0 Dependency-Injection Placeholder

The file lib/core/di/injector.dart still contains the Phase 0 GreetingRepository demonstration pair.

This is a known preserved gap.

It was deliberately not replaced during reconstruction because doing so would cross the established scope boundary for MV-IP-002.

Any future replacement should be an explicit implementation task, not an implicit reconstruction correction.

---

## 10. Generated Code

Generated Dart code was recreated using build_runner.

The reconstruction used:

dart run build_runner build --delete-conflicting-outputs

The generated Isar files are present in the library data models.

Static analysis currently reports one remaining deprecation warning in generated Riverpod code:

AutoDisposeProviderRef in lib/core/di/injector.g.dart.

This generated file was intentionally not edited manually.

---

## 11. Validation Performed

The current working copy has been actively validated.

### Dependency resolution

flutter pub get completed successfully.

No dependency upgrades were performed.

### Code generation

dart run build_runner build --delete-conflicting-outputs completed successfully.

### Static analysis

flutter analyze completed with 0 analyzer errors and 1 deprecation warning in generated Riverpod code.

### Tests

flutter test completed with 27/27 tests passing.

The Linux Isar native library was made available through LD_LIBRARY_PATH for this test execution only. No project source or dependency modification was made for this workaround.

### Application build

flutter build has NOT been run.

Therefore, the project does not yet have a confirmed application build.

---

## 12. Toolchain Used for Validation

Validation was performed on:

- Zorin OS 18.1
- Flutter 3.24.5 stable
- Dart 3.5.4
- OpenJDK 17.0.20.1
- Android Studio
- Android SDK tooling

Flutter was intentionally not upgraded.

Dependencies were intentionally not upgraded.

---

## 13. Reconstruction Manifest

The authoritative reconstruction audit trail is:

RECONSTRUCTION_MANIFEST.md

It records:

- reconstructed components
- missing historical artifacts
- explicit exclusions
- validation
- reconstruction-process notes

The manifest distinguishes historical reconstruction limitations from the later validation performed in the working copy.

---

## 14. Missing Historical Documentation

The following historical artifacts were not recoverable with sufficient confidence:


docs/MedVault_Jules_Handover.md (original historical version)

AGENTS.md

This document is a newly reconstructed replacement for the original handover.

AGENTS.md must not be treated as recovered unless independently verified. Any newly created version must be explicitly labelled PROPOSED.

Several historical infrastructure scripts are also recorded as missing in RECONSTRUCTION_MANIFEST.md.

They were not fabricated.

---

## 15. Instructions to Jules

Jules should treat the current source tree and reconstruction manifest as the starting point for continued implementation.


Before making architectural changes:


1. Read RECONSTRUCTION_MANIFEST.md.
2. Read this handover document.
3. Inspect the existing implementation rather than recreating completed components.
4. Preserve the explicit exclusions listed above.
5. Do not infer that an absent component is necessarily a bug.
6. Do not invent additional task groups or historical requirements.
7. Do not silently introduce provider wiring, UUID generation, device identity, sibling lookup, or other excluded components.
8. Keep generated code generated through tooling.
9. Maintain the existing Git history and make focused commits for future implementation work.

---

## 16. Recommended Starting Point for Future Development

The reconstruction boundary is now stable.


Future work should proceed from the verified current implementation rather than continuing reconstruction indefinitely.


The next implementation task should be determined from the governing MedVault project requirements, not inferred from missing historical files.


In particular, Jules should not begin by "fixing" the intentional absences listed in this document.


If a future requirement genuinely calls for one of those components, it should be introduced as a new, explicitly scoped implementation decision.

---

## 17. Final Handover State

Reconstruction: COMPLETE
MV-IP-001 Task Group A: COMPLETE / FROZEN
MV-IP-002 Task Group A: COMPLETE / FROZEN
Dependency resolution: VERIFIED
Code generation: VERIFIED
Static analysis: VERIFIED
Tests: 27/27 PASS
Application build: NOT YET VERIFIED
Working tree: CLEAN

This document is the reconstructed handover boundary for continued MedVault development.
