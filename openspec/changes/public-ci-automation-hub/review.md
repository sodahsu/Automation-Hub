---
title: "Public CI Automation Hub 審查"
tags:
  - OpenSpec/Review
  - CI/GitHubActions
  - Security/PublicPrivateBoundary
date: 2026-09-25
type: review
status: active
source: ai-assisted
---

# Public CI Automation Hub 審查

## 實作前發現

- Public `Automation-Hub` repository 已存在，適合作為 orchestration location。
- 當時的核心問題是 private-repository GitHub-hosted Actions quota 已用盡，因此原 private CI 不能再當作可用 capacity。
- 六個 private repositories 都在範圍內，但真實名稱刻意不寫入 Public repo。
- Phase 1 可以在不改 repository visibility、也不寫入 target repository 的前提下恢復 CI。
- Public / Private 邊界使 log hygiene、Artifact policy、cache policy 與 metadata masking 成為必要 requirement。
- Manual `workflow_dispatch` 足以作為緊急 recovery path，而且不需要 private-repository Action 反向觸發 Public Hub。
- Automatic triggering 在 Phase 1 初始設計中刻意延後，後續另案處理。

## 實作檢查點 — 2026-09-25

已在 `main` 實作：

- `.gitignore`：阻擋 private checkout、environment、log 與 report path。
- `SECURITY.md`：定義 Public / Private security boundary 與 incident response。
- `README.md`：說明必要 Secrets、手動流程與後續自動化，不揭露 target identity。
- `.github/workflows/private-ci.yml`：提供 alias selection、read-only permissions、Secret preflight、runtime target masking、private checkout、runtime setup、sanitized CI、summary、timeout、concurrency、always-run cleanup。
- `scripts/common/run-ci.sh`：偵測 Node package manager，執行 repository-native CI，並把 private command output 留在 runner 暫存檔。
- Public repository search 沒有找到已知 private target repository names。
- GitHub Actions 使用目前採用的 major version（`actions/checkout@v7`、`actions/setup-node@v7`），package-manager automatic cache 明確關閉。

## Readiness Sign-off

- [x] 問題與 recovery objective 已定義。
- [x] Public repository / private target boundary 已定義。
- [x] Read-only first 原則已定義。
- [x] Private repository identity 排除於 committed config。
- [x] Production deploy 排除。
- [x] Private-repository mutation 排除。
- [x] 既有 private workflow 保留。
- [x] Rollback 不需要 private source change。
- [x] Public workflow 與 sanitized CI adapter 已實作。
- [x] 必要 GitHub Secrets 已設定。
- [x] Public-runner read-only checkout 已實跑成功。
- [x] 成功與失敗 runs 均完成 log leakage review。
- [x] Node/npm canonical `check:ci` 已 end-to-end PASS。
- [x] 六倉 alias 均完成實跑。
- [x] Automatic triggering 已在獨立 `automatic-private-ci-sweep` change 實作。

## Security Review Gate

在宣布六倉可用前，需確認：

1. 沒有 private repository 名稱被 commit。
2. Target identifier 在使用前已 masking。
3. Token value 永不輸出。
4. Private checkout 不會上傳為 Artifact。
5. Workspace / source directory 不進 cache。
6. Failure log 不 dump source content。
7. Success / failure 都會執行 cleanup。
8. Token permission 維持 read-only、selected-repository scoped。
9. Workflow 無法 push 到 target repository。
10. 不使用帶 private credential 的 `pull_request_target`。

## Pilot 證據 — repo-01 run #4

- 結果：PASS。
- Public runner 完成 read-only archive checkout、Node setup、dependency install 與 canonical `check:ci`。
- Sanitized bridge：`package-json` PASS、npm PASS、install PASS、`check:ci` PASS。
- Hardening 前 target 自己曾在 Job Summary 暴露測試 aggregate：15 files / 135 tests passed。
- Connector-side log review 無 known private repository name hit。
- Artifact count：0。
- 此 run 同時揭露一個邊界：private test tooling 可直接寫入 Public `GITHUB_STEP_SUMMARY`。

## 安全強化驗證 — repo-01 run #5

- 結果：PASS。
- Private target 完成 read-only checkout、Node setup、install、canonical `check:ci`。
- Public Job Summary 只剩 Hub 自己產生的 sanitized target / stage table。
- 先前 private-generated Vitest Test Report 不再出現。
- Connector-side log review 無 known private repository name hit。
- Artifact count：0。
- `GITHUB_STEP_SUMMARY`、`GITHUB_OUTPUT`、`GITHUB_ENV`、`GITHUB_PATH` command-file isolation 完成實跑驗證。

## Rollout 證據 — repo-02 run #6

- 結果：PASS。
- Read-only archive checkout PASS。
- Node 22 / npm install PASS。
- Canonical `check:ci` PASS。
- Public Job Summary 只含 Hub sanitized table。
- Log 無 known private repository name hit。
- Artifact count：0。

## Rollout 證據 — repo-03 run #7

- 結果：PASS。
- Read-only archive checkout PASS。
- Node 22 / npm install PASS。
- Canonical `check:ci` PASS。
- Public Job Summary 只含 Hub sanitized table。
- Log 無 known private repository name hit。
- Artifact count：0。

## Coverage Review — repo-04

Generic bridge 首次雖然 PASS，但與原 private CI 比較後發現 package-level `check:ci` coverage 不足。

原 private CI 還包含：

- ShellCheck
- governance
- architecture contract / drift
- skill resolver
- routing / integration audit
- skill audit
- spec-governance
- spec-truth-gate

因此新增 dedicated `repo-04` adapter，鏡像 read-only validation gates；event classification、deployment / mutation 與 failure Artifact upload 仍刻意排除。

