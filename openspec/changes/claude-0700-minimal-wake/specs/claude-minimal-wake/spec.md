## Purpose

提供一個與本機環境解耦的最小 Claude 喚醒機制：每天台灣時間 07:00 對指定 Claude 帳號送出一次單回合請求，並以最小權限與可驗證方式執行。主要觸發來源為外部排程對 `workflow_dispatch` 的呼叫；GitHub `schedule` 只作備援，且受冪等防呆約束，同一個台北日期不會重複喚醒。

## ADDED Requirements

### Requirement: 系統 MUST 每天 07:00 觸發一次 Claude minimal wake，主要來源為外部排程

系統 **MUST** 在 `Asia/Taipei` 時區每天 07:00 建立一次 Claude minimal wake。主要觸發來源 **MUST** 是外部排程（cron-job.org）呼叫本 workflow 的 `workflow_dispatch` endpoint；GitHub `schedule` **MUST** 保留為備援，且 **MUST NOT** 被當成 07:00 的準點來源，因為其實測觸發時間落在台北 08:28–11:15（證據：archive 後位於 `openspec/changes/archive/2026-10-23-claude-0700-minimal-wake/evidence/scheduled-runs-2026-10-23.md`）。

#### Scenario: 外部排程在 07:00 到達

- **WHEN** 外部排程在 `Asia/Taipei` 07:00 以 `POST` 呼叫本 workflow 的 dispatches endpoint
- **THEN** GitHub Actions **MUST** 建立 wake workflow run，event 為 `workflow_dispatch`
- **AND** run 的建立時間 **SHOULD** 落在 07:00 ± 5 分鐘內
- **AND** workflow **MUST** 使用 GitHub-hosted runner
- **AND** 本機 Mac、Orca 或 self-hosted runner **MUST NOT** 成為執行 dependency

#### Scenario: GitHub schedule 備援觸發

- **WHEN** GitHub `schedule` 事件啟動 workflow
- **THEN** workflow **MUST** 先通過冪等防呆，才可呼叫 Claude
- **AND** 系統 **MUST NOT** 以 `schedule` run 的建立時間作為「07:00 準時」的證據

### Requirement: Schedule 備援 MUST 冪等，同一台北日期最多一次成功喚醒

由 `schedule` 事件觸發時，workflow **MUST** 先查詢本 workflow 在同一個台北日期（`Asia/Taipei` 00:00:00–23:59:59）內是否已有一次成功的喚醒；已有就 **MUST** 跳過（`SKIP`），且 **MUST NOT** 呼叫 Claude。「成功的喚醒」**MUST** 定義為：當日某個 run 中，呼叫 Claude 的 step conclusion 為 `success`；整體 conclusion 為 `success` 但 Claude step 被跳過或失敗的 run **MUST NOT** 計入。

#### Scenario: 當日已有成功的喚醒

- **WHEN** `schedule` 事件啟動 workflow
- **AND** 同一台北日期內已有一個 run 的 Claude step conclusion 為 `success`
- **THEN** 防呆 **MUST** 輸出不喚醒的結果
- **AND** Claude step **MUST NOT** 執行
- **AND** step summary **MUST** 記錄 `SKIP` 與命中的 run id

#### Scenario: 當日尚無成功的喚醒

- **WHEN** `schedule` 事件啟動 workflow
- **AND** 同一台北日期內沒有任何 run 的 Claude step conclusion 為 `success`
- **THEN** 防呆 **MUST** 放行，workflow 照常呼叫一次 Claude

#### Scenario: 防呆無法查到歷史

- **WHEN** `schedule` 事件啟動 workflow
- **AND** 查詢當日 run 或其 jobs 的 API 失敗，或回應格式不符
- **THEN** 防呆 **MUST** fail closed：不呼叫 Claude，且防呆 step **MUST** 失敗，使該次 run 為紅燈而可被看見
- **AND** workflow **MUST NOT** 自動 retry

#### Scenario: 外部排程與手動觸發不受防呆限制

- **WHEN** 事件為 `workflow_dispatch`（外部排程或使用者手動）
- **THEN** workflow **MUST** 直接執行 Claude minimal request，不查詢當日歷史

### Requirement: 外部排程的 dispatch credential MUST 專用且最小

外部排程呼叫 dispatches endpoint 所用的 token **MUST** 是專用的 fine-grained token，只授權 `sodahsu/Automation-Hub` 的 Actions read/write 與 Metadata read；**MUST NOT** 與任何 private repository credential（例如 `PRIVATE_REPOS_*`）共用，token value **MUST NOT** 出現在 committed repository content。

#### Scenario: 設定外部排程

- **WHEN** 使用者在外部排程服務設定 07:00 job
- **THEN** token **MUST** 只存在於該服務的 request header
- **AND** repository 內的文件 **MUST** 只描述 URL、method、header 名稱與 body 格式，**MUST NOT** 包含 token value

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

Wake workflow **MUST** 只取得完成執行所需的最低 GitHub Actions 權限：`contents: read`、Claude Code Action OIDC 身分交換所需的 `id-token: write`，以及冪等防呆讀取本 workflow 歷史 run 所需的 `actions: read`。其中 `id-token: write` **MUST NOT** 被視為 repository content write permission，`actions: read` **MUST NOT** 被擴大為 `actions: write`。

#### Scenario: Workflow 取得 GitHub token 與 OIDC token

- **WHEN** GitHub Actions 建立 wake job
- **THEN** workflow **MUST** 使用 `contents: read`
- **AND** workflow **MUST** 使用 `id-token: write` 供 Claude Code Action 取得 OIDC token
- **AND** workflow **MUST** 使用 `actions: read`，且 **MUST NOT** 持有 `actions: write`
- **AND** checkout **MUST NOT** persist Git credential
- **AND** workflow **MUST NOT** commit、push、建立 branch、PR 或 issue

### Requirement: Third-party Actions MUST 固定 immutable commit SHA

Wake workflow 使用的第三方 GitHub Actions **MUST** 固定到 40 字元 immutable commit SHA，不得只使用可移動 tag。

#### Scenario: Workflow 載入第三方 Action

- **WHEN** workflow 使用 `actions/checkout` 或 `anthropics/claude-code-action`
- **THEN** `uses:` reference **MUST** 為 40 字元 commit SHA
- **AND** 可在行尾註記對應版本名稱供人工辨識

### Requirement: Wake MUST 支援 manual smoke test

系統 **MUST** 保留 `workflow_dispatch`，使 wake 在正式啟用前可以手動驗證；它同時是外部排程的呼叫入口。

#### Scenario: 使用者手動觸發

- **WHEN** 使用者從 GitHub Actions 執行 manual dispatch
- **THEN** workflow **MUST** 執行與 scheduled wake 相同的 Claude minimal request
- **AND** 不得因 manual trigger 額外取得 repository content write permission

### Requirement: Wake MUST NOT 被定義為 Claude 額度 reset 保證

本功能 **MUST** 只把「建立一次有效 Claude request」視為契約；系統不得把 Claude usage window 或 reset time 視為由本 workflow 可控制的保證行為。

#### Scenario: 07:00 wake 成功

- **WHEN** 07:00 Claude request 成功完成
- **THEN** 系統 **MAY** 記錄後續 usage window 的觀察結果
- **BUT** 系統 **MUST NOT** 宣稱或依賴固定的 07:00 reset contract
