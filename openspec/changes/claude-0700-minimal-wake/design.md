# Design

## Context

Claude 07:00 Wake 的目的，是在本機 Mac、Orca 與 self-hosted runner 都不在線時，仍由 GitHub Actions 對指定 Claude 帳號送出一次最小有效請求。Automation-Hub 為 Public repository，因此 credential、GitHub 權限與第三方 Action supply-chain 風險必須保持最小。

## Goals / Non-Goals

### Goals

- 每天 07:00（Asia/Taipei）由 GitHub-hosted runner 執行；觸發來源以外部排程為主，GitHub `schedule` 為備援。
- 使用指定帳號對應的 Claude Code OAuth token。
- 單回合、低成本、無工具派工的 Claude request。
- 不授予 repository content write。
- 第三方 Actions 固定 immutable SHA。
- 支援 manual smoke test 與 runtime evidence。

### Non-Goals

- 不控制 Claude usage reset。
- 不啟動 Orca。
- 不加入多階段 wake、模型調度、queue 或 retry loop。
- 不讀取或修改六個 private repositories。
- 不為了讓 GitHub `schedule` 變準而調整 cron 分鐘或時區：延遲原因在 GitHub 一側，無法從外部驗證（見 evidence）。

## Technical Approach

外部排程（cron-job.org）在 07:00 Asia/Taipei 對本 workflow 的 dispatches endpoint 發出 `POST`，建立 GitHub-hosted Ubuntu job；GitHub `schedule` 同樣會建立 run，但只作備援。job 先以唯讀方式 checkout repository，執行冪等防呆，再透過固定 SHA 的 Claude Code Action 使用 repository secret 中的 OAuth credential 發送單回合請求。OIDC 僅用於 action 的身分交換；workflow 不持有 repository content write 權限，也不建立 retry、Agent 或後續派工。

## Architecture Decisions

### 1. 使用 GitHub-hosted runner

採用 `ubuntu-latest`，讓 workflow 與本機電腦完全解耦。這也避免為單一每日 wake 維護 self-hosted runner。

### 2. 使用 OAuth Secret

`CLAUDE_PISCEAN0619_OAUTH_TOKEN` 僅存在 GitHub Actions Secret，不寫入 repository。workflow 只引用 secret name。

### 3. 權限採最小集合

workflow 使用：

~~~yaml
permissions:
  contents: read
  id-token: write
~~~

`contents: read` 供 checkout；`id-token: write` 是 Claude Code Action 取得 OIDC token 所需，並不提供 repository content write。

### 4. 固定第三方 Action SHA

Public Automation-Hub 的 security audit 要求所有 `uses:` reference 使用 immutable 40 字元 commit SHA。版本資訊只以註解保留，避免 movable tag 被替換。

### 5. 最小 Claude invocation

Claude 使用低成本模型並限制 `--max-turns 1`。Prompt 明確要求只回覆 `OK`，且不得檢查檔案、使用工具或修改 repository。

### 6. 外部排程為主、GitHub schedule 為備援（2026-10-23）

實測 25 筆 schedule run 落在台北 08:28–11:15，無法當作 07:00 的來源。因此 07:00 由外部排程以 `workflow_dispatch` 觸發，作法與 detector 一致（專用 token、`POST .../actions/workflows/claude-0700-wake.yml/dispatches`，body `{"ref":"main"}`），設定步驟在 `docs/external-scheduler.md`。GitHub `schedule` 保留：外部排程或其 token 失效時，至少當天晚一點還有一次喚醒，勝過整天沒有。

選擇不拆成兩個 workflow：同一個 workflow 共用 concurrency group，兩種觸發即使撞在一起也會排隊而不是並行。

### 7. 冪等防呆只擋 schedule

`scripts/wake/wake-guard.sh` 只在 `schedule` 事件啟動時檢查：以台北日期（固定 UTC+8，Asia/Taipei 無 DST）算出當日區間，查本 workflow 當日 `status=success` 的 run，再逐個查 jobs，只要有一個 job 的 Claude step（`Trigger Claude for piscean0619`）conclusion 為 `success` 就視為已喚醒。

