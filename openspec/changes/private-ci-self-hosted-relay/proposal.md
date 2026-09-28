---
title: "以受控 self-hosted relay 恢復 Private CI"
tags:
  - Automation-Hub
  - Private-CI
  - Self-hosted-Runner
  - Security
date: 2026-09-29
type: decision
status: active
source: ai-assisted
---

# 以受控 self-hosted relay 恢復 Private CI

## Why

private repositories 的 GitHub-hosted Actions quota 尚未恢復；Ai-agent PR #482 的 job 在 runner 分派前失敗，沒有任何測試步驟或可讀 log。Public Automation-Hub 原本在 GitHub-hosted runner 直接讀 private source，若再擴充 PR mode，會把 private source 帶進 public runner trust domain。

## What Changes

- `private-ci.yml` 的 private CI job 改由使用者控制的 self-hosted runner label `private-ci` 執行。
- Public Hub 仍只接受 alias、mode 與手動 request；private mapping、read token、PR metadata、exact-SHA checkout 與 repository-native CI 只在受控 runner 上執行。
- 增加 `baseline` 與受限的 `pr-exact-sha` mode；PR mode V1 只支援已審查的 `repo-04` adapter，且只接受 same-repository open PR。
- PR head 於執行前後做 read-only stability check；變更、查詢失敗、fork 或錯誤 base 全部 fail closed。
- Public summary 只保留 alias、mode、stage、status、exit code；不公開 source、repository identifier、branch、PR number、SHA、raw log 或 token。
- detector 維持 default-branch-only，不把 PR result 混入 baseline evidence。

## Non-goals

- 不修改 GitHub billing、repository visibility、branch protection 或 private repo write policy。
- 不自動註冊、刪除或輪替 self-hosted runner；registration token 只由使用者在受控主機設定。
- 不把 PR mode result 升格為 `baseline-green`，不取代正式 exact-SHA review／merge gate。
- 不支援 fork PR、`pull_request_target`、merge-ref fallback 或 caller-provided branch/ref/SHA。
