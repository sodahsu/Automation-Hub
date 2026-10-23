# 外部排程（cron-job.org）

本文件涵蓋 cron-job.org 上的兩個 job，都只做一件事：對 Public `Automation-Hub` 的某個 workflow 發出 `workflow_dispatch`。

| job | workflow | cadence | 章節 |
| --- | --- | --- | --- |
| detector | `detect-private-changes.yml` | 每 5 分鐘 | 本節之後到「Token 輪替」 |
| Claude 07:00 wake | `claude-0700-wake.yml` | 每天 07:00（Asia/Taipei） | 最後一節「07:00 Claude wake job」 |

## Detector job（每 5 分鐘）

GitHub Actions 的 `schedule` 在本儲存庫已多次出現「workflow 本身可由 push / workflow_dispatch 正常執行，但沒有收到任何 `event: schedule`」的情況。

因此使用外部排程備援：外部服務只負責呼叫 Public `Automation-Hub` 的 `workflow_dispatch`。**2026-10-23 起 cadence 改為每 5 分鐘（`detector-cadence-5m`）：當天 02:55:06Z 至 03:40:10Z 的 10 個 detector runs 相鄰間隔已約 5 分鐘；完整掃描（節流改為 `% 5` 之後）的間隔待 merge 後以 live runs 驗收。**歷史證據：2026-10-04 live GitHub Actions evidence 曾觀察到連續 8 個 detector runs 約每 15 分鐘執行，當時 runtime 行為符合 15 分鐘 cadence。本執行環境未直接登入 cron-job.org 讀取設定頁，因此這裡只宣告 live 行為，不把 scheduler UI 的 minutes 欄位冒充為已直接確認。Detector 本身仍在 Automation-Hub 內執行，六個 private repositories 的名稱、mapping、read-only credential 與 CI 邏輯都不會交給外部服務。

## GitHub endpoint

~~~text
POST https://api.github.com/repos/sodahsu/Automation-Hub/actions/workflows/detect-private-changes.yml/dispatches
~~~

Request body：

~~~json
{"ref":"main"}
~~~

必要 headers：

~~~text
Accept: application/vnd.github+json
Content-Type: application/json
X-GitHub-Api-Version: 2022-11-28
Authorization: Bearer <專用 token>
~~~

## 專用 Token

必須另外建立一顆 fine-grained personal access token，只授權：

- Repository：`sodahsu/Automation-Hub`
- Actions：Read and write
- Metadata：Read（GitHub 自動包含）

不得使用：

- `PRIVATE_REPOS_READ_TOKEN`
- 六倉使用的跨 repository PAT
- deployment token
- 任何具 private source write 權限的 credential

外部 scheduler 只需要「喚醒 Public detector」；private repository 的讀取仍由 Automation-Hub 自己的 GitHub Actions Secret 完成。

## cron-job.org 建議設定

cron-job.org 支援 HTTPS、POST request、custom headers 與 request body。本 change 的**標準 cadence**為每 5 分鐘；2026-10-23 live runtime 已以 GitHub Actions timestamps 觀察到約 5 分鐘的喚醒間隔（2026-10-04 時為約 15 分鐘），但 external scheduler 設定頁本身仍待有登入環境時直接核對。

設定：

- Title：`Automation-Hub detector`
- URL：上述 GitHub endpoint
- Method：`POST`
- Schedule：每 5 分鐘
- Timezone：UTC
- Save response：Off
- Failure notification：On
- Body：`{"ref":"main"}`
- Headers：使用上方四個 headers；Authorization 的 token 只存在 scheduler 設定，不寫入 repository

建議 minutes：

~~~text
0,5,10,15,20,25,30,35,40,45,50,55
~~~


## Runtime 驗收規則

Repository 內的 README / OpenSpec 更新本身不代表 runtime 已經切換成功。2026-10-04 曾取得 live GitHub Actions timestamps，證實當時 runtime 行為符合約 15 分鐘；2026-10-23 的 timestamps 顯示喚醒已約每 5 分鐘。設定頁精確值則仍需直接登入外部 scheduler 才能驗證。

只有同時滿足以下條件，才可宣稱 5 分鐘 cadence 已在 runtime 生效：

