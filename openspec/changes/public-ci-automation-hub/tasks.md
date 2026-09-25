# 任務：public-ci-automation-hub

## 0. 治理與邊界

- [x] 0.1 確認 `Automation-Hub` 是 Public orchestration repository。
- [x] 0.2 確認六個 target repositories 維持 Private。
- [x] 0.3 確認目前優先目標是在 private Actions quota 無法使用時恢復 CI。
- [x] 0.4 建立 public-safe aliases：`repo-01`～`repo-06`。
- [x] 0.5 禁止在已 commit 檔案公開 alias-to-private-repository mapping。
- [ ] 0.6 在 CLI / config 可用時，以 repository 支援的 OpenSpec strict command 驗證此 change。

## 1. Repository 安全骨架

- [x] 1.1 在 `.gitignore` 排除 `workspace/`、`repos/`、`tmp/`、`.env*` 與 `*.log`。
- [x] 1.2 建立 `SECURITY.md`，定義 Public repo / Private source 邊界。
- [x] 1.3 建立 README，說明架構與手動執行方式，不公開 private repository 真名。
- [x] 1.4 確認已 commit 設定不包含 private repository 名稱或 clone URL。

## 2. Secret 契約

- [x] 2.1 文件化必要 Secret：`PRIVATE_REPOS_READ_TOKEN`。
- [x] 2.2 文件化必要 Secret：`PRIVATE_REPOS_JSON`。
- [x] 2.3 Token 必須是 fine-grained、selected-repository only，且 Contents read-only + Metadata read。
- [x] 2.4 Repository code 不得建立、輸出、讀回或輪替 Secret value。
- [x] 2.5 任一必要 Secret 不可用時，preflight 必須失敗。

## 3. 手動 Dispatch Workflow

- [x] 3.1 建立 `workflow_dispatch`，input 只接受 public-safe target alias；Phase 1 只檢查 private target 的 default branch。
- [x] 3.2 Alias 限定為 `repo-01`～`repo-06`。
- [x] 3.3 Workflow permission 設為 `contents: read`。
- [x] 3.4 加入 per-target concurrency control。
- [x] 3.5 設定有界的 job timeout。
- [x] 3.6 不使用 `pull_request_target`。

## 4. 安全的 Target 解析與 Checkout

- [x] 4.1 Runtime 從 `PRIVATE_REPOS_JSON` 解析 alias。
- [x] 4.2 Unknown / empty / malformed target 必須 fail closed。
- [x] 4.3 後續 command 使用前先 mask 解析出的 repository identifier。
- [x] 4.4 使用 `PRIVATE_REPOS_READ_TOKEN` checkout 到 `workspace/`。
- [x] 4.5 避免輸出 clone URL 或 remote configuration；checkout 後清除 remote/origin 資訊。
- [x] 4.6 Target CI 相容時使用 shallow fetch。
- [x] 4.7 以 `always()` cleanup 移除 private workspace。

## 5. CI Adapter

- [x] 5.1 不修改 checkout，直接由 lockfile 偵測 package manager。
- [x] 5.2 支援的 Node package manager 使用 repository-native dependency install。
- [x] 5.3 有 `lint` 就執行，沒有就標記 `SKIP`。
- [x] 5.4 有 `typecheck` 就執行，沒有就標記 `SKIP`。
- [x] 5.5 有 `test` 就執行，沒有就標記 `SKIP`。
- [x] 5.6 有 `build` 就執行，沒有就標記 `SKIP`。
- [x] 5.7 不自行發明缺少的 package script。
- [x] 5.8 對需要額外驗證的 non-Node targets 建立經 review 的明確 adapter；repo-05 / repo-06 已完成。

## 6. Public Log / Artifact Gate

- [x] 6.1 禁止 `cat` / dump source file、note、`.env` 或完整 environment。
- [x] 6.2 Authentication / target resolution 階段禁止 `set -x`。
- [x] 6.3 停用 source / workspace Artifact upload。
- [x] 6.4 不 cache `workspace/` 或 private source。
- [x] 6.5 只輸出 sanitized stage status 與安全 aggregate metrics。
- [x] 6.6 檢查失敗 runs #1–#3 與成功 repo-01 run #4；fetched job log 沒有 known private repository name hit，Artifact count 為 0。

## 7. 單一 Target Pilot

