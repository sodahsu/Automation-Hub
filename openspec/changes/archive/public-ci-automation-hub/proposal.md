# 提案：public-ci-automation-hub

## 為什麼要做

六個 private repositories 原本都依賴 GitHub-hosted Actions 執行 CI，但 private-repository Actions quota 已用盡，因此 lint、typecheck、test、build 與 repository health checks 都不能再假設能正常執行。

復原方案是：六個來源儲存庫繼續維持 Private，但把 CI workload 改由 Public `Automation-Hub` 執行。

Hub 會在 runtime 使用 least-privilege fine-grained token，以 read-only 方式存取指定的 private repository，在標準 Public GitHub-hosted runner 上執行 repository-native checks，最後只輸出經過清理的狀態摘要。

因為本儲存庫是 Public，所以除了 source content 與 credential 之外，private-repository metadata 也必須受到保護。

因此已 commit 的設定只能使用 `repo-01`～`repo-06` 這類 public-safe alias；真實 alias-to-repository mapping 必須留在 GitHub Secrets。

## 變更內容

1. 建立 `Automation-Hub` 作為六個 private repositories 的 Public CI orchestrator。
2. 新增可手動執行的 CI workflow，input 只接受 public-safe target alias。
3. 在 runtime 從 private mapping 解析真實 repository。
4. 使用 read-only fine-grained token checkout 指定 private repository。
5. 偵測 repository 既有 package manager 與 repository-native CI command。
6. 在不修改 source 的前提下執行可用的 install / lint / typecheck / test / build。
7. 加入嚴格的 log、artifact、cache、timeout、concurrency 與 cleanup 控制。
8. Phase 1 完全排除 production deployment 與所有 private-repository write path。
9. 保留 private repositories 既有 workflow 作為 rollback / reference，復原期間不刪除、不停用。

## 範圍

- 僅修改 `Automation-Hub`。
- 六個 private targets 對外只表示為 `repo-01`～`repo-06`。
- 使用 Public GitHub-hosted standard runner。
- Read-only checkout 與 CI / health validation。
- 初始 trigger：`workflow_dispatch`。
- Public summary 只顯示 PASS / FAIL / SKIP 與 step name，不輸出 private source content。

## 不包含

- 不把任何 private repository 改成 Public。
- 不在已 commit 檔案中公開 private repository 真名。
- Phase 1 不對 private repository 執行 write、commit、push、tag、merge，也不建立自動 PR。
- 不執行 production deployment。
- 不修改 Vercel、Cloudflare、Pages、release、database、billing、branch protection 或 repository visibility 設定。
- Workflow code 不建立、不輪替 token。
- 不把 private checkout、含 private source 的 build output、notes 或 environment files 上傳成 Artifact。
- 初始復原期間不刪除、不停用 private-repository 既有 workflow。
- 不假設六個 repositories 使用相同 runtime 或 package manager。

## 驗收條件

- `Automation-Hub` 維持 Public，六個 target repositories 維持 Private。
- 已 commit 檔案不包含 private repository 真名或 clone URL。
- Target selection 只使用 alias。
- 真實 repository mapping 與 read token 透過 GitHub Secrets 提供。
- Private token 權限僅限 selected repositories 的 read-only Contents / Metadata。
- 手動 run 可以選一個 alias，在 Public runner checkout target 並執行支援的 CI checks。
- 缺少 optional script 時回報 `SKIP`，而不是自行發明 requirement。
- CI 不修改、也不 push private checkout。
- Log 不主動輸出 source file、note、environment value、token value 或 repository mapping。
- 解析出的 private repository identifier 在後續使用前必須先 masking。
- Artifact 預設停用。
- Repository source directory 不進 cache。
- Job 必須有 timeout 與 concurrency control。
- Failure output 只指出失敗 stage，不 dump private source。
- Job 結束後必須刪除 private workspace。
- 既有 private workflow 繼續保留，作為 rollback / reference。
