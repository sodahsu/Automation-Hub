# Tasks: align-external-scheduler-to-15m

- [x] 建立 change proposal / design / spec delta / tasks。
- [x] 將 `private-change-detection` capability 從 5 分鐘改為 15 分鐘。
- [x] 修正 README 與 `docs/external-scheduler.md` 的 5 分鐘殘留敘述。
- [ ] 將 external scheduler cadence 設成 `0,15,30,45`。Blocked：cron-job.org 執行環境無已登入憑證，本次嘗試未修改任何 runtime 設定；見 `evidence/runtime-change-attempt-2026-09-27.md`。
- [ ] 取得至少三個連續 `workflow_dispatch` detector runs 的 live timestamps，確認約 15 分鐘間隔。目前 live runs 仍約每 5 分鐘，migration pending。
- [x] 確認 change detector 仍只 dispatch 有變更的 alias，且 private access / sanitized log policy 無變動（branch diff 未修改 workflow / adapter）。
- [ ] 執行 OpenSpec strict validation 與 repository checks。
- [ ] independent review 後開 draft PR；runtime evidence 未完成前不得宣稱 migration complete，也不得自動 merge。