- [x] 7.1 使用者手動建立具 selected-repository read-only scope 的 `PRIVATE_REPOS_READ_TOKEN`。
- [x] 7.2 使用者手動建立 `PRIVATE_REPOS_JSON`；runtime mapping 只存在 GitHub Actions Secret。
- [x] 7.3 對 pilot alias 執行 Public runner preflight 與 read-only private archive checkout。
- [x] 7.4 驗證 repo-01 成功 run：log 無 known private repository name、無 source Artifact，token 與 runtime target identifier 都維持 masking。
- [x] 7.5 Repository-native sanitized CI adapter 已完成並可執行。
- [x] 7.6 repo-01 證據：package-json PASS、npm PASS、install PASS、canonical `check:ci` PASS；15 個 test files / 135 tests 通過。
- [x] 7.7 Phase 1 archive checkout 不含 `.git`；CI step 不取得 private-repository token，因此沒有 repository write path。

## 8. 六倉 Rollout

- [x] 8.1 六個 alias mapping 全部只存在 Secret，不進 committed config。
- [x] 8.2 六個 alias 逐一驗證；repo-01～repo-06 都可透過 Public bridge 成功執行。
- [x] 8.3 Runtime 假設已確認：repo-01～repo-04 使用 Node 22 路徑；repo-05 使用 Python + Node 20.19.0；repo-06 使用 Python + sparse Git metadata。
- [x] 8.4 支援 CI stages 已確認：generic Node `check:ci`、repo-04 governance / architecture adapter、repo-05 candidate-contract adapter、repo-06 Vault Health adapter 均已實跑。
- [x] 8.5 Content-heavy target 使用 aggregate-only logging；repo-06 只發布 sanitized stage status，Public log 無 private report body 或 known private repository name。
- [x] 8.6 六倉自動 regression sweep #17 全部 PASS，並取得 sanitized per-target summaries。

## 9. 既有 Private Workflows

- [x] 9.1 Recovery 期間保持既有 private workflow 不變。
- [x] 9.2 各 target adapter 與原 private CI 的重疊/差異已在本 change Review 記錄。
- [x] 9.3 未經另案明確核准，不刪除、不停用 private workflow。
- [x] 9.4 Production deployment workflow 不納入本 migration。

## 10. 後續自動化 — 獨立決策

- [x] 10.1 Manual Hub 穩定後評估 scheduled polling / event bridge；最後選擇 read-only polling，避免新增 private write credential / infrastructure。
- [x] 10.2 Automatic triggering 已在獨立 change `automatic-private-ci-sweep` 實作。
- [x] 10.3 不為了 automatic trigger 而增加 private-repo write access。

## 11. Review / 完成條件

- [ ] 11.1 進行獨立 security review：real-run logs、masking、Artifacts、permissions、cleanup。
- [x] 11.2 已驗證 committed repository content 不包含 known private target identifier 或 Secret value。
- [x] 11.3 已驗證 private-repository hosted Actions quota 無法使用時，repo-01 仍可在 Public runner end-to-end 執行。
- [x] 11.4 Phase 1 已覆蓋六個 target adapters；六倉 regression run #17 亦全部 PASS。

## 實作檢查點 — 2026-09-25

已在 `main` 實作：

- `.gitignore`
- `SECURITY.md`
- `README.md`
- `.github/workflows/private-ci.yml`
- `scripts/common/run-ci.sh`

Runtime configuration 已完成，並由六倉逐步 rollout 驗證。

## 安全強化檢查點 — repo-01 run #4 後

- [x] 發現 private test tooling 即使 stdout/stderr 被壓制，仍可能寫入 Public `GITHUB_STEP_SUMMARY`。
- [x] Private CI execution 期間，把 `GITHUB_STEP_SUMMARY`、`GITHUB_OUTPUT`、`GITHUB_ENV`、`GITHUB_PATH` 改指向 temporary sink files。
- [x] `always()` cleanup 會移除 private command-file sink directory。
- [x] 重跑 repo-01 #5，確認 private tooling 不再注入自己的 Job Summary，只剩 Hub 產生的 sanitized summary。

## Rollout 檢查點 — repo-02 run #6

- [x] repo-02 read-only archive checkout PASS。
- [x] Node 22 / npm install PASS。
- [x] Canonical `check:ci` PASS。
- [x] 只有 sanitized summary，沒有 private-generated Job Summary。
- [x] Fetched job log 無 known private repository name hit。
- [x] Artifact count：0。

## Rollout 檢查點 — repo-03 run #7

