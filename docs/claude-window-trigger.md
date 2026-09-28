# Claude Window Trigger

此 workflow 只做一件事：在固定時間送出一個極小 Claude request。它不負責寫程式、不掃六倉，也不啟動 Orca Dispatcher。

## 排程

時區：`Asia/Taipei`

- 07:07
- 12:07
- 17:07
- 22:07

每天 4 次，每週最多 28 次 scheduled runs。

> GitHub 的 scheduled workflow 只會從 default branch 執行，而且排程可能延遲；這些時間是 scheduler 目標，不是 Claude reset 的保證。

## 預設狀態

Scheduled run 預設只會 dry-run。沒有設定以下 variable 時，不會呼叫 Claude：

`CLAUDE_WINDOW_TRIGGER_ENABLED=true`

目前若尚未有可供 Claude Code 使用的 OAuth token，請保持 variable 未設定或設為 `false`。

## 啟用 live 前

需要 repository secret：

`CLAUDE_CODE_OAUTH_TOKEN`

Claude Pro / Max 使用者可在本機 Claude Code 依 Anthropic 官方流程產生 OAuth token，再存入 GitHub Actions Secret。

本 workflow 不使用 `ANTHROPIC_API_KEY`。若 repository 中存在該 Secret，live preflight 會主動拒絕執行，避免意外走 API PAYG。

## 手動測試順序

1. 合併 workflow 到 default branch。
2. Actions → Claude Window Trigger → Run workflow。
3. 先保持 `mode=dry-run`。
4. 確認排程與 summary 正常。
5. 設定 `CLAUDE_CODE_OAUTH_TOKEN`。
6. 手動選 `mode=live` 執行一次。
7. 到 Claude Usage / `/usage` 確認 session reset time。
8. 至少觀察兩個工作日。
9. 確認行為符合需求後，再新增 repository variable `CLAUDE_WINDOW_TRIGGER_ENABLED=true`。

## Live request

- Model: `claude-haiku-4-5-20251001`
- Prompt: `Reply exactly: OK`
- Max turns: 1
- Repository checkout: 無
- Artifact: 無
- Retry loop: 無
- GitHub permission: `contents: read`

Haiku 4.5 是目前可用的低成本 Claude 模型之一；模型若退休或在 Claude Code 訂閱路徑不可用，本 workflow 應更新指定模型，而不是自動 fallback 到 Sonnet / Opus。

## 重要限制

此 workflow 能證明「GitHub 在指定時間送出請求」，不能單獨證明「每個請求都會重新錨定 Claude 的五小時 session」。是否真的形成預期的 28 個 usage 區段，必須看 Claude 實際顯示的 reset time。
