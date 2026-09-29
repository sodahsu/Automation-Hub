---
title: "Run Private CI on Pull Request Heads"
tags:
  - OpenSpec/Change
  - Governance/Automation
  - CI-Gate
date: 2026-09-29
type: decision
status: proposed
source: ai-assisted
---

# Run Private CI on Pull Request Heads

## Why

2026-09-29，private 來源 repo（例如 Ai-agent）的 GitHub Actions 因帳號付款問題無法啟動，PR #484～#486 的 CI 全部「job was not started」，只能靠本機驗證就合併。Automation-Hub 是 Public repo，Actions 不受這個計費限制影響，但現行設計只驗證 default branch（`Private CI MUST 只驗證 default branch`），所以只能在合併後做事後驗證，擋不住壞的 PR，結果也不會出現在 PR 的 checks 上。

讓 Automation-Hub 驗證 PR head，並把結果回寫成 PR 上的 commit status，private repo 自己的 Actions 停擺時，PR 仍然有合併前的 CI 證據。

## What Changes

- `private-ci.yml` 的 `workflow_dispatch` 新增選填 input `sha`，只接受 40 碼十六進位 commit SHA。沒帶 `sha` 時行為與現在完全相同（驗證 default branch）。
- 帶 `sha` 時用 `/repos/{repo}/tarball/{sha}` 取得該 commit 的原始碼，跑同一套 `run-ci.sh`。repo-06 不支援 PR 模式（它是 main-only 的知識庫，且走 sparse clone）。
- PR 模式的 job 名稱改為 `CI — <alias> · PR`，避免被 detector 的 default branch 追蹤邏輯（`^CI — repo-0[1-6]$`）誤認成 main 的結果。
- 新增獨立 job 回寫 commit status（context `automation-hub/private-ci`）：開始時寫 `pending`，結束時寫 `success`／`failure`／`error`，`target_url` 指向 Public run。寫入用的新 secret `PRIVATE_REPOS_STATUS_TOKEN` 只存在這兩個 job，執行 private 程式碼的 CI job 拿不到。
- `detect-private-changes.yml` 每輪額外列出 repo-01～05 的 **open、非 Draft** PR。head SHA 上還沒有 `automation-hub/private-ci` status 的，dispatch 一次 PR 模式。Draft 不跑，與六倉「Ready 後才集中跑 CI」的規則一致，也節省執行次數。
- `PRIVATE_REPOS_READ_TOKEN` 需要新增兩個唯讀權限：Pull requests: Read、Commit statuses: Read。

## 取捨（需要使用者決定的單向門）

這個 change 會修改兩條既有的信任邊界：

1. **`Private CI MUST 只驗證 default branch` → 放寬為可驗證指定 SHA。** 仍然不接受分支名稱作為 Public input，只接受 SHA，不會在 Public log 洩漏 private 分支名。
2. **`Private repository access MUST 維持 read-only` → 新增一個僅能寫 commit status 的 credential。** 這是 Automation-Hub 第一次對 private repo 有寫入能力。影響範圍限制在：fine-grained PAT、只選需要的 repo、只給 Commit statuses: Read and write，不含 Contents 寫入，無法改 code、branch 或 PR。

不接受第 2 點的話，退路是只做第 1 點：PR 驗證的結果只留在 Public run summary，不回寫到 PR。

## Non-goals

- 不讓 PR 的 check 成為強制合併條件。private repo 的 branch protection／ruleset 是否能要求這個 status，取決於 GitHub 方案（Unknown，見 design）。
- 不提高 repo-04（Ai-agent）的 CI 覆蓋度。`architecture/workflows.json` 標示它是 `partial`，PR 模式跑的就是這份 partial 範圍。
- 不處理 repo-06（ObsidianBook）。

## Capabilities

修改既有 capability `private-change-detection`：MODIFIED 兩條、ADDED 兩條。

## Impact

- `.github/workflows/private-ci.yml`、`.github/workflows/detect-private-changes.yml`
- `README.md`（secret 與權限說明）
- 使用者手動設定：新建 `PRIVATE_REPOS_STATUS_TOKEN`；替 `PRIVATE_REPOS_READ_TOKEN` 加兩個唯讀權限
