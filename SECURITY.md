# 安全政策

## 公開儲存庫邊界

本儲存庫為公開儲存庫。所有已提交的檔案、workflow log、job summary、artifact、cache key、Issue 與 Pull Request，都應視為公開可見資訊。

## 私有目標儲存庫規則

- 私有儲存庫在已提交檔案中只能以 `repo-01` 到 `repo-06` 的 alias 表示。
- 真實的儲存庫識別資訊只能存放在既有的 GitHub Actions 私密設定中，不得寫入公開檔案。
- 私有儲存庫的讀取憑證只能存放在 GitHub Actions 私密設定中。
- 私有儲存庫存取權限維持唯讀（read-only）。
- 私有原始碼、筆記內容、環境設定檔、憑證、儲存庫對照資訊與 clone URL，不得提交到本公開儲存庫，也不得上傳為 Artifact。
- 不得在 GitHub Actions log 中輸出完整環境變數、原始碼內容、筆記本文、remote URL，或任何由私密設定衍生出的敏感值。
- 在驗證身分或解析目標儲存庫的步驟中，不得使用 `set -x`。
- 不得快取 `workspace/`、私有原始碼目錄、`.env` 檔、憑證，或任何包含私有原始碼內容的 bundle。

## Runner 邊界

- 取得 private source 的 `private-ci.yml` 只能使用 GitHub Settings allow-list 的受控 runner group 與 `private-ci` label。
- 不得使用裸 `self-hosted` 作為 fallback，也不得把 runner 註冊到 Public Hub 以外的 source repository 或一般 cloud-agent workflow。
- `private-ci.yml` 只能從 Automation-Hub `main` 或受控手動 dispatch 執行；不接受 `pull_request` / `pull_request_target` 事件。
- Runner registration/JIT token 不進 repository、Actions secret、Issue、PR、log 或 artifact；registration 由受控主機管理。
- Runner offline 時 job 只能 queued/unavailable，不得改排 GitHub-hosted runner。
- self-hosted runner 每次執行都必須清除 workspace、`.git` metadata、askpass、command files、raw logs、archive、PR metadata 與 temporary output。

## Workflow 限制

Private CI workflow 不得：

- 對私有目標儲存庫執行 push、tag、merge 或建立 branch；
- 執行 production deployment；
- 建立、輪替或修改私密設定；
- 修改儲存庫 visibility、billing 或 branch protection；
- 搭配私有儲存庫憑證使用 `pull_request_target`；
- 將私有儲存庫 checkout 內容上傳為 Artifact；
- 將 private read token、Hub dispatch token 或 runner registration token 傳入 target CI；
- 把 `PR CI — ` 結果當成 `CI — ` default baseline evidence。

## 事件處理

如果私有內容或憑證遭到公開：

1. 立即停用受影響的 workflow。
2. 立即撤銷或輪替已暴露的憑證。
3. 在 GitHub 允許的範圍內，移除公開 Artifact、log 或其他公開引用。
4. 檢查相關私有儲存庫是否出現未授權的寫入或變更。
5. 在重新啟用受影響功能之前，建立新的 OpenSpec change，記錄原因、修正方式與重新啟用條件。
