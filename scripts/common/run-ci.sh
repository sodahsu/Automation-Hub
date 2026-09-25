#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${1:-workspace}"
summary_file="${2:-${RUNNER_TEMP:-/tmp}/automation-hub-ci-summary.md}"
target_alias="${3:-}"

if [[ ! -d "$workspace" ]]; then
  echo "::error title=CI preflight failed::Private workspace was not created."
  exit 2
fi

workspace="$(cd "$workspace" && pwd)"
mkdir -p "$(dirname "$summary_file")"

declare -a rows=()
overall_rc=0

add_row() {
  local stage="$1"
  local status="$2"
  rows+=("| ${stage} | ${status} |")
}

write_summary() {
  {
    echo "### Private CI Bridge"
    echo
    echo "| Stage | Status |"
    echo "| --- | --- |"
    printf '%s\n' "${rows[@]}"
  } > "$summary_file"
}

cleanup_logs() {
  rm -f "${RUNNER_TEMP:-/tmp}"/automation-hub-*.log 2>/dev/null || true
}
trap cleanup_logs EXIT

run_stage() {
  local stage="$1"
  shift

  local safe_stage
  safe_stage="$(printf '%s' "$stage" | tr -cs '[:alnum:]_-' '-')"
  local log_file="${RUNNER_TEMP:-/tmp}/automation-hub-${safe_stage}.log"

  if "$@" >"$log_file" 2>&1; then
    add_row "$stage" "PASS"
    rm -f "$log_file"
    return 0
  else
    local rc=$?
    add_row "$stage" "FAIL (exit ${rc})"
    echo "::error title=Private CI stage failed::${stage} failed with exit code ${rc}. Private command output was intentionally withheld from this public log."
    rm -f "$log_file"
    overall_rc=$rc
    return "$rc"
  fi
}

has_script() {
  local script_name="$1"
  node -e '
    const fs = require("fs");
    const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
    process.exit(p.scripts && Object.prototype.hasOwnProperty.call(p.scripts, process.argv[1]) ? 0 : 1);
  ' "$script_name"
}

cd "$workspace"

if [[ ! -f package.json ]]; then
  add_row "adapter" "SKIP (no supported project adapter)"
  write_summary
  exit 0
fi

run_stage "package-json" node -e 'JSON.parse(require("fs").readFileSync("package.json", "utf8"))' || {
  write_summary
  exit "$overall_rc"
}

pm=""
if [[ -f pnpm-lock.yaml ]]; then
  pm="pnpm"
elif [[ -f package-lock.json ]]; then
  pm="npm"
elif [[ -f yarn.lock ]]; then
  pm="yarn"
elif [[ -f bun.lock || -f bun.lockb ]]; then
  pm="bun"
else
  add_row "package-manager" "SKIP (no supported lockfile)"
  write_summary
  exit 0
fi

add_row "package-manager" "PASS (${pm})"

case "$pm" in
  npm)
    run_stage "install" npm ci --no-audit --no-fund || { write_summary; exit "$overall_rc"; }
    runner=(npm run)
    ;;
  pnpm)
    run_stage "install" corepack pnpm install --frozen-lockfile || { write_summary; exit "$overall_rc"; }
    runner=(corepack pnpm run)
    ;;
  yarn)
    if [[ -f .yarnrc.yml ]]; then
      run_stage "install" corepack yarn install --immutable || { write_summary; exit "$overall_rc"; }
    else
      run_stage "install" corepack yarn install --frozen-lockfile || { write_summary; exit "$overall_rc"; }
    fi
    runner=(corepack yarn run)
    ;;
  bun)
    add_row "adapter" "SKIP (Bun adapter requires separate review)"
    write_summary
    exit 0
    ;;
esac

