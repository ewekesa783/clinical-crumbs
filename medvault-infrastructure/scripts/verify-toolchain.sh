#!/usr/bin/env bash
#
# verify-toolchain.sh
#
# Verifies that the local development toolchain required by MV-IP-000
# is present. Hard checks (git, fvm, java) cause the script to exit
# non-zero if missing. Soft checks (Android SDK, Android Studio, VS Code,
# available RAM, available disk) are advisory only and print a warning
# without failing the script.
#
# Referenced specifications: MV-IP-000 Task B.1-B.4 (Toolchain
# verification).

set -uo pipefail

FAIL=0

check_hard() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$("$cmd" --version 2>&1 | head -n1)"
    echo "[OK]   ${name}: ${version}"
  else
    echo "[FAIL] ${name}: not found on PATH." >&2
    FAIL=1
  fi
}

check_soft() {
  local name="$1"
  local cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK]   ${name}: found."
  else
    echo "[WARN] ${name}: not found. This is advisory only; see" >&2
    echo "       [ASSUMPTION] in MV-IP-000 Task B.3 for rationale." >&2
  fi
}

echo "=== Hard checks (required) ==="
check_hard "git" "git"
check_hard "fvm" "fvm"
check_hard "java" "java"

echo
echo "=== Soft checks (advisory) ==="
check_soft "Android SDK (adb)" "adb"
check_soft "Android Studio (studio)" "studio"
check_soft "VS Code (code)" "code"

echo
echo "=== Soft checks: system resources ==="
if command -v free >/dev/null 2>&1; then
  total_ram_kb="$(free -k | awk '/^Mem:/{print $2}')"
  total_ram_gb=$(( total_ram_kb / 1024 / 1024 ))
  if [[ "$total_ram_gb" -lt 8 ]]; then
    echo "[WARN] Available RAM (~${total_ram_gb} GB) is below the" >&2
    echo "       recommended 8 GB minimum. [ASSUMPTION]: 8 GB is a" >&2
    echo "       conservative estimate for comfortable Flutter builds;" >&2
    echo "       no specific figure is mandated by the specifications." >&2
  else
    echo "[OK]   Available RAM: ~${total_ram_gb} GB."
  fi
else
  echo "[WARN] Could not determine available RAM ('free' not found)." >&2
fi

if command -v df >/dev/null 2>&1; then
  avail_kb="$(df -k . | awk 'NR==2{print $4}')"
  avail_gb=$(( avail_kb / 1024 / 1024 ))
  if [[ "$avail_gb" -lt 10 ]]; then
    echo "[WARN] Available disk space (~${avail_gb} GB) is below the" >&2
    echo "       recommended 10 GB minimum. [ASSUMPTION]: 10 GB is a" >&2
    echo "       conservative estimate; no specific figure is mandated" >&2
    echo "       by the specifications." >&2
  else
    echo "[OK]   Available disk space: ~${avail_gb} GB."
  fi
else
  echo "[WARN] Could not determine available disk space ('df' not found)." >&2
fi

echo
if [[ "$FAIL" -ne 0 ]]; then
  echo "One or more hard checks failed. See [FAIL] lines above." >&2
  exit 1
fi

echo "All hard checks passed."
exit 0
