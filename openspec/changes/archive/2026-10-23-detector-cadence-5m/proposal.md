# Proposal: detector-cadence-5m

## Why

Detector 的 cadence 現在有三份互相不一致的 truth：契約（spec／文件）寫每 15 分鐘；cron-job.org 的喚醒已經是每 5 分鐘；實際完整掃描卻因 PR #23（2026-10-13）的節流，只在 UTC 分鐘 `% 15 == 0` 發生，其餘喚醒立即 `SKIP`。

改成 5 分鐘的理由：`hub-ci-kick.sh` 只在 `gh pr ready` 與非 Draft 的 `gh pr create` 立即喚醒 detector；網頁手動 Ready、hook 失敗、以及 push 新 commit 到已 Ready 的 PR，都只能等輪詢。完整掃描間隔由 15 分鐘縮到 5 分鐘，這些情境的最壞等待時間由約 15 分鐘降到約 5 分鐘。`TASK_PROGRESS.md` 已在 2026-10-09 登記這項待辦，2026-10-23 使用者決定執行。

## Evidence and Cost

- **喚醒已是 5 分鐘**：2026-10-23 的 run 建立時間為 02:55:06、03:00:33、03:05:06、03:10:10、03:15:11、03:20:10、03:25:06、03:30:21、03:35:06、03:40:10Z（`gh run list -R sodahsu/Automation-Hub --workflow detect-private-changes.yml --limit 30 --json createdAt,event,conclusion`）。
- **完整掃描只有 1/3**：同日抽樣 16 個 run（02:50–04:05Z）的 `Detect private push activity` step，UTC 分鐘為 00／15／30／45 的 5 個耗時 27–33 秒（完整掃描），其餘 11 個耗時 0–1 秒（`SKIP`）。
- Hub 是 public repo，GitHub-hosted runner 不計費。
- 每次完整掃描約 13～20 個 API 呼叫，每小時 12 次，遠低於 5,000/hr 的上限。
- 單次完整掃描約 30 秒量級（上述抽樣 27–33 秒；先前盤點最長 41 秒），遠小於 5 分鐘間隔，不會與下一輪重疊。
- detector 已有 `concurrency: cancel-in-progress: true` 與「執行中的 alias 不重複排隊」保護，本 change 不改。喚醒頻率沒有變（本來就每 5 分鐘一次），變的只是其中做完整掃描的比例由 1/3 變成 3/3。

## Unknown

- **2026-10-04 為何定為 15 分鐘：Unknown。** 現有文件與歷史 change（`align-external-scheduler-to-15m`）只記錄 live cadence 與遷移證據，沒有記錄選擇 15 分鐘的理由。本 change 不假設原因；上方的成本評估是改成 5 分鐘的依據，不是對當初決定的反駁。
- cron-job.org 設定頁的 minutes 欄位：本 change 與先前的證據一樣，只以 GitHub Actions timestamps 證明 live 行為，沒有直接讀取設定頁。
- 2026-10-23 的 run 清單裡，有數組「同一秒建立、一個 `cancelled` 一個 `success`」且不在 5 分鐘格點上（03:44:19、04:01:59、04:07:29Z）。推測是 hub-ci-kick 的 `force=true` 喚醒，來源未驗證；驗收時視為非排程喚醒剔除（見 `tasks.md`）。

## What Changes

- **spec**：`private-change-detection` 的 cadence requirement 由「每 15 分鐘（minutes `0,15,30,45`）」改為「每 5 分鐘（minutes `0,5,10,…,55`）」；cadence migration 驗收改為「至少 6 個連續做了完整掃描（非 SKIP）的 detector runs、相鄰間隔約 5 分鐘」；「runtime 仍是舊 cadence 時保持 pending」改為對應 15 分鐘的版本。新增一個 scenario，明定節流與 cadence 對齊、`force=true` 繞過節流。
- **detector**：`.github/workflows/detect-private-changes.yml` 的節流由 `% 15` 改為 `% 5`；第 1 行、`force` input description、節流註解與 SKIP 訊息同步改成 5 分鐘。`force=true` 的繞過語意保留（目標私有 repo 的 hub-ci-kick hook 依賴它）。不改其他邏輯、權限或 concurrency。
- **文件**：`README.md`、`docs/external-scheduler.md` 的現行契約改為 5 分鐘；2026-10-04 的歷史證據敘述保留原文，補一句「2026-10-23 起改為 5 分鐘」。
- **取代舊 change**：`align-external-scheduler-to-15m` 方向相反，以 `openspec archive align-external-scheduler-to-15m --yes --skip-specs` 歸檔（必須 `--skip-specs`，避免把 15 分鐘 delta 套回 canonical）；`openspec/changes/README.md` 移除舊列、加入本 change。
- **進度**：`TASK_PROGRESS.md` 把「detector 輪詢 15 分鐘 → 5 分鐘」改為進行中，並新增一項只記錄、不實作的待辦（vault-health `pull_request` trigger 改由 Hub 承接）。

## Out of Scope

- 不修改 cron-job.org（已是 5 分鐘）、不改專用 token 權限、不改任何 Secret。
- 不改 detector 演算法、`pushed_at` 比較、alias dispatch、PR 模式、permissions、concurrency。
- 不實作「目標私有 repo `vault-health.yml` 的 pull_request trigger 改由 Hub 承接」，只在 `TASK_PROGRESS.md` 記錄。
- 不修改目標私有 repo。其 `openspec/specs/hook-wiring-integrity/spec.md` 提到「繞過偵測器對一般 workflow_dispatch 的 15 分鐘節流」與「UTC 分鐘不是 00、15、30、45」的 scenario，改成 5 分鐘後字面會過時，需要另一個目標私有 repo PR。

## Impact

- `.github/workflows/detect-private-changes.yml`：節流 `% 15` → `% 5`（行為變更：完整掃描由每 15 分鐘變為每 5 分鐘）。
- `openspec/specs/private-change-detection/spec.md`：本 change 歸檔時才套用 delta；在此之前 canonical spec 仍寫 15 分鐘。
- `README.md`、`docs/external-scheduler.md`、`TASK_PROGRESS.md`、`openspec/changes/README.md`：文字更新。
- `openspec/changes/align-external-scheduler-to-15m/`：歸檔為 `openspec/changes/archive/2026-10-23-align-external-scheduler-to-15m/`（superseded）。
- 跨 repo：目標私有 repo 的 `hook-wiring-integrity` spec 字面過時（見上），另案處理。
- 風險與回滾：風險是 private API 與 Actions 用量增加三倍，量級見上方成本評估；回滾是把節流改回 `% 15` 並還原文件，cron-job.org 不需動。
