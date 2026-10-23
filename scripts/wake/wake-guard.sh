#!/usr/bin/env bash
# Claude 07:00 wake 的冪等防呆。
#
# 契約：只有 GitHub `schedule`（備援來源）會被擋。若本 workflow 在「台北日期」當天已經有一次
# 真的呼叫過 Claude 且成功的 run，schedule 觸發就 SKIP；外部排程或手動的 workflow_dispatch
# 一律放行（它是主要來源，也是 smoke test 的入口）。
#
# 輸出：寫 should_wake=true|false 到 $GITHUB_OUTPUT。
# 失敗策略（fail closed）：查不到歷史（API 失敗、回應格式不對）就不喚醒並讓 step 失敗。
# 理由：schedule 只是備援，漏喚醒一天的代價是「額度視窗晚開始」，且 run 會變紅被看見；
# 誤判成「今天還沒喚醒」會重複呼叫 Claude、白燒額度，而且不會有任何訊號。
#
# 必要環境變數：GH_TOKEN、GITHUB_REPOSITORY、GITHUB_EVENT_NAME、GITHUB_RUN_ID、GITHUB_OUTPUT
# 選用：GITHUB_STEP_SUMMARY、WORKFLOW_FILE、CLAUDE_STEP_NAME、
#       WAKE_GUARD_NOW_EPOCH（僅供測試固定「現在」）
set -Eeuo pipefail

: "${GITHUB_REPOSITORY:?}" "${GITHUB_EVENT_NAME:?}" "${GITHUB_RUN_ID:?}" "${GITHUB_OUTPUT:?}"

workflow_file="${WORKFLOW_FILE:-claude-0700-wake.yml}"
# 這個名稱必須與 workflow 裡呼叫 Claude 的 step 一致：用它判斷「當天有沒有真的喚醒過」，
# 因為被防呆 SKIP 的 run 整體結論也是 success，不能只看 run conclusion。
claude_step_name="${CLAUDE_STEP_NAME:-Trigger Claude for piscean0619}"
summary_file="${GITHUB_STEP_SUMMARY:-/dev/null}"

emit() { echo "should_wake=$1" >> "${GITHUB_OUTPUT}"; }

summary() {
  {
    echo "## Claude wake guard"
    echo
    echo "$1"
  } >> "${summary_file}"
}

fail_closed() {
  emit false
  echo "::error title=Wake guard unavailable::$1 不喚醒 Claude（fail closed）。"
  summary "FAIL — $1 不喚醒 Claude；請查 run log，必要時手動 \`workflow_dispatch\`。"
  exit 1
}

if [[ "${GITHUB_EVENT_NAME}" != "schedule" ]]; then
  emit true
  summary "WAKE — event=\`${GITHUB_EVENT_NAME}\`：外部排程與手動觸發不受冪等防呆限制。"
  exit 0
fi

# 台北日期的起點（轉成 UTC）。Asia/Taipei 自 1979 年起沒有 DST，固定 +8 小時是安全的；
# 刻意只用 epoch 算術加 jq 的 strftime，避免 GNU date 與 BSD date 的旗標差異。
now="${WAKE_GUARD_NOW_EPOCH:-$(date -u +%s)}"
taipei_now=$(( now + 8 * 3600 ))
day_start=$(( taipei_now - taipei_now % 86400 - 8 * 3600 ))
start_iso="$(jq -rn --argjson e "${day_start}" '$e | strftime("%Y-%m-%dT%H:%M:%SZ")')"
end_iso="$(jq -rn --argjson e "$(( day_start + 86400 - 1 ))" '$e | strftime("%Y-%m-%dT%H:%M:%SZ")')"
taipei_date="$(jq -rn --argjson e "${taipei_now}" '$e | strftime("%Y-%m-%d")')"

runs_file="$(mktemp)"
jobs_file="$(mktemp)"
ids_file="$(mktemp)"
trap 'rm -f "${runs_file}" "${jobs_file}" "${ids_file}"' EXIT

if ! gh api -X GET "repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_file}/runs" \
    -f status=success -f "created=${start_iso}..${end_iso}" -F per_page=100 > "${runs_file}"; then
  fail_closed "查詢當日 success runs 失敗。"
fi

if ! jq -e '.workflow_runs | type == "array"' "${runs_file}" > /dev/null 2>&1; then
  fail_closed "success runs 回應格式不符。"
fi

# API 的 created 區間已經限定當日；這裡再過濾一次，並排除本 run 自己。
jq -r --arg self "${GITHUB_RUN_ID}" --arg start "${start_iso}" --arg end "${end_iso}" '
  .workflow_runs[]
  | select((.id | tostring) != $self)
  | select(.created_at >= $start and .created_at <= $end)
  | .id
' "${runs_file}" > "${ids_file}"

checked=0
while IFS= read -r run_id; do
  [[ -n "${run_id}" ]] || continue
  checked=$(( checked + 1 ))
  if ! gh api -X GET "repos/${GITHUB_REPOSITORY}/actions/runs/${run_id}/jobs" -F per_page=100 > "${jobs_file}"; then
    fail_closed "查詢 run ${run_id} 的 jobs 失敗。"
  fi
  if ! jq -e '.jobs | type == "array"' "${jobs_file}" > /dev/null 2>&1; then
    fail_closed "run ${run_id} 的 jobs 回應格式不符。"
  fi
  if jq -e --arg step "${claude_step_name}" '
      any(.jobs[]; any((.steps // [])[]; .name == $step and .conclusion == "success"))
    ' "${jobs_file}" > /dev/null; then
    emit false
    summary "SKIP — 台北日期 ${taipei_date} 已有一次成功的喚醒（run ${run_id}）；本次 schedule 備援不呼叫 Claude。"
    exit 0
  fi
done < "${ids_file}"

emit true
summary "WAKE — 台北日期 ${taipei_date} 尚無成功的喚醒（已檢查 ${checked} 個當日 success run）；schedule 備援執行。"
