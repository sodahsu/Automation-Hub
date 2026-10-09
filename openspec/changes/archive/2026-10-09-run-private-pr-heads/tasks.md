## 1. 使用者手動設定（實作前）

- [ ] 1.1 （使用者手動）`PRIVATE_REPOS_READ_TOKEN` 加上 Pull requests: Read、Commit statuses: Read。2026-10-04 runtime 已證明 detector 能讀 Ready PR / status 並完成 PR-head CI，但本環境看不到 PAT 設定頁，**精確 scope 仍未直接驗證**；見 `evidence/runtime-pr-head-ci-2026-10-04.md`。
  - 歸檔時延後：PAT 精確 scope 只能在 GitHub Settings 頁面由使用者核對，runtime 與 repo 內程式都無法反推「沒有多授權」（2026-10-09）。
- [ ] 1.2 （使用者手動）新建 fine-grained PAT `PRIVATE_REPOS_STATUS_TOKEN`：只選 repo-01～05 對應的 repo，Commit statuses: Read and write，存成 Automation-Hub Actions secret。2026-10-04 runtime 已證明 pending / final commit status 可成功寫入，但**是否只授權這組最小 scope**仍無法由 runtime 反推；見 evidence。
  - 歸檔時延後：同上，`PRIVATE_REPOS_STATUS_TOKEN` 是否只授權 repo-01～05 的 Commit statuses 讀寫，需使用者在 Settings 頁面確認（2026-10-09）。

## 2. private-ci.yml

- [x] 2.1 `workflow_dispatch` 新增選填 input `sha`，驗證 `^[0-9a-f]{40}$`，並拒絕 `repo-06`
- [x] 2.2 PR 模式用 `/tarball/{sha}` 取原始碼，job 名稱為 `CI — <alias> · PR`
- [x] 2.3 新增 `mark-pending` 與 `report` job；status token 不出現在 `ci` job
- [x] 2.4 PR 模式 concurrency group 帶入 sha

## 3. detect-private-changes.yml

- [x] 3.1 列出 repo-01～05 的 open、非 Draft PR，head 沒有 `automation-hub/private-ci` status 就 dispatch
- [x] 3.2 summary 只寫計數，不寫 PR 編號、標題或分支名
- [x] 3.3 確認 default branch 偵測邏輯與 job 名稱比對不受影響

## 4. 文件

- [x] 4.1 README 更新 secret 說明與 PR 模式
- [x] 4.2 Ai-agent 已以獨立 OpenSpec `record-hub-pr-head-evidence` + Draft PR #541 擴充 `architecture/workflows.json.remoteEvidence.automationHub`：新增 `prStatusContext: automation-hub/private-ci`，repo-01～05 `prHead: true`、repo-06 `false`。同 SHA 的 CI-only PR #543 已由 Automation-Hub run `37190764398` 驗證 success；Hub runtime 本身未修改。

## 5. 驗證

- [x] 5.1 `actionlint`（若有）與 YAML parse
- [x] 5.2 `openspec validate run-private-pr-heads --strict`
- [ ] 5.3 （secret 就緒後手動）手動：對 Ai-agent 一個 Ready PR dispatch `target=repo-04 sha=<head>`，確認 PR 上依序出現 `pending` → `success`／`failure`。2026-10-04 已有更接近 production 的**自動 detector**證據：Ai-agent #534～#537 都成功走 `Mark PR status pending` → `CI — repo-04 · PR` → `Report PR status`，但「人類手動 dispatch」這個特定入口尚未單獨驗證。
  - 歸檔時延後：需使用者手動 dispatch `target=repo-04 sha=<head>` 一次，觀察 PR 上 `pending` → `success／failure`；自動 detector 路徑已有 runtime 證據，人工入口尚未單獨驗證（2026-10-09）。
- [x] 5.4 不帶 `sha` 的 default-branch 行為不變。2026-10-03 Public runs `37137402812`、`37135302261` 皆為 `CI — repo-04` success，PR status jobs skipped；另有 `repo-01` default-branch success。這是 runtime 等價證據，不需另製造測試 run。
- [ ] 5.5 等一輪 detector，確認新的 Ready PR 會自動 dispatch、Draft 不會、已有 status 的不重跑。2026-10-04 已證明前半：Ai-agent #534～#537 的 PR-head run 皆由 `github-actions[bot]` 觸發且 status success；**Draft skip 與已有 status 不重跑仍缺直接 runtime evidence**。
  - 歸檔時延後：Draft PR 不 dispatch、已有 status 的 head 不重跑，仍缺直接 runtime evidence，需專用 smoke 或逐輪 detector 觀察（2026-10-09）。
