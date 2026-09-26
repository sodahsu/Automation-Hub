# Automation-Hub

公開、唯讀的私有儲存庫 CI 協調中心。

Automation-Hub 的用途，是在六個來源儲存庫維持 Private 的前提下，改由 Public GitHub-hosted runner 執行 CI 與健康檢查。所有 private repo 存取都維持唯讀，公開輸出只保留經過清理的狀態摘要，production deployment 不在本專案範圍內。

目前支援四種執行方式：

- **手動單倉執行**：從 Actions 選擇 `repo-01`～`repo-06`。
- **PR head 驗證**：對 repo-01～05 的 Ready PR head 跑同一套 CI，並把結果回寫為 PR 上的 commit status（見「PR 模式」）。
- **每 15 分鐘變更偵測**：只有偵測到 private repo 有新的 push activity 才執行對應 alias。
- **Hub 自身回歸測試**：`private-ci.yml` 或共用 adapter 程式碼在 `main` 變更時，自動跑一次六倉 regression。

## 架構

~~~text
手動 workflow_dispatch
或每 15 分鐘 change detector
            |
            v
repo-01 .. repo-06          僅公開 alias
            |
            v
PRIVATE_REPOS_JSON           GitHub Secret
            |
            v
private repository           僅在 runtime 解析
            |
            |  PRIVATE_REPOS_READ_TOKEN
            v
暫存 workspace/
            |
            +--> install
            +--> lint      （若存在）
            +--> typecheck （若存在）
            +--> test      （若存在）
            +--> build     （若存在）
            |
            v
只公開 PASS / FAIL / SKIP 摘要

PR 模式（dispatch 帶 sha，僅 repo-01..05）：

resolve ──> mark-pending ──> ci ──> report
（驗證輸入） （STATUS_TOKEN）  （READ_TOKEN，  （STATUS_TOKEN）
              寫 pending      跑 private     寫 success /
                              程式碼）       failure / error
~~~

## 必要的 GitHub Actions Secrets

請手動到 **Settings → Secrets and variables → Actions** 建立。

### `PRIVATE_REPOS_READ_TOKEN`

使用 fine-grained GitHub personal access token，且只授權指定的 private repositories。

目前需要的 repository permissions：

- Contents：Read-only
- Metadata：Read
- Pull requests：Read-only（detector 列出 open PR）
- Commit statuses：Read-only（detector 判斷 head 是否已驗證）

不要授予 private repo write 權限。

### `PRIVATE_REPOS_STATUS_TOKEN`

PR 模式回寫 commit status 專用的第二支 fine-grained personal access token，是 Automation-Hub 唯一的 private repo 寫入 credential。

- Repository access：只選 repo-01～05 對應的 private repositories（不含 repo-06）
- Commit statuses：Read and write
- Metadata：Read

不授予 Contents、Pull requests 或其他 write 權限，因此無法改 code、branch 或 PR。這支 token 只出現在 `mark-pending` 與 `report` 兩個 job，執行 private 程式碼的 `ci` job 拿不到它。

### `PRIVATE_REPOS_JSON`

用 JSON object 保存 public alias 與 private repository 的 runtime 對照。

概念格式：

~~~json
{
  "repo-01": "<owner/private-repository>",
  "repo-02": "<owner/private-repository>",
  "repo-03": "<owner/private-repository>",
  "repo-04": "<owner/private-repository>",
  "repo-05": "<owner/private-repository>",
  "repo-06": "<owner/private-repository>"
}
~~~

真實 mapping 不得 commit 到 Public repo。

## 手動執行 CI

1. 開啟 **Actions**。
2. 選擇 **Private CI Bridge (read-only)**。
3. 點 **Run workflow**。
4. 選擇 `repo-01`～`repo-06`。
5. 執行。

手動模式只執行所選的一個 alias。

不帶 `sha` 時，bridge 檢查 private target 的 default branch，避免把 private branch/ref 名稱暴露為 Public workflow input。

## PR 模式（驗證 PR head）

private repo 自己的 Actions 停擺時（例如帳號付款問題），PR 仍可取得合併前的 CI 證據。

- 手動：在 **Run workflow** 選 `repo-01`～`repo-05`，並在 `sha` 填 PR head 的 40 碼 commit SHA。`sha` 只接受 `^[0-9a-f]{40}$`，且不支援 `repo-06`；格式錯誤會在任何網路請求前失敗。不接受分支名稱。
- 自動：detector 每輪列出 repo-01～05 的 open、非 Draft PR，head SHA 上還沒有 `automation-hub/private-ci` status 的就 dispatch 一次。Draft 不跑；已有任何狀態的 status 不重跑（要重跑就手動 dispatch）。
- 結果：`automation-hub/private-ci` commit status 依序為 `pending` → `success`／`failure`／`error`，`target_url` 指向 Public run，description 只含清理過的 PASS／FAIL／SKIP 計數。
- job 名稱為 `CI — <alias> · PR`，不會被 detector 當成 default branch 的結果；concurrency group 帶入 sha，不會卡住 main 的健康檢查。
- Detector 的 step summary 只寫每個 alias 的 `PR RUN n / PR SKIP m` 計數，不寫 PR 編號、標題、分支或作者。

PR 模式假設 PR 程式碼與 default branch 同樣可信（同一 owner 與其 AI 代理）；若日後接受外部貢獻者的 PR，必須重新評估，因為 PR 程式碼會在持有 read token 的 job 中執行。

## 每 15 分鐘偵測 private repo 變更

