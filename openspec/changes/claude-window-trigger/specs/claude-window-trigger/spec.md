## ADDED Requirements

### Requirement: Claude window trigger 必須與實際派工分離

系統 **MUST** 只發送最小 Claude request，且 **MUST NOT** 啟動 Orca Dispatcher、repository sweep、Planner、Executor、Reviewer 或任何實際開發工作。

#### Scenario: Scheduled trigger 到點

- **WHEN** scheduled trigger 到達設定時間
- **THEN** workflow 只能進入 dry-run 或單次最小 Claude request
- **AND** 不得 checkout repository
- **AND** 不得啟動其他 AI 工作流程

### Requirement: Scheduled live 必須顯式啟用

Scheduled run **MUST** 預設為 dry-run，只有 repository variable `CLAUDE_WINDOW_TRIGGER_ENABLED` 明確等於 `true` 時才能發出 Claude request。

#### Scenario: Variable 未設定或不是 true

- **WHEN** schedule event 啟動 workflow
- **AND** `CLAUDE_WINDOW_TRIGGER_ENABLED` 不等於 `true`
- **THEN** workflow 必須只執行 dry-run
- **AND** 不得讀取或使用 Claude OAuth token

### Requirement: Live authentication 只能使用 Claude OAuth

Live request **MUST** 使用 `CLAUDE_CODE_OAUTH_TOKEN`，且 **MUST NOT** fallback 到 `ANTHROPIC_API_KEY`。

#### Scenario: OAuth token 缺少

- **WHEN** live 模式被要求
- **AND** `CLAUDE_CODE_OAUTH_TOKEN` 為空
- **THEN** workflow 必須 fail closed
- **AND** 不得嘗試 API PAYG authentication

#### Scenario: Repository 存在 API key

- **WHEN** live preflight 偵測到 `ANTHROPIC_API_KEY`
- **THEN** workflow 必須停止
- **AND** 不得呼叫 Claude action

### Requirement: Claude request 必須維持最小成本形態

Live trigger **MUST** 使用指定的低成本 Haiku 模型、固定短 prompt 與單一 agentic turn，且不得加入 repository context。

#### Scenario: 發送 live request

- **WHEN** authentication 與 enable guard 都通過
- **THEN** prompt 必須是 `Reply exactly: OK`
- **AND** `max-turns` 必須為 1
- **AND** 不得啟用 MCP、web search、shell、讀寫檔案或 sub-agent 工作

### Requirement: Workflow 執行必須有界

Trigger workflow **MUST** 設定單一 concurrency group 與 job timeout，且 **MUST NOT** 建立自動 retry loop。

#### Scenario: Trigger 重疊

- **WHEN** 新 trigger 啟動而舊 trigger 尚未完成
- **THEN** GitHub Actions 必須取消舊 run 或阻止重疊
- **AND** 不得因此額外發出重複 Claude requests

### Requirement: Schedule 必須使用台灣時區

Workflow **MUST** 使用 IANA timezone `Asia/Taipei`，並在每日 07:07、12:07、17:07、22:07 排程。

#### Scenario: Default branch 已包含 workflow

- **WHEN** GitHub scheduler 處理 schedule
- **THEN** workflow 應依 Asia/Taipei 的四個設定時段啟動
- **AND** scheduling delay 不得被解讀成 Claude usage reset 的保證

### Requirement: 28-window 假設必須實測

系統 **MUST NOT** 僅因每週存在 28 次 schedule 就宣稱已建立 28 個 Claude 五小時 usage windows。

#### Scenario: 啟用 live 後驗證 reset

- **WHEN** live trigger 已可使用
- **THEN** 使用者必須以 Claude Usage / reset time 驗證實際行為
- **AND** 至少觀察兩個工作日後才能判定排程是否達成預期 window alignment
