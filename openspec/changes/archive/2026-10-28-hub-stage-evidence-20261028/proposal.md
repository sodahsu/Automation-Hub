# Proposal: hub-stage-evidence-20261028

## Why

現有 CI summary 供人閱讀，但無法由唯讀 API 穩定取得 stage rows。提供受限 schema 的 run-scoped artifact，讓外部稽核依 stage 證據判斷；既有 job 結論與 Markdown summary 維持原語意。

## What Changes

- `run-ci.sh` 由同一份 stage rows 同時產生 Markdown summary 與版本化 JSON 證據。
- `private-ci.yml` 將 JSON 以 alias 命名為 artifact，固定保留 30 天；找不到檔案時警告，上傳失敗不改變 job conclusion。
- 新增 stage evidence 測試與 README 文件，修改既有 `private-change-detection` capability 的 artifact 契約。
- security audit 原本禁止所有 artifact；為符合跨倉契約，增加唯一且可由 YAML 結構驗證的去敏 stage evidence 例外，其他 workflow 與 private source artifact 仍禁止。

## Source Contract

本 change 的欄位、狀態、命名及上傳行為依跨倉 change `hub-stage-evidence-20261028` 的「跨倉契約 v1」執行，不在此另行擴充。

## Out of Scope

- 不改 private repository、其映射、驗證指令或既有 exit code。
- 不觸發 workflow、不 push、不建立 PR，也不修改 GitHub 設定。
- 不上傳 private source、命令輸出或失敗原因。

## Impact

- `scripts/common/run-ci.sh`、`.github/workflows/private-ci.yml`、stage evidence 測試與 README。
- `openspec/specs/private-change-detection` 的 artifact 行為 delta。
- `scripts/security/audit.py` 與 `SECURITY.md`：將唯一允許的 artifact 限定在 `private-ci.yml` 的單一固定路徑、命名前綴與最多 30 天保留。
