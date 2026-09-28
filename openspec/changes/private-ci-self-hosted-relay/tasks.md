---
title: "受控 self-hosted relay CI Tasks"
tags:
  - Automation-Hub
  - Private-CI
  - Tasks
date: 2026-09-29
type: workflow
status: active
source: ai-assisted
---

# 受控 self-hosted relay CI Tasks

## Phase 1: 契約與設計

- [x] 1.1 確認 private GitHub-hosted job 是 runner 啟動前失敗，不是 target test failure。
- [x] 1.2 確認 Public Hub 直接讀 private source 會擴大 public runner data boundary。
- [x] 1.3 定義 self-hosted label/group、token separation、baseline/PR provenance 與 sanitized result schema。
- [x] 1.4 完成 proposal、design、spec delta。

## Phase 2: Workflow implementation

- [x] 2.1 將 private CI job 固定到 `[self-hosted, private-ci]`，禁止 GitHub-hosted fallback。
- [x] 2.2 加入 Hub main-ref guard、baseline/pr mode 與 repo-04 pilot gate。
- [x] 2.3 加入 private PR metadata、exact head checkout、head stability check 與 fail-closed validation。
- [x] 2.4 保留 detector default-only 與既有 run-ci adapter；target step 不接 private token。
- [x] 2.5 強化 cleanup、public summary allowlist 與 security audit。
- [x] 2.6 更新 README、SECURITY 與 runner registration runbook。

## Phase 3: Local verification

- [x] 3.1 `openspec validate --all --strict` 通過。
- [x] 3.2 `python3 scripts/security/audit.py` 通過。
- [ ] 3.3 workflow YAML／shell syntax、`git diff --check` 與 adapter checks 通過。
- [x] 3.4 驗證 `PR CI — ` prefix 不會被 default baseline collector 收集。

## Phase 4: Controlled runner verification

- [ ] 4.1 使用短期 registration token，在受控 runner group 註冊 `private-ci` label；不把 token 寫入 repository。
- [ ] 4.2 確認 runner online、job labels 正確，沒有 GitHub-hosted fallback。
- [ ] 4.3 執行 default-mode repo-04 smoke test，確認 sanitized result 與 cleanup。
- [ ] 4.4 執行 PR #482 exact-SHA mode，確認 pre/post head stability、repo-04 adapter 與 provenance separation。
- [ ] 4.5 執行 invalid PR、fork/base mismatch、head change、runner unavailable negative paths。

## Phase 5: Review and delivery

- [ ] 5.1 建立 Automation-Hub Draft PR，包含 runner boundary 與 token scope 說明。
- [ ] 5.2 完成 public security review 與 remote evidence。
- [ ] 5.3 取得 Automation-Hub PR 的當前對話合併指示後才合併。
- [ ] 5.4 Hub 合併後重跑 PR #482 evidence；不自動合併 Ai-agent #482。
