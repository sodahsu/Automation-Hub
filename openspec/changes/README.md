# OpenSpec active change inventory

更新日期：2026-10-04

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
| `align-external-scheduler-to-15m` | CLOSEOUT | 2026-10-04 live 已證實約 15 分鐘 cadence；完成 strict/review，精確 cron-job.org UI 值若無法直接讀取就保留為未驗證，再歸檔。 |
| `run-private-pr-heads` | CLOSEOUT | 程式與 Ai-agent #534–#537 runtime 已證實 PR status chain；補 Ai-agent remoteEvidence，保留 PAT 最小 scope 為人工確認。 |
| `trigger-openspec-validation-on-pr` | ARCHIVED | 2026-10-04 完成 opened / synchronize / ready_for_review runtime 驗證，canonical `ci-pr-validation` 已建立並歸檔。 |
| `claude-0700-minimal-wake` | WAITING-HUMAN | workflow 已 scheduled success；剩 OAuth 帳號身分、usage/reset 與離線觀察。 |
| `claude-window-trigger` | WAITING-HUMAN | scheduled workflow 已成功執行；剩 enable flag、live usage 與兩工作日觀察。 |
| `align-claude-code-action-version` | ARCHIVED | 2026-10-04 以 deferred / no production change 收納；未執行跨 repo 升級。 |

## 優先順序

1. 剩餘 CLOSEOUT：`align-external-scheduler-to-15m`、`run-private-pr-heads`。
2. WAITING-HUMAN 不阻塞 Hub health。
3. action-version 調查已歸檔；若未來要升級，應在 owning repo 重新開 change。
