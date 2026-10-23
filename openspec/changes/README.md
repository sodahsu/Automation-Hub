# OpenSpec active change inventory

更新日期：2026-10-23

這份檔案是目前 `openspec/changes/` 的收納索引，不取代各 change 的 `proposal.md`、`design.md`、`specs/`、`tasks.md`。

狀態定義：

- **ACTIVE**：仍有實作、修正或研究工作，不能歸檔。
- **CLOSEOUT**：主要實作已完成，只剩驗證、證據回填、canonical spec 對齊或 archive。
- **WAITING-HUMAN**：剩下的是使用者操作、外部登入、帳號／憑證、跨機器 smoke 或明確裁決；不應被健康檢查誤判成 production 故障。
- **HOLD**：刻意暫緩或純調查紀錄；不應偷偷繼續實作。

收納原則：只有完成條件與 spec truth 已對齊的 change 才能進 `archive/`；未完成 delta 不可因整理方便而併入 canonical spec。

## Current queue

| Change | 狀態 | 下一步 |
|---|---|---|
| `detector-cadence-5m` | CLOSEOUT | detector 節流改為 UTC 分鐘 `% 5`，契約由 15 分鐘改為 5 分鐘（cron-job.org 已是 5 分鐘）。等待 merge 後的 live 驗收：至少 6 個連續做了完整掃描、相鄰間隔約 5 分鐘的 detector runs；通過後歸檔（套用 delta 到 canonical spec，不加 `--skip-specs`）。 |
| `trigger-openspec-validation-on-pr` | ARCHIVED | 2026-10-04 完成 opened / synchronize / ready_for_review runtime 驗證，canonical `ci-pr-validation` 已建立並歸檔。 |
| `claude-0700-minimal-wake` | WAITING-HUMAN | workflow 已 scheduled success；剩 OAuth 帳號身分、usage/reset 與離線觀察。 |
| `claude-window-trigger` | WAITING-HUMAN | scheduled workflow 已成功執行；剩 enable flag、live usage 與兩工作日觀察。 |
| `align-claude-code-action-version` | ARCHIVED | 2026-10-04 以 deferred / no production change 收納；未執行跨 repo 升級。 |

## Archived this pass

2026-10-09（使用者於對話中批准，例外於 `openspec/project.md`「runtime observation 未完成須留 active」）：

- `run-private-pr-heads`：以 `--skip-specs` 歸檔（delta 內容已在 canonical `private-change-detection`）。Hub 程式／runtime 與 Ai-agent contract 都已成立；PAT 最小 scope（1.1、1.2）、手動 dispatch（5.3）、Draft skip 與已有 status 不重跑（5.5）四項**沒有勾、歸檔時延後**，清單與原因見 `archive/2026-10-09-run-private-pr-heads/DEFERRED.md`。

2026-10-23：

- `align-external-scheduler-to-15m`：以 `--skip-specs` 歸檔為 `archive/2026-10-23-align-external-scheduler-to-15m/`，標記 **superseded by `detector-cadence-5m`**。cadence 方向改為 5 分鐘，其 15 分鐘 delta 不得套回 canonical spec；三個未勾項目（scheduler 設定頁、generic repository checks、independent review）因此不再執行。

## 優先順序

1. CLOSEOUT：`detector-cadence-5m` 只剩 merge 後的 live 驗收與歸檔；目前沒有 Hub repo 內可直接完成的 ACTIVE change。
2. WAITING-HUMAN（含 scheduler 精確設定／review）不阻塞已觀察到的 Hub runtime health。
3. action-version 調查已歸檔；若未來要升級，應在 owning repo 重新開 change。
