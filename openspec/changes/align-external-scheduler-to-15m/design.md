# Design: align-external-scheduler-to-15m

## Decision

保留現有 external scheduler architecture，只調整 cadence contract 與 acceptance evidence：

```text
cron-job.org
  every 15 min
      ↓ workflow_dispatch
detect-private-changes.yml
      ↓ changed aliases only
private-ci.yml
```

Detector 邏輯、alias mapping、read-only credential 與 public log sanitization 全部維持不變。

## Runtime completion rule

Repository 變更與 runtime 設定分開驗收。只有當外部 scheduler 實際改成 `0,15,30,45`，且 live GitHub Actions 至少出現三個連續 `workflow_dispatch` detector runs、相鄰間隔符合約 15 分鐘，才可宣稱 cadence migration 完成。

若 runtime 仍維持 5 分鐘，即使 README / spec 已更新，也只能標記為「contract prepared / runtime pending」，不得把 task 勾完成。

## Overengineering check

目前問題是單一 external cadence drift，現有 scheduler 與 detector 均可正常工作；最小充分變更是修改既有 spec / docs 與加上 acceptance evidence，不新增 workflow、state store、scheduler abstraction 或監控服務。

## Verification

1. OpenSpec strict validation 通過。
2. repository security / workflow checks 通過。
3. live cadence 以 GitHub Actions timestamps 驗證；沒有 live evidence 時明確保留 pending。
