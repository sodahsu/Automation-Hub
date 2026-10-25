# TASK_PROGRESS

更新：2026-10-23
狀態：active

> 過期後先重新驗證 GitHub runtime、OpenSpec 與 PR 狀態；本檔是接手入口，不取代 source-of-truth。

## Resume Here

- 目前 owner：Automation-Hub 的 public CI / private-repo orchestration。
- ACTIVE：0。
- WAITING-HUMAN：`claude-0700-minimal-wake`（見下方「進行中：claude-0700-minimal-wake」）。`claude-window-trigger` 已於 2026-10-23 撤銷（dropped）並歸檔，workflow 與文件已刪除；`align-external-scheduler-to-15m` 已於 2026-10-23 被 `detector-cadence-5m` 取代並歸檔。
- 2026-10-13 PR #23（`perf/throttle-private-detector-20261012`）已合併；workflow 端加入每 15 分鐘（UTC 00/15/30/45）節流檢查，防禦非整數倍分的過早喚醒（2026-10-23 起由 `detector-cadence-5m` 改為每 5 分鐘）。
- 2026-10-09 起 `run-private-pr-heads` 已歸檔（使用者批准）；四項使用者端驗證延後，仍在下方「Next Action」，清單見 `openspec/changes/archive/2026-10-09-run-private-pr-heads/DEFERRED.md`。
- CLOSEOUT：0。
- 2026-10-23 detector-cadence-5m 已於 PR #26 合併並完成 live 驗收；14 個連續完整掃描、間隔 4:45–5:06，證據與歸檔見 `openspec/changes/archive/2026-10-23-detector-cadence-5m/`。

## Completed

- 2026-10-13 PR #23 合併至 `main` (`5538f49`)：在 `detect-private-changes.yml` 增加 early wake 節流機制。
- 2026-10-04 已證明 detector 約 15 分鐘 cadence。
- PR-head CI 已在目標私有 repo #534–#537 與最新 #538 跑出 pending → CI → final status。
- OpenSpec inventory branch PR #19 的 strict validation 已綠。
- `trigger-openspec-validation-on-pr` 已完成 canonical reconciliation 並歸檔。

## Waiting Human

### run-private-pr-heads（已歸檔，延後項目仍待使用者）

Hub 端 runtime 已成立。Task 4.2 的目標私有 repo architecture contract 已進入實作：

- 目標私有 repo OpenSpec：`record-hub-pr-head-evidence`
- Draft PR：目標私有 repo #541
- CI-only validation PR：目標私有 repo #543（不得 merge；#542 為重複 validation PR，已關閉）
- contract 形狀：`remoteEvidence.automationHub.prStatusContext = automation-hub/private-ci`；repo-01～05 `prHead: true`，repo-06 `false`。

Hub repo 本身不修改 workflow；目標私有 repo #543 / Automation-Hub run `37190764398` 已 success，因此 task 4.2 已回填完成。

### 已完成：detector-cadence-5m（detector 輪詢 15 分鐘 → 5 分鐘）

- 2026-10-09 登記，2026-10-23 使用者決定改 5 分鐘，change 已歸檔：`openspec/changes/archive/2026-10-23-detector-cadence-5m/`。
- cron-job.org 已經是 5 分鐘，不需使用者再改設定。證據：2026-10-23 detector runs 的建立時間為 02:55:06、03:00:33、03:05:06、03:10:10、03:15:11、03:20:10、03:25:06、03:30:21、03:35:06、03:40:10Z（`gh run list -R sodahsu/Automation-Hub --workflow detect-private-changes.yml --limit 30 --json createdAt,event,conclusion`）。
- 真正的缺口在節流：PR #23 讓未帶 `force` 的喚醒只在 UTC 分鐘 `% 15 == 0` 做完整掃描，所以喚醒雖是 5 分鐘，完整掃描仍是 15 分鐘一次。本 change 把節流改為 `% 5`，`force=true` 繞過語意保留（目標私有 repo 的 hub-ci-kick hook 依賴它）。
- 為什麼值得做：`hub-ci-kick.sh` 只在 `gh pr ready` 與非 Draft 的 `gh pr create` 立即喚醒；網頁手動 Ready、hook 失敗、以及 **push 新 commit 到已 Ready 的 PR** 都只能等輪詢。Hub 是 public repo，加密頻率不增加 Actions 費用。
- 2026-10-04 為何定為 15 分鐘：Unknown（現有文件只記錄 live cadence，未記原因；本 change 不假設原因）。
- 完成：PR #26 已合併（`9edcad7`）；2026-10-23 04:35–05:45Z 有 15 個連續完整掃描 run，相鄰建立間隔 4:45–5:26（排除非排程喚醒後，排程 run 彼此間隔 4:45–5:06）；證據見歸檔 evidence。目標私有 repo PR #655 已將 `hook-wiring-integrity` 改為 5 分鐘。
- 取代：`align-external-scheduler-to-15m`（方向相反）已於 2026-10-23 以 `--skip-specs` 歸檔。

