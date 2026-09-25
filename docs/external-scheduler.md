# 外部 5 分鐘排程備援

GitHub Actions 的 `schedule` 在本儲存庫已多次出現「workflow 本身可由 push / workflow_dispatch 正常執行，但沒有收到任何 `event: schedule`」的情況。

因此準備一條外部排程備援：外部服務每 5 分鐘只負責呼叫 Public `Automation-Hub` 的 `workflow_dispatch`。Detector 本身仍在 Automation-Hub 內執行，六個 private repositories 的名稱、mapping、read-only credential 與 CI 邏輯都不會交給外部服務。

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

cron-job.org 支援 HTTPS、POST request、custom headers 與 request body，可作為目前的 5 分鐘備援。

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

## 驗收

外部 scheduler 啟用後，至少驗證：

1. 外部 request 收到 GitHub 2xx。
2. Automation-Hub 出現 `Detect Private Repository Changes` 的 `workflow_dispatch` run。
3. 沒有 private repo 新 push 時，Detector 不建立 private CI run。
4. 任一 private repo 有新 push 時，只建立該 alias 的 CI。
5. Public logs 仍維持 private-name hit 0、private-report marker 0、Artifact 0。

## GitHub 原生 schedule

External scheduler 已於 2026-09-25 完成完整鏈路驗證，GitHub 原生 `schedule` 已從 detector 移除，避免兩個喚醒來源互相 cancel。External scheduler 目前是唯一的定時喚醒來源。

## Token 續期

專用 token 於 2026-12-24 到期。到期後 cron-job.org 會收到 401，detector 將停止被喚醒；Public CI 本身不會因此失敗，所以不會有 GitHub 端告警。續期時在 GitHub token 設定頁 Regenerate，並更新 cron-job.org 的 Authorization header；cron-job.org 的 Failure notification 必須維持 On。
