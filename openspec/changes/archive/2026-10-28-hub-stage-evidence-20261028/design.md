# Design: hub-stage-evidence-20261028

## Decision

由 `write_summary()` 從現有 `rows` 序列化 JSON，避免另跑指令或從 Markdown 以外的資料源重建 stage 結果。空的第 4 個位置參數保留既有呼叫行為。JSON 僅含 `schemaVersion`、`target`、`stages`；每筆 stage 僅含 `name` 與第一個狀態字，stage 名稱不符合契約 regex 時整個 stages 清空。

workflow 使用 matrix job 中既有的 `matrix.target` 作 artifact alias，並於 summary 發布後、workspace cleanup 前上傳 `${RUNNER_TEMP}/stage-evidence/stage-evidence.json`。上傳條件、缺檔處理與保留天數依跨倉 change `hub-stage-evidence-20261028` 的「跨倉契約 v1」；action 固定至經 GitHub tag ref 查得的完整 commit SHA。上傳 step 使用 `continue-on-error`，避免上傳服務錯誤覆蓋 CI 結論。

## Security Audit Exception

既有 security audit 禁止任何 artifact，而跨倉契約要求發布 sanitized stage evidence。為避免放寬成一般 artifact 上傳，audit 以 YAML 結構解析確認：只有 `private-ci.yml` 可包含 upload-artifact，且恰有一個 step；路徑必須精確為 `${{ runner.temp }}/stage-evidence/stage-evidence.json`，名稱以 `hub-stage-evidence-` 開頭，保留天數必須是正整數且不超過 30。其他 workflow、額外 upload step、workspace 路徑、萬用字元或任何路徑變更都拒絕。security self-check 會以違規 fixture 驗證這些拒絕規則。

## Data Boundary

Artifact 只包含 public-safe alias、stage 識別字和列舉狀態。括號原因及 stage 命令輸出不寫入 JSON；既有 Markdown summary 不變。JSON 由 Python 標準庫編碼，避免手工 escaping 造成無效檔案。

## Verification

新增 shell 測試涵蓋四種狀態、原因去除、非法名稱 fail-closed、空參數、repo-03 缺少 package.json 的提早結束，以及 JSON 頂層白名單與解析。工作流程只做靜態驗證，不觸發 live run。