- 為什麼要看 step 而不是 run conclusion：被防呆 `SKIP` 的 run 整體結論也是 `success`，只看 run 會把「沒喚醒的成功 run」誤認為「已喚醒」。
- 為什麼 `workflow_dispatch` 不受限：它是主要來源，也是 smoke test 的入口；使用者明確按下的觸發不該被靜默吞掉。
- **殘留風險（接受）**：若 `schedule` 某天剛好準時（07:00 附近）先於外部排程建立 run，後到的 `workflow_dispatch` 仍會執行，同一天會有兩次喚醒。實測 25 筆 schedule 最早也晚了 1 小時 28 分，且代價只是多一次 Haiku 單回合請求，所以不為此讓 dispatch 也受防呆約束；若日後出現，再改成對 dispatch 提供 `force` 繞過、預設也受防呆。
- 同一個 concurrency group（`cancel-in-progress: false`）讓後到的 run 排隊到前一個結束，防呆才看得到前一個 run 的結果。

### 8. 防呆查詢失敗時 fail closed

查詢失敗（API 非 2xx、回應格式不符）時**不喚醒**，並讓防呆 step 失敗（run 紅燈、GitHub 會寄失敗通知）。理由：schedule 只是備援，漏喚醒一天的代價是額度視窗晚開始，而且紅燈可見；誤判成「今天還沒喚醒」會重複呼叫 Claude、白燒額度而且沒有任何訊號。兩種錯誤不對稱，選可見、可手動補救的一邊。

### 9. 權限增加 `actions: read`

防呆需要讀本 workflow 的歷史 run 與 jobs。`actions: read` 是唯讀，不是寫入權限；`actions: write` 仍只允許存在於 detector（`scripts/security/audit.py` 檢查）。選擇單一 job 而不是拆成 guard job 與 wake job，是為了少一次 runner 啟動與避免跨 job 傳遞狀態；代價是 Claude Code Action 那個 step 也在帶有 `actions: read` 的 token 環境，對公開 repo 的公開資料而言風險可忽略。

### 10. 不自動 retry

V1 不做 retry，以避免一次排程事件意外產生多次 Claude request。失敗直接由 Actions run 顯示並供人工判讀。

## Failure Modes

- OAuth Secret 缺失或失效：Claude step 失敗，workflow 結束。
- OIDC 權限缺失：Claude Code Action 無法取得 OIDC token。
- Action SHA 無效：setup step 失敗，不執行 Claude。
- GitHub scheduler 延遲：實測延遲 1.5–4.3 小時，所以 `schedule` 只作備援；07:00 的準時性由外部排程負責，驗收看 `workflow_dispatch` run 的建立時間。
- 外部排程失效（token 過期或撤銷、cron-job.org 停擺）：dispatch 收到 401／404，GitHub 端沒有任何 run 也沒有告警；由 cron-job.org 的 Failure notification 通知使用者，`schedule` 備援會在當天稍晚補上一次喚醒。
- 防呆查詢失敗：fail closed，不喚醒，run 紅燈（見決策 8）。
- 防呆 step 名稱漂移：`CLAUDE_STEP_NAME` 與 Claude step 的 `name` 不一致時，防呆永遠找不到當日喚醒而放行（重複喚醒）；`scripts/wake/test-wake-guard.sh` 會檢查兩者一致。
- Claude model alias 失效：另開修正，僅替換 model reference。

## Verification

- `bash scripts/wake/test-wake-guard.sh` 必須全數通過：當日已成功 → SKIP、當日沒有 → 執行、被 SKIP 的 run 不算喚醒、日界線（台北 23:59:59／00:00:00）、API 失敗與格式錯誤 fail closed、`workflow_dispatch` 不查 API。
- `workflow_dispatch` smoke test 必須 success。
- 成功 run 中 Claude step 必須 success、`max-turns=1`。
- Actions log 中 OAuth token 必須被遮罩。
- Security audit 必須 PASS。
- `openspec validate --all --strict` 必須 PASS。
- 既有 25 筆 `schedule` run 已證明 event 為 `schedule`、runner 為 GitHub-hosted、Claude step 成功（evidence）。
- 外部排程 07:00 準時性：連續 3 天，`workflow_dispatch` run 在 07:00 ± 5 分鐘建立且 Claude step 成功（由使用者驗收，tasks 第 10 節）。
- 防呆在真實 `schedule` 事件下的行為：部署後第一個 `schedule` run 的 step summary 應為 `SKIP`（當天外部排程已喚醒）或 `WAKE`（外部排程當天缺席）。
