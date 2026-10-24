# 任務：私有 CI 覆蓋稽核

- [ ] 透過授權的私有檢視確認六個 runtime alias 對應與預設分支；`UNVERIFIED`：本次沒有可用的私有 mapping 檢視，且不得把對照寫入公開 repo。
- [x] 確認成功 CI 覆蓋最新 push 時維持 `SKIP — successful CI covers latest push`。
- [x] 最新 push 的 CI 結論為 `failure` 或 `timed_out` 時輸出 `FAIL — latest push CI failed; not covered` 並停止重派；其他結論維持重派。
- [x] 確認既有 adapter 在沒有驗證 stage 時 exit 1，故成功結論代表至少有驗證 stage 執行；排除「history record 加 sanitized verification counts」的未實作要求。
- [x] 記錄 `ref: main` 選擇 Automation-Hub workflow 版本，並非私有 target branch，因此不是缺陷。
- [x] 更新本 change 的繁體中文 OpenSpec，包含風險、測試計畫與回滾方式。
- [ ] detector 判斷邏輯內嵌在 workflow，本機無法單元測試，GitHub 實跑 `UNVERIFIED`；沒有新增測試框架。
- [ ] `actionlint`：`UNVERIFIED`，本機未安裝。
- [ ] GitHub 實跑修改後 workflow：`UNVERIFIED`，本任務禁止觸發 workflow。
- [x] 查閱既有 Actions 狀態；僅讀取，不觸發 workflow。
- [x] `bash scripts/common/test-run-ci-portable.sh`：exit 0。
- [x] Python YAML parse `.github/workflows/detect-private-changes.yml`：exit 0。
- [x] `python3 scripts/security/audit.py`：exit 0。
- [x] `openspec validate private-ci-coverage-audit --strict`：exit 0。
- [x] `git diff --check`：exit 0。
- [ ] `actionlint .github/workflows/detect-private-changes.yml .github/workflows/private-ci.yml`：`UNVERIFIED`，本機未安裝，command exit 127。

## 測試計畫

- 執行 `bash scripts/common/test-run-ci-portable.sh`。
- 若本次修改 shell 檔，執行對應 `bash -n`。
- 使用 Python 或 Ruby 解析 `.github/workflows/detect-private-changes.yml`。
- 執行 `python3 scripts/security/audit.py`。
- 若已安裝 `openspec`，執行 `openspec validate private-ci-coverage-audit --strict`。
- 執行 `git diff --check`。
- workflow 判斷沒有本機單元測試入口；GitHub 實跑列為 `UNVERIFIED`。

## 回滾

還原 `.github/workflows/detect-private-changes.yml` 中對 `failure`／`timed_out` 的分支即可恢復修改前行為。本 change 未變更 adapter、secret 或私有 repository。
