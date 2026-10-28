# 任務：私有 CI 覆蓋稽核

## 實作

- [x] Detector 記錄 `conclusion`；只有最新 push 之後成功完成的 job 算覆蓋。
- [x] 最新 push 的 CI 結論為 `failure`／`timed_out` 時輸出 `FAIL — latest push CI failed; not covered`，不重派。
- [x] 進行中的 job 一律 `WAIT`。
- [x] `run-ci.sh` 沒有驗證 stage 時 exit 1，摘要保留 `UNVERIFIED`。
- [x] 確認 `ref: main` 選的是 Automation-Hub workflow 版本，不是缺陷。
- [ ] 歸檔時保留 `UNVERIFIED`：未執行 alias 對照檢視；公開變更紀錄不記載私有映射或名稱。

## 測試計畫

- [x] `bash scripts/common/test-run-ci-portable.sh`：exit 0（含新增的「不支援的 adapter 不可通過」案例）。
- [x] `bash -n scripts/common/run-ci.sh scripts/common/test-run-ci-portable.sh`：exit 0。
- [x] Python YAML parse 兩個 workflow：exit 0。
- [x] `python3 scripts/security/audit.py`：exit 0。
- [x] `openspec validate private-ci-coverage-audit --strict`：exit 0。
- [x] `git diff --check`：exit 0。
- [ ] Detector 分類沒有本機單元測試入口；合併後 run `40725755633` 確認 workflow 執行成功，未以該 run 宣稱所有分類分支均已驗證。
- [ ] `actionlint`：`UNVERIFIED`，本機未安裝（exit 127）；未宣稱通過。

## 回滾

revert 實作 commit，detector 與 adapter 一起還原；兩者不可分開回滾（見 design.md）。
