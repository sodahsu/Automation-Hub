# 外部 15 分鐘排程備援

GitHub Actions 的 `schedule` 在本儲存庫已多次出現「workflow 本身可由 push / workflow_dispatch 正常執行，但沒有收到任何 `event: schedule`」的情況。

因此準備一條外部排程備援：外部服務每 15 分鐘只負責呼叫 Public `Automation-Hub` 的 `workflow_dispatch`。Detector 本身仍在 Automation-Hub 內執行，六個 private repositories 的名稱、mapping、read-only credential 與 CI 邏輯都不會交給外部服務。

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

cron-job.org 支援 HTTPS、POST request、custom headers 與 request body，目前標準 cadence 為每 15 分鐘。

設定：

- Title：`Automation-Hub detector`
- URL：上述 GitHub endpoint
- Method：`POST`
- Schedule：每 15 分鐘
- Timezone：UTC
- Save response：Off
- Failure notification：On
- Body：`{"ref":"main"}`
- Headers：使用上方四個 headers；Authorization 的 token 只存在 scheduler 設定，不寫入 repository

建議 minutes：

~~~text
0,15,30,45
~~~


## Runtime 驗收規則

Repository 內的 README / OpenSpec 更新只代表 cadence contract 已準備完成，**不代表** cron-job.org runtime 已經切換成功。

只有同時滿足以下條件，才可宣稱 15 分鐘 cadence 已在 runtime 生效：

1. cron-job.org 的 minutes 設為 `0,15,30,45`。
2. GitHub Actions 至少出現三個連續 `Detect Private Repository Changes` 的 `workflow_dispatch` runs。
3. 相鄰 run 的時間間隔符合約 15 分鐘。
4. Detector 仍維持只 dispatch 有新 push 的 alias，沒有恢復固定六倉全跑。

若 live runs 仍約每 5 分鐘出現，migration 必須保持 pending；不得以文件或 spec 已更新作為完成證據。

## 驗收

外部 scheduler 啟用後，至少驗證：

1. 外部 request 收到 GitHub 2xx。
2. Automation-Hub 出現 `Detect Private Repository Changes` 的 `workflow_dispatch` run。
3. 沒有 private repo 新 push 時，Detector 不建立 private CI run。
4. 任一 private repo 有新 push 時，只建立該 alias 的 CI。
5. Public logs 仍維持 private-name hit 0、private-report marker 0、Artifact 0。

## GitHub 原生 schedule

External scheduler 已於 2026-09-25 完成完整鏈路驗證，GitHub 原生 `schedule` 已從 detector 移除，避免兩個喚醒來源互相 cancel。External scheduler 目前是唯一的定時喚醒來源。

## Token 輪替

專用 token 已於 2026-09-25 改為 No expiration：權限只能觸發 Automation-Hub 的 Actions，外洩時最大影響是多跑幾次 detector，不值得承擔定期到期導致排程無聲中斷的風險。

需要輪替（懷疑外洩或定期更換）時：

1. GitHub token 設定頁按 Regenerate。**舊 token 會立即失效**，從這一刻起到 cron-job.org 存檔前的喚醒都會 401。
2. 立刻在 cron-job.org 該 job 的 ADVANCED 頁，把 `Authorization` 的 Value 換成 `Bearer <新 token>`，按 SAVE。以手動貼上為準；該頁面不接受瀏覽器自動化工具直接改值。
3. 等下一輪 15 分鐘，確認 Automation-Hub 出現新的 `workflow_dispatch` detector run 且 success。

中斷期間漏掉的喚醒不需補跑：detector 恢復後第一輪會以 `pushed_at` 補抓所有未涵蓋的 push。cron-job.org 的 Failure notification 必須維持 On，因為 token 失效時 GitHub 端不會產生任何告警。
