# Proposal: align-external-scheduler-to-15m

## Why

目前 repository 文件已宣告 external scheduler 每 15 分鐘喚醒 detector，但 live Actions evidence 仍顯示約每 5 分鐘一輪；同時正式 capability spec `private-change-detection` 仍寫「MUST 每 5 分鐘」。因此目前存在三份互相不一致的 truth：文件=15 分鐘、spec=5 分鐘、runtime=5 分鐘。

## Assumptions

- Detector 演算法與 private read-only security boundary 不變。
- 目標 cadence 為每 15 分鐘一次，minutes=`0,15,30,45`。
- cron-job.org 是唯一的定時喚醒來源。
- 外部 scheduler 設定屬 runtime configuration，repo 內不得在沒有 live evidence 時宣稱已完成切換。

## What Changes

- 將 `private-change-detection` capability cadence 從 5 分鐘改成 15 分鐘。
- 修正 README / `docs/external-scheduler.md` 中仍殘留的 5 分鐘描述。
- 明確定義 runtime acceptance evidence：切換完成後，必須觀察連續 detector runs 符合 15 分鐘 cadence，才可把 migration task 標記完成。
- 不修改 detector algorithm、private CI adapter、credential scope 或 private repo write boundary。

## Out of Scope

- 不新增新的 scheduler service。
- 不恢復 GitHub native `schedule`。
- 不變更 token 權限。
- 不以 repo 文件更新冒充 cron-job.org runtime 已完成修改。
