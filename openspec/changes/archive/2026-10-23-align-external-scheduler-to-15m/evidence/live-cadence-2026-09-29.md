# Live cadence 稽核（2026-09-29）

來源：`gh run list -R sodahsu/Automation-Hub --workflow detect-private-changes.yml --limit 20`（UTC，僅列 `workflow_dispatch`）。

結論：runtime 仍約每 5 分鐘，尚未切換為 15 分鐘，migration 維持 pending。

```
12:45:11  12:50:08  12:55:06  13:00:28  13:05:06  13:10:09  13:15:11
13:20:09  13:25:06  13:30:18  13:35:06  13:40:09  13:45:10  13:50:08
13:55:06  14:00:25  14:05:07  14:10:09  14:15:11
```

（13:56:38 為 `push` 事件，非 scheduler。）相鄰間隔皆約 5 分鐘，不符合 `0,15,30,45`。
