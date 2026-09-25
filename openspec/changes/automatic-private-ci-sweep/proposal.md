# 提案：automatic-private-ci-sweep

## 為什麼要做

Phase 1 已恢復六個 private repo 的 read-only CI，但固定週期六倉全跑會造成不必要的工作。

新的目標是：**每 5 分鐘檢查一次 private repo 是否有新的 push activity，只有實際有變更的 alias 才 dispatch 既有 CI bridge。**

## 變更內容

1. 新增獨立 detector workflow：`.github/workflows/detect-private-changes.yml`。
2. Detector 每 5 分鐘執行一次：`2-57/5 * * * *`。
3. Detector 使用既有 private read-only credential 讀取 repository metadata。
4. Detector 比較 private repo 的 `pushed_at` 與該 alias 最近一次 CI job 的 `started_at`。
5. 若最新 CI 已涵蓋該次 push，標記 `SKIP`。
6. 若有較新的 push，才 dispatch `private-ci.yml` 的該 alias。
7. 若該 alias 已有 CI 執行中，標記 `WAIT`，下一輪再判斷，避免重複排隊。
8. Detector 對 Public Automation-Hub 自己使用 `actions: write`，只用於 workflow dispatch；private repo 權限仍維持 read-only。
9. 保留既有手動單倉 dispatch，以及 Hub workflow/adapter 變更時的六倉 regression。

## 偵測模型

本 change 不保存 private commit SHA，也不建立 public state file。

Detector 使用 repository-level `pushed_at` 作為保守變更訊號。

這代表非 default branch 的 push 可能多觸發一次 default-branch CI；這個取捨可以避免在 Public Automation-Hub 長期保存 private commit metadata，也不需要新的 credential 或 private-repository write access。

## 排程

~~~text
2-57/5 * * * *
~~~

等同每 5 分鐘執行一次，並避開整點的常見排程高峰。

## 範圍

- 只修改 Automation-Hub。
- 六個 public-safe aliases。
- Private repository metadata 維持 read-only。
- Public Automation-Hub workflow dispatch。
- 沿用既有 sanitized CI bridge。

## 不包含

- 不修改 private repository workflow。
- 不增加 private repository write token。
- 不保存 private commit SHA。
- 不公開 alias-to-repository mapping。
- 不建立 webhook server 或外部 relay。
- 不遷移 production deployment。
- 不上傳 private source、cache 或 artifact。

## 驗收條件

- Detector 每 5 分鐘可成功執行。
- 沒有新 push 時不 dispatch CI。
- 有新 push 時只 dispatch 對應 alias。
- 執行中的 alias 不重複排隊。
- Manual single-target dispatch 仍可用。
- Hub-code regression trigger 仍可用。
- Private credential 維持 selected-repository read-only。
- Public log 不揭露 private repo 真名或 source。
