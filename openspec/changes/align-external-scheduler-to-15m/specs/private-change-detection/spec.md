## MODIFIED Requirements

### Requirement: Private repository 變更偵測 MUST 每 15 分鐘執行

系統 **MUST** 每 15 分鐘喚醒 Public Automation-Hub 的 detector workflow，檢查六個 private repository aliases 的 push activity。喚醒來源為外部 scheduler 呼叫 detector 的 `workflow_dispatch`；外部 scheduler **MUST** 使用只具 Automation-Hub Actions read/write 權限的專用 token。標準 minutes **MUST** 為 `0,15,30,45`。

#### Scenario: 排程時間到達

- **WHEN** 外部 scheduler 在排程時間呼叫 detector 的 `workflow_dispatch`
- **THEN** detector **MUST** 檢查 `repo-01`～`repo-06`
- **AND** detector **MUST NOT** 因為排程本身就固定執行六倉完整 CI

#### Scenario: Cadence migration 被宣告完成

- **WHEN** 系統宣告 external scheduler 已從舊 cadence 切換為 15 分鐘
- **THEN** 驗收證據 **MUST** 包含至少三個連續 `workflow_dispatch` detector runs 的 live timestamps
- **AND** 相鄰 run 間隔 **MUST** 符合約 15 分鐘 cadence
- **AND** repository 文件或 spec 更新 **MUST NOT** 單獨被視為 runtime migration 已完成

#### Scenario: Runtime 仍以 5 分鐘喚醒

- **WHEN** live detector runs 仍持續約每 5 分鐘出現
- **THEN** migration status **MUST** 保持 pending
- **AND** 系統 **MUST NOT** 宣稱 15 分鐘 cadence 已在 runtime 生效
