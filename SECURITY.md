# 安全政策

## 公開儲存庫邊界

本儲存庫為公開儲存庫。所有已提交的檔案、workflow log、job summary、artifact、cache key、Issue 與 Pull Request，都應視為公開可見資訊。

## 私有目標儲存庫規則

- 私有儲存庫在已提交檔案中只能以 `repo-01` 到 `repo-06` 的 alias 表示。
- 真實的儲存庫識別資訊只能存放在既有的 GitHub Actions 私密設定中，不得寫入公開檔案。
- 私有儲存庫的讀取憑證只能存放在 GitHub Actions 私密設定中。
- 私有儲存庫的程式碼與 PR 資料維持唯讀；只有獨立的狀態憑證可寫入 commit status。
- 私有原始碼、筆記內容、環境設定檔、憑證、儲存庫對照資訊與 clone URL，不得提交到本公開儲存庫，也不得上傳為 Artifact。唯一例外是 `private-ci.yml` 上傳的去敏 stage evidence JSON；它只含 public-safe alias、stage 名稱與列舉狀態。
- 不得在 GitHub Actions log 中輸出完整環境變數、原始碼內容、筆記本文、remote URL，或任何由私密設定衍生出的敏感值。
- 在驗證身分或解析目標儲存庫的步驟中，不得使用 `set -x`。
- 不得快取 `workspace/`、私有原始碼目錄、`.env` 檔、憑證，或任何包含私有原始碼內容的 bundle。

## Workflow 限制

公開 CI workflow 不得：

- 對私有目標儲存庫執行 push、tag、merge 或建立 branch；
- 執行 production deployment；
- 建立、輪替或修改私密設定；
- 修改儲存庫 visibility、billing 或 branch protection；
- 搭配私有儲存庫憑證使用 `pull_request_target`；
- 將私有儲存庫 checkout 內容上傳為 Artifact。

唯一允許的 Artifact 是去敏 stage evidence：`private-ci.yml` 必須恰有一個 upload step，`with.path` 固定為 `${{ runner.temp }}/stage-evidence/stage-evidence.json`，`with.name` 以 `hub-stage-evidence-` 開頭，`retention-days` 為 30 或更短。不得上傳 workspace 路徑或萬用字元；`scripts/security/audit.py` 以 YAML 結構檢查此界線，其他 workflow 一律禁止 Artifact upload。

## #34 安全檢查紀錄

- Hub workflow 與 alias 對照由維護者管理；手動輸入、PR metadata、GitHub API 回應、目標程式及其輸出都不當作可信指令或通過證據。只用已知 alias、映射的儲存庫與驗證過的完整 SHA 存取目標，查不到或證據不完整就不派工。
- Hub workflow token 在 detector 只有 Actions: Write（派工）及 Contents: Read，在 receiver 只有 Contents: Read。目標讀取憑證負責讀取程式碼、PR 與 commit status；既有狀態憑證只需目標 Commit statuses: Write，只進入 detector 與 receiver 的狀態步驟，不提供給執行目標程式的步驟。
- 啟用 repo-06 PR status 回寫時，`PRIVATE_REPOS_STATUS_TOKEN` 的 repository access 需包含 repo-06，且只授予 Commit statuses: write；不得增加 Contents、Pull requests 或其他權限。未授權時，pending status 寫入被拒絕會使 workflow fail closed，不會執行 CI 或回報成功。
- 自動掃描只接受 head repository 與映射目標相同的非草稿 PR；fork 或來源不可辨識時不派工。手動指定 SHA 不做 PR 來源比對，只能由受信任的操作者指定可執行的 SHA，不是 fork PR 的驗證入口。
- Detector 串行執行，在派工前為目標的 exact SHA 寫入獨立的 reservation status，並查同 SHA 的狀態歷史確認沒有其他 reservation 或 CI status。它記錄 detector run attempt，不代表 CI 通過；歷史不完整或派工回應不明時保留 reservation，不重送。維護者應先查 Hub run，再決定是否需要手動處理。
- 摘要用 Hub 固定欄位、stage 白名單及列舉值重建，不發布目標產生的 Markdown；artifact 在上傳前驗證與重寫。
- 指令檔隔離用於防止正常 adapter 意外寫入，不是同 runner 上任意程式碼的沙盒。仍須信任既有目標程式與 PR head；本變更未新增可執行目標。
- 同一個 GitHub-hosted runner 不構成程式碼沙盒；在 runner 上執行的依賴安裝與檢查可能互相存取檔案及程序。Actions log、job summary 與 artifact 一律視為公開，所有依賴與其輸出均須按公開資訊處理。
- 若發現可疑依賴、鎖定檔異常，或任何未預期的公開 log、summary、artifact 內容，立即停用受影響 workflow，停止後續觸發，並依下方事件處理程序移除公開資料及檢查影響；完成調查與修正前不得重新啟用。
- 唯讀查詢 GitHub 儲存庫 runner 清單：`total_count=0`。靜態稽核與合成測試不是獨立 review，也不涵蓋 GitHub 線上取消／回寫行為；後兩者仍待合併前確認。

## 事件處理

如果私有內容或憑證遭到公開：

1. 立即停用受影響的 workflow。
2. 立即撤銷或輪替已暴露的憑證。
3. 在 GitHub 允許的範圍內，移除公開 Artifact、log 或其他公開引用。
4. 檢查相關私有儲存庫是否出現未授權的寫入或變更。
5. 在重新啟用受影響功能之前，建立新的 OpenSpec change，記錄原因、修正方式與重新啟用條件。

若事件涉及可疑依賴或非預期公開輸出，也依相同程序停用 workflow、移除可移除的公開資料，並先完成調查與修正，再建立重新啟用條件。
