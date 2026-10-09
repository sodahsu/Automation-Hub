# TASK_PROGRESS

更新：2026-10-09
狀態：active

> 過期後先重新驗證 GitHub runtime、OpenSpec 與 PR 狀態；本檔是接手入口，不取代 source-of-truth。

## Resume Here

- 目前 owner：Automation-Hub 的 public CI / private-repo orchestration。
- ACTIVE：0。
- WAITING-HUMAN：`align-external-scheduler-to-15m`、`claude-0700-minimal-wake`、`claude-window-trigger`。
- 2026-10-09 起 `run-private-pr-heads` 已歸檔（使用者批准）；四項使用者端驗證延後，仍在下方「Next Action」，清單見 `openspec/changes/archive/2026-10-09-run-private-pr-heads/DEFERRED.md`。
- CLOSEOUT：0。

## Completed

- 2026-10-04 已證明 detector 約 15 分鐘 cadence。
- PR-head CI 已在 Ai-agent #534–#537 與最新 #538 跑出 pending → CI → final status。
- OpenSpec inventory branch PR #19 的 strict validation 已綠。
- `trigger-openspec-validation-on-pr` 已完成 canonical reconciliation 並歸檔。

## Waiting Human

### run-private-pr-heads（已歸檔，延後項目仍待使用者）

Hub 端 runtime 已成立。Task 4.2 的 Ai-agent architecture contract 已進入實作：

- Ai-agent OpenSpec：`record-hub-pr-head-evidence`
- Draft PR：Ai-agent #541
- CI-only validation PR：Ai-agent #543（不得 merge；#542 為重複 validation PR，已關閉）
- contract 形狀：`remoteEvidence.automationHub.prStatusContext = automation-hub/private-ci`；repo-01～05 `prHead: true`，repo-06 `false`。

Hub repo 本身不修改 workflow；Ai-agent #543 / Automation-Hub run `37190764398` 已 success，因此 task 4.2 已回填完成。

### detector 輪詢 15 分鐘 → 5 分鐘（待處理，2026-10-09 登記）

- 待使用者先在 cron-job.org 把 `detect-private-changes.yml` 的喚醒間隔由 15 分改為 5 分（代理無法存取該帳號）。
- 為什麼值得做：`hub-ci-kick.sh` 只在 `gh pr ready` 與非 Draft 的 `gh pr create` 立即喚醒；網頁手動 Ready、hook 失敗、以及 **push 新 commit 到已 Ready 的 PR** 都只能等輪詢。Hub 是 public repo，加密頻率不增加 Actions 費用。
- 動手前先查清楚：2026-10-04 為何定為 15 分鐘（現有文件只記錄 live cadence，未記原因）。
- 驗收：以 `gh run list --workflow detect-private-changes.yml` 的實際 run 間隔為證，連續至少 6 次約 5 分鐘才算；不以設定頁為證。2026-10-09 基線：連續 38 次間隔 14.7–15.3 分鐘。
- 完成後更新 README「每 15 分鐘」字樣、`docs/external-scheduler.md` 與 `private-change-detection` spec。

## Next Action

1. 人工核對 `PRIVATE_REPOS_READ_TOKEN` / `PRIVATE_REPOS_STATUS_TOKEN` 是否只有文件要求的最小 scope。
2. 若要完整驗收 manual entry，再手動 dispatch `target=repo-04 sha=<head>` 一次。
3. 觀察至少下一輪 detector：已有 `automation-hub/private-ci` status 的同一 head 不重跑；未直接觀察前保持 known-unverified。

## Guardrails

- 不把 Hub workflow success 等同每個 target stage 都執行；SKIP 不是 PASS。
- 不修改 Secrets / PAT scope。
- 不直接 merge。
