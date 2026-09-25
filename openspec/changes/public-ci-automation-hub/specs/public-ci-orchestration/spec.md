## ADDED Requirements

### Requirement: Public Hub 執行 CI，同時 target repositories 維持 Private

系統必須從 Public `Automation-Hub` 執行 Phase 1 CI，同時六個 target repositories 必須維持 Private。

#### Scenario: 手動要求執行某個 private target 的 CI

- **WHEN** 授權使用者手動 dispatch Hub，並選擇支援的 target alias
- **THEN** job 必須在 Public Hub 的標準 GitHub-hosted runner 上執行
- **AND** target repository 必須維持 Private
- **AND** workflow 不得變更 target repository visibility

### Requirement: Private target identity 只能在 runtime 解析

已 commit 的 Hub 檔案必須只使用 public-safe alias：`repo-01`～`repo-06`。

Alias-to-private-repository mapping 必須在 runtime 由 GitHub Secret 提供，且不得 commit。

#### Scenario: 解析 repository mapping

- **WHEN** workflow 把 alias 解析成 private repository identifier
- **THEN** 必須在後續 command 使用前先 mask 該 identifier
- **AND** 不得把 identifier 寫入 committed files、Artifacts 或 summaries

#### Scenario: Alias 不存在

- **WHEN** requested alias 不存在於 Secret mapping
- **THEN** workflow 必須在 checkout 前 fail closed
- **AND** 不得猜測或 fallback 到其他 repository

### Requirement: Phase 1 private access 必須採 least-privilege read-only

Hub 必須使用 fine-grained token 存取 selected private repositories，且 repository permission 只限 checkout / CI 所需的 read access。

#### Scenario: 準備 target checkout

- **WHEN** Hub checkout selected private repository
- **THEN** authentication 必須來自 GitHub Secret
- **AND** workflow 不得對該 repository 執行 commit、push、tag、merge 或建立 branch

#### Scenario: 未來需要 write capability

- **WHEN** 未來 use case 需要 write access
- **THEN** Phase 1 workflow 不得靜默擴大 token permission
- **AND** write access 必須另開經 review 的 OpenSpec change

### Requirement: CI 使用 repository-native checks，且不得修改 source

Hub 只能執行 target repository 既有 runtime / configuration 所支援的 checks，不得修改 application source，也不得發明缺少的 project script。

#### Scenario: 存在標準 Node CI scripts

- **WHEN** target repository 提供支援的 lint、typecheck、test 或 build script
- **THEN** Hub 必須依該 repository 既有 package-manager / lockfile contract 執行適用的 scripts

#### Scenario: Optional script 不存在

- **WHEN** target 沒有定義某個 optional CI stage
- **THEN** Hub 必須把該 stage 回報為 `SKIP`
- **AND** 不得新增或合成替代 script

#### Scenario: Repository runtime 無法安全辨識

- **WHEN** generic adapter 無法判斷安全且支援的 runtime
- **THEN** job 必須停止，或改走經明確 review 的 target adapter
- **AND** 不得修改 checkout 來硬套 generic adapter

### Requirement: Public logs 不得暴露 private source 或 Secret

Hub 必須把 workflow log 視為公開輸出，並將內容縮減為 sanitized status information。

#### Scenario: CI 成功

- **WHEN** CI stages 完成
- **THEN** summary 可以顯示 target alias 與 PASS / FAIL / SKIP
- **AND** 不得輸出 token value、Secret mapping、note body、source-file content、environment file 或未核准的 private identifier

#### Scenario: CI 失敗

- **WHEN** 某個 CI stage 失敗
- **THEN** workflow 只需用最少診斷資訊指出 failing stage
- **AND** 不得因此 dump private workspace 或 full environment

### Requirement: Private checkout 必須是 ephemeral，且不可匯出

Private repository checkout 只能存在於目前 job 的 ephemeral runner workspace。

#### Scenario: Job 完成或失敗

- **WHEN** job 進入 cleanup
- **THEN** workflow 必須移除 private workspace
- **AND** 即使前面 step 失敗，cleanup 也必須執行

#### Scenario: 考慮 Artifact upload

- **WHEN** workflow 嘗試上傳 `workspace/`、source files、vault files、environment files 或含 source 的 build output
- **THEN** Phase 1 必須拒絕該 upload

### Requirement: Source checkout 不得 cache

Hub 不得 cache private source directory 或整個 private workspace。

#### Scenario: 未來新增 dependency cache

- **WHEN** 有人提議加入 dependency-manager cache
- **THEN** cache 必須只限已驗證不包含 private source 或 credential 的 dependency material
- **AND** 啟用前必須經過明確 review

### Requirement: CI jobs 必須有界且彼此隔離

每個 target execution 必須有明確 runtime bound 與 concurrency 行為。

#### Scenario: 同一 alias 有重複 run

- **WHEN** 同一 target 有多個 overlapping run
- **THEN** workflow 必須套用 target-scoped concurrency policy
- **AND** 避免無控制的 duplicate execution

#### Scenario: CI hang 住

- **WHEN** execution 超過設定的 job timeout
- **THEN** GitHub Actions 必須終止 job
- **AND** cleanup 仍必須嘗試執行

### Requirement: Production mutation 必須維持在 recovery path 之外

Phase 1 Hub 只能恢復 validation，不得執行 production deployment 或其他 production mutation。

#### Scenario: Target repository 已有 deploy workflow

- **WHEN** target repository 包含 deploy / release / publish workflow
- **THEN** 這些 workflow 必須維持在本 Hub change 之外
- **AND** 本 change 不得刪除、停用或重寫它們

### Requirement: 既有 private workflows 必須保留作為 rollback reference

Recovery implementation 必須與既有 private-repository workflow definitions 共存。

#### Scenario: Hub recovery 不再適用

- **WHEN** Hub 被停用、未通過 security review，或 private Actions capacity 恢復
- **THEN** target repositories 不應需要任何 source rollback
- **AND** 既有 private workflows 必須繼續可用，作為原本 reference path
