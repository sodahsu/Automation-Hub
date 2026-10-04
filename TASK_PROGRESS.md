# TASK_PROGRESS

更新：2026-10-04
狀態：active

> 過期後先重新驗證 GitHub runtime、OpenSpec 與 PR 狀態；本檔是接手入口，不取代 source-of-truth。

## Resume Here

- 目前 owner：Automation-Hub 的 public CI / private-repo orchestration。
- ACTIVE：`run-private-pr-heads`。
- WAITING-HUMAN：`align-external-scheduler-to-15m`、`claude-0700-minimal-wake`、`claude-window-trigger`。
- CLOSEOUT：0。

## Completed

- 2026-10-04 已證明 detector 約 15 分鐘 cadence。
- PR-head CI 已在 Ai-agent #534–#537 與最新 #538 跑出 pending → CI → final status。
- OpenSpec inventory branch PR #19 的 strict validation 已綠。
- `trigger-openspec-validation-on-pr` 已完成 canonical reconciliation 並歸檔。

## In Progress

### run-private-pr-heads

Hub 端 runtime 已成立，但 task 4.2 仍需要 Ai-agent 擴充 `architecture/workflows.json` 的 PR-mode remoteEvidence contract。
這是跨 repo architecture contract，不應在 Hub repo 偷改 Ai-agent schema。

## Next Action

1. 由 Ai-agent owning change 擴充 machine-readable remoteEvidence contract。
2. 完成後回本 repo 更新 task 4.2 evidence。
3. PAT 最小 scope、manual dispatch、Draft skip / already-status no-retry 若無直接證據，維持 WAITING-HUMAN / known-unverified。

## Guardrails

- 不把 Hub workflow success 等同每個 target stage 都執行；SKIP 不是 PASS。
- 不修改 Secrets / PAT scope。
- 不直接 merge。
