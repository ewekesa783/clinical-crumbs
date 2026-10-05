# MedVault Source Reconstruction — Manifest

This manifest accompanies `MedVault_Source_Reconstruction.zip` and
records exactly what was reconstructed, partially reconstructed, not
reconstructed, or explicitly excluded, together with the validation
actually performed (and not performed).

## 1. Reconstructed

### medvault-infrastructure (Phase 0 / MV-IP-000 skeleton)
- Root: README.md, LICENSE (placeholder), CHANGELOG.md, .gitignore
- signing/, index/, cdn/, deploy/, monitoring/ — README.md + .gitkeep each
- docs/adr/.gitkeep, docs/modules/.gitkeep
- scripts/create-repositories.sh
- scripts/verify-toolchain.sh
- scripts/README.md

### medvault-shared (Phase 0 skeleton)
- Root config (README, LICENSE, CHANGELOG, .gitignore, pubspec.yaml,
  analysis_options.yaml)
- lib/medvault_shared.dart (empty public API, as specified for Phase 0)
- lib/src/curriculum_pack/.gitkeep
- test/smoke_test.dart

### medvault-toolkit (Phase 0 skeleton)
- Root config (README, LICENSE, CHANGELOG, .gitignore, pubspec.yaml,
  analysis_options.yaml)
- bin/medvault_toolkit.dart (placeholder CLI entry point)
- lib/src/.gitkeep
- test/smoke_test.dart

### medvault-app — Phase 0 skeleton
- Root config (README, LICENSE, CHANGELOG, .gitignore,
  analysis_options.yaml, pubspec.yaml, tool-versions.json [placeholder
  values — known gap, preserved])
- lib/main.dart, lib/app/app.dart, lib/app/bootstrap.dart (empty Isar
  schema list — known gap, preserved exactly, NOT fixed)
- lib/app/router/app_router.dart, route_names.dart (intentionally empty)
- lib/app/debug/component_gallery_screen.dart
- lib/core/theme/{app_colors,app_typography,app_theme}.dart
- lib/core/constants/spacing_tokens.dart (placeholder, no definitions)
- lib/core/database/app_database.dart (isarInstanceProvider placeholder)
- lib/core/error/failure.dart (sealed base class, no subtypes)
- lib/core/di/injector.dart — KNOWN GAP preserved exactly: still contains
  only the Phase 0 GreetingRepository demonstration pair, despite its
  own doc comment saying it is deleted at the start of Phase 1. No
  composition root wiring the real repositories/services exists.
