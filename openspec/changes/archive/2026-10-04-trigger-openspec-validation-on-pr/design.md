# Design: trigger-openspec-validation-on-pr

## 決策 1：沿用既有 workflow 與 path scope

不新增第二支 workflow。既有 `validate-openspec.yml` 已固定 runner、Node、action SHA、strict command 與 read-only permission；只擴充同一支 workflow 的事件來源。`openspec/**` 與 workflow 自身仍是唯一 path scope，避免所有文件 PR 都觸發成本。

## 決策 2：明確列出 PR lifecycle events

使用 `opened`、`synchronize`、`reopened` 與 `ready_for_review`。前 3 個涵蓋一般 PR 建立、更新與重新開啟；`ready_for_review` 確保 Draft PR 在進入 review 狀態時也會取得 check。關閉事件不需要驗證，因此不加入。

## 決策 3：以 PR number／ref 隔離 concurrency

現有固定 group 適合單一 main push，但多個 PR 共用同一 group 會互相取消。改為 `github.event.pull_request.number || github.ref` 作為 group suffix：同一 PR 的新 commit 仍 cancel 舊 run，不同 PR 互不影響。

## 不變更

- `push` 到 `main` 與 `workflow_dispatch` 保留。
- `permissions: contents: read` 保留。
- Node 20.19.0、immutable action SHA 與 OpenSpec strict command 保留。
- 不增加 private repository secrets 或寫入權限。

## 驗證策略

- OpenSpec strict validation。
- YAML parse 與 workflow 靜態檢查。
- Security audit 確認 immutable SHA、permission 與 cleanup 邊界未漂移。
- 合併後以新的 OpenSpec PR、Draft→Ready 事件與 commit update 觀察 GitHub check 是否出現；在 workflow 尚未進入 main 前，不把本 PR 自身沒有遠端 check 解讀成實作失敗。