### 進行中：claude-0700-minimal-wake（07:00 喚醒改由外部排程為主）

- 2026-10-23 使用者授權主代理裁決，change：`openspec/changes/claude-0700-minimal-wake/`（分支 `task/detector-cadence-5m`，與 `detector-cadence-5m` 同一條分支）。
- 起因：GitHub `schedule` 25 筆（2026-09-29 至 2026-10-23）實測落在台北 08:28–11:15，比 07:00 晚 1 小時 28 分至 4 小時 15 分；cron 與 `timezone: Asia/Taipei` 沒有寫錯。證據：`openspec/changes/claude-0700-minimal-wake/evidence/scheduled-runs-2026-10-23.md`。
- 已做（待 PR 合併）：`claude-0700-wake.yml` 加冪等防呆 step（`scripts/wake/wake-guard.sh`，只擋 `schedule`；當日已有「呼叫 Claude 的 step 成功」的 run 就 SKIP；查詢失敗 fail closed），權限加 `actions: read`；本機 stub 測試 `bash scripts/wake/test-wake-guard.sh` 通過。
- 待辦（使用者）：PR 合併**之後**，依 `docs/external-scheduler.md`「07:00 Claude wake job」建立專用 token 與 cron-job.org 07:00 job；連續 3 天確認 `workflow_dispatch` run 在 07:00 ± 5 分鐘建立。另有 OAuth 帳號身分確認（5.1）與 usage window 觀察（8.1、8.2）。完整清單見該 change `tasks.md` 檔尾。
- 合併前不要建立外部排程：`main` 上的舊 workflow 沒有防呆，會與 `schedule` 重複喚醒。
- 不 archive：`openspec/project.md` 要求 runtime observation 未完成留 active。
- 另：`claude-window-trigger` 已撤銷並刪除（從未啟用，見 `openspec/changes/archive/2026-10-23-claude-window-trigger/`）。

### 待辦（只記錄、不實作）：目標私有 repo `vault-health.yml` 的 pull_request trigger 改由 Hub 承接

2026-10-23 使用者決定先記錄、不實作。屬跨 repo 完整流程（Hub 與兩個目標私有 repo），動工前需另開 OpenSpec change。

- 效益：依 2026-10-13～10-23 實測，`vault-health` 是 private Actions 最大的剩餘消耗，約 20 分鐘／10 天。
- 前置條件一：Hub 的 repo-06 要支援 PR 模式。目前 PR 模式只支援 repo-01～05，repo-06 只驗 main（`sha` 帶 repo-06 會在任何網路請求前失敗）。
- 前置條件二：目標私有 repo 的 `claude.yml`／`gemini.yml` 目前以 `vault-health.yml` 的 run 作為 vault PR 的等待條件（約第 343／416 行），要改成等 `automation-hub/private-ci` status。

## Next Action

0. PR 合併後（需使用者在對話中針對該 PR 明確指示）：建立 cron-job.org 07:00 job 並做 3 天準時性驗收（見上方 claude-0700-minimal-wake）。
1. 人工核對 `PRIVATE_REPOS_READ_TOKEN` / `PRIVATE_REPOS_STATUS_TOKEN` 是否只有文件要求的最小 scope。
2. 若要完整驗收 manual entry，再手動 dispatch `target=repo-04 sha=<head>` 一次。
3. 觀察至少下一輪 detector：已有 `automation-hub/private-ci` status 的同一 head 不重跑；未直接觀察前保持 known-unverified。

## Guardrails

- 不把 Hub workflow success 等同每個 target stage 都執行；SKIP 不是 PASS。
- 不修改 Secrets / PAT scope。
- 不直接 merge。
