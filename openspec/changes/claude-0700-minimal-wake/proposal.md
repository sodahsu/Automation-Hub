# 提案：claude-0700-minimal-wake

## 為什麼要做

需要在本機電腦未開機、Orca 未啟動的情況下，仍能每天於台灣時間 07:00 對指定 Claude 帳號建立一次最小有效請求。

這個 change 的目的不是派工，也不是控制 Claude 的五小時額度週期，而是提供一個獨立、可觀察、可隨時停用的雲端 wake trigger。

## 變更內容

1. 新增 `.github/workflows/claude-0700-wake.yml`。
2. 使用 GitHub-hosted `ubuntu-latest` runner，不依賴本機 Mac 或 self-hosted runner。
3. 每天 07:00 以 `Asia/Taipei` timezone 觸發。
4. 保留 `workflow_dispatch`，供手動 smoke test。
5. 使用指定 Claude 帳號所產生的 OAuth token，透過 GitHub Secret `CLAUDE_PISCEAN0619_OAUTH_TOKEN` 注入。
6. Claude 請求限制為單回合，使用低成本模型，Prompt 僅要求回覆 `OK`。
7. 不執行派工、不讀取 private repositories、不修改 repository、不建立 PR / issue / commit。
8. workflow 權限維持 `contents: read`，checkout 不保存 Git credential。
9. 加入 concurrency group，避免同一 wake workflow 意外重疊執行。
10. Job 設定短 timeout，避免異常時長時間佔用 runner 或 Claude session。

## 執行模型

~~~text
07:00 Asia/Taipei
        ↓
GitHub Actions scheduler
        ↓
GitHub-hosted ubuntu-latest
        ↓
CLAUDE_PISCEAN0619_OAUTH_TOKEN
        ↓
Claude Haiku
        ↓
max-turns = 1
        ↓
Reply exactly: OK
        ↓
Exit
~~~

## 範圍

- 只修改 Public Automation-Hub。
- 只建立 Claude wake workflow 與對應 OpenSpec。
- 使用 GitHub-hosted runner。
- 使用指定 Claude 帳號的 OAuth token。
- 一天一次 07:00 scheduled wake。
- 保留 manual dispatch。

## 不包含

- 不啟動 Orca。
- 不加入 12:00 / 17:00 / 22:00 第二階段 wake。
- 不建立 Planner / Executor / Reviewer。
- 不讀取六個 private repositories。
- 不執行任何工作 queue。
- 不建立自動 retry loop。
- 不切換 Claude 多帳號。
- 不呼叫 Codex 或 Antigravity。
- 不把「07:00 wake」定義為 Claude 五小時額度 reset 的保證機制。
- 不在 repository 內保存 OAuth token。

## 安全邊界

Automation-Hub 為 Public repository，因此：

- OAuth token **MUST** 只存在 GitHub Actions Secret。
- workflow、log、summary 與 OpenSpec **MUST NOT** 包含 token value。
- workflow **MUST NOT** 取得 repository write permission。
- checkout **MUST NOT** persist Git credentials。
- Wake prompt **MUST NOT**要求 Claude 掃描 repository 或使用工具。
- 不新增 private repository credential 或 alias mapping。

## 驗收條件

- `.github/workflows/claude-0700-wake.yml` 存在。
- workflow schedule 為 07:00 `Asia/Taipei`。
- workflow 可用 `workflow_dispatch` 手動執行。
- 使用 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`，且 token 不存在於 committed files。
- Claude invocation 為單回合最小請求。
- GitHub-hosted runner 執行，不依賴本機 Mac。
- Workflow 無 repository write permission。
- Manual smoke test 成功並得到預期最小回應。
- 至少觀察一筆真實 scheduled run。
- OpenSpec strict validation 通過。

## 已知風險

1. GitHub scheduled workflow 並非硬即時排程，07:00 可能有延遲。
2. OAuth token 若過期或被撤銷，scheduled wake 會失敗。
3. Claude model availability / alias 未來可能變更，需要更新 workflow。
4. 這個 wake 只證明「07:00 發生一次有效 Claude request」，不保證 Claude usage window 或 reset time 被固定在 07:00。