Detector workflow：`.github/workflows/detect-private-changes.yml`

喚醒來源：外部 scheduler（cron-job.org）每 15 分鐘呼叫 detector 的 `workflow_dispatch`，設定與專用 token 規範見 `docs/external-scheduler.md`。GitHub 原生 `schedule` 在本儲存庫實測幾乎不觸發，已移除。

Detector 不會固定重跑六倉，而是：

1. 以 alias 讀取六個 private repo 的 repository metadata。
2. 取得 private repo 的 `pushed_at`。
3. 查詢該 alias 最近一次 Public CI job 的 `started_at`。
4. 若最近 CI 已在最新 push 之後開始，標記為 `SKIP`。
5. 若有更新的 push，才透過 Public Automation-Hub 自己的 `workflow_dispatch` 執行該 alias。
6. 若該 alias 已有 CI 執行中，標記為 `WAIT`，下一輪再判斷，避免重複排隊。

這個 detector 不保存 private commit SHA，也不持有 private repo write 權限（write 只在 PR 模式的 `mark-pending`／`report` job）。只有 Public Automation-Hub 的 detector job 具有 `actions: write`，用途僅限觸發既有 Public CI workflow。

因為採用 repository-level `pushed_at`，其他 branch 的 push 可能造成一次額外 default-branch CI；這是刻意採用的保守策略。

**Hub CI 綠燈的意思是「該 repo 的 default branch 健康」，不代表剛 push 的 feature branch 通過。** feature branch 由各 private repo 自己的 CI 負責；PR head 另可透過 PR 模式取得驗證（不強制為合併條件）。

## Hub 自身的六倉 regression

當下列檔案在 `main` 變更時，會自動跑六倉 regression：

- `.github/workflows/private-ci.yml`
- `scripts/common/**`

用途是驗證 orchestration code 自己沒有把六倉 CI 跑壞。

Regression matrix：

- `fail-fast: false`
- `max-parallel: 2`
- 六個 alias 各自獨立執行

## 支援的 CI adapter

### 一般 Node 專案

有 `package.json` 的 Node-family repositories 會依 lockfile 判斷 package manager：

- `pnpm-lock.yaml` → pnpm
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `bun.lock` / `bun.lockb` → 可辨識，但目前不執行，直到 Bun adapter 完成 review

執行原則：

1. 安裝 dependency。
2. 若 target 已有 `check:ci`，優先執行。
3. 否則依序執行既有的 `lint` / `typecheck` / `test` / `build`。
4. 不存在的 optional script 標記為 `SKIP`。
5. 不自行發明 target repo 原本沒有的 CI command。

### `repo-04` 專屬 adapter

`repo-04` 的 private CI 比 package-level `check:ci` 更完整，因此 Hub 額外鏡像其唯讀驗證 gate，包括：

- ShellCheck
- governance
- architecture tests / contract / drift
- skill resolver / registry / routing
- runner integration
- skill audit
- shared-path audit
- spec-governance
- spec-truth-gate
- target 原有 `check:ci`

Adapter 只建立沒有 remote、沒有 credential 的本機暫時 Git baseline；cleanup 時整個 workspace 都會移除。

### `repo-05` contract adapter

`repo-05` 不是一般 package-manager CI target。

Hub 會鏡像其 contract-oriented CI：

- Python unit tests
- candidate contract validation
- architecture contract validation
- strict OpenSpec validation

此 alias 使用 Node `20.19.0`，與原 private CI 對齊。

原本獨立的 scheduled upstream-watch 不納入一般 CI，因為它屬於 monitoring/reporting，而不是 source validation gate。

### `repo-06` Vault Health adapter

`repo-06` 是大型內容型儲存庫，因此不下載完整 archive，而使用與原 Vault Health workflow 對齊的 sparse read-only Git checkout。

Checkout 完成後：

- 保留本機 Git metadata，供唯讀 health inventory 使用。
- 移除所有 remote。
- CI 階段不再持有 private repo credential。

Adapter 只執行結構性、唯讀的 Vault Health gate，並壓制 private report body，不讓內容進入 Public log。

## Public log 政策

Private repository CI 的 stdout/stderr 會先寫入 runner 的暫存檔，不會預設直接印到 Public log。

Public summary 只包含：

- target alias
- adapter / package manager
- stage name
- PASS / FAIL / SKIP
- 失敗 stage 的 exit code

禁止上傳 private source artifact。

## GitHub Actions command-file 隔離

執行 private repository CI 時，會把下列 GitHub command files 改成 runner 暫存位置：

- `GITHUB_STEP_SUMMARY`
- `GITHUB_OUTPUT`
- `GITHUB_ENV`
- `GITHUB_PATH`

目的在避免 target tooling 直接把 private summary、output、environment mutation 或 PATH mutation 注入 Public orchestration job。

Cleanup 階段會刪除所有暫存 command files，最後只發布 Hub 自己產生的 sanitized summary。

## OpenSpec

目前主要變更：

- `openspec/changes/public-ci-automation-hub/` — Phase 1 唯讀 CI 復原與六倉 rollout。
- `openspec/changes/run-private-pr-heads/` — PR head 驗證與 commit status 回寫。
- `openspec/specs/private-change-detection/`（change 已歸檔於 `openspec/changes/archive/2026-09-25-automatic-private-ci-sweep/`）— 每 15 分鐘 private change detector 與 Hub-code regression trigger。

實作需同時遵守兩個 change 中的安全、遷移與驗證規則。
