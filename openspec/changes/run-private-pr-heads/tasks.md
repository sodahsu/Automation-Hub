## 1. 使用者手動設定（實作前）

- [ ] 1.1 （使用者手動）`PRIVATE_REPOS_READ_TOKEN` 加上 Pull requests: Read、Commit statuses: Read
- [ ] 1.2 （使用者手動）新建 fine-grained PAT `PRIVATE_REPOS_STATUS_TOKEN`：只選 repo-01～05 對應的 repo，Commit statuses: Read and write，存成 Automation-Hub Actions secret

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
- [ ] 4.2 （Ai-agent 另開 PR）Ai-agent `architecture/workflows.json` 的 remoteEvidence 註記 PR 模式（另開 Ai-agent PR）

## 5. 驗證

- [x] 5.1 `actionlint`（若有）與 YAML parse
- [x] 5.2 `openspec validate run-private-pr-heads --strict`
- [ ] 5.3 （secret 就緒後手動）手動：對 Ai-agent 一個 Ready PR dispatch `target=repo-04 sha=<head>`，確認 PR 上依序出現 `pending` → `success`／`failure`
- [ ] 5.4 （secret 就緒後手動）手動：不帶 `sha` dispatch，確認 default branch 行為不變
- [ ] 5.5 （secret 就緒後手動）手動：等一輪 detector，確認新的 Ready PR 會自動 dispatch、Draft 不會、已有 status 的不重跑
