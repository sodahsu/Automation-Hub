# Tasks: hub-stage-evidence-20261028

## 1. 實作

- [x] 1.1 在 `run-ci.sh` 新增可選第 4 參數，從同一份 rows 產生契約 JSON；空參數不寫檔，非法 stage 名稱輸出空 stages。
- [x] 1.2 在 `private-ci.yml` 將證據傳給 run-ci，並以固定 SHA 的 upload-artifact 上傳，保留 alias 名稱、always、warn 與 30 天設定。
- [x] 1.3 更新 README 說明公開 stage evidence 的欄位與邊界。
- [x] 1.4 建立 `private-change-detection` 的 MODIFIED delta。
- [x] 1.5 將 `scripts/security/audit.py` 改為 YAML 結構驗證唯一的去敏 evidence artifact 例外，並在 `SECURITY.md` 記錄邊界與理由。

## 2. 驗證

- [x] 2.1 執行 `bash -n` 檢查相關 shell scripts。
- [x] 2.2 執行 stage evidence 測試及既有 `test-run-ci-portable.sh`。
- [x] 2.3 以 Python 解析兩個 workflow YAML，並執行 security audit、OpenSpec strict validation 與 `git diff --check`。
- [x] 2.4 檢查變更範圍並提交至目前分支；不執行 push、PR 或 workflow。
- [x] 2.5 security audit 自我測試須拒絕其他 workflow 的 upload、重複 upload step 與錯誤路徑。
