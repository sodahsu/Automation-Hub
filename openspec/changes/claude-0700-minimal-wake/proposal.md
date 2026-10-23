# Proposal

## Why

需要在本機電腦未開機、Orca 未啟動的情況下，仍能每天於台灣時間 07:00 對指定 Claude 帳號建立一次最小有效請求。此功能只負責建立一次可驗證的雲端 wake request，不負責派工或控制 Claude 額度 reset。

### 2026-10-23 修訂：觸發來源改為外部排程為主

首版只用 GitHub `schedule`。2026-09-29 到 2026-10-23 共 25 筆 schedule run 全部成功，但實際建立時間落在台北 08:28–11:15，比 07:00 晚 1 小時 28 分到 4 小時 15 分（中位數 2 小時 30 分，見 `evidence/scheduled-runs-2026-10-23.md`）。cron 與 `timezone: Asia/Taipei` 本身沒有寫錯；延遲屬於 GitHub scheduler 一側。喚醒晚了數小時就失去「在 07:00 開啟額度視窗」的意義。

2026-10-23 使用者授權主代理裁決（環境收拾 session）：

- **cron-job.org 在 07:00 Asia/Taipei 以 `workflow_dispatch` 觸發為主**，比照 `docs/external-scheduler.md` 對 detector 的做法（專用 token、POST dispatches）。
- **GitHub `schedule` 保留為備援**，但加冪等防呆：同一個台北日期已有一次成功的喚醒，schedule 觸發就 `SKIP`，且不得再呼叫 Claude。

## What Changes

- 新增 `.github/workflows/claude-0700-wake.yml`。
- 使用 GitHub-hosted `ubuntu-latest` runner，不依賴本機 Mac 或 self-hosted runner。
- 每天 07:00（`Asia/Taipei`）由外部排程以 `workflow_dispatch` 觸發為主；GitHub `schedule`（`0 7 * * *`、`Asia/Taipei`）保留為備援。
- 新增 `scripts/wake/wake-guard.sh` 冪等防呆：只對 `schedule` 事件生效，查本 workflow 當日（台北日期）是否已有「呼叫 Claude 的 step 成功」的 run；已有就 `SKIP`；查詢失敗 fail closed（不喚醒、step 失敗）。`workflow_dispatch` 不受限。
- 新增 `scripts/wake/test-wake-guard.sh`：以 stub `gh` 在本機測試防呆的各分支。
- `docs/external-scheduler.md` 擴充 07:00 job 的設定步驟與驗收方式。
- 使用 `CLAUDE_PISCEAN0619_OAUTH_TOKEN` 注入指定 Claude 帳號的 OAuth credential。
- Claude 請求限制為低成本模型、單回合、極短固定回應。
- 權限只允許 `contents: read`、Claude Code Action OIDC 所需的 `id-token: write`，以及防呆唯讀查歷史所需的 `actions: read`；不授予 repository content write，也不授予 `actions: write`。
- 第三方 GitHub Actions 固定到 immutable commit SHA。
- 不執行派工、不讀 private repositories、不修改 repository、不建立 PR / issue / commit。

## Capabilities

### New Capabilities

- `claude-minimal-wake`: 每天 07:00 透過 GitHub-hosted runner 對指定 Claude 帳號建立一次最小、單回合、可驗證的 wake request。

### Modified Capabilities

- 無。

## Impact

- `.github/workflows/claude-0700-wake.yml`: 新增每日 Claude wake workflow；2026-10-23 加入防呆 step 與 `actions: read`。
- `scripts/wake/wake-guard.sh`、`scripts/wake/test-wake-guard.sh`: 冪等防呆與其本機測試。
- `docs/external-scheduler.md`: 07:00 外部排程 job 的設定與驗收。
- cron-job.org 與專用 dispatch token：由使用者建立（不在 repo 內，tasks 第 10 節）。
- `openspec/changes/claude-0700-minimal-wake/`: 定義行為、權限、安全邊界與驗收項目。
- GitHub Actions repository secret：需要 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`。
- 不影響六個 private repositories、既有 private CI bridge、Orca 或本機排程。
