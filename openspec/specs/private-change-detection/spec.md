# private-change-detection Specification

## Purpose

定義 Public Automation-Hub 如何以外部排程偵測六個 private repositories 的變更、只對需要的 alias dispatch CI，並在不暴露 private branch/ref 的前提下驗證 default branch 與 Ready PR head。

## Requirements

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

### Requirement: Private CI MUST 只驗證 default branch 或具名 PR head SHA

由 detector 因 push activity 觸發的 private CI **MUST** 取得 private repository 的 default branch。PR head 驗證 **MUST** 只以 40 碼 commit SHA 作為 Public workflow input，且 **MUST NOT** 將 private branch 或 ref 名稱作為 Public workflow input。

#### Scenario: 非 default branch 有新 push

- **WHEN** private repository 的非 default branch 有新 push，使 `pushed_at` 更新
- **THEN** detector **MAY** dispatch 該 alias 的 default branch CI
- **AND** 該 CI **MUST** 驗證 default branch，而非被 push 的 branch
- **AND** CI 結果 **MUST** 被解讀為 default branch 健康狀態，不作為 feature branch 的驗證結果

#### Scenario: 以 SHA 驗證 PR head

- **WHEN** private CI 以 `sha` input 被 dispatch
- **THEN** `sha` **MUST** 符合 `^[0-9a-f]{40}$`，否則 **MUST** 在任何網路請求前失敗
- **AND** CI **MUST** 驗證該 commit 的內容
- **AND** job 名稱 **MUST** 與 default branch CI 區分，使 detector 的 default branch 追蹤不把它當成 default branch 結果

### Requirement: Private repository access MUST 維持 read-only

Detector 與 CI job **MUST** 沿用 selected-repository read-only credential 讀取 private repository，且 **MUST NOT** 增加 private repository 的 Contents 或 Pull requests write permission。唯一允許的寫入是以獨立 credential 寫 commit status。

#### Scenario: 讀取 private repository metadata

- **WHEN** detector 查詢 private repository metadata、open PR 或 commit status
- **THEN** private read credential **MUST** 只用於 read-only GitHub API request
- **AND** private repository identifier **MUST** 在後續 log 使用前 masking
- **AND** detector **MUST NOT** 對 private repository 建立 commit、branch、tag、PR 或其他 mutation

#### Scenario: 回寫 commit status

- **WHEN** PR 模式需要回寫驗證結果
- **THEN** 寫入 **MUST** 使用只具 Commit statuses 權限的獨立 credential
- **AND** 該 credential **MUST NOT** 出現在執行 private repository 程式碼的 job 中
- **AND** status description **MUST** 只包含經過清理的 PASS／FAIL／SKIP 摘要

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

### Requirement: Detector MUST 對 Ready PR head 各 dispatch 一次驗證

Detector **MUST** 對 repo-01～repo-05 的 open、非 Draft PR，在 head SHA 尚無 `automation-hub/private-ci` status 時 dispatch 一次 PR 模式 CI。

#### Scenario: 新的 Ready PR

- **WHEN** private repository 有 open、非 Draft PR，其 head SHA 沒有 `automation-hub/private-ci` status
- **THEN** detector **MUST** 以該 alias 與 head SHA dispatch 一次 PR 模式 CI

#### Scenario: Draft PR

- **WHEN** PR 仍為 Draft
- **THEN** detector **MUST NOT** dispatch PR 模式 CI

#### Scenario: 已有 status 的 head

- **WHEN** head SHA 已有任何狀態的 `automation-hub/private-ci` status
- **THEN** detector **MUST NOT** 重複 dispatch

#### Scenario: Summary 不洩漏 PR 資訊

- **WHEN** detector 寫入 step summary
- **THEN** summary **MUST** 只包含 alias 與計數
- **AND** **MUST NOT** 包含 PR 編號、標題、分支名或作者

### Requirement: PR 模式 MUST 把結果回寫為 commit status

PR 模式 CI **MUST** 在開始時對 head SHA 寫入 `pending`，並在結束時寫入 `success`、`failure` 或 `error`，context 為 `automation-hub/private-ci`，`target_url` 指向 Public run。

#### Scenario: CI 通過

- **WHEN** PR 模式的 CI job 成功
- **THEN** head SHA 的 `automation-hub/private-ci` status **MUST** 為 `success`

#### Scenario: CI 失敗或未完成

- **WHEN** CI job 失敗
- **THEN** status **MUST** 為 `failure`
- **WHEN** CI job 被取消或無法取得原始碼
- **THEN** status **MUST** 為 `error`，不得停留在 `pending`

#### Scenario: repo-06 不支援 PR 模式

- **WHEN** `target` 為 `repo-06` 且帶有 `sha`
- **THEN** workflow **MUST** 在任何網路請求前失敗
