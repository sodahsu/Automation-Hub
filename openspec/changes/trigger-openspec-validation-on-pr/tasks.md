---
title: "Trigger OpenSpec Validation on Pull Requests Tasks"
tags:
  - OpenSpec/Tasks
  - Governance/Tasks
date: 2026-09-28
type: workflow
status: active
source: ai-assisted
---

# Trigger OpenSpec Validation on Pull Requests Tasks

## Phase 1: 契約與設計

- [x] 1.1 確認現有 workflow 只有 `push` 到 `main` 與 `workflow_dispatch`，且 PR #10 沒有 checks。
- [x] 1.2 定義 PR target、path scope、四個 lifecycle events 與既有 trigger 保留條件。
- [x] 1.3 定義 concurrency 依 PR number／ref 隔離，避免不同 PR 互相取消。
- [x] 1.4 完成 proposal、design、spec delta 與 tasks。

## Phase 2: Workflow implementation

- [x] 2.1 在 `validate-openspec.yml` 加入受限於 `main` 的 `pull_request` trigger。
- [x] 2.2 保留 `push`、`workflow_dispatch`、read-only permissions、Node、action SHA 與 strict command。
- [x] 2.3 將 concurrency group 改為 PR／ref scoped。

## Phase 3: Local verification

- [x] 3.1 `openspec validate --all --strict` 通過。
- [x] 3.2 workflow YAML parse 與 `git diff --check` 通過。
- [x] 3.3 `python3 scripts/security/audit.py` 通過。

## Phase 4: Remote verification

- [x] 4.1 建立 target `main` 的 Draft PR，確認 workflow definition 可被 GitHub 接受。2026-10-04：Draft PR #19 opened 後 `驗證 OpenSpec` run `37182894118` success。
- [x] 4.2 workflow change 進入 `main` 後，以新的 scoped PR 驗證 check 會在 `opened`／`synchronize` 出現。2026-10-04：PR #19 opened run `37182894118` success；後續 commit 觸發 synchronize run `37182974523` success。
- [x] 4.3 透過 `ready_for_review` 觀察 validation check。原 action-version 調查已改以 deferred 收納，因此改用本次 scoped PR #19 做等價且更直接的 runtime 驗證；2026-10-04 Ready 後 run `37183027261` success。
- [x] 4.4 遠端 `opened` / `synchronize` / `ready_for_review` 皆已成功；本次決定在 canonical `ci-pr-validation` spec 建立並通過 strict validation後 archive。
