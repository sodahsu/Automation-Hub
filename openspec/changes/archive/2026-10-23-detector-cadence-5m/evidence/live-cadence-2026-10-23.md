# Live cadence 驗收（2026-10-23）

## 結果

PR #26 於 2026-10-23 04:33:20Z 合併，merge commit 為 `9edcad7b81ee68c16388ba1b55948a6ef3bd64c2`。截至本次取數時間，04:35:06Z 至 05:45:12Z 的 15 個 5 分鐘格點 `workflow_dispatch` run 均完成完整掃描；相鄰建立間隔為 4:45 至 5:26，其中 05:20:31Z 的非排程成對喚醒與 05:26:28Z 的格點外喚醒剔除後，排程 run 間隔為 4:45 至 5:06。符合至少 6 個連續 run、間隔 4–6 分鐘的驗收條件。

完整掃描依 tasks.md 判準，以 `Detect private push activity` step 耗時至少 10 秒判定。此區間 15 次耗時 10–14 秒。

## Run 逐筆結果

`step 耗時`是 jobs API 回傳的 step 完成時間減開始時間；表格含最近 30 筆 run，足以涵蓋合併前基線、合併後連續區間與同秒配對 run。

| Run ID | createdAt (UTC) | Event / conclusion | Step 耗時 | 判定與理由 |
|---:|---|---|---:|---|
| 39907504330 | 2026-10-23 05:45:12Z | workflow_dispatch / success | 12 秒 | 完整 |
| 39907029746 | 2026-10-23 05:40:09Z | workflow_dispatch / success | 14 秒 | 完整 |
| 39906568569 | 2026-10-23 05:35:06Z | workflow_dispatch / success | 13 秒 | 完整 |
| 39906122923 | 2026-10-23 05:30:22Z | workflow_dispatch / success | 13 秒 | 完整 |
| 39905764982 | 2026-10-23 05:26:28Z | workflow_dispatch / success | 12 秒 | 完整；非格點，剔除為非排程喚醒 |
| 39905640564 | 2026-10-23 05:25:06Z | workflow_dispatch / success | 13 秒 | 完整 |
| 39905215213 | 2026-10-23 05:20:31Z | workflow_dispatch / success | 無 | 剔除：同秒成對建立的非排程喚醒；run 已取消，step 未執行 |
| 39905214965 | 2026-10-23 05:20:31Z | workflow_dispatch / cancelled | 無 | 剔除：同秒成對建立的非排程喚醒；step 未執行 |
| 39905182664 | 2026-10-23 05:20:10Z | workflow_dispatch / success | 10 秒 | 完整 |
| 39904724510 | 2026-10-23 05:15:12Z | workflow_dispatch / success | 14 秒 | 完整 |
| 39904266545 | 2026-10-23 05:10:10Z | workflow_dispatch / success | 10 秒 | 完整 |
| 39903798916 | 2026-10-23 05:05:07Z | workflow_dispatch / success | 11 秒 | 完整 |
| 39903373901 | 2026-10-23 05:00:32Z | workflow_dispatch / success | 12 秒 | 完整 |
| 39903086252 | 2026-10-23 04:57:20Z | workflow_dispatch / success | 13 秒 | 完整；非格點，剔除為非排程喚醒 |
| 39902884987 | 2026-10-23 04:55:06Z | workflow_dispatch / success | 12 秒 | 完整 |
| 39902438624 | 2026-10-23 04:50:09Z | workflow_dispatch / success | 11 秒 | 完整 |
| 39901995478 | 2026-10-23 04:45:12Z | workflow_dispatch / success | 13 秒 | 完整 |
| 39901542206 | 2026-10-23 04:40:10Z | workflow_dispatch / success | 11 秒 | 完整 |
| 39901099108 | 2026-10-23 04:35:06Z | workflow_dispatch / success | 12 秒 | 完整 |
| 39900943758 | 2026-10-23 04:33:22Z | push / success | 12 秒 | 剔除：不是 workflow_dispatch 排程喚醒 |
| 39900789517 | 2026-10-23 04:31:39Z | workflow_dispatch / success | 12 秒 | 完整；非格點，且與同秒配對 run 一起剔除 |
| 39900789433 | 2026-10-23 04:31:39Z | workflow_dispatch / cancelled | 無 | 剔除：同秒成對建立的非排程喚醒；step 未執行 |
| 39900673587 | 2026-10-23 04:30:21Z | workflow_dispatch / success | 10 秒 | 完整 |
| 39900557660 | 2026-10-23 04:29:04Z | workflow_dispatch / success | 13 秒 | 完整；非格點，且與同秒配對 run 一起剔除 |
| 39900557064 | 2026-10-23 04:29:03Z | workflow_dispatch / cancelled | 無 | 剔除：同秒成對建立的非排程喚醒；step 未執行 |
| 39900207725 | 2026-10-23 04:25:06Z | workflow_dispatch / success | 0 秒 | 節流；合併前基線 |
| 39900064700 | 2026-10-23 04:23:30Z | workflow_dispatch / success | 13 秒 | 完整；非格點，且與同秒配對 run 一起剔除 |
| 39900064142 | 2026-10-23 04:23:30Z | workflow_dispatch / cancelled | 無 | 剔除：同秒成對建立的非排程喚醒；step 未執行 |
| 39899769050 | 2026-10-23 04:20:10Z | workflow_dispatch / success | 0 秒 | 節流；合併前基線 |
| 39899331480 | 2026-10-23 04:15:12Z | workflow_dispatch / success | 37 秒 | 完整；合併前基線 |
| 39899691158 | 2026-10-23 04:19:16Z | workflow_dispatch / cancelled | 無 | 剔除：非格點且同秒成對建立；step 未執行 |
| 39899691101 | 2026-10-23 04:19:16Z | workflow_dispatch / success | 29 秒 | 完整；非格點且同秒成對建立，剔除為非排程喚醒 |

合併前 04:10:10Z run `39898865898` 的 step 為 1 秒，屬節流基線；04:20、04:25 分別為 0 秒，亦屬節流。04:15:12Z run 為 37 秒完整掃描，是舊 15 分鐘格點上的預期完整掃描。jobs 數據由本次續作重新取得確認。

## 取數指令

Run 清單（原樣）：

```sh
gh run list -R sodahsu/Automation-Hub --workflow detect-private-changes.yml --limit 30 --json databaseId,createdAt,event,conclusion
```

每個 run 的 step 時間（以 `<id>` 代入上表 Run ID；原樣）：

```sh
gh api repos/sodahsu/Automation-Hub/actions/runs/<id>/jobs --jq '.jobs[].steps[] | select(.name=="Detect private push activity") | [.started_at,.completed_at] | @tsv'
```

本次續作重新執行上述原始指令（run list 使用 limit 30），並逐筆對本表所列 run ID 執行 jobs 指令。另重取基線 run `39898865898`、`39899769050`、`39900207725`、`39899331480` 的 jobs。
