## MODIFIED Requirements

### Requirement: Detector MUST 對 Ready PR head 去重，bridge MUST 防止重複驗證

Detector **MUST** 對 repo-01～repo-06 的 open、非 Draft PR，在每次掃描依 alias／完整 head SHA 去重，且僅在該 SHA 尚無 `automation-hub/private-ci` status 時 dispatch PR 模式 CI。

#### Scenario: repo-06 Ready PR

- **WHEN** repo-06 有 open、非 Draft PR，且其 head SHA 尚無 `automation-hub/private-ci` status
- **THEN** detector **MUST** 以 repo-06 alias 與完整 head SHA dispatch PR 模式 CI
- **AND** bridge **MUST** 以該完整 SHA 寫入 pending 與最終 status

#### Scenario: 新的 Ready PR

- **WHEN** private repository 有 open、非 Draft PR，其 head SHA 沒有 `automation-hub/private-ci` status
- **THEN** detector **MUST** 以該 alias 與 head SHA dispatch 一次 PR 模式 CI

#### Scenario: Draft PR

- **WHEN** PR 仍為 Draft
- **THEN** detector **MUST NOT** dispatch PR 模式 CI

#### Scenario: 已有 status 的 head

- **WHEN** head SHA 已有任何狀態的 `automation-hub/private-ci` status
- **THEN** detector **MUST NOT** 重複 dispatch

#### Scenario: 重送與原始 run 重跑

- **WHEN** 同一 alias／SHA 的請求在 pending 可見前被重送
- **THEN** bridge **MUST** 序列化同一 alias／SHA 的 workflow，且已有 claim 時，新 run 不執行目標或改寫狀態
- **AND** 只允許原始 run 的較新 attempt 重新取得 claim；同一 attempt 不得重複執行或完成同一 claim

#### Scenario: Summary 不洩漏 PR 資訊

- **WHEN** detector 寫入 step summary
- **THEN** summary **MUST** 只包含 alias 與計數
- **AND** **MUST NOT** 包含 PR 編號、標題、分支名或作者

### Requirement: PR 模式 MUST 把結果回寫為 commit status

PR 模式 CI **MUST** 在開始時對指定的完整 head SHA 寫入 `pending`，且僅由該 claim 的擁有者在結束時向同一 SHA 寫入 `success`、`failure` 或 `error`。context 為 `automation-hub/private-ci`，`target_url` 指向 Public run attempt；公開摘要與 artifact 不得包含私有 SHA。

#### Scenario: repo-06 PR head 使用 sparse exact-SHA checkout

- **WHEN** `target` 為 `repo-06` 且帶有格式正確的 `sha`
- **THEN** workflow **MUST** 以與 default 模式相同的 sparse path 清單 checkout 該完整 SHA
- **AND** workflow **MUST** 在執行 adapter 前確認 checkout 的 HEAD 與輸入 SHA 完全相同
- **AND** 公開摘要與 artifact **MUST NOT** 包含該 SHA 或 private repository 資料

#### Scenario: CI 通過

- **WHEN** PR 模式的 CI job 成功
- **THEN** head SHA 的 `automation-hub/private-ci` status **MUST** 為 `success`

#### Scenario: CI 失敗或未完成

- **WHEN** 必要檢查回報失敗
- **THEN** status **MUST** 為 `failure`
- **WHEN** 缺少有效檢查／必要入口，或發生基礎設施錯誤
- **THEN** report 能執行且仍持有 claim 時 **MUST** 寫入 `error`，並以 `UNVERIFIED` 或 `INFRASTRUCTURE_ERROR` 區分
- **AND** report 遭取消或無法回寫時，未完成的 `pending` 不得視為通過