- [x] repo-03 read-only archive checkout PASS。
- [x] Node 22 / npm install PASS。
- [x] Canonical `check:ci` PASS。
- [x] 只有 sanitized summary，沒有 private-generated Job Summary。
- [x] Fetched job log 無 known private repository name hit。
- [x] Artifact count：0。

## Rollout 檢查點 — repo-04 run #8

- [x] Generic read-only checkout / Node 22 / npm / `check:ci` 路徑 PASS。
- [x] Sanitized log review PASS；Artifact 0；無 known private repository name hit。
- [x] 與 target 原 private CI 比較後發現 coverage gap：package-level `check:ci` 無法代表 ShellCheck、governance、architecture、skill routing/audit、spec-governance gates。
- [x] 新增 public-safe `repo-04` adapter，鏡像 read-only validation gates；deployment、PR classification 與 Artifact upload 仍排除。
- [x] 以 dedicated adapter 重跑 repo-04 並解決 runner / tooling compatibility，最終所有 gate PASS。

## Runner correctness 修正 — repo-04 dedicated adapter

- [x] 發現 `run_stage()` exit-code propagation bug：失敗 command 可能顯示 `FAIL (exit 0)`，且 overall job 仍為 green。
- [x] 修正 `run_stage()`，在 `else` branch 立即 capture `$?` 並 propagate 真正 non-zero status。
- [x] 在修正後 failure semantics 下重跑 repo-04，ShellCheck 結果可被信任。

## repo-04 ShellCheck 語意對齊

- [x] 確認原 private CI 使用 ShellCheck `severity: error`，並排除 SC1090 / SC1091。
- [x] Public bridge repo-04 adapter 改用相同 ShellCheck severity semantics。
- [x] 對齊後重跑 repo-04，shellcheck-scripts / shellcheck-skills 都 PASS。

## repo-04 最終 dedicated-adapter 驗證

- [x] 所有 repo-04 gates PASS：ShellCheck、governance、architecture tests / contract / drift、skill resolver、registry、routing audit / matrix、runner integration、skill audit、shared-path audit、spec-governance、spec-truth-gate、`check:ci`。
- [x] Fetched Public job log 無 known private repository name hit。
- [x] Artifact count：0。
- [x] 無 private-generated Job Summary。
- [x] repo-04 對 Phase 1 CI recovery 的 coverage 已足夠。

## repo-05 Adapter 準備與驗證

- [x] 檢查原 `candidate-contract.yml`。
- [x] 新增 read-only adapter：unit tests、candidate contract validation、architecture JSON / doc validation、OpenSpec strict validation。
- [x] Node runtime 與原 private CI 對齊：Node 20.19.0。
- [x] Scheduled `upstream-watch` 不納入 per-run CI；它屬於獨立 monitoring concern。
- [x] 第一次 Public bridge run 抓到一筆真實 expired lifecycle checkpoint；private repo lifecycle 正式收斂後，rerun attempt #2 PASS。
- [x] Expired reference-only candidate 改為 `archived`，不是單純延後 deadline。
- [x] Public log 無 known private repository name hit，Artifact count：0。

## repo-06 Adapter 準備與驗證

- [x] 檢查 target 的 read-only Vault Health workflow，並將 source-validation gate 與 write-oriented AI workflow 分離。
- [x] 大型 repo 改用 sparse read-only checkout，範圍對齊原 Vault Health workflow，而不是下載完整 archive。
- [x] 保留 local Git metadata 供 `git ls-files` health logic 使用，但 checkout 後移除所有 remotes。
- [x] Read-only Vault Health adapter 包含：Python dependency、health unit tests、skill sync、metadata normalizer、vault health、follow-up radar、stale-fact audit、Hub / index drift、relation structural gate、canonical memory health、source-link dry-run。
- [x] Schedule-only claim harvest / backlog report 不進 manual CI；write-oriented AI generation / retry workflow 不進 Hub。
- [x] YAML-sensitive askpass heredoc 改成 deterministic `printf` helper。
- [x] 解決 sparse checkout lazy-fetch authentication 後重跑，最終 repo-06 PASS。
- [x] Public log 無 private report body / known private repository name；Artifact count：0。

## 六倉最終狀態

- [x] repo-01 PASS。
- [x] repo-02 PASS。
- [x] repo-03 PASS。
- [x] repo-04 PASS。
- [x] repo-05 PASS。
- [x] repo-06 PASS。
- [x] 六倉 rollout 無剩餘 target-side CI debt 阻擋 Phase 1 recovery。