# repo-04 has a broader private CI than its package-level check:ci script.
# Mirror the read-only validation gates that can run safely in this public bridge.
if [[ "$target_alias" == "repo-04" ]]; then
  if [[ ! -d .git ]]; then
    run_stage "local-git-baseline" bash -c '
      git init -q &&
      git config user.name "automation-hub" &&
      git config user.email "automation-hub@invalid.local" &&
      git add -A &&
      git commit -qm "ci baseline"
    ' || { write_summary; exit "$overall_rc"; }
  fi

  run_stage "shellcheck-tool" bash -c 'command -v shellcheck >/dev/null' || { write_summary; exit "$overall_rc"; }

  run_stage "shellcheck-scripts" bash -c '
    mapfile -d "" files < <(find scripts -type f -name "*.sh" -print0 2>/dev/null || true)
    if ((${#files[@]})); then shellcheck --severity=error -e SC1090 -e SC1091 "${files[@]}"; fi
  ' || { write_summary; exit "$overall_rc"; }

  run_stage "shellcheck-skills" bash -c '
    mapfile -d "" files < <(find skills -type f -name "*.sh" -print0 2>/dev/null || true)
    if ((${#files[@]})); then shellcheck --severity=error -e SC1090 -e SC1091 "${files[@]}"; fi
  ' || { write_summary; exit "$overall_rc"; }

  run_stage "governance" bash scripts/governance-check.sh || { write_summary; exit "$overall_rc"; }
  run_stage "architecture-tests" python3 -m unittest discover -s architecture -p "test_*.py" -v || { write_summary; exit "$overall_rc"; }
  run_stage "architecture-contract" python3 architecture/check.py || { write_summary; exit "$overall_rc"; }
  run_stage "architecture-drift" bash scripts/repo-architecture-drift-check.sh --repo-only || { write_summary; exit "$overall_rc"; }
  run_stage "skill-resolver-tests" python3 -m unittest discover -s scripts/test -p "test_*.py" -v || { write_summary; exit "$overall_rc"; }
  run_stage "registry-check" bash scripts/generate-skill-registry.sh --check || { write_summary; exit "$overall_rc"; }
  run_stage "routing-audit" python3 scripts/lib/skill_context.py audit || { write_summary; exit "$overall_rc"; }
  run_stage "routing-matrix" python3 scripts/test/skill-routing-matrix.py || { write_summary; exit "$overall_rc"; }
  run_stage "runner-integration" python3 scripts/test/skill-runner-integration.py || { write_summary; exit "$overall_rc"; }
  run_stage "skill-audit" bash scripts/audit/skill-audit.sh || { write_summary; exit "$overall_rc"; }

  if [[ -f scripts/audit/shared-path-audit.sh ]]; then
    run_stage "shared-path-audit" bash scripts/audit/shared-path-audit.sh || { write_summary; exit "$overall_rc"; }
  else
    add_row "shared-path-audit" "SKIP"
  fi

  run_stage "spec-governance-tests" python3 -m unittest discover -s scripts/spec-governance/tests -p "test_*.py" -v || { write_summary; exit "$overall_rc"; }
  run_stage "spec-truth-gate" python3 scripts/spec-governance/cli.py check --mode audit || { write_summary; exit "$overall_rc"; }

  if has_script "check:ci"; then
    run_stage "check:ci" "${runner[@]}" "check:ci" || { write_summary; exit "$overall_rc"; }
  else
    add_row "check:ci" "SKIP"
  fi

  write_summary
  exit "$overall_rc"
fi
# Prefer an existing canonical aggregate CI command when available.
if has_script "check:ci"; then
  run_stage "check:ci" "${runner[@]}" "check:ci" || {
    write_summary
    exit "$overall_rc"
  }
  write_summary
  exit "$overall_rc"
fi

for stage in lint typecheck test build; do
  if has_script "$stage"; then
    run_stage "$stage" "${runner[@]}" "$stage" || {
      write_summary
      exit "$overall_rc"
    }
  else
    add_row "$stage" "SKIP"
  fi
done

write_summary
exit "$overall_rc"
