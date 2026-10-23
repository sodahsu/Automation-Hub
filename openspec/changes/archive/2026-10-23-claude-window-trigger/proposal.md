# 提案：claude-window-trigger

## 為什麼要做

使用者希望把 Claude 的使用節奏固定在每日四個時段，但不希望 GitHub Actions 到點就執行大型 AI 任務。此 change 只建立「最小 Claude request」排程器：在 07:07、12:07、17:07、22:07（Asia/Taipei）發送一次極短請求，真正的開發工作仍由人工或其他 dispatcher 另外執行。

目前帳號尚未準備可供 GitHub Actions 使用的 Claude OAuth，因此排程預設必須是 dry-run；只有在 OAuth Secret 已設定且 repository variable 明確啟用後，scheduled run 才能進入 live 模式。

## 變更內容

1. 新增獨立 GitHub Actions workflow `.github/workflows/claude-window-trigger.yml`。
2. 使用 GitHub timezone-aware schedule，以 `Asia/Taipei` 排定每日 07:07、12:07、17:07、22:07。
3. scheduled run 預設 dry-run；只有 `CLAUDE_WINDOW_TRIGGER_ENABLED=true` 才允許 live。
4. 手動 `workflow_dispatch` 預設 dry-run，可顯式選擇 live 進行驗證。
5. live 模式只接受 `CLAUDE_CODE_OAUTH_TOKEN`，不允許 `ANTHROPIC_API_KEY` fallback。
6. 使用 Haiku 4.5、固定最短 prompt、`max-turns=1`、禁止常用工具、禁止 checkout。
7. workflow 採最小 GitHub permission、concurrency 與 timeout。
8. 本 change 不宣稱最小 request 一定能重新錨定 Claude 的五小時 usage window；該行為必須以實際 Usage/Reset 資訊驗證。

## 範圍

- 僅修改 Public `Automation-Hub`。
- 不讀取六個 private repositories。
- 不 checkout Automation-Hub。
- 不啟動 Orca Dispatcher。
- 不執行 Planner / Executor / Reviewer。
- 不執行 Git、CI、測試、build 或 deploy。
- 不建立 Artifact 或 cache。
- 不建立額外 API PAYG 路徑。

## 不包含

- 不自動建立或輪替 Claude OAuth token。
- 不自動修改 GitHub Secrets / Variables。
- 不保證 Claude 的 session reset clock 會因單次 request 被重新錨定。
- 不做模型 fallback；指定模型不可用時直接失敗。
- 不在失敗時 retry Claude request。

## 驗收條件

- Scheduled workflow 在 default branch 上每日執行四次，時區為 Asia/Taipei。
- 未啟用 repository variable 時 scheduled run 不呼叫 Claude。
- 手動執行預設 dry-run。
- Live 模式缺少 `CLAUDE_CODE_OAUTH_TOKEN` 時 fail closed。
- Repository 若存在 `ANTHROPIC_API_KEY`，live preflight 必須拒絕執行。
- Live 模式不 checkout repository、不使用 MCP、不讀 private source。
- Claude request 使用 Haiku 4.5、固定 prompt `Reply exactly: OK`、最多一個 turn。
- 同一時間只能存在一個 trigger run。
- Job timeout 為 3 分鐘，沒有 retry loop。