1. cron-job.org 的 minutes 設為 `0,5,10,15,20,25,30,35,40,45,50,55`。
2. GitHub Actions 至少出現六個連續 `Detect Private Repository Changes` 的 `workflow_dispatch` runs，且每一個都做了完整掃描（不是節流 `SKIP`；`Detect private push activity` step 耗時 ≥ 10 秒，2026-10-23 基線為完整掃描 27–33 秒、`SKIP` 0–1 秒）。
3. 相鄰 run 的時間間隔符合約 5 分鐘。
4. Detector 仍維持只 dispatch 有新 push 的 alias，沒有恢復固定六倉全跑。

若 live 完整掃描仍約每 15 分鐘出現（例如其餘喚醒仍被節流為 `SKIP`），migration 必須保持 pending；不得以文件或 spec 已更新作為完成證據。

## 驗收

外部 scheduler 啟用後，至少驗證：

1. 外部 request 收到 GitHub 2xx。
2. Automation-Hub 出現 `Detect Private Repository Changes` 的 `workflow_dispatch` run。
3. 沒有 private repo 新 push 時，Detector 不建立 private CI run。
4. 任一 private repo 有新 push 時，只建立該 alias 的 CI。
5. Public logs 仍維持 private-name hit 0、private-report marker 0、Artifact 0。

## GitHub 原生 schedule

External scheduler 已於 2026-09-25 完成完整鏈路驗證，GitHub 原生 `schedule` 已從 detector 移除，避免兩個喚醒來源互相 cancel。External scheduler 目前是 detector 唯一的定時喚醒來源（`claude-0700-wake.yml` 的做法不同：外部排程為主、GitHub `schedule` 為備援並存，見最後一節）。

## Token 輪替

專用 token 已於 2026-09-25 改為 No expiration：權限只能觸發 Automation-Hub 的 Actions，外洩時最大影響是多跑幾次 detector，不值得承擔定期到期導致排程無聲中斷的風險。

需要輪替（懷疑外洩或定期更換）時：

1. GitHub token 設定頁按 Regenerate。**舊 token 會立即失效**，從這一刻起到 cron-job.org 存檔前的喚醒都會 401。
2. 立刻在 cron-job.org 該 job 的 ADVANCED 頁，把 `Authorization` 的 Value 換成 `Bearer <新 token>`，按 SAVE。以手動貼上為準；該頁面不接受瀏覽器自動化工具直接改值。
3. 等下一輪 5 分鐘，確認 Automation-Hub 出現新的 `workflow_dispatch` detector run 且 success。

中斷期間漏掉的喚醒不需補跑：detector 恢復後第一輪會以 `pushed_at` 補抓所有未涵蓋的 push。cron-job.org 的 Failure notification 必須維持 On，因為 token 失效時 GitHub 端不會產生任何告警。

## 07:00 Claude wake job

### 為什麼需要外部排程

`claude-0700-wake.yml` 的 GitHub `schedule` 實測不準：2026-09-29 到 2026-10-23 共 25 筆 schedule run，建立時間落在台北 08:28–11:15，比 07:00 晚 1 小時 28 分到 4 小時 15 分（逐筆資料見 `openspec/changes/claude-0700-minimal-wake/evidence/scheduled-runs-2026-10-23.md`）。cron 與 `timezone` 沒有寫錯，延遲在 GitHub 一側。因此 07:00 改由 cron-job.org 以 `workflow_dispatch` 觸發為主，GitHub `schedule` 保留為備援。

備援的冪等防呆（`scripts/wake/wake-guard.sh`）：`schedule` 觸發時，若同一個台北日期已有一次「呼叫 Claude 的 step 成功」的 run，就 `SKIP`，不再呼叫 Claude；查不到歷史時 fail closed（不喚醒、run 紅燈）。`workflow_dispatch` 不受防呆限制。

### GitHub endpoint

~~~text
POST https://api.github.com/repos/sodahsu/Automation-Hub/actions/workflows/claude-0700-wake.yml/dispatches
~~~

Request body：

~~~json
{"ref":"main"}
~~~

必要 headers 與 detector job 相同（`Authorization` 的 token 只存在 scheduler 設定，不寫入 repository）：

~~~text
Accept: application/vnd.github+json
Content-Type: application/json
X-GitHub-Api-Version: 2022-11-28
Authorization: Bearer <專用 token>
~~~

成功時 GitHub 回 `204 No Content`。

### 專用 token

