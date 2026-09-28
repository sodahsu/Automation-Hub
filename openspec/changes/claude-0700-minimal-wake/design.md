# Design

## Context

Claude 07:00 Wake 的目的，是在本機 Mac、Orca 與 self-hosted runner 都不在線時，仍由 GitHub Actions 對指定 Claude 帳號送出一次最小有效請求。Automation-Hub 為 Public repository，因此 credential、GitHub 權限與第三方 Action supply-chain 風險必須保持最小。

## Goals / Non-Goals

### Goals

- 每天 07:00（Asia/Taipei）由 GitHub-hosted runner 執行。
- 使用指定帳號對應的 Claude Code OAuth token。
- 單回合、低成本、無工具派工的 Claude request。
- 不授予 repository content write。
- 第三方 Actions 固定 immutable SHA。
- 支援 manual smoke test 與 runtime evidence。

### Non-Goals

- 不控制 Claude usage reset。
- 不啟動 Orca。
- 不加入多階段 wake、模型調度、queue 或 retry loop。
- 不讀取或修改六個 private repositories。

## Technical Approach

GitHub Actions 以每日排程建立 GitHub-hosted Ubuntu job，先以唯讀方式 checkout repository，再透過固定 SHA 的 Claude Code Action 使用 repository secret 中的 OAuth credential 發送單回合請求。OIDC 僅用於 action 的身分交換；workflow 不持有 repository content write 權限，也不建立 retry、Agent 或後續派工。

## Architecture Decisions

### 1. 使用 GitHub-hosted runner

採用 `ubuntu-latest`，讓 workflow 與本機電腦完全解耦。這也避免為單一每日 wake 維護 self-hosted runner。

### 2. 使用 OAuth Secret

`CLAUDE_PISCEAN0619_OAUTH_TOKEN` 僅存在 GitHub Actions Secret，不寫入 repository。workflow 只引用 secret name。

### 3. 權限採最小集合

workflow 使用：

~~~yaml
permissions:
  contents: read
  id-token: write
~~~

`contents: read` 供 checkout；`id-token: write` 是 Claude Code Action 取得 OIDC token 所需，並不提供 repository content write。

### 4. 固定第三方 Action SHA

Public Automation-Hub 的 security audit 要求所有 `uses:` reference 使用 immutable 40 字元 commit SHA。版本資訊只以註解保留，避免 movable tag 被替換。

### 5. 最小 Claude invocation

Claude 使用低成本模型並限制 `--max-turns 1`。Prompt 明確要求只回覆 `OK`，且不得檢查檔案、使用工具或修改 repository。

### 6. 不自動 retry

V1 不做 retry，以避免一次排程事件意外產生多次 Claude request。失敗直接由 Actions run 顯示並供人工判讀。

## Failure Modes

- OAuth Secret 缺失或失效：Claude step 失敗，workflow 結束。
- OIDC 權限缺失：Claude Code Action 無法取得 OIDC token。
- Action SHA 無效：setup step 失敗，不執行 Claude。
- GitHub scheduler 延遲：接受非 hard-real-time 的執行延遲，不把數分鐘延遲視為功能失敗。
- Claude model alias 失效：另開修正，僅替換 model reference。

## Verification

- `workflow_dispatch` smoke test 必須 success。
- 成功 run 中 Claude step 必須 success、`max-turns=1`。
- Actions log 中 OAuth token 必須被遮罩。
- Security audit 必須 PASS。
- `openspec validate --all --strict` 必須 PASS。
- 下一筆真實 `schedule` event 必須在 Mac 不在線時成功後，才能完成 scheduled runtime 驗收。
