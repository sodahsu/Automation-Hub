# 任務：claude-window-trigger

> **dropped（2026-10-23）**：2026-10-23 使用者授權主代理裁決（環境收拾 session），本 change 撤銷，以 `--skip-specs` 歸檔，delta 不進 canonical spec。`.github/workflows/claude-window-trigger.yml` 與 `docs/claude-window-trigger.md` 於同一個 PR 刪除；下方已勾選的 1～3 節是歷史實作紀錄，不代表目前 repo 仍有該 workflow。
>
> 撤銷理由與證據：
>
> - **從來沒有真正啟用**：repository variable `CLAUDE_WINDOW_TRIGGER_ENABLED` 沒設（`gh variable list -R sodahsu/Automation-Hub` 為空）。2026-09-30 至 2026-10-23 共 74 筆 `schedule` run 全部 success，但最新一筆（run 39883536041）的 log 為 `Dry-run only; Claude was not called.`，`SCHEDULE_ENABLED` 為空。
> - **live 需要的 credential 不存在**：`CLAUDE_CODE_OAUTH_TOKEN` 不在 Actions secrets（`gh secret list -R sodahsu/Automation-Hub` 只有 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`、`PRIVATE_REPOS_JSON`、`PRIVATE_REPOS_READ_TOKEN`、`PRIVATE_REPOS_STATUS_TOKEN`）。
> - **用途與 `claude-0700-minimal-wake` 重疊**，而後者已經每天實際送出請求並成功。
> - **GitHub `schedule` 不足以達成這個 change 要的時段節奏**：24 天內 74 筆 run，把每筆 run 的台北建立時間歸到「最近一個已過的設定時段」，07:07 為 24 筆、17:07 為 23 筆、22:07 為 24 筆，12:07 只有 3 筆；另外實際觸發時間也比設定時間晚數小時（同期 `claude-0700-wake` 的 25 筆 schedule run 落在台北 08:28–11:15）。
>
> 因此不是「剩使用者驗證」，而是「不再需要」：未勾的第 4 節全部 dropped。

## 1. Workflow

- [x] 1.1 建立獨立 `claude-window-trigger.yml`。
- [x] 1.2 加入 Asia/Taipei timezone-aware schedule。
- [x] 1.3 每日排定 07:07、12:07、17:07、22:07。
- [x] 1.4 加入 `workflow_dispatch`，預設 dry-run。
- [x] 1.5 加入單一 concurrency group 與 3 分鐘 timeout。
- [x] 1.6 權限縮限為 `contents: read`。

## 2. Cost / Safety Guard

- [x] 2.1 Scheduled live 必須由 `CLAUDE_WINDOW_TRIGGER_ENABLED=true` 顯式開啟。
- [x] 2.2 Live 只讀取 `CLAUDE_CODE_OAUTH_TOKEN`。
- [x] 2.3 偵測到 `ANTHROPIC_API_KEY` 時 fail closed。
- [x] 2.4 不使用 `actions/checkout`。
- [x] 2.5 固定最短 prompt 與最小 system prompt。
- [x] 2.6 固定 `max-turns=1`。
- [x] 2.7 使用 `--bare`，並以 `--tools ""` 移除所有 built-in tools。
- [x] 2.8 以 `--disallowedTools "mcp__*"` 移除所有 MCP tools。
- [x] 2.9 不設定高成本模型 fallback。
- [x] 2.10 不建立 retry loop。

## 3. 文件

- [x] 3.1 文件化啟用條件、Secret 與 Variable。
- [x] 3.2 文件化目前帳號未準備 OAuth 時應保持 disabled。
- [x] 3.3 文件化「28 windows」仍需實測 reset 行為，不能由 workflow 存在本身推論。

## 4. 驗證

- [ ] 4.1 合併到 default branch 後確認四個 scheduled events 可被 GitHub 識別。 — **dropped**：已觀察到 07:07、17:07、22:07 三個時段會觸發，12:07 只出現 3 次（見上方理由）；change 撤銷，不再追蹤。
- [ ] 4.2 先以 dry-run 驗證 workflow。 — **dropped**：dry-run 已被 74 筆 schedule run 事實上跑過，但 change 撤銷，不補驗收證據。
- [ ] 4.3 設定 Claude OAuth 後手動 live 一次。 — **dropped**：`CLAUDE_CODE_OAUTH_TOKEN` 不存在，也不打算建立；wake 需求改由 `claude-0700-minimal-wake` 承接。
- [ ] 4.4 連續至少兩個工作日記錄 Claude Usage / reset time。 — **dropped**：從未 live，沒有可記錄的對象。
- [ ] 4.5 實測成立後再把 `CLAUDE_WINDOW_TRIGGER_ENABLED` 設為 `true`。 — **dropped**：該 variable 本來就不存在，不需要清理。
