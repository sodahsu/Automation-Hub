#!/usr/bin/env bash
# wake-guard.sh 的本機測試：用 stub gh 取代 GitHub API，不碰網路、不呼叫 Claude。
# 用法：bash scripts/wake/test-wake-guard.sh（任何一個案例失敗就 exit 1）
set -Eeuo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
guard="${root}/scripts/wake/wake-guard.sh"
workflow="${root}/.github/workflows/claude-0700-wake.yml"
step_name="Trigger Claude for piscean0619"

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
mkdir -p "${work}/bin"

# stub gh：依 API 路徑回放 fixture；有 fail_* 檔就模擬 HTTP 失敗。
cat > "${work}/bin/gh" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "${STUB_DIR}/calls.log"
path=""
for a in "$@"; do
  case "${a}" in repos/*) path="${a}" ;; esac
done
case "${path}" in
  */actions/workflows/*/runs)
    if [[ -f "${STUB_DIR}/fail_runs" ]]; then echo "gh: HTTP 500" >&2; exit 1; fi
    cat "${STUB_DIR}/runs.json" ;;
  */actions/runs/*/jobs)
    id="${path#*/actions/runs/}"; id="${id%/jobs}"
    if [[ -f "${STUB_DIR}/fail_jobs_${id}" ]]; then echo "gh: HTTP 502" >&2; exit 1; fi
    cat "${STUB_DIR}/jobs_${id}.json" ;;
  *) echo "stub gh: unexpected path ${path}" >&2; exit 99 ;;
esac
STUB
chmod +x "${work}/bin/gh"

failures=0
epoch() { jq -rn --arg t "$1" '$t | fromdate'; }

# new_case <name>：建立乾淨的 stub 目錄
new_case() {
  case_dir="${work}/${1}"
  mkdir -p "${case_dir}"
  : > "${case_dir}/calls.log"
  : > "${case_dir}/output"
  : > "${case_dir}/summary"
}

runs_json() { # runs_json <id:created_at>...
  jq -n '{total_count: ($ARGS.positional | length), workflow_runs: [$ARGS.positional[] | split("@") | {id: (.[0] | tonumber), created_at: .[1]}]}' --args "$@"
}

jobs_json() { # jobs_json <step conclusion>
  jq -n --arg name "${step_name}" --arg c "$1" '{jobs: [{name: "Minimal Claude wake", steps: [{name: "Checkout repository", conclusion: "success"}, {name: $name, conclusion: $c}]}]}'
}

# run_guard <event> <now_iso> [run_id]
run_guard() {
  local rc=0
  PATH="${work}/bin:${PATH}" STUB_DIR="${case_dir}" GH_TOKEN=stub \
    GITHUB_REPOSITORY=owner/repo GITHUB_EVENT_NAME="$1" GITHUB_RUN_ID="${3:-900}" \
    GITHUB_OUTPUT="${case_dir}/output" GITHUB_STEP_SUMMARY="${case_dir}/summary" \
    WAKE_GUARD_NOW_EPOCH="$(epoch "$2")" \
    bash "${guard}" > "${case_dir}/stdout" 2> "${case_dir}/stderr" || rc=$?
  rc_value="${rc}"
}

# expect <label> <expected should_wake> <expected exit>
expect() {
  local got
  got="$(grep -o 'should_wake=.*' "${case_dir}/output" | tail -1 || true)"
  if [[ "${got}" == "should_wake=$2" && "${rc_value}" == "$3" ]]; then
    echo "PASS  $1"
  else
    echo "FAIL  $1 （got '${got}', exit ${rc_value}；預期 should_wake=$2, exit $3）"
    failures=$(( failures + 1 ))
  fi
}

assert_contains() { # assert_contains <label> <file> <needle>
  if grep -qF -- "$3" "$2"; then echo "PASS  $1"; else echo "FAIL  $1 （$2 沒有 '$3'）"; failures=$(( failures + 1 )); fi
}
assert_not_contains() {
  if grep -qF -- "$3" "$2"; then echo "FAIL  $1 （$2 不該有 '$3'）"; failures=$(( failures + 1 )); else echo "PASS  $1"; fi
}

now_after_0700="2026-10-23T01:03:32Z" # 台北 2026-10-23 09:03，真實 schedule 備援的典型時間

new_case dispatch
run_guard workflow_dispatch "${now_after_0700}"
expect "workflow_dispatch 不受防呆限制，直接喚醒" true 0
assert_not_contains "workflow_dispatch 不查 API" "${case_dir}/calls.log" "repos/"

new_case schedule_none
runs_json > "${case_dir}/runs.json"
run_guard schedule "${now_after_0700}"
expect "schedule 且當日沒有成功喚醒 → 執行" true 0
assert_contains "查詢條件：只取 success" "${case_dir}/calls.log" "status=success"
assert_contains "查詢區間：台北 10-23 = UTC 10-22T16:00:00Z..10-23T15:59:59Z" "${case_dir}/calls.log" "created=2026-10-22T16:00:00Z..2026-10-23T15:59:59Z"
assert_contains "summary 標示 WAKE" "${case_dir}/summary" "WAKE"

