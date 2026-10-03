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

# 這些 stage 只負責備料或偵測環境：PASS 只代表前置條件成立，
# 不代表目標程式碼的任何檢查被執行過。
setup_stages=" package-json package-lock package-manager install local-git-baseline shellcheck-tool python-deps "
unverified_note="UNVERIFIED：沒有任何 adapter／檢查 stage 執行；這次綠燈只代表沒有東西失敗，不代表通過。"

add_row() {
  local stage="$1"
  local status="$2"
  rows+=("| ${stage} | ${status} |")
}

# 只掃已記錄的 rows，不碰 run_stage 與各 adapter 的流程，exit code 因此不受影響。
count_verifying_rows() {
  local row stage status count=0
  for row in "${rows[@]}"; do
    # row 由 add_row 產生，固定為「| <stage> | <status> |」。
    IFS='|' read -r _ stage status _ <<<"$row"
    stage="${stage# }"
    stage="${stage% }"
    status="${status# }"
    if [[ "$setup_stages" == *" ${stage} "* ]]; then
      continue
    fi
    if [[ "$status" == PASS* ]]; then
      count=$((count + 1))
    fi
  done
  echo "$count"
}

write_summary() {
  local unverified=0
  # 失敗的 run 本來就是紅燈；只有「綠燈卻沒驗證任何東西」需要額外標示。
  if (( overall_rc == 0 )) && [[ "$(count_verifying_rows)" == "0" ]]; then
    unverified=1
  fi

  {
    echo "### Private CI Bridge"
    echo
    echo "| Stage | Status |"
    echo "| --- | --- |"
    printf '%s\n' "${rows[@]}"
    if (( unverified )); then
      echo
      echo "> **${unverified_note}**"
    fi
  } > "$summary_file"

  if (( unverified )); then
    # 刻意不改 exit code：改成紅燈會破壞 detector 以 job 結論判斷的語意。
    # 這行寫進 log 與 annotation；真正的 job summary 由 workflow 的 publish step
    # 讀 $summary_file 後發布（$GITHUB_STEP_SUMMARY 在此 step 已被隔離到暫存檔）。
    echo "::warning title=Private CI unverified::${unverified_note}"
  fi
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

run_advisory() {
  local stage="$1"
  shift

  local safe_stage
  safe_stage="$(printf '%s' "$stage" | tr -cs '[:alnum:]_-' '-')"
  local log_file="${RUNNER_TEMP:-/tmp}/automation-hub-${safe_stage}.log"

  if "$@" >"$log_file" 2>&1; then
    add_row "$stage" "PASS"
  else
    local rc=$?
    add_row "$stage" "ADVISORY (exit ${rc})"
  fi
  rm -f "$log_file"
  return 0
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

# repo-05 has no package.json but its private CI is a Python + OpenSpec contract suite.
# Mirror candidate-contract.yml exactly enough for read-only recovery.
if [[ "$target_alias" == "repo-05" ]]; then
  run_stage "unit-tests" python3 -m unittest discover -s tests -p "test_*.py" -v || { write_summary; exit "$overall_rc"; }
  run_stage "candidate-contract" python3 scripts/check-candidates.py || { write_summary; exit "$overall_rc"; }
  run_stage "architecture-json" python3 -m json.tool architecture/contract.json || { write_summary; exit "$overall_rc"; }
  run_stage "architecture-doc" test -s docs/CANDIDATE-CONTRACT.md || { write_summary; exit "$overall_rc"; }
  run_stage "openspec-strict" npx --yes @fission-ai/openspec@1.8.0 validate --all --strict || { write_summary; exit "$overall_rc"; }
  write_summary
  exit "$overall_rc"
fi
# repo-06 mirrors the read-only/manual path of its Vault Health workflow.
# Report bodies stay inside suppressed temporary logs and are never published.
if [[ "$target_alias" == "repo-06" ]]; then
  run_stage "python-deps" python3 -m pip install --disable-pip-version-check PyYAML==6.0.3 || { write_summary; exit "$overall_rc"; }
  run_stage "skill-sync" python3 90_System/scripts/check-skill-sync.py || { write_summary; exit "$overall_rc"; }
  run_stage "health-unit-tests" python3 -m unittest discover -s 90_System/tests -p "test_*.py" -v || { write_summary; exit "$overall_rc"; }
  run_stage "metadata-normalizer" python3 90_System/scripts/metadata-normalizer.py check --format json || { write_summary; exit "$overall_rc"; }
  run_stage "vault-health" python3 90_System/scripts/vault-health.py || { write_summary; exit "$overall_rc"; }
  run_stage "followup-radar" python3 90_System/scripts/followup_radar.py --limit 30 || { write_summary; exit "$overall_rc"; }
  run_advisory "stale-fact-audit" python3 90_System/scripts/stale-fact-audit.py
  run_stage "hub-drift" python3 90_System/scripts/generate_hub.py --check || { write_summary; exit "$overall_rc"; }
  run_stage "index-drift" python3 90_System/scripts/index-drift-check.py || { write_summary; exit "$overall_rc"; }

  relation_log="${RUNNER_TEMP:-/tmp}/automation-hub-relation-health.log"
  if python3 90_System/scripts/relation-health.py >"$relation_log" 2>&1; then
    if grep -qE "(非法關係類型|右側沒有 wikilink|目標不存在|自我指向)：[1-9]" "$relation_log"; then
      add_row "relation-health" "FAIL (contract)"
      rm -f "$relation_log"
      overall_rc=1
      write_summary
      exit "$overall_rc"
    fi
    add_row "relation-health" "PASS"
    rm -f "$relation_log"
  else
    rc=$?
    add_row "relation-health" "FAIL (exit ${rc})"
    rm -f "$relation_log"
    overall_rc=$rc
    write_summary
    exit "$overall_rc"
  fi

  run_stage "memory-health" python3 90_System/scripts/memory-health.py --strict || { write_summary; exit "$overall_rc"; }
  run_stage "source-link-format" python3 90_System/scripts/fix-source-links.py || { write_summary; exit "$overall_rc"; }
  add_row "claim-harvest" "SKIP (schedule-only)"
  add_row "source-backlog" "SKIP (schedule-only)"
  write_summary
  exit "$overall_rc"
fi
# repo-03 is verified through the Garden PR status. Require its canonical npm CI
# gate so an unsupported checkout can never publish a green, empty adapter run.
if [[ "$target_alias" == "repo-03" ]]; then
  if [[ ! -f package.json ]]; then
    add_row "package-json" "FAIL (required file missing)"
    overall_rc=2
    write_summary
    exit "$overall_rc"
  fi

  run_stage "package-json" node -e 'JSON.parse(require("fs").readFileSync("package.json", "utf8"))' || {
    write_summary
    exit "$overall_rc"
  }

  if [[ ! -s package-lock.json ]]; then
    add_row "package-lock" "FAIL (required file missing or empty)"
    overall_rc=2
    write_summary
    exit "$overall_rc"
  fi
  add_row "package-lock" "PASS"

  if ! has_script "check:ci"; then
    add_row "check:ci" "FAIL (required script missing)"
    overall_rc=2
    write_summary
    exit "$overall_rc"
  fi

  run_stage "install" npm ci --no-audit --no-fund || { write_summary; exit "$overall_rc"; }
  run_stage "check:ci" npm run check:ci || { write_summary; exit "$overall_rc"; }
  write_summary
  exit "$overall_rc"
fi
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

