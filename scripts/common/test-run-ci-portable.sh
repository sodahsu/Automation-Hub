#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
runner="$root/scripts/common/run-ci.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if grep -Eq 'shellcheck-scripts|skill-resolver-tests|spec-truth-gate|architecture-tests' "$runner"; then
  echo "run-ci.sh still contains the removed repo-specific stage list" >&2
  exit 1
fi

for scenario in present missing; do
  workspace="$tmp/$scenario"
  mkdir -p "$workspace/architecture"
  printf '%s\n' '{"name":"portable-test","version":"1.0.0","scripts":{}}' > "$workspace/package.json"
  printf '%s\n' '{"name":"portable-test","version":"1.0.0","lockfileVersion":3,"packages":{"":{"name":"portable-test","version":"1.0.0"}}}' > "$workspace/package-lock.json"
  if [[ "$scenario" == present ]]; then
    printf '%s\n' '{"repositories":[{"repository":"<owner/private-repository>","portableCiEntrypoint":"touch \"$PORTABLE_MARKER\""}]}' > "$workspace/architecture/repos.json"
  else
    printf '%s\n' '{"repositories":[{"repository":"<owner/private-repository>","ciEntrypoint":"false"}]}' > "$workspace/architecture/repos.json"
  fi
  summary="$tmp/$scenario-summary.md"
  marker="$tmp/$scenario-marker"
  rc=0
  PRIVATE_REPOSITORY='<owner/private-repository>' PORTABLE_MARKER="$marker" RUNNER_TEMP="$tmp" bash "$runner" "$workspace" "$summary" repo-04 >/dev/null 2>&1 || rc=$?
  if [[ "$scenario" == present ]]; then
    [[ "$rc" == 0 && -f "$marker" ]] || { echo "portable entrypoint did not run" >&2; exit 1; }
    grep -Eq '\| portable-ci-entrypoint \| PASS \|' "$summary"
  else
    [[ "$rc" != 0 ]] || { echo "missing portable entrypoint unexpectedly passed" >&2; exit 1; }
    grep -Eq '\| portable-ci-entrypoint \| FAIL \(portableCiEntrypoint missing or invalid\) \|' "$summary"
  fi
done

echo "run-ci portable adapter tests passed"
