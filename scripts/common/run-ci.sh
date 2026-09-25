#!/usr/bin/env bash
set -Eeuo pipefail

workspace="${1:-workspace}"
summary_file="${2:-${RUNNER_TEMP:-/tmp}/automation-hub-ci-summary.md}"

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
  fi

  local rc=$?
  add_row "$stage" "FAIL (exit ${rc})"
  echo "::error title=Private CI stage failed::${stage} failed with exit code ${rc}. Private command output was intentionally withheld from this public log."
  rm -f "$log_file"
  overall_rc=$rc
  return "$rc"
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
