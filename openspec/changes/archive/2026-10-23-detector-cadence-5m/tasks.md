# Tasks: detector-cadence-5m

## 1. Spec 與 change

- [x] 建立 change：`proposal.md`、`tasks.md`、`specs/private-change-detection/spec.md`（RENAMED + MODIFIED）。
- [x] `openspec validate detector-cadence-5m --strict` 與 `openspec validate --specs --strict` 通過（本機 openspec 1.7.0；另以 CI 使用的 `npx @fission-ai/openspec@1.8.0 validate --all --strict` 驗證通過）。
- [x] 在 scratch 副本上實際執行 `openspec archive detector-cadence-5m --yes`，確認 delta 能乾淨套用到 canonical spec（只驗證，不在本 repo 執行）。

## 2. Detector 實作

- [x] `.github/workflows/detect-private-changes.yml`：節流 `% 15` 改為 `% 5`。
- [x] 同步第 1 行、`force` input description、節流註解與 SKIP 訊息為 5 分鐘。
- [x] 保留 `force=true` 繞過語意（Ai-agent 的 hub-ci-kick hook 依賴它）；不改其他邏輯、權限或 concurrency。
- [x] 抽出節流 bash 片段做本機測試：分鐘 00、05、55 為 FULL，01、07、14 為 SKIP，`force=true` 為 FULL。
- [x] `python3 scripts/security/audit.py` 通過；workflow YAML 可被 `yaml.safe_load` 解析。

## 3. 文件

- [x] `README.md`：每 15 分鐘 → 每 5 分鐘；2026-10-04 的歷史證據保留原文並補註。
- [x] `docs/external-scheduler.md`：標題、標準 cadence、minutes、runtime 驗收條件與 token 輪替後的等待時間改為 5 分鐘；歷史證據保留原文並補註。
- [x] `TASK_PROGRESS.md`：「detector 輪詢 15 分鐘 → 5 分鐘」改為進行中；新增「vault-health `pull_request` trigger 改由 Hub 承接」待辦（只記錄，不實作）。

## 4. 取代舊 change

- [x] 在 `align-external-scheduler-to-15m/tasks.md` 的未勾項目旁註明「superseded by detector-cadence-5m（2026-10-23）」。
- [x] `openspec archive align-external-scheduler-to-15m --yes --skip-specs`（必須 `--skip-specs`，避免把 15 分鐘 delta 套回 canonical）。
- [x] `openspec/changes/README.md`：移除舊列、加入本 change。

## 5. 合併與 live 驗收

- [x] PR #26 已合併至 `main`（2026-10-23 04:33:20Z；merge commit `9edcad7`）。
- [x] Live 驗收：合併後有至少 6 個連續、全部做了完整掃描、相鄰間隔約 5 分鐘（4～6 分鐘）的 `workflow_dispatch` runs。**不以 cron-job.org 設定頁為證。**逐筆資料見 `evidence/live-cadence-2026-10-23.md`。
  - 判斷「完整掃描」：`gh api repos/sodahsu/Automation-Hub/actions/runs/<id>/jobs --jq '.jobs[].steps[] | select(.name=="Detect private push activity") | [.started_at,.completed_at] | @tsv'`，耗時 ≥ 10 秒者為完整掃描。2026-10-23 基線：完整掃描 27–33 秒、節流 `SKIP` 0–1 秒。
  - 剔除非排程喚醒：不在 5 分鐘格點上、同一秒成對建立（其中一個被 concurrency 取消）的 run（例如 2026-10-23 的 03:44:19、04:01:59、04:07:29Z）；推測為 `force=true` 喚醒，來源未驗證。
  - 基線（變更前）：2026-10-23 02:55–03:40Z 的 10 個排程喚醒，間隔約 5 分鐘，但其中只有 00／15／30／45 分的 run 做完整掃描。
- [x] 驗收證據寫入 `evidence/live-cadence-2026-10-23.md`。
- [x] 歸檔本 change：`openspec archive detector-cadence-5m --yes`（**不加** `--skip-specs`，因為要把 5 分鐘 delta 套到 canonical spec）；歸檔後 canonical spec 與 `openspec validate --all --strict` 通過。

## 6. 後續（本 change 不做）

- [x] Ai-agent PR #655 已完成：`hook-wiring-integrity` 改為 5 分鐘。