## Runner correctness 發現與修正

Dedicated adapter 首次執行發現 `run_stage()` 有 exit-code propagation bug：

- failing command 可能被顯示為 `FAIL (exit 0)`
- overall job 可能錯誤維持 green

修正方式：

- 在 `else` branch 立即 capture `$?`
- propagate 真正 non-zero code

修正後重新執行，failure semantics 恢復可信。

## repo-04 ShellCheck 語意對齊

比較原 private CI 後確認：

- ShellCheck 使用 `severity: error`
- 排除 SC1090 / SC1091

Public bridge adapter 已改成相同 semantics。

最終結果：

- shellcheck-scripts PASS
- shellcheck-skills PASS

## repo-04 最終 Dedicated Adapter

最終所有 mirrored read-only gates PASS：

- ShellCheck scripts / skills
- governance
- architecture unit / contract / drift
- skill resolver
- registry
- routing audit / matrix
- runner integration
- skill audit
- shared-path audit
- spec-governance
- spec-truth-gate
- canonical `check:ci`

安全結果：

- known private repository name hits：0
- Artifact count：0
- private-generated Job Summary：0

repo-04 已足夠覆蓋 Phase 1 CI recovery。

## repo-05 Adapter 設計

repo-05 的主要 CI 是 contract-oriented，而不是 package-oriented。

Public bridge 鏡像其 read-only workflow：

- Python unit tests
- candidate contract validation
- architecture JSON / doc validation
- `@fission-ai/openspec@1.8.0 validate --all --strict`

此 alias 使用 Node 20.19.0，與原 private CI 對齊。

Scheduled upstream-watch 不納入 per-run CI，因為它屬於 external monitoring / reporting，而不是 source-validation gate。

## repo-05 真實 Target Debt 與結案

Dedicated adapter 首次實跑時：

- unit tests PASS
- candidate-contract 正確抓到一筆真實 lifecycle violation
- 一個 active candidate 的 review checkpoint 已於 2026-09-24 到期，但狀態仍是 `researching`

Hub 沒有把 gate 改成 advisory，也沒有自動延後 deadline。

後續 private repo 正式把該 reference-only candidate 收斂為 `archived`，移除 stale `reviewBy`，並在 decision 記錄 2026-09-25 closure rationale。

Rerun attempt #2：

- repo-05 PASS
- Public log 無 known private repository name hit
- Artifact count：0

這證明 Hub 抓到的是 target 真實 debt，而不是 bridge defect。

## repo-06 Adapter 設計

repo-06 是大型 content repository，主要 validation path 為 read-only Vault Health workflow。

Bridge 採用：

- token-scoped sparse Git checkout
- 只 checkout health-check 所需範圍
- checkout 後移除所有 remotes
- 保留 local Git metadata，僅供 `git ls-files` 類 read-only health inventory 使用
- CI step 不再持有 private-repository token

Adapter 鏡像：

- pinned PyYAML install
- health unit tests
- managed skill sync
- metadata normalizer
- vault health
- follow-up radar
- stale-fact audit（advisory）
- Hub drift
- index drift
- relation graph structural validation
- canonical memory health
- source-link dry-run validation

Schedule-only claim-harvest / backlog report 標記 `SKIP`；write-oriented Claude / Gemini / retry workflow 不納入 Hub。

## repo-06 最終驗證

結果：PASS。

所有 read-only stages 都通過：

- Python dependency setup
- health unit tests
- skill sync
- metadata normalizer
- vault health
- follow-up radar
- stale-fact audit
- Hub drift
- index drift
- relation health
- canonical memory health
- source-link dry-run

安全結果：

- selected-repository PAT 只在 clone / lazy sparse materialization 使用
- CI 前已移除所有 remotes
- Public log 無 known private repository name hit
- 無 private report body
- Artifact count：0

## 六倉 Rollout 最終狀態

Public recovery path 已對六個 alias 全部實跑。

最終：

- repo-01：PASS
- repo-02：PASS
- repo-03：PASS
- repo-04：PASS
- repo-05：PASS
- repo-06：PASS

Phase 1 recovery objective 已達成：

- Private repositories 維持 Private。
- Fine-grained token 維持 selected-repository read-only。
- Public GitHub-hosted runners 可執行 sanitized CI。
- Private source / report body 不上傳為 Artifact。
- CI recovery 不需要 target repository write access。

## 後續自動化銜接

原本延後的 automatic-triggering decision 已在獨立 `automatic-private-ci-sweep` OpenSpec change 實作。

目前實際設計不是固定每 3 小時全掃，而是：

- 每 5 分鐘執行 detector。
- 讀取 private repository `pushed_at`。
- 與對應 alias 最近一次 CI job `started_at` 比較。
- 無新 push → `SKIP`。
- 有新 push → 只 dispatch 該 alias。
- CI 正在跑 → `WAIT`，下一輪再判斷。

Private repo 仍維持 read-only，不新增 private write token。

另外，Hub 自己的 workflow / shared adapter code 在 `main` 變更時，會自動執行六倉 regression。

Automatic regression run #17：

- 六個 aliases 全部 PASS。
- known private-name hits：0。
- private report markers：0。
- Artifact count：0。

Detector run #1：

- success。
- 當時六倉無新的 private push，因此沒有多 dispatch CI。
- Private repository identifier 維持 masking。

## 結論

Phase 1 已完成其核心目的：在不公開 private source、不增加 target write access、不改 repository visibility 的前提下，恢復六倉 CI。

目前架構可持續使用，且已具備每 5 分鐘 change-aware polling；剩餘工作屬於持續觀察與獨立 security review，而不是 Phase 1 功能缺口。
