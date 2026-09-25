# 設計：public-ci-automation-hub

## 決策 1 — Public orchestrator、Private source

`Automation-Hub` 是唯一的 Public execution repository。

其中只能包含：

- workflow
- generic script
- security policy
- public-safe alias

六個 target repositories 必須繼續維持 Private，只能在 job 執行期間 checkout 到 ephemeral runner workspace。

Private checkout 不得複製回 `Automation-Hub`。

## 決策 2 — 不 commit private repository 真名

已 commit 的設定只能使用：

```text
repo-01
repo-02
repo-03
repo-04
repo-05
repo-06
```

真實 mapping 必須放在 GitHub Secret，例如：

`PRIVATE_REPOS_JSON`

僅示意格式：

```json
{
  "repo-01": "<owner/private-repository>",
  "repo-02": "<owner/private-repository>"
}
```

真實值不得出現在本 Public repository。

任何解析出的 repository identifier 在 shell step 使用前，必須先透過 GitHub log masking command 隱藏。

## 決策 3 — Authentication 與 target mapping 分離

使用兩個獨立 Secret：

- `PRIVATE_REPOS_READ_TOKEN` — fine-grained token，只授權六個 selected private repositories，且 Phase 1 維持 read-only。
- `PRIVATE_REPOS_JSON` — alias-to-repository mapping。

如此可避免 workflow 直接包含 repository identity，也避免把 target mapping 綁死在 token 本身。

本 change 不包含 write token。

## 決策 4 — Manual dispatch 作為緊急復原入口

初始復原使用 `workflow_dispatch`，input 只接受 alias。

理由：

- 即使 private-repository Actions 無法執行，Public Hub 仍可運作。
- 不需要修改 target repository。
- Recovery path 清楚、可觀察。
- 緊急復原階段不額外引入 webhook / GitHub App infrastructure。

Automatic polling、webhook dispatch 或 per-commit orchestration 必須在 read-only Hub 穩定後，以獨立 change 設計。

## 決策 5 — 使用 ephemeral workspace checkout

每個 job 必須：

1. 從 Secret mapping 解析 alias 對應 repository。
2. Mask 解析後 identifier。
3. 建立 ephemeral `workspace/`。
4. 只 checkout CI 所需的 ref / depth。
5. 執行 checks。
6. 輸出 sanitized status。
7. 在 `always()` cleanup step 移除 workspace。

Public repository 的 `.gitignore` 必須排除：

- `workspace/`
- `repos/`
- `tmp/`
- `.env*`
- log files

## 決策 6 — 執行 repository-native CI，不自行發明 script

Hub 可以依 lockfile 偵測 package manager：

- `pnpm-lock.yaml` → pnpm
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `bun.lock` / `bun.lockb` → bun

Node-family repository 若有對應 script，依需求執行：

1. install
2. lint
3. typecheck
4. test
5. build

若 script 不存在，回報 `SKIP`。

Hub 不得：

- 修改 `package.json`
- 建立缺少的 script
- 更新 lockfile
- 安裝未經 review 的 global project dependency
- 自動「修復」application code

Non-Node repository 必須使用經明確 review 的 target-specific adapter，不做 generic guessing。

## 決策 7 — Obsidian / 內容型 repository 不得把內容印到 Public log

對 content-heavy targets，尤其 vault-style repositories，check 可以在 runner 內部讀檔，但不得把 note body 或 source document 印到 Public Actions log。

允許的 Public output 例如：

```text
Health check: PASS
Broken links: 0
Validation: PASS
```

除非另有明確核准，否則避免輸出：

- file content
- 可視為 private metadata 的 note title
- path dump

## 決策 8 — 不上傳 source artifact，也不 cache workspace

Phase 1 預設不得上傳 Artifact。

Dependency-manager cache 只有在證明不含 private checkout 或 environment data 時，才可以另案加入。

永遠不得 cache：

- `workspace/`
- private source directory
- `.env*`
- credentials
- vault contents
- 內嵌 private source map 的 generated bundle

## 決策 9 — Mapping / authentication 問題必須 fail closed

只要發生下列任一情況，job 必須在 CI 執行前停止：

- alias 不存在於 private mapping。
- 解析出的 repository value 為空或格式錯誤。
- checkout authentication 失敗。
- requested ref 無法解析。
- token 不可用。

Workflow 不得 fallback 到：

- Public repository
- 猜測的 repository name
- anonymous clone

## 決策 10 — Deployment 維持原位置

Production deployment 明確排除。

Private repositories 既有用於下列用途的 workflow 保持不動：

- Vercel
- Cloudflare
- Pages
- release
- publish
- migration
- 其他 mutation

Hub 先恢復 validation；deployment migration 必須另開 OpenSpec change。

## 決策 11 — 執行時間與 concurrency 必須有界

每個 job 都必須設定 timeout。

每個 target 使用獨立 concurrency group，避免同一 alias 出現無控制的重複並行執行。

單一 target 失敗不得暴露或修改其他 target。

## Rollout

### Phase A — OpenSpec 與 public-safe skeleton

- 建立 OpenSpec。
- 建立安全邊界。
- 建立不含 Secret 的 generic manual workflow。

### Phase B — 單一 target pilot

- 使用者手動建立兩個必要 Secrets。
- 透過 Secret mapping 選定一個 alias 作為 pilot。
- 執行 checkout + safe health check。
- 檢查 log 是否洩漏 metadata / content。

### Phase C — CI command validation

- 對 pilot 啟用 repository-native install / lint / typecheck / test / build。
- 與 repository-local 或已知可用的 CI 行為比較。

### Phase D — 其餘 aliases

- 其餘 target mapping 只加入 private Secret。
- Alias 逐一驗證。

### Phase E — Operational handoff

- Private quota 無法使用期間，以 Public Hub 作為 temporary / primary CI path。
- 原 private workflow 保留，供 rollback / reference。

### Phase F — 後續 automation

- 另外評估 scheduled polling、GitHub App / webhook dispatch 或其他 event bridge。
- 不把本 change 靜默擴張成 eventing platform。

## Rollback

Rollback 不需要修改任何 private repository。

1. 停止執行 Hub workflow。
2. 移除或 rotate `PRIVATE_REPOS_READ_TOKEN`。
3. 移除 `PRIVATE_REPOS_JSON`。
4. Public Hub workflow 可依需求保留或刪除。
5. Private Actions quota / capacity 恢復後，原 private repository workflow 仍是 reference path。

## Phase 1 完成前所需證據

- Public runner 可以成功 read-only checkout。
- Token 已 masking，且不出現在 log。
- 解析後 repository identifier 已 masking。
- Public log 不含 private source。
- 沒有 private source Artifact。
- 沒有對 target repository 寫入。
- Timeout / concurrency 行為已確認。
- Cleanup step 有執行。
- 至少一個 target 完成 repository-native CI checks。