new_case schedule_done
runs_json "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
jobs_json success > "${case_dir}/jobs_800.json"
run_guard schedule "${now_after_0700}"
expect "schedule 且當日已有成功喚醒 → SKIP" false 0
assert_contains "summary 標示 SKIP 與來源 run" "${case_dir}/summary" "SKIP"
assert_contains "summary 記錄命中的 run id" "${case_dir}/summary" "run 800"

new_case schedule_skipped_run
runs_json "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
jobs_json skipped > "${case_dir}/jobs_800.json"
run_guard schedule "${now_after_0700}"
expect "當日 success run 的 Claude step 是 skipped（沒真的喚醒）→ 不算，執行" true 0

new_case schedule_failed_claude
runs_json "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
jobs_json failure > "${case_dir}/jobs_800.json"
run_guard schedule "${now_after_0700}"
expect "Claude step 失敗的 run 不算已喚醒 → 執行" true 0

new_case schedule_yesterday
runs_json "700@2026-10-22T15:59:59Z" > "${case_dir}/runs.json"
jobs_json success > "${case_dir}/jobs_700.json"
run_guard schedule "${now_after_0700}"
expect "前一個台北日的成功 run（即使 API 回傳）不算 → 執行" true 0
assert_not_contains "前一日的 run 不會被拿去查 jobs" "${case_dir}/calls.log" "/runs/700/jobs"

new_case schedule_tomorrow
runs_json "701@2026-10-23T16:00:00Z" > "${case_dir}/runs.json"
jobs_json success > "${case_dir}/jobs_701.json"
run_guard schedule "${now_after_0700}"
expect "下一個台北日的成功 run（即使 API 回傳）不算 → 執行" true 0

new_case schedule_self
runs_json "900@2026-10-23T01:03:32Z" > "${case_dir}/runs.json"
jobs_json success > "${case_dir}/jobs_900.json"
run_guard schedule "${now_after_0700}" 900
expect "本 run 自己不計入 → 執行" true 0

new_case schedule_second_run_hits
runs_json "801@2026-10-22T23:30:00Z" "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
jobs_json skipped > "${case_dir}/jobs_801.json"
jobs_json success > "${case_dir}/jobs_800.json"
run_guard schedule "${now_after_0700}"
expect "多個當日 run：只要有一個真的喚醒成功 → SKIP" false 0

new_case boundary_before_midnight
runs_json > "${case_dir}/runs.json"
run_guard schedule "2026-10-22T15:59:59Z" # 台北 10-22 23:59:59
expect "台北 23:59:59 仍算 10-22" true 0
assert_contains "查詢區間 = 台北 10-22" "${case_dir}/calls.log" "created=2026-10-21T16:00:00Z..2026-10-22T15:59:59Z"

new_case boundary_at_midnight
runs_json > "${case_dir}/runs.json"
run_guard schedule "2026-10-22T16:00:00Z" # 台北 10-23 00:00:00
expect "台北 00:00:00 起算新的一天" true 0
assert_contains "查詢區間 = 台北 10-23" "${case_dir}/calls.log" "created=2026-10-22T16:00:00Z..2026-10-23T15:59:59Z"

new_case api_runs_fail
touch "${case_dir}/fail_runs"
run_guard schedule "${now_after_0700}"
expect "查 runs 的 API 失敗 → 不喚醒、step 失敗（fail closed）" false 1
assert_contains "失敗時 summary 說明原因" "${case_dir}/summary" "FAIL"

new_case api_runs_malformed
echo '{"message":"Bad credentials"}' > "${case_dir}/runs.json"
run_guard schedule "${now_after_0700}"
expect "runs 回應格式不符 → 不喚醒、step 失敗" false 1

new_case api_jobs_fail
runs_json "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
touch "${case_dir}/fail_jobs_800"
run_guard schedule "${now_after_0700}"
expect "查 jobs 的 API 失敗 → 不喚醒、step 失敗" false 1

new_case api_jobs_malformed
runs_json "800@2026-10-22T23:00:05Z" > "${case_dir}/runs.json"
echo '{"message":"Not Found"}' > "${case_dir}/jobs_800.json"
run_guard schedule "${now_after_0700}"
expect "jobs 回應格式不符 → 不喚醒、step 失敗" false 1

# workflow 與 guard 必須共用同一個 step 名稱，且 Claude step 只在 guard 放行時執行。
assert_contains "workflow 的 Claude step 名稱與 guard 約定一致" "${workflow}" "      - name: ${step_name}"
assert_contains "workflow 把同一個名稱傳給 guard" "${workflow}" "CLAUDE_STEP_NAME: ${step_name}"
assert_contains "Claude step 由 guard 輸出控制" "${workflow}" "if: steps.guard.outputs.should_wake == 'true'"

if (( failures > 0 )); then
  echo "wake-guard tests: ${failures} failed"
  exit 1
fi
echo "wake-guard tests: all passed"