規格與 detector 的專用 token 相同：fine-grained personal access token，Repository 只選 `sodahsu/Automation-Hub`，Actions：Read and write，Metadata：Read；不得使用 `PRIVATE_REPOS_*` 或任何具 private source 權限的 credential。

建議為 wake job 另建一顆（例如命名 `Automation-Hub wake dispatcher`），不與 detector 共用：任何一邊輪替或撤銷，不會讓另一邊跟著中斷。

殘留風險要知道：兩顆 token 權限相同，任何一顆外洩都能 dispatch 本 repo 的任何 workflow，包含會消耗 Claude 額度的 wake；這與 detector 的專用 token 是同一個風險等級，沿用「不設到期、靠 cron-job.org 的 Failure notification 發現失效」的決定。

### cron-job.org 設定

前置條件：含冪等防呆的 `claude-0700-wake.yml` 已合併到 `main`，才建立這個 job；否則 `main` 上的舊 workflow 沒有防呆，外部排程喚醒後，當天稍晚的 `schedule` 會再喚醒一次。

- Title：`Automation-Hub claude-0700-wake`
- URL：上述 GitHub endpoint
- Method：`POST`
- Schedule：每天 07:00（hours `7`、minutes `0`，days／months／weekdays 全選）
- Timezone：`Asia/Taipei`。若設定頁沒有這個選項，改成 UTC 並把 hours 設為 `23`（UTC 23:00 = 台北 07:00）；Unknown：本執行環境未登入 cron-job.org，設定頁的選項名稱沒有直接核對。
- Save response：Off
- Failure notification：On（token 失效時 GitHub 端不會有任何 run，也不會有告警，這是唯一的訊號）
- Retry／重送：不要開。逾時後重送可能讓同一天出現兩次喚醒；漏掉的當天由 GitHub `schedule` 備援補一次。
- Body：`{"ref":"main"}`
- Headers：使用上方四個 headers

### 設定後驗收

1. 在 cron-job.org 對該 job 按一次 test run：預期 HTTP `204`。Actions 會出現 `Claude 07:00 Wake` 的 `workflow_dispatch` run 並 success（這一次會真的呼叫一次 Claude Haiku，單回合）。
2. 連續 3 天，每天用下面的指令確認：

~~~text
gh run list -R sodahsu/Automation-Hub --workflow claude-0700-wake.yml --limit 10 --json databaseId,createdAt,event,conclusion
~~~

   - 當天有一個 `event` 為 `workflow_dispatch` 的 run，`createdAt` 落在 UTC 22:55–23:05（= 台北 06:55–07:05），`conclusion` 為 `success`。
   - 確認 Claude step 真的成功：`gh api repos/sodahsu/Automation-Hub/actions/runs/<id>/jobs --jq '.jobs[].steps[] | select(.name=="Trigger Claude for piscean0619") | .conclusion'` 應為 `success`。
   - 同一天稍晚的 `schedule` run（若有）：Claude step 的 conclusion 應為 `skipped`，run 頁面 Summary 顯示 `SKIP — 台北日期 … 已有一次成功的喚醒`。若是 `success`，代表防呆放行了第二次喚醒，請回報。
3. 通過條件：連續 3 天都符合，才算外部排程準時性驗收完成。

### 常見失敗

- cron-job.org 收到 `401`：token 錯誤、被撤銷或到期。
- `404`：URL 的 repo／workflow 檔名寫錯，或 token 沒有 `sodahsu/Automation-Hub` 的 Actions 權限。
- `422`：`ref` 不存在，或 workflow 沒有 `workflow_dispatch` 觸發。
- 07:00 沒有 `workflow_dispatch` run、但稍晚出現 `schedule` run 且 step summary 為 `WAKE`：外部排程當天缺席，備援補上；先檢查 cron-job.org 的執行紀錄。
- `schedule` run 紅燈、防呆 step 失敗：防呆查不到歷史（GitHub API 失敗），為避免重複喚醒而不呼叫 Claude；當天若需要喚醒，手動 `workflow_dispatch` 一次。

### Token 輪替

與 detector 相同流程（Regenerate → 立刻換 cron-job.org 該 job 的 `Authorization` Value → SAVE）。差別：wake 每天只喚醒一次，中斷期間漏掉的喚醒**不會**由後續輪詢補上，只靠當天稍晚的 GitHub `schedule` 備援；輪替請避開 07:00 前後。
