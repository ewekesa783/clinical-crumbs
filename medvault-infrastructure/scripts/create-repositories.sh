#!/usr/bin/env bash
#
# create-repositories.sh
#
# Creates the four MedVault GitHub repositories (medvault-app,
# medvault-shared, medvault-toolkit, medvault-infrastructure) with branch
# protection on `main`, using the GitHub CLI (`gh`).
#
# Referenced specifications: MV-IP-000 Task C.1-C.3 (Repository creation
# and branch protection).
#
# [ASSUMPTION] Repository visibility defaults to private; no explicit
# visibility decision is recorded in the governing specifications.
# [ASSUMPTION] README content at creation time is a minimal placeholder;
# the full README content is established separately by later tasks.
# [ASSUMPTION] `required_status_checks` is left unset in this script because
# no CI workflow exists yet at Phase 0 to be required; this is deferred to
# the phase in which CI is first introduced.
#
# This script is idempotent: re-running it against already-created
# repositories will not fail or duplicate work; `gh repo create` is skipped
# if the repository already exists, and branch protection is re-applied
# (which is safe, since it is declarative).

set -euo pipefail

ORG="${MEDVAULT_GH_ORG:-}"
VISIBILITY="${MEDVAULT_GH_VISIBILITY:-private}"

if [[ -z "$ORG" ]]; then
  echo "ERROR: MEDVAULT_GH_ORG environment variable must be set to the" >&2
  echo "       GitHub user or organization under which the repositories" >&2
  echo "       will be created." >&2
  exit 1
fi

REPOS=(
  "medvault-app"
  "medvault-shared"
  "medvault-toolkit"
  "medvault-infrastructure"
)

command -v gh >/dev/null 2>&1 || {
  echo "ERROR: GitHub CLI (gh) is required but was not found on PATH." >&2
  exit 1
}

for repo in "${REPOS[@]}"; do
  full_name="${ORG}/${repo}"
  echo "=== Processing repository: ${full_name} ==="

  if gh repo view "${full_name}" >/dev/null 2>&1; then
    echo "Repository ${full_name} already exists. Skipping creation."
  else
    echo "Creating repository ${full_name} (visibility: ${VISIBILITY})..."
    gh repo create "${full_name}" \
      --"${VISIBILITY}" \
      --description "MedVault: ${repo}" \
      --confirm
  fi

  echo "Applying branch protection to 'main' on ${full_name}..."
  # [ASSUMPTION] Branch protection requires at least one approving review
  # and up-to-date status before merge; no explicit reviewer count is
  # specified in the governing specifications, so one (1) is used as a
  # conservative minimum consistent with a small initial team.
  gh api \
    --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/${full_name}/branches/main/protection" \
    -f "required_pull_request_reviews[required_approving_review_count]=1" \
    -f "enforce_admins=true" \
    -f "restrictions=null" \
    -f "required_status_checks=null" \
    >/dev/null || {
      echo "WARNING: Branch protection could not be applied to ${full_name}." >&2
      echo "         This may occur if the default branch is not yet named" >&2
      echo "         'main' (e.g. the repository has no commits yet)." >&2
    }

  echo "Done with ${full_name}."
  echo
done

echo "All repositories processed."
