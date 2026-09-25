# 審查：automatic-private-ci-sweep

## 設計決策

最終設計從「固定週期六倉全跑」收斂為「每 5 分鐘 detector + 有變更才 dispatch」。

Detector 是獨立 workflow，因此沒有變更時產生的 polling run 不會污染 Private CI Bridge 本身的 job history。

這讓 detector 可以無狀態地取得 private repo 的 `pushed_at`，再與對應 alias 最近一次 CI job 的 `started_at` 比較。

## 為什麼比較 `started_at`，而不是 `completed_at`

如果 private push 發生在舊 CI 已經開始之後，使用 `completed_at` 可能把較新的 push 誤判為「已測過」。

比較 `started_at` 可以避開這個 race condition：只要 push 晚於 job start，下一輪 detector 仍會再次 dispatch。

## 權限模型

- Private repo：沿用既有 fine-grained read-only credential。
- Public Automation-Hub detector：`actions: write`，只用來觸發既有 `private-ci.yml`。
- Private CI job：維持 `contents: read` 與原有 sanitized execution boundary。

沒有新增 private write token，也沒有讓 private target code 取得 Public Hub 的 dispatch credential。

## 偵測方式的取捨

使用 repository-level `pushed_at` 是保守策略。

其他 branch 的 push 可能造成一次額外 default-branch CI，但這比把 private commit SHA 長期保存到 Public Hub 更符合目前的安全邊界。

## Runtime 證據

- Detector run #1 由 detector workflow 建立 commit 自動觸發。
- Run #1：success。
- 當時六倉最近 CI 均已晚於最新 private push，因此 detector 沒有建立新的 workflow_dispatch run。
- Detector log 中 private repository identifiers 維持 masking。
- 既有六倉 regression run #17 提供 CI adapter 的 6/6 PASS 證據。

## 尚待觀察

還需要等待一筆真實 private push，確認 detector 只 dispatch 對應 alias；另外等待第一筆 cron event，取得 scheduler-specific evidence。


## 真實 private push 驗證

在沒有為測試額外修改 private repo 的情況下，偵測到一筆真實的新 push：

- 只有 repo-04 的 private repository `pushed_at` 晚於最近一次六倉 regression；
- 其他五個 aliases 都已被較新的 CI job 涵蓋；
- detector 只 dispatch 一筆 Public CI；
- 該 run 唯一 job 為 `CI — repo-04`；
- repo-04 CI 最終 PASS。

第一次 dispatch 時另發現 GitHub API 實際成功建立 workflow run，但回傳 HTTP 200；原 detector 只接受 HTTP 204，因此把成功誤判為 failure。成功條件已修正為所有 HTTP 2xx，修正後 detector PASS。

這個 smoke test 已證明「有新 push 才跑，且只跑變更 alias」的核心 selector 行為。


## 六倉 private update → CI 實跑證據

六個 alias 都已各自取得「private repository 有新 push → detector 判斷 → dispatch 對應 alias → Public CI PASS」的實跑證據。

其中 repo-04 使用先前的真實單倉 smoke test；repo-01、repo-02、repo-03、repo-05、repo-06 則在六倉 workflow hardening 後由同一輪 detector 自動判斷並 dispatch。當時 repo-04 沒有新 push，因此沒有被多跑，證明 selector 不會固定重跑六倉。

目前唯一尚未取得的是 GitHub Scheduler 自己的第一筆 `event: schedule` run。也就是：change detection 與 per-alias dispatch 已確認；「完全無人工觸發 detector」的 scheduler-specific evidence 仍待第一筆 cron event。


## GitHub Scheduler 失效與外部備援

GitHub 原生 `schedule` 已使用下列方式交叉驗證：

- detector 本身的 push / workflow_dispatch 都正常；
- 六倉 private push detection 與 per-alias dispatch 都正常；
- 建立完全不讀 Secret 的 schedule probe；
- 再建立一支全新 workflow ID 的 schedule probe v2；
- 修改 cron 後再改回，嘗試重新註冊 schedule。

以上情況下仍沒有任何 `event: schedule` run，因此目前不能把 GitHub Scheduler 當作唯一自動喚醒來源。

曾嘗試使用既有 Vercel production project 作為 5 分鐘 scheduler。API route 可正常部署，但加入 `*/5 * * * *` Cron 後 deployment failure，與目前 Hobby Cron 頻率限制一致，因此已完整還原，不讓 production 留下失敗設定。

正式備援設計改為外部 HTTP scheduler：

1. 每 5 分鐘 POST Public Automation-Hub 的 `workflow_dispatch` endpoint；
2. 使用獨立 fine-grained token，只授權 Automation-Hub Actions write；
3. private repository mapping / read-only token 繼續只存在 Automation-Hub GitHub Actions Secrets；
4. detector 與六倉 CI 邏輯完全不搬到第三方服務。

實際設定方式記錄於 `docs/external-scheduler.md`。

目前剩餘 blocker 是建立外部服務帳號內的 schedule 與專用 GitHub token。這兩項 credential 不應出現在 repository 或聊天內容中。


## 上線後更新（2026-09-25）

External scheduler 自 12:15 UTC 起每 5 分鐘穩定喚醒 detector，完整鏈路（external → detector → 只 dispatch 有變更的 `CI — repo-02` → PASS）已驗證；專用 token 權限已於 GitHub 設定頁核對。GitHub 原生 `schedule` 期間只出現一筆 event，已從 detector 移除。上方「剩餘 blocker」段落已解除。
