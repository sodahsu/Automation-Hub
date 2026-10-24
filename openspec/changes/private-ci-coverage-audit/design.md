# 設計：私有 CI 覆蓋稽核

## 判定規則

Detector 對每個 alias 取最近一次 bridge job 的 `status`、`conclusion`、`started_at`：

| 狀態 | 條件 | 輸出 | 是否 dispatch |
|---|---|---|---|
| 進行中 | `status != completed` | `WAIT — CI in progress; recheck next poll` | 否，下一輪再判斷 |
| 已完成，覆蓋最新 push | `started_at >= pushed_at` 且 `conclusion == success` | `SKIP — successful CI covers latest push` | 否 |
| 已完成，最新 push 失敗 | `started_at >= pushed_at` 且 `conclusion` 為 `failure`／`timed_out` | `FAIL — latest push CI failed; not covered` | 否，等下一次 push |
| 其他 | 結論為 `cancelled`、`skipped`、`startup_failure`、空值，或 job 早於最新 push | — | 是 |

失敗不重派的理由：同一個 push 的 CI 失敗通常可重現，每五分鐘重派只會累積相同結果的 run。偶發失敗需要重跑時，由人工 `workflow_dispatch` 處理。

## Adapter 結果

`scripts/common/run-ci.sh` 在沒有任何驗證 stage（扣除 `package-json`、`install` 等備料 stage）時把 `overall_rc` 設為 1，並保留 `UNVERIFIED` 摘要與 annotation。這讓 detector 只看 `conclusion` 就能分辨「真的通過」與「沒驗到東西」。

## 風險

- 沒有支援 adapter 的 target，PR commit status 會從 `success` 變成 `failure`。目前六個 alias 都有 adapter（兩個走專用分支，其餘有 `package.json`），現況不受影響；新增 target 時要先補 adapter。
- `started_at` 與 `pushed_at` 的比較是時間上的間接證據，不是私有 SHA 的精確比對；私有 SHA 不寫進公開 log。
- 公開文件與證據不得記錄 alias 對應的私有 repository 名稱。

## 回滾

revert 本 change 的實作 commit（detector 與 adapter 一起還原）。只還原 adapter 而保留 detector 時，沒有驗證 stage 的 run 會再度被當成成功覆蓋，因此兩者不可分開回滾。
