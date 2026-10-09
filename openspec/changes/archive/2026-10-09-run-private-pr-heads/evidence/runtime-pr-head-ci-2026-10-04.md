# PR-head CI runtime evidence（2026-10-04）

## Scope

本文件只記錄可由 GitHub runtime 直接證明的事實，不把 Secret 內容或 PAT scope 推論成已直接檢查。

## Ready PR head 已由 Automation-Hub 驗證並回寫 status

Ai-agent 最近四個已合併 PR 的 head commit 均可讀到同一個 commit status context：

| Ai-agent PR | Head SHA | Commit status | Automation-Hub run |
|---|---|---|---|
| #534 | `ac4734c1219b1f504aa65bc7480d9a83b3811709` | `automation-hub/private-ci = success` | `37134554565` |
| #535 | `b28e0d5729374f7eb3165edf3849c37d79514e30` | `automation-hub/private-ci = success` | `37135490127` |
| #536 | `c6695aa38b6784d3236d09584f1d2944a9d02fe1` | `automation-hub/private-ci = success` | `37137264807` |
| #537 | `160424b74a428041c9b71b2b609e47339933b5f3` | `automation-hub/private-ci = success` | `37137406155` |

這些 Public workflow runs 的 `actor` 與 `triggering_actor` 都是 `github-actions[bot]`，不是人類手動觸發，符合 detector 自動 dispatch 的行為。

以 run `37137406155` 為例，jobs 依序為：

- `Resolve run mode` → success
- `Mark PR status pending` → success
- `CI — repo-04 · PR` → success
- `Report PR status` → success

因此可直接證明：PR mode resolve、pending status 寫入、repo-04 PR-head CI、final status 回寫都曾在真實 runtime 成功。

## Default-branch mode 仍正常

相鄰時段的 Public runs 仍存在不帶 PR suffix 的 default-branch mode，例如：

- run `37137402812`：`CI — repo-04` → success；`Mark PR status pending` / `Report PR status` 皆 skipped
- run `37135302261`：`CI — repo-04` → success；PR status jobs skipped
- run `37136198256`：`CI — repo-01` → success；PR status jobs skipped

因此 PR-head mode 上線後，default-branch mode 沒有被破壞。

## 尚未直接證明

以下仍不應冒充已驗證：

1. `PRIVATE_REPOS_READ_TOKEN` 與 `PRIVATE_REPOS_STATUS_TOKEN` 在 GitHub Settings 裡的**精確最小權限 scope**。Runtime 證明 credential 能完成所需操作，但不能證明沒有多授權。
2. 一個「人類手動 dispatch + sha」案例；目前證據是 detector 自動 dispatch。
3. Draft PR 明確不 dispatch。
4. 同一個已有 `automation-hub/private-ci` status 的 PR head 在後續 detector rounds 中不會重跑；需要逐輪 runtime evidence 或專用 smoke 才能完整證明。
