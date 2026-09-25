## ADDED Requirements

### Requirement: Private repository 變更偵測 MUST 每 5 分鐘執行

系統 **MUST** 每 5 分鐘喚醒 Public Automation-Hub 的 detector workflow，檢查六個 private repository aliases 的 push activity。喚醒來源為外部 scheduler 呼叫 detector 的 `workflow_dispatch`；外部 scheduler **MUST** 使用只具 Automation-Hub Actions read/write 權限的專用 token。

#### Scenario: 排程時間到達

- **WHEN** 外部 scheduler 在排程時間呼叫 detector 的 `workflow_dispatch`
- **THEN** detector **MUST** 檢查 `repo-01`～`repo-06`
- **AND** detector **MUST NOT** 因為排程本身就固定執行六倉完整 CI

### Requirement: Detector MUST 只對有新 push 的 alias dispatch CI

Detector **MUST** 以 private repository 的 `pushed_at` 與該 alias 最近一次 Public CI job 的 `started_at` 比較，只有新 push 尚未被既有 CI 涵蓋時才 dispatch。

#### Scenario: 沒有新 push

- **WHEN** 最近一次 CI job 的 `started_at` 晚於或等於 private repository 的 `pushed_at`
- **THEN** detector **MUST** 標記該 alias 為 `SKIP`
- **AND** **MUST NOT** dispatch 新的 CI run

#### Scenario: 有新的 push

- **WHEN** private repository 的 `pushed_at` 晚於最近一次 CI job 的 `started_at`
- **THEN** detector **MUST** dispatch `private-ci.yml`
- **AND** dispatch input **MUST** 只包含該 public-safe alias

### Requirement: 執行中的 alias MUST 避免重複排隊

Detector **MUST** 檢查最近 CI job 的 execution status，避免同一 alias 在既有 CI 尚未結束時無限制重複 dispatch。

#### Scenario: CI 正在執行且尚未涵蓋最新 push

- **WHEN** alias 有 CI job 尚未完成
- **AND** 該 CI job 的 `started_at` 早於最新 `pushed_at`
- **THEN** detector **MUST** 標記為 `WAIT`
- **AND** **MUST NOT** 在本輪重複 dispatch
- **AND** 下一輪 detector **MUST** 重新判斷

### Requirement: Private CI MUST 只驗證 default branch

由 detector 觸發的 private CI **MUST** 取得 private repository 的 default branch，且 **MUST NOT** 將 private branch 或 ref 名稱作為 Public workflow input。

#### Scenario: 非 default branch 有新 push

- **WHEN** private repository 的非 default branch 有新 push，使 `pushed_at` 更新
- **THEN** detector **MAY** dispatch 該 alias 的 CI
- **AND** 該 CI **MUST** 驗證 default branch，而非被 push 的 branch
- **AND** CI 結果 **MUST** 被解讀為 default branch 健康狀態，不作為 feature branch 的驗證結果

### Requirement: Private repository access MUST 維持 read-only

Detector **MUST** 沿用 selected-repository read-only credential 取得 private repository metadata，且 **MUST NOT** 增加 private repository write permission。

#### Scenario: 讀取 private repository metadata

- **WHEN** detector 查詢 private repository metadata
- **THEN** private credential **MUST** 只用於 read-only GitHub API request
- **AND** private repository identifier **MUST** 在後續 log 使用前 masking
- **AND** detector **MUST NOT** 對 private repository 建立 commit、branch、tag、PR 或其他 mutation

### Requirement: Public Hub dispatch permission MUST 與 private credential 分離

Detector 對 Public Automation-Hub 的 `actions: write` **MUST** 只用於 dispatch Hub 自己的 CI workflow，且 **MUST NOT** 傳遞給 private target code。

#### Scenario: Detector 發現新 push

- **WHEN** detector 需要啟動對應 alias 的 CI
- **THEN** Public Hub token **MUST** 只呼叫 Automation-Hub 的 workflow dispatch endpoint
- **AND** private target CI execution **MUST NOT** 取得該 dispatch credential

### Requirement: Detector MUST 不長期保存 private commit metadata

Detector **MUST NOT** 將 private commit SHA、真實 repository mapping 或 private source 長期保存到 Public repository、Artifact 或 cache。

#### Scenario: Detector 完成一輪 polling

- **WHEN** metadata comparison 完成
- **THEN** 暫存 metadata file **MUST** 留在 ephemeral runner
- **AND** Public summary **MUST** 只包含 alias 與 `RUN` / `SKIP` / `WAIT` decision
