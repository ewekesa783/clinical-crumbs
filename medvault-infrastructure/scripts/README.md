# medvault-infrastructure/scripts

Phase 0 (MV-IP-000) toolchain and repository-setup scripts.

## Scripts present in this reconstruction

- `create-repositories.sh` — creates the four MedVault GitHub repositories
  with branch protection (MV-IP-000 Task C.1-C.3).
- `verify-toolchain.sh` — verifies local developer toolchain prerequisites
  (MV-IP-000 Task B.1-B.4).

## Known gap

The original Phase 0 implementation pass produced additional scripts
(`create-labels-milestones-templates.sh`, `create-workspace.sh`,
`verify-root-files.sh`, `verify-medvault-app-skeleton.sh`,
`verify-medvault-shared-skeleton.sh`, `verify-medvault-toolkit-skeleton.sh`,
`verify-medvault-infrastructure-skeleton.sh`, `verify-environment.sh`,
`activate-fvm.sh`, `verify-fvm-activation.sh`, `install-dependencies.sh`,
`verify-medvault-shared-linkage.sh`, `verify-minimal-architectural-skeleton.sh`)
during the Phase 0 (MV-IP-000) implementation pass of this project. Their
exact final content could not be reconstructed with confidence in this pass
following an environment reset that occurred during reconstruction, and per
the explicit instruction not to invent file content, they are recorded as
MISSING in RECONSTRUCTION_MANIFEST.md rather than fabricated.
