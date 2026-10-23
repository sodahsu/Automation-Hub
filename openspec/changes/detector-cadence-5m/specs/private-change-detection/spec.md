## RENAMED Requirements

- FROM: `### Requirement: Private repository 變更偵測 MUST 每 15 分鐘執行`
- TO: `### Requirement: Private repository 變更偵測 MUST 每 5 分鐘執行`

## MODIFIED Requirements

### Requirement: Private repository 變更偵測 MUST 每 5 分鐘執行

系統 **MUST** 每 5 分鐘喚醒 Public Automation-Hub 的 detector workflow，檢查六個 private repository aliases 的 push activity。喚醒來源為外部 scheduler 呼叫 detector 的 `workflow_dispatch`；外部 scheduler **MUST** 使用只具 Automation-Hub Actions read/write 權限的專用 token。標準 minutes **MUST** 為每 5 分鐘，即 `0,5,10,15,20,25,30,35,40,45,50,55`。

#### Scenario: 排程時間到達

- **WHEN** 外部 scheduler 在排程時間呼叫 detector 的 `workflow_dispatch`
- **THEN** detector **MUST** 檢查 `repo-01`～`repo-06`
- **AND** detector **MUST NOT** 因為排程本身就固定執行六倉完整 CI

#### Scenario: 未帶 force 且 UTC 分鐘是 5 的倍數

- **WHEN** detector 被 `workflow_dispatch` 喚醒，且 `force` 不是 `true`
- **AND** 喚醒當下的 UTC 分鐘是 5 的倍數
- **THEN** detector **MUST** 做完整掃描

#### Scenario: 未帶 force 且 UTC 分鐘不是 5 的倍數

- **WHEN** detector 被 `workflow_dispatch` 喚醒，且 `force` 不是 `true`
- **AND** 喚醒當下的 UTC 分鐘不是 5 的倍數
- **THEN** detector **MUST** 在 step summary 記錄 `SKIP` 並立即結束
- **AND** **MUST NOT** 讀取 private API 或 dispatch CI

#### Scenario: 帶 force 的喚醒

- **WHEN** detector 被 `workflow_dispatch` 喚醒，且 `force` 為 `true`
- **THEN** detector **MUST** 略過節流並做完整掃描，不論 UTC 分鐘

#### Scenario: Cadence migration 被宣告完成

- **WHEN** 系統宣告 detector 的完整掃描 cadence 已從舊 cadence 切換為 5 分鐘
- **THEN** 驗收證據 **MUST** 包含至少六個連續 `workflow_dispatch` detector runs 的 live timestamps，且這些 run **MUST** 都做了完整掃描（不是節流 `SKIP`）
- **AND** 相鄰 run 間隔 **MUST** 符合約 5 分鐘 cadence
- **AND** repository 文件或 spec 更新 **MUST NOT** 單獨被視為 runtime migration 已完成

#### Scenario: Runtime 仍以 5 分鐘喚醒

- **WHEN** live detector runs 約每 5 分鐘被喚醒，但完整掃描仍約每 15 分鐘出現（其餘喚醒被節流為 `SKIP`）
- **THEN** migration status **MUST** 保持 pending
- **AND** 系統 **MUST NOT** 宣稱 5 分鐘 cadence 已在 runtime 生效

#### Scenario: Runtime 仍以 15 分鐘喚醒

- **WHEN** live detector runs 的喚醒本身仍約每 15 分鐘出現
- **THEN** migration status **MUST** 保持 pending
- **AND** 系統 **MUST NOT** 宣稱 5 分鐘 cadence 已在 runtime 生效
