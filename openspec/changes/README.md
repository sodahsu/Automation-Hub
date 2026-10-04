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
| `align-external-scheduler-to-15m` | WAITING-HUMAN | Live 已證實約 15 分鐘，PR #19 OpenSpec strict validation 已綠；剩 cron-job.org 設定頁精確值、generic repository/security checks 與獨立 review。外部登入／獨立驗證完成前不 archive。 |
| `run-private-pr-heads` | WAITING-HUMAN | Hub 程式/runtime 與 Ai-agent machine-readable remoteEvidence contract 都已成立；#541 的同 SHA validation #543 / Hub run `37190764398` success。剩 PAT 最小 scope、manual dispatch 與 no-retry runtime observation，不能由 repo 內程式自行證明。 |
| `trigger-openspec-validation-on-pr` | ARCHIVED | 2026-10-04 完成 opened / synchronize / ready_for_review runtime 驗證，canonical `ci-pr-validation` 已建立並歸檔。 |
| `claude-0700-minimal-wake` | WAITING-HUMAN | workflow 已 scheduled success；剩 OAuth 帳號身分、usage/reset 與離線觀察。 |
| `claude-window-trigger` | WAITING-HUMAN | scheduled workflow 已成功執行；剩 enable flag、live usage 與兩工作日觀察。 |
| `align-claude-code-action-version` | ARCHIVED | 2026-10-04 以 deferred / no production change 收納；未執行跨 repo 升級。 |

## 優先順序

1. CLOSEOUT 已歸零；目前沒有 Hub repo 內可直接完成的 ACTIVE change。`run-private-pr-heads` 已降為 WAITING-HUMAN。
2. WAITING-HUMAN（含 scheduler 精確設定／review）不阻塞已觀察到的 Hub runtime health。
3. action-version 調查已歸檔；若未來要升級，應在 owning repo 重新開 change。
