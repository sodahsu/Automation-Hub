# OpenSpec active change inventory

更新日期：2026-10-23

這份檔案是目前 `openspec/changes/` 的收納索引，不取代各 change 的 `proposal.md`、`design.md`、`specs/`、`tasks.md`。

狀態定義：

- **ACTIVE**：仍有實作、修正或研究工作，不能歸檔。
- **WAITING-HUMAN**：剩下的是使用者操作、外部登入、帳號／憑證、跨機器 smoke 或明確裁決；不應被健康檢查誤判成 production 故障。
- **HOLD**：刻意暫緩或純調查紀錄；不應偷偷繼續實作。

收納原則：只有完成條件與 spec truth 已對齊的 change 才能進 `archive/`；未完成 delta 不可因整理方便而併入 canonical spec。

## Current queue

| Change | 狀態 | 下一步 |
|---|---|---|
| `trigger-openspec-validation-on-pr` | ARCHIVED | 2026-10-04 完成 opened / synchronize / ready_for_review runtime 驗證，canonical `ci-pr-validation` 已建立並歸檔。 |
| `claude-0700-minimal-wake` | WAITING-HUMAN | 2026-10-23 修訂：GitHub `schedule` 實測落在台北 08:28–11:15（晚 1.5–4.3 小時），改為 cron-job.org 在 07:00 以 `workflow_dispatch` 為主、`schedule` 為備援，並加冪等防呆（`scripts/wake/wake-guard.sh`，本機 stub 測試通過）。尚待：PR 合併 → 使用者建立 cron-job.org 07:00 job → 連續 3 天 07:00 ± 5 分驗收；另有 OAuth 帳號身分（5.1）與 usage window 觀察（8.1、8.2）。**不 archive**：`openspec/project.md` 要求 runtime observation 未完成必須留 active，且沒有使用者針對本 change 的延後批准。清單見該 change `tasks.md` 檔尾「使用者驗收清單」。 |
| `claude-window-trigger` | ARCHIVED（dropped） | 2026-10-23 撤銷：從未啟用（一律 dry-run、`CLAUDE_CODE_OAUTH_TOKEN` 不存在），用途與 `claude-0700-minimal-wake` 重疊；workflow 與文件已刪除，以 `--skip-specs` 歸檔。 |
| `align-claude-code-action-version` | ARCHIVED | 2026-10-04 以 deferred / no production change 收納；未執行跨 repo 升級。 |

## Archived this pass

2026-10-09（使用者於對話中批准，例外於 `openspec/project.md`「runtime observation 未完成須留 active」）：

- `run-private-pr-heads`：以 `--skip-specs` 歸檔（delta 內容已在 canonical `private-change-detection`）。Hub 程式／runtime 與目標私有 repo contract 都已成立；PAT 最小 scope（1.1、1.2）、手動 dispatch（5.3）、Draft skip 與已有 status 不重跑（5.5）四項**沒有勾、歸檔時延後**，清單與原因見 `archive/2026-10-09-run-private-pr-heads/DEFERRED.md`。

2026-10-23：

- `detector-cadence-5m`：2026-10-23 PR #26 合併後，以 14 個連續完整掃描、間隔 4:45–5:06 的 live run 完成驗收；不加 `--skip-specs` 歸檔至 `archive/2026-10-23-detector-cadence-5m/`，5 分鐘 delta 已套用至 canonical `private-change-detection`。目標私有 repo PR #655 已將 `hook-wiring-integrity` 改為 5 分鐘。
- `claude-window-trigger`：以 `--skip-specs` 歸檔為 `archive/2026-10-23-claude-window-trigger/`，標記 **dropped**。2026-10-23 使用者授權主代理裁決：該 change 實作的 workflow 從未 live（`CLAUDE_WINDOW_TRIGGER_ENABLED` 沒設、`CLAUDE_CODE_OAUTH_TOKEN` 不存在；2026-09-30 至 2026-10-23 的 74 筆 schedule run 全部 success，最新一筆的 log 為 `Dry-run only; Claude was not called.`），用途與 `claude-0700-minimal-wake` 重疊；`claude-window-trigger.yml`、`docs/claude-window-trigger.md` 與 README 對應段落同步刪除，5 個未勾項目（第 4 節）均標 dropped。
- `align-external-scheduler-to-15m`：以 `--skip-specs` 歸檔為 `archive/2026-10-23-align-external-scheduler-to-15m/`，標記 **superseded by `detector-cadence-5m`**。cadence 方向改為 5 分鐘，其 15 分鐘 delta 不得套回 canonical spec；三個未勾項目（scheduler 設定頁、generic repository checks、independent review）因此不再執行。

## 優先順序

1. ACTIVE changes：目前沒有 Hub repo 內可直接完成的 change。
2. WAITING-HUMAN：`claude-0700-minimal-wake`（PR 合併後，由使用者建立 cron-job.org 07:00 job 並做 3 天準時性驗收）；不阻塞已觀察到的 Hub runtime health。
3. action-version 調查已歸檔；若未來要升級，應在 owning repo 重新開 change。
