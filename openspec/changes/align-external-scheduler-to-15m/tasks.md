# Tasks: align-external-scheduler-to-15m

- [x] 建立 change proposal / design / spec delta / tasks。
- [x] 將 `private-change-detection` capability 從 5 分鐘改為 15 分鐘。
- [x] 修正 README 與 `docs/external-scheduler.md` 的 5 分鐘殘留敘述。
- [ ] 將 external scheduler cadence 設成 `0,15,30,45`。2026-10-04 live runtime 已呈現穩定約 15 分鐘 cadence，但本執行環境未直接登入 cron-job.org 讀取設定頁，因此不把「設定值本身」冒充已驗證；見 `evidence/live-cadence-2026-10-04.md`。
- [x] 取得至少三個連續 `workflow_dispatch` detector runs 的 live timestamps，確認約 15 分鐘間隔。2026-10-04 觀察到 8 個連續 success runs，04:15:09Z → 06:00:23Z，相鄰皆約 15 分鐘；見 `evidence/live-cadence-2026-10-04.md`。
- [x] 確認 change detector 仍只 dispatch 有變更的 alias，且 private access / sanitized log policy 無變動（branch diff 未修改 workflow / adapter）。
- [ ] 執行 OpenSpec strict validation 與 repository checks。2026-10-04 PR #19 run `37183410335` 的 `OpenSpec strict validation` job 已 success；該 run 沒有另外執行 generic repository/security checks，因此只把 strict 部分視為已驗證，不把整個複合 task 勾成完成。
- [x] 開立 Draft PR #2。
- [ ] 完成 independent review；舊 PR #2 的 runtime evidence 已過時，2026-10-04 reconciliation 需重新 review。外部 scheduler 設定頁仍未直接驗證前，不宣稱該 UI 設定值已被確認。
