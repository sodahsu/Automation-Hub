# 任務：私有 CI 覆蓋稽核

## 實作

- [x] Detector 記錄 `conclusion`；只有最新 push 之後成功完成的 job 算覆蓋。
- [x] 最新 push 的 CI 結論為 `failure`／`timed_out` 時輸出 `FAIL — latest push CI failed; not covered`，不重派。
- [x] 進行中的 job 一律 `WAIT`。
- [x] `run-ci.sh` 沒有驗證 stage 時 exit 1，摘要保留 `UNVERIFIED`。
- [x] 確認 `ref: main` 選的是 Automation-Hub workflow 版本，不是缺陷。
- [ ] 透過授權的私有檢視確認六個 alias 的對應與預設分支。`UNVERIFIED`：本次沒有私有 mapping 檢視，且對照不得寫進公開 repo。

## 測試計畫

- [x] `bash scripts/common/test-run-ci-portable.sh`：exit 0（含新增的「不支援的 adapter 不可通過」案例）。
- [x] `bash -n scripts/common/run-ci.sh scripts/common/test-run-ci-portable.sh`：exit 0。
- [x] Python YAML parse 兩個 workflow：exit 0。
- [x] `python3 scripts/security/audit.py`：exit 0。
- [x] `openspec validate private-ci-coverage-audit --strict`：exit 0。
- [x] `git diff --check`：exit 0。
- [ ] Detector 判斷邏輯內嵌在 workflow，本機沒有單元測試入口。`UNVERIFIED`：合併後以 detector run 的 step summary 確認 `SKIP`／`FAIL`／`WAIT` 分類。
- [ ] `actionlint`：`UNVERIFIED`，本機未安裝（exit 127）。

## 回滾

revert 實作 commit，detector 與 adapter 一起還原；兩者不可分開回滾（見 design.md）。