- lib/features/home/presentation/screens/home_screen.dart (placeholder)
- lib/shared/widgets/app_button.dart (placeholder, no definitions)
- lib/l10n/app_en.arb
- assets/seed_data/topic_taxonomy.json ([] placeholder)
- test/smoke_test.dart, integration_test/app_launch_test.dart (placeholder)
- scripts/run-full-verification.sh (placeholder only)
- All Phase 0 .gitkeep placeholder directories (core/theme/tokens,
  core/database/migrations, core/search, core/network, core/storage,
  core/utils, core/extensions, features/home/* empty subfolders,
  shared/models, assets/images/*, assets/fonts, assets/seed_data/
  curriculum_packs, assets/lottie, docs/adr, docs/modules)

### medvault-app — MV-IP-001 (Core Data and Reading), Task Group A — COMPLETE/FROZEN
Full domain/data/mapper/repository layering for all five collections,
each reconstructed in its FINAL accepted (post-correction) shape:

- **core/sync/sync_metadata.dart**, **core/database/sync_metadata_model.dart**,
  **core/database/sync_metadata_mapper.dart** — shared SyncMetadata trio
  extracted during Task A.1A.
- **TaxonomyNode** (Task A.1 → A.1A correction): domain entity with zero
  Isar imports; separate `TaxonomyNodeModel` (`@collection`, `Id`,
  `@Index`, `@enumerated NodeType`); `TaxonomyNodeMapper`;
  `TaxonomyRepository` interface; `IsarTaxonomyRepository` — KNOWN GAP
  preserved exactly: uses `.filter()` (unindexed scan), not `.where()`
  (indexed lookup), on all three methods, despite indexed fields
  existing. Mapper test + repository test (real temp-directory Isar
  instance) included.
- **Note** (Task A.2 → A.2A refinement): domain entity; `NoteModel` with
  composite unique `(topicUuid, mode)` index; `NoteMapper` with
  defensive `List<String>.from(...)` copying for `tags`/`citationOrder`
  in both directions; `NoteRepository`; `IsarNoteRepository` (correctly
  uses `.where()`, in contrast to TaxonomyNode). Mapper test + repository
  test included.
- **Citation** (Task A.3 → A.3A contract clarification): domain entity
  with `SourceType` enum; `CitationModel`; `CitationMapper`;
  `CitationRepository` with `getByUuids` documented and implemented to
  preserve input order and multiplicity, silently omitting missing
  UUIDs; `IsarCitationRepository`. Mapper test + repository test
  (including the order/multiplicity/omission behavior) included.
- **Bookmark** (Task A.4 → A.4A index correction): domain entity;
  `BookmarkModel` with **non-unique** `noteUuid` index (corrected from
  an earlier unique index); `BookmarkMapper`; `BookmarkRepository` with
  `getByNoteUuid` returning a list; `IsarBookmarkRepository`. Mapper
  test + repository test (asserting a note may have >1 bookmark)
  included.
- **History** (Task A.5 → A.5A/A.5B corrections): domain entity;
  `HistoryModel` with **unique** `noteUuid` index; `HistoryMapper`;
  `HistoryRepository` with the method renamed
  `getMostRecentByNoteUuid` → `getByNoteUuid`, and a documented
  `save()`-does-not-enforce-upsert contract clarification; `IsarHistoryRepository`.
  Mapper test + repository test (including the unique-index rejection
  of a second distinct entry for the same note) included.

### medvault-app — MV-IP-002 (Domain Services), Task Group A — COMPLETE/FROZEN
- **dto/topic_notes.dart** (`TopicNotes`), **dto/note_with_citations.dart**
  (`NoteWithCitations`), **dto/recently_viewed_entry.dart`** — FINAL A.3A
  shape: `{Note note, DateTime viewedAt}` only, no History exposed.
- **LibraryService** (Task A.1 → A.1A → A.1B final shape): 5 repository
  dependencies + injected `generateUuid`/`createSyncMetadata`/`now`
  functions (no UUID-generation mechanism or composition root exists in
  this project — known gap, by design not resolved here); separate
  `_uuidFor`/`_syncFor` helpers (replacing an earlier combined
  `_resolveIdentity` helper); methods `getTopicNotes`,
  `getNoteWithCitations`, `recordNoteViewed`, `isNoteBookmarked`,
  `bookmarkNote`.
- **TaxonomyNavigationService** (Task A.2 → A.2A correction): ONLY
  `getBreadcrumbPath`. `getSiblings()` was explicitly removed per the
  project's service-layer test and is NOT present (confirmed via
  repository-wide search — see §5 Validation).
- **RecentlyViewedService** (Task A.3 → A.3A refinement): resolves a
  single note's recently-viewed entry into the narrowed DTO shape.
- Service-layer tests for all three, using in-memory fake repositories
  (this project's established service-test convention), including a
  test asserting `_uuidFor` reuse on a repeat `recordNoteViewed` call
  and an explicit comment documenting the absence of a `getSiblings()`
  test.
- Confirmed absent (Task A.4, withdrawn): `lib/features/library/di/
  library_providers.dart` and all associated Riverpod composition-root
  wiring, hand-rolled UUID generator, and device-identity placeholder.
  MV-IP-002 Task Group A.5 re-confirmed no further work was justified;
  there is NO Task Group B in this reconstruction, and none was
  invented.

## 2. Partially reconstructed

None. Every file listed under §1 was reconstructed in full for this
pass; there is no file that was started but left incomplete.

## 3. Not reconstructed (recorded as MISSING, not fabricated)

- **medvault-infrastructure/scripts/**: `create-labels-milestones-templates.sh`,
  `create-workspace.sh`, `verify-root-files.sh`,
  `verify-medvault-app-skeleton.sh`, `verify-medvault-shared-skeleton.sh`,
  `verify-medvault-toolkit-skeleton.sh`,
  `verify-medvault-infrastructure-skeleton.sh`, `verify-environment.sh`,
  `activate-fvm.sh`, `verify-fvm-activation.sh`, `install-dependencies.sh`,
  `verify-medvault-shared-linkage.sh`,
  `verify-minimal-architectural-skeleton.sh`. These were produced during
  an earlier pass of this project's Phase 0 implementation, but their
  exact final content could not be reconstructed with confidence after
  an environment reset that occurred mid-task during this
  reconstruction effort. Per the explicit instruction not to invent file
  content, they are recorded as missing rather than fabricated.
- **docs/MedVault_Jules_Handover.md**: a consolidated handover document
  was produced earlier in this project's history, but its content was
  also lost in the same environment reset and could not be
  regenerated verbatim without inventing text. It is NOT included in
  this archive. (The present reconstruction task's explicit priority is
  source code, not documentation, so this omission does not block
  delivery of the archive, but it is recorded here rather than silently
  dropped.)
- **AGENTS.md**: no verified final/accepted content for this file
  survived the environment reset either; it is not included. If a
  version is needed, it should be treated as PROPOSED ONLY, never as
  part of the original accepted source tree, per the project's explicit
  instruction not to conflate proposed and accepted artifacts.
- **Non-library feature modules**: no features beyond `home` (Phase 0
  placeholder) and `library` (MV-IP-001/002) were ever specified or
  implemented in this project's history, so none are reconstructed here
  — this is a correct absence, not a gap.
- **Attachment, AppSettings, sibling-lookup method**: never implemented
  in this project's history (documented known gaps). Correctly absent.

## 4. Explicitly excluded (per governing instructions — NOT a gap)

- `lib/features/library/di/library_providers.dart` — withdrawn as a
  scope violation during MV-IP-002 Task A.4A. Confirmed absent.
- Any Riverpod provider wiring the five Phase 1 repositories or the
  three MV-IP-002 services into a composition root.
- Any hand-rolled UUID-generation implementation.
- Any device-identity placeholder implementation.
- Any `getSiblings()` method on `TaxonomyNavigationService`.
- Any `_resolveIdentity` combined helper on `LibraryService` (replaced
  by the separate `_uuidFor`/`_syncFor` helpers).
- Any `getMostRecentByNoteUuid` method name on `HistoryRepository`
  (renamed to `getByNoteUuid`).
- Any `RecentlyViewedEntry` shape exposing a `History` entity (narrowed
  to `{Note, viewedAt}`).
- A "Task Group B" for MV-IP-002, or any task/file implying one. None
  exists in the governing project context, and none was invented here.

## 5. Validation

**What was performed:**
- A full recursive search for each excluded/withdrawn identifier
  (`library_providers`, `getSiblings`, `_resolveIdentity`,
  `getMostRecentByNoteUuid`) across the entire reconstructed tree,
  confirming every match is a documentary comment explaining the
  removal/rename/withdrawal, never a live implementation.
- A check that `recently_viewed_entry.dart` imports only `Note`, not
  `History`.
- A check that `LibraryService` defines both `_uuidFor` and `_syncFor`
  as separate methods (not a combined `_resolveIdentity`).
- A brace-balance check (`{` count == `}` count) across every `.dart`
  file in all four repositories, to catch gross structural truncation.
- A check that `medvault-app/pubspec.yaml` and
  `medvault-toolkit/pubspec.yaml` both declare the `medvault_shared:
  path: ../medvault-shared` sibling-directory dependency, and that
  `medvault-shared/`, `medvault-toolkit/`, `medvault-app/` are in fact
  sibling directories under `MedVault/` so that dependency resolves.
- A manual review of every file's imports against the files actually
  present, to confirm referenced classes (e.g. `TaxonomyNodeModelSchema`,
  `NoteModelSchema`, `SyncMetadataMapper`) are defined somewhere in the
  tree.

**What was NOT performed (no execution environment is, or has ever
been, available to this project for this purpose):**
- `flutter pub get` / `dart pub get` was NOT run. Dependency resolution
  against pub.dev is unverified.
- `flutter analyze` / `dart analyze` was NOT run. Static-analysis
  correctness (e.g. whether every import path is correct, whether
  generated `.g.dart`/`.freezed.dart` files — which are NOT included,
  since they are build-generated and were never committed in this
  project's history — would actually be produced by `build_runner`) is
  UNVERIFIED.
- `flutter test` / `dart test` was NOT run. No test in this archive has
  been confirmed to actually pass.
- `flutter build` was NOT run. **This project's source code has never
  been compiled, in this reconstruction pass or in any prior pass of
  this project's history.** Do not treat anything in this archive as
  confirmed to compile or run.

## Post-reconstruction validation performed in the working copy

The following validation was performed after the reconstruction was
completed, using the current working copy:

- flutter pub get was run successfully in medvault-app. Dependency
  resolution completed successfully under the reconstructed dependency
  constraints; dependencies were not upgraded.
- dart run build_runner build --delete-conflicting-outputs was run
  successfully, generating the required build-generated Dart files.
- flutter analyze was run after generation and source corrections.
  Result: no analyzer errors; one remaining deprecation warning in
  generated Riverpod code (AutoDisposeProviderRef). The generated
  file was intentionally not edited.
- flutter test was run successfully with the Linux Isar native library
  available through LD_LIBRARY_PATH. Result: 27/27 tests passed.
  The environment variable was used only for test execution and no
  project source/dependency modification was made for this workaround.
- flutter build has NOT been run. Therefore full application build
  validation remains unperformed, and the project should not be
  described as having a confirmed production/buildable application.

## 6. Reconstruction-process note

This reconstruction required two full rebuilds of the working tree
after unexpected environment/container resets erased all previously
written files mid-task (once before this pass began, and the state
checked again at the start of this pass confirmed a second, complete
loss). All content in this archive was written fresh in this single
pass, from the project history retained in conversation context, not
copied forward from any file on disk that might have survived a reset
— none did.
