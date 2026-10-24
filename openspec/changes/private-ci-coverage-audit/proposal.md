# 提案：修正私有 CI 覆蓋判定

## 問題

Detector 依 alias 找到最近一次 bridge job，並記錄其 `status`、`conclusion` 與 `started_at`。當 job 開始時間不早於儲存庫最近一次 `pushed_at` 時，只有 `conclusion == success` 才代表該 push 已有成功 CI 覆蓋；若結論是 `failure` 或 `timed_out`，目前每次輪詢仍會重派相同 push，外部 scheduler 每五分鐘喚醒時會造成重複執行。

## 提議變更

保留成功 CI 覆蓋最新 push 時的 `SKIP — successful CI covers latest push` 判定。若同一 push 上最近完成的 CI 結論為 `failure` 或 `timed_out`，摘要寫入 `FAIL — latest push CI failed; not covered` 並停止處理該 alias；此 push 不視為已覆蓋，但也不在後續輪詢重派，等下一次 push 再執行。其他結論（例如 `cancelled`、`skipped`、`startup_failure` 或空值）仍依既有行為重派。

本 change 也記錄既有 adapter 的實際行為：沒有任何驗證 stage 時以 exit 1 結束，因此 `conclusion == success` 本身即表示至少執行過一個驗證 stage。`ref: main` 是選擇 Automation-Hub workflow 的版本，不是私有 target branch，因此不是缺陷。

保留 public-safe alias 輸出，不在公開檔案或摘要加入私有 repository 名稱、mapping、source 或 credential。沒有授權的私有檢視時，alias 對應與私有預設分支仍標示 `UNVERIFIED`。

## 範圍

- `.github/workflows/detect-private-changes.yml`：只調整最新 push 的完成 job 結論判斷。
- `openspec/changes/private-ci-coverage-audit/`：以繁體中文記錄已完成實作、驗證計畫與限制。
- 不修改 adapter、secret、私有 repository 或其他輪詢邏輯。
