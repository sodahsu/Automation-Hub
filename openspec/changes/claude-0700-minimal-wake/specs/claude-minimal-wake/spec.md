## Purpose

提供一個與本機環境解耦的最小 Claude 喚醒機制：每天台灣時間 07:00 由 GitHub-hosted runner 對指定 Claude 帳號送出一次單回合請求，並以最小權限與可驗證方式執行。

## ADDED Requirements

### Requirement: 系統 MUST 每天 07:00 觸發一次 Claude minimal wake

系統 **MUST** 使用 GitHub Actions scheduled workflow，在 `Asia/Taipei` 時區每天 07:00 建立一次 Claude minimal wake。

#### Scenario: 每日排程到達

- **WHEN** `Asia/Taipei` 時間到達 07:00
- **THEN** GitHub Actions **MUST** 建立 wake workflow run
- **AND** workflow **MUST** 使用 GitHub-hosted runner
- **AND** 本機 Mac、Orca 或 self-hosted runner **MUST NOT** 成為執行 dependency

### Requirement: Wake MUST 使用指定 Claude 帳號的 OAuth Secret

Wake workflow **MUST** 透過 GitHub Actions Secret `CLAUDE_PISCEAN0619_OAUTH_TOKEN` 提供 Claude Code OAuth credential，且 credential value **MUST NOT** 出現在 committed repository content。

#### Scenario: Claude wake 開始

- **WHEN** workflow 呼叫 Claude Code Action
- **THEN** OAuth credential **MUST** 從 GitHub Actions Secret 注入
- **AND** committed YAML、OpenSpec、log summary **MUST NOT** 包含 token value

### Requirement: Wake request MUST 維持最小單回合

Claude wake **MUST** 限制為單回合最小請求，不得在 V1 執行工作派送或 repository analysis。

#### Scenario: Claude 收到 wake prompt

- **WHEN** Claude Code Action 開始執行
- **THEN** `max-turns` **MUST** 為 1
- **AND** prompt **MUST** 只要求極短固定回應
- **AND** prompt **MUST NOT** 要求讀取 repository、掃描 private repo、建立 Agent 或修改檔案
- **AND** workflow **MUST NOT** 建立自動 retry loop

### Requirement: Wake workflow MUST 維持最小 repository 權限

Wake workflow **MUST** 只取得完成執行所需的最低 GitHub Actions 權限：`contents: read` 與 Claude Code Action OIDC 身分交換所需的 `id-token: write`。其中 `id-token: write` **MUST NOT** 被視為 repository content write permission。

#### Scenario: Workflow 取得 GitHub token 與 OIDC token

- **WHEN** GitHub Actions 建立 wake job
- **THEN** workflow **MUST** 使用 `contents: read`
- **AND** workflow **MUST** 使用 `id-token: write` 供 Claude Code Action 取得 OIDC token
- **AND** checkout **MUST NOT** persist Git credential
- **AND** workflow **MUST NOT** commit、push、建立 branch、PR 或 issue

### Requirement: Third-party Actions MUST 固定 immutable commit SHA

Wake workflow 使用的第三方 GitHub Actions **MUST** 固定到 40 字元 immutable commit SHA，不得只使用可移動 tag。

#### Scenario: Workflow 載入第三方 Action

- **WHEN** workflow 使用 `actions/checkout` 或 `anthropics/claude-code-action`
- **THEN** `uses:` reference **MUST** 為 40 字元 commit SHA
- **AND** 可在行尾註記對應版本名稱供人工辨識

### Requirement: Wake MUST 支援 manual smoke test

系統 **MUST** 保留 `workflow_dispatch`，使 scheduled wake 在正式啟用前可以手動驗證。

#### Scenario: 使用者手動觸發

- **WHEN** 使用者從 GitHub Actions 執行 manual dispatch
- **THEN** workflow **MUST** 執行與 scheduled wake 相同的 Claude minimal request
- **AND** 不得因 manual trigger 額外取得 repository content write permission

### Requirement: Wake MUST NOT 被定義為 Claude 額度 reset 保證

本功能的契約只涵蓋「建立一次有效 Claude request」，不得把 Claude usage window 或 reset time 視為由本 workflow 可控制的保證行為。

#### Scenario: 07:00 wake 成功

- **WHEN** 07:00 Claude request 成功完成
- **THEN** 系統 **MAY** 記錄後續 usage window 的觀察結果
- **BUT** 系統 **MUST NOT** 宣稱或依賴固定的 07:00 reset contract
