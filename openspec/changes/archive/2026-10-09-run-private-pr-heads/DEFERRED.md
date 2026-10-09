# Deferred closeout

日期：2026-10-09

這筆 change 的 Hub 端實作與 runtime 證據已成立，使用者於 2026-10-09 對話中批准歸檔；下列四項**沒有完成、也沒有被勾成完成**，歸檔後仍待使用者處理。

## 已成立的事實

- `private-ci.yml` PR 模式、`detect-private-changes.yml` Ready PR 偵測與文件（tasks 2.x、3.x、4.x）皆已完成。
- Ai-agent 端 machine-readable `remoteEvidence.automationHub` contract 已成立（tasks 4.2）；同 SHA 的 validation PR 由 Hub run `37190764398` 驗證 success。
- 2026-10-04 的 PR-head CI runtime 證據見 `evidence/runtime-pr-head-ci-2026-10-04.md`（pending → CI → final status 全程成功、default-branch mode 未被破壞）。

## 歸檔時延後的項目

| 項目 | 為什麼不能由 repo 內程式證明 | 誰做 |
|---|---|---|
| 1.1 `PRIVATE_REPOS_READ_TOKEN` 最小 scope（Pull requests: Read、Commit statuses: Read） | runtime 只能證明「能做到所需操作」，不能證明「沒有多授權」；只有 Settings 頁面看得到 | 使用者 |
| 1.2 `PRIVATE_REPOS_STATUS_TOKEN` 只授權 repo-01～05 的 Commit statuses 讀寫 | 同上 | 使用者 |
| 5.3 手動 `workflow_dispatch` 帶 `sha` 的入口 | 目前證據都是 detector 自動 dispatch；人工入口需有人實際操作一次 | 使用者 |
| 5.5 Draft PR 不 dispatch、已有 status 的 head 不重跑 | 缺直接 runtime evidence，需專用 smoke 或逐輪 detector 觀察 | 使用者（或另開 smoke change） |

## 為什麼歸檔

`openspec/project.md` 的歸檔規則要求「仍有 runtime observation 未完成必須留在 active 區」。本次是使用者在對話中明確批准的例外：Hub 端沒有任何可再由 repo 內變更推進的項目，剩下全是使用者端設定頁與人工操作；繼續掛 active 只會讓 inventory 長期顯示一個沒有下一步動作的 change。若日後 smoke 發現缺陷，應另開新的 OpenSpec change，不重啟這筆。

## spec 處理

以 `--skip-specs` 歸檔：本 change 的 delta 內容已包含在 canonical `openspec/specs/private-change-detection/spec.md`（逐 requirement 比對文字，4 條皆已包含）。canonical 把其中一條 requirement 的標題擴寫為「…或具名 PR head SHA」，所以 `MODIFIED` 以舊標題比對，預期會因標題不符被歸檔工具拒絕（未實測，因為內容本來就已在 canonical，無需套用）。
