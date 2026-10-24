# 設計：私有 CI 覆蓋稽核

## 判定規則

Detector 先沿用既有條件，確認最近一次 CI 已完成，且 `started_at` 不早於最新 `pushed_at`，再依 `conclusion` 決定是否覆蓋或重派：

- `success`：輸出 `SKIP — successful CI covers latest push`，停止處理該 alias。
- `failure` 或 `timed_out`：輸出 `FAIL — latest push CI failed; not covered`，停止處理該 alias；下一次 push 才重新 dispatch。
- 其他結論（包含 `cancelled`、`skipped`、`startup_failure`、空值）：沿用既有行為，繼續 dispatch。
- 尚未完成的 job：沿用既有 `WAIT` 行為，於下一輪重新判斷。

`scripts/common/run-ci.sh` 在沒有任何驗證 stage 時會 exit 1。因此成功結論已足以表示至少有一個驗證 stage 執行，不需要另外保存 verification counts。`ref: main` 指向公開 Automation-Hub workflow 版本，不代表私有 target branch。

## 風險與回復

adapter 若因沒有支援的 adapter 而 exit 1，該 target 的 PR status 會是 failure。目前六個公開 alias 都有 adapter：其中兩個使用專用分支 adapter，其餘有 `package.json`；因此目前設定不受影響。文件與公開證據不得記錄 alias 對應的私有 repository 名稱。

回復方式：還原 `.github/workflows/detect-private-changes.yml` 中新增的 `failure`／`timed_out` 分支，即恢復先前的輪詢行為。本 change 不修改 adapter 或私有端設定。

## 測試計畫

- 執行 `bash scripts/common/test-run-ci-portable.sh`、`python3 scripts/security/audit.py`、YAML parse、`git diff --check` 與 OpenSpec strict validation（若工具可用）。
- detector 判斷邏輯內嵌在 workflow，本機無法單元測試，GitHub 實跑 `UNVERIFIED`；不得為此新建測試框架。
- `actionlint` 未安裝時標示 `UNVERIFIED`，不以未執行宣稱通過。
- 用已存在且經清理的 Actions 摘要檢視現況；不觸發 workflow。修改後的 GitHub 實跑需由後續獲准的流程驗證。
