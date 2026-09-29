# Design：Run Private CI on Pull Request Heads

## Job 拓撲（PR 模式，帶 `sha` input 時）

```
mark-pending ──> ci ──> report
（status token）  （read token，跑 private code）  （status token）
```

- `mark-pending`：對 `sha` 寫 `pending`。detector 看到 `pending` 就不會重複 dispatch，dedup 直接靠 status 本身，不需要另外存狀態，符合既有「Detector MUST 不長期保存 private commit metadata」。
- `ci`：與現行 job 相同，只把 tarball URL 換成 `/tarball/{sha}`。**這個 job 的 env 不出現 `PRIVATE_REPOS_STATUS_TOKEN`**，private 程式碼執行時拿不到寫入 credential。
- `report`：`needs: ci`、`if: always()`，依 `ci` 結果寫 `success`／`failure`；`ci` 被取消或取得原始碼失敗時寫 `error`。description 只放 PASS／FAIL／SKIP 計數，不放任何 private 內容。
- 沒帶 `sha` 時，`mark-pending` 與 `report` 以 `if` 跳過，matrix 與現在相同。

## Input 驗證

- `sha`：`^[0-9a-f]{40}$`，不符就在任何網路請求之前失敗。
- 帶 `sha` 時 `target` 不能是 `repo-06`。
- 不新增分支名 input，維持「不讓 private ref 名稱出現在 Public workflow input」。

## Detector 擴充

每輪、對 repo-01～05：

1. `GET /repos/{r}/pulls?state=open&per_page=50`（read token，需 Pull requests: Read）
2. 過濾 `draft == false`
3. 對每個 head SHA：`GET /repos/{r}/commits/{sha}/status`（read token，需 Commit statuses: Read），找 context `automation-hub/private-ci`
4. 沒有這個 context → dispatch `private-ci.yml`，帶 `target` 與 `sha`
5. 有（任何狀態）→ SKIP。要重跑就手動 dispatch。

Summary 表格只寫 alias 與 `PR RUN`／`PR SKIP` 計數，不寫 PR 編號、標題或分支名。PR 相關資料不落地。

## Concurrency

- PR 模式：`private-ci-<alias>-<sha>`，`cancel-in-progress: false`。
- default branch 模式：維持 `private-ci-<alias>`。
- 兩者分開，PR 驗證不會卡住 main 的健康檢查。

## Credential

| Secret | 權限 | 使用的 job |
|---|---|---|
| `PRIVATE_REPOS_READ_TOKEN` | Contents: Read、Metadata: Read、**Pull requests: Read**（新）、**Commit statuses: Read**（新） | detector、ci |
| `PRIVATE_REPOS_STATUS_TOKEN`（新） | Commit statuses: Read and write、Metadata: Read；只選 repo-01～05 | mark-pending、report |

兩支 token 分開，讀的那支不會因此多出寫入能力，寫的那支碰不到 Contents。

## 不確定之處

- **Unknown**：private repo 在目前方案下能否用 ruleset 要求 `automation-hub/private-ci` 才能合併。這個 change 不依賴它，status 至少會顯示在 PR checks 上。
- **Unknown**：detector 每 15 分鐘多打 5 次 pulls API 加上每個 PR 一次 status API，是否逼近 fine-grained PAT 的 rate limit。預期遠低於 5000/hr，實作後觀察。
- **Assumption**：PR head 的程式碼與 default branch 同樣可信，全部出自同一個 owner 與其 AI 代理。若日後接受外部貢獻者的 PR，必須重新評估：外部 PR 的程式碼會在持有 read token 的 job 裡執行。
