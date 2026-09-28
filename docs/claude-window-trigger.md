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

Claude 訂閱使用者可在本機透過 `claude setup-token` 產生長效 OAuth token，再存入 GitHub Actions Secret。

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

- Model: `haiku`（Claude CLI alias，固定使用 Haiku 級）
- Prompt: `Reply exactly: OK`
- System prompt: `Reply exactly: OK`
- Max turns: 1
- Session persistence: 關閉（`--no-session-persistence`）
- Claude Code mode: `--bare`
- Built-in tools: 全部停用（`--tools ""`）
- MCP tools: 全部拒絕（`--disallowedTools "mcp__*"`）
- Repository checkout: 無
- Artifact: 無
- Retry loop: 無
- GitHub permission: `contents: read`

使用 Claude CLI 的 `haiku` alias，避免 workflow 綁死在特定 dated model。此 workflow 不設定 Sonnet / Opus fallback；Haiku 路徑不可用時應直接失敗並人工檢查。

## 重要限制

此 workflow 能證明「GitHub 在指定時間送出請求」，不能單獨證明「每個請求都會重新錨定 Claude 的五小時 session」。是否真的形成預期的 28 個 usage 區段，必須看 Claude 實際顯示的 reset time。
