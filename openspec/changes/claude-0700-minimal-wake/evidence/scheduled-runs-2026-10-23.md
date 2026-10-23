# Evidence：claude-0700-wake 的實際觸發時間（2026-10-23 取得）

取得方式（唯讀）：

~~~text
gh run list -R sodahsu/Automation-Hub --workflow claude-0700-wake.yml --limit 30 --json createdAt,event,conclusion,databaseId
gh api repos/sodahsu/Automation-Hub/actions/runs/<id>/jobs   # 每筆 run 一次，取 runner 與 step conclusion
~~~

## 結論

1. **cron 的時區沒有寫錯。** `0 7 * * *` 搭配 `timezone: "Asia/Taipei"` 的目標是 UTC 23:00（前一天）；25 筆 schedule run 的建立時間都落在 UTC 00:28–03:15，也就是目標之後 1 小時 28 分到 4 小時 15 分。如果 GitHub 忽略 `timezone` 而把 `0 7` 當成 UTC，run 會出現在台北 15:00 之後，與觀察不符。設定本身沒有錯；延遲屬於 GitHub scheduler 一側（Unknown：GitHub 內部為何延遲這麼久，無法從外部確認，也不影響結論）。
2. **schedule 不能當 07:00 的來源。** 25 筆全部晚於目標：最短 1 小時 28 分、中位數 2 小時 30 分、最長 4 小時 15 分，台北時間落在 08:28–11:15。
3. **每一筆都是 GitHub-hosted runner**：job 的 `runner_group_name` 為 `GitHub Actions`、label 為 `ubuntu-latest`，沒有 self-hosted label；因此 wake 不依賴本機 Mac 是否在線。
4. **每一筆 schedule run 的 Claude step（`Trigger Claude for piscean0619`）conclusion 都是 `success`**；event 都是 `schedule`。
5. 2026-09-28 的兩筆 `workflow_dispatch` 是 smoke test：第一筆（36393454452）失敗、第二筆（36393598504）成功，與 tasks 第 6 節記錄的 run 36393598504 一致。

## 逐筆資料

「延遲」＝台北建立時間減去當天 07:00。

| run id | event | 建立時間（UTC） | 建立時間（台北） | 延遲 | run 結論 | Claude step | runner label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 36393454452 | workflow_dispatch | 2026-09-28T07:46:05Z | 2026-09-28 15:46:05 | —（手動 smoke test） | failure | failure | ubuntu-latest |
| 36393598504 | workflow_dispatch | 2026-09-28T07:47:39Z | 2026-09-28 15:47:39 | —（手動 smoke test） | success | success | ubuntu-latest |
| 36512205938 | schedule | 2026-09-29T02:21:26Z | 2026-09-29 10:21:26 | 3 小時 21 分 | success | success | ubuntu-latest |
| 36656370110 | schedule | 2026-09-30T01:42:11Z | 2026-09-30 09:42:11 | 2 小時 42 分 | success | success | ubuntu-latest |
| 36802064417 | schedule | 2026-10-01T01:38:28Z | 2026-10-01 09:38:28 | 2 小時 38 分 | success | success | ubuntu-latest |
| 36952898295 | schedule | 2026-10-02T01:51:16Z | 2026-10-02 09:51:16 | 2 小時 51 分 | success | success | ubuntu-latest |
| 37086349077 | schedule | 2026-10-03T01:30:24Z | 2026-10-03 09:30:24 | 2 小時 30 分 | success | success | ubuntu-latest |
| 37170325858 | schedule | 2026-10-04T02:12:12Z | 2026-10-04 10:12:12 | 3 小時 12 分 | success | success | ubuntu-latest |
| 37251093127 | schedule | 2026-10-05T01:21:11Z | 2026-10-05 09:21:11 | 2 小時 21 分 | success | success | ubuntu-latest |
| 37404770886 | schedule | 2026-10-06T02:34:14Z | 2026-10-06 10:34:14 | 3 小時 34 分 | success | success | ubuntu-latest |
| 37559225063 | schedule | 2026-10-07T01:52:20Z | 2026-10-07 09:52:20 | 2 小時 52 分 | success | success | ubuntu-latest |
| 37717344769 | schedule | 2026-10-08T02:20:02Z | 2026-10-08 10:20:02 | 3 小時 20 分 | success | success | ubuntu-latest |
| 37875458476 | schedule | 2026-10-09T02:37:30Z | 2026-10-09 10:37:30 | 3 小時 37 分 | success | success | ubuntu-latest |
| 38015163466 | schedule | 2026-10-10T01:57:32Z | 2026-10-10 09:57:32 | 2 小時 57 分 | success | success | ubuntu-latest |
| 38101652755 | schedule | 2026-10-11T01:23:07Z | 2026-10-11 09:23:07 | 2 小時 23 分 | success | success | ubuntu-latest |
| 38193621475 | schedule | 2026-10-12T01:53:09Z | 2026-10-12 09:53:09 | 2 小時 53 分 | success | success | ubuntu-latest |
| 38340794666 | schedule | 2026-10-13T03:14:58Z | 2026-10-13 11:14:58 | 4 小時 14 分 | success | success | ubuntu-latest |
| 38495838414 | schedule | 2026-10-14T01:27:36Z | 2026-10-14 09:27:36 | 2 小時 27 分 | success | success | ubuntu-latest |
| 38663381198 | schedule | 2026-10-15T01:01:58Z | 2026-10-15 09:01:58 | 2 小時 01 分 | success | success | ubuntu-latest |
| 38831908430 | schedule | 2026-10-16T00:51:55Z | 2026-10-16 08:51:55 | 1 小時 51 分 | success | success | ubuntu-latest |
| 38988372900 | schedule | 2026-10-17T00:52:36Z | 2026-10-17 08:52:36 | 1 小時 52 分 | success | success | ubuntu-latest |
| 39082880379 | schedule | 2026-10-18T00:28:29Z | 2026-10-18 08:28:29 | 1 小時 28 分 | success | success | ubuntu-latest |
| 39181376782 | schedule | 2026-10-19T00:34:25Z | 2026-10-19 08:34:25 | 1 小時 34 分 | success | success | ubuntu-latest |
| 39352813234 | schedule | 2026-10-20T01:19:48Z | 2026-10-20 09:19:48 | 2 小時 19 分 | success | success | ubuntu-latest |
| 39525170131 | schedule | 2026-10-21T01:04:37Z | 2026-10-21 09:04:37 | 2 小時 04 分 | success | success | ubuntu-latest |
| 39703385899 | schedule | 2026-10-22T01:02:59Z | 2026-10-22 09:02:59 | 2 小時 02 分 | success | success | ubuntu-latest |
| 39881796745 | schedule | 2026-10-23T01:03:32Z | 2026-10-23 09:03:32 | 2 小時 03 分 | success | success | ubuntu-latest |

## 這份證據不能證明什麼

- 不能證明某一次 run 發生時本機 Mac 是關機的；只能證明 runner 是 GitHub-hosted，結構上不依賴 Mac。
- 不能證明 Claude 額度視窗（usage / reset）因這些請求有任何變化；該項觀察移交使用者（tasks 第 8 節）。
- 不能證明 cron-job.org 的 07:00 觸發準時；外部排程尚未建立，驗收條件見 tasks 第 10 節。
