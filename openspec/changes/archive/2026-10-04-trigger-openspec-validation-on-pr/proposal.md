---
title: "Trigger OpenSpec Validation on Pull Requests"
tags:
  - OpenSpec/Change
  - Governance/Automation
  - CI-Gate
date: 2026-09-28
type: decision
status: active
source: ai-assisted
---

# Trigger OpenSpec Validation on Pull Requests

## Why

`validate-openspec.yml` 目前只在 `push` 到 `main` 或手動 `workflow_dispatch` 時執行。Automation-Hub 的 PR 因此沒有自動的 OpenSpec validation check；實際 PR #10 已回報 `no checks reported`。這讓變更只能依賴本機驗證，無法在 PR review surface 上留下一致的 strict validation 證據。

## What Changes

- 保留既有 `push` 到 `main` 與 `workflow_dispatch` 觸發。
- 新增 target `main` 的 `pull_request` 觸發，僅涵蓋 `openspec/**` 或本 workflow 的變更。
- PR 事件涵蓋 `opened`、`synchronize`、`reopened` 與 `ready_for_review`，讓 Draft PR 轉 Ready 後也會取得 validation。
- 將 concurrency group 依 PR number 或 ref 分隔，避免不同 PR 共用固定 group 而互相取消；同一 PR 的新 commit 仍可取消舊執行。
- 保留 `contents: read`、Node 20.19.0、action SHA 與 `npx --yes @fission-ai/openspec@1.8.0 validate --all --strict --json` 不變。

## Capabilities

新增 `ci-pr-validation` capability delta，定義 PR path scope、事件集合、既有觸發保留、read-only permission 與 concurrency isolation。

## Impact

- OpenSpec 相關 PR 會在 GitHub PR checks 看到自動 validation。
- README 或其他非 OpenSpec 變更不會因此增加不必要的 CI 執行。
- workflow change 本身在尚未進入 `main` 前，GitHub 可能不會以新 trigger 執行該 PR；本地 strict validation 與合併後的新 PR 事件是完整驗收路徑。
- 不改 private repository access、credentials、workflow permissions 或 action version。
