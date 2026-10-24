# 提案：修正私有 CI 覆蓋判定

## 問題

1. **Detector 不看結論**：detector 依 alias 找最近一次 bridge job，原本只記錄 `status` 與 `started_at`。只要 job 已完成且開始時間不早於最新 `pushed_at`，就判定「已覆蓋」並略過 dispatch，不管這次 CI 是成功、失敗還是被取消。失敗或沒有實際驗證的 run 因此會被當成已覆蓋。
2. **沒有驗證也是綠燈**：`scripts/common/run-ci.sh` 在沒有任何 adapter／檢查 stage 執行時仍 exit 0，`private-ci.yml` 把它對應成 PR commit status `success`。
3. **改成看結論之後的副作用**：若只要求 `conclusion == success` 才算覆蓋，最新 push 上真正失敗的 CI 會在外部 scheduler 每五分鐘喚醒時被重派，一天約 288 次，結果都一樣。

## 提議變更

- Detector 額外記錄 job 的 `conclusion`。最新 push 之後完成的 job：
  - `success`：輸出 `SKIP — successful CI covers latest push`。
  - `failure` 或 `timed_out`：輸出 `FAIL — latest push CI failed; not covered`，不重派；這個 push 不算已覆蓋，下一次 push 才會重新 dispatch。
  - 其他結論（`cancelled`、`skipped`、`startup_failure`、空值）：重派。
- 進行中的 job 一律輸出 `WAIT`，下一輪再判斷；不再因開始時間晚於 push 就標成已覆蓋。
- Adapter 沒有執行任何驗證 stage 時改為 exit 1，摘要標示 `UNVERIFIED`。因此 `conclusion == success` 本身就代表至少跑過一個驗證 stage，不需要另外保存 verification counts。

`ref: main` 選的是 Automation-Hub 自己的 workflow 版本，不是私有 target branch；原本懷疑的「dispatch ref 寫死 main」經查不是缺陷。

公開檔案與摘要只保留 alias，不寫入私有 repository 名稱、mapping、source 或 credential。沒有授權的私有檢視時，alias 對應與私有預設分支標示 `UNVERIFIED`。

## 範圍

- `.github/workflows/detect-private-changes.yml`：覆蓋判斷。
- `scripts/common/run-ci.sh`：沒有驗證 stage 時的 exit code。
- `scripts/common/test-run-ci-portable.sh`：新增「不支援的 adapter 不可通過」案例。
- 不修改 secret、私有 repository 或其他輪詢邏輯。
