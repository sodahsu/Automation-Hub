# Review: automatic-private-ci-sweep

## Design decision

最終設計從「固定週期六倉全跑」收斂為「每 5 分鐘 detector + 有變更才 dispatch」。

Detector 是獨立 workflow，因此沒有變更時產生的 polling run 不會污染 Private CI Bridge 本身的 job history。這讓 detector 可以無狀態地拿 private repo 的 `pushed_at`，與對應 alias 最近一次 CI job 的 `started_at` 比較。

## Why `started_at` instead of completed_at

如果 private push 發生在一個舊 CI 已開始之後，使用 `completed_at` 可能把那個較新的 push 誤判為「已測過」。比較 `started_at` 可以避免這個 race：只要 push 晚於 job start，下一輪 detector 仍會再 dispatch。

## Permission model

- Private repo：沿用既有 fine-grained read-only credential。
- Public Automation-Hub detector：`actions: write`，只用來觸發既有 `private-ci.yml`。
- Private CI job：維持 `contents: read` 與原有 sanitized execution boundary。

沒有新增 private write token，也沒有讓 private target code 取得 Public Hub 的 dispatch credential。

## Detection trade-off

使用 repository-level `pushed_at` 是保守策略。其他 branch 的 push 可能造成一次額外 default-branch CI，但這比把 private commit SHA 長期保存到 Public Hub 更符合目前安全邊界。

## Runtime evidence

- Detector run #1 由 detector workflow 建立 commit 自動觸發。
- Run #1：success。
- 當時六倉最近 CI 均已晚於最新 private push，因此 detector 沒有建立新的 workflow_dispatch run。
- Detector log 中 private repository identifiers 維持 masking。
- 既有六倉 regression run #17 仍提供 CI adapter 的 6/6 PASS 證據。

## Remaining observation

還需要等待一筆真實 private push，確認 detector 只 dispatch 對應 alias；另外等待第一筆 cron event 以取得 scheduler-specific evidence。
