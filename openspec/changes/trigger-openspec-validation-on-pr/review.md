---
title: "Trigger OpenSpec Validation on Pull Requests Review"
tags:
  - OpenSpec/Review
  - Governance/Review
date: 2026-09-28
type: review
status: active
source: ai-assisted
---

# Trigger OpenSpec Validation on Pull Requests Review

## 實作與驗證證據

- 本地 workflow YAML parse：通過。
- `openspec validate --all --strict`：通過。
- `npx --yes @fission-ai/openspec@1.8.0 validate --all --strict --json`：待本地依賴／網路條件確認。
- `python3 scripts/security/audit.py`：`Security audit: PASS`。
- `npx --yes @fission-ai/openspec@1.8.0 ...`：本次未執行，因本地 auto mode gate 不允許未明確核准的 `npx --yes` 外部套件下載；repo-local `openspec validate --all --strict` 已通過。

## Readiness Sign-off

- [x] Proposal、Design 與 Spec 定義 PR trigger、path scope、concurrency 與 permission 邊界。
- [x] 不變更既有 push／manual trigger、action SHA 與 strict validation command。
- [x] 本地實作、YAML parse、diff check 與 security audit 完成。
- [ ] Workflow change 已進入 `main`，並取得真實 PR check evidence。
- [ ] 既有 action version PR 已透過 `ready_for_review` 取得 validation evidence。
