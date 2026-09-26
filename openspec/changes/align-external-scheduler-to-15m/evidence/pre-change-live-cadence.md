# Pre-change live cadence evidence — 2026-09-27

## Purpose

記錄本 change 開始前的實際 runtime cadence，證明 repository 文件雖已提到 15 分鐘，但 external scheduler 尚未切換完成。

## GitHub Actions evidence

來源：`sodahsu/Automation-Hub` → `Detect Private Repository Changes` workflow runs。

| Run ID | created_at (UTC) | 台北時間 | Event | Conclusion |
|---|---|---|---|---|
| `36254185268` | 2026-09-26T16:05:05Z | 2026-09-27 00:05:05 | `workflow_dispatch` | success |
| `36253897453` | 2026-09-26T16:00:25Z | 2026-09-27 00:00:25 | `workflow_dispatch` | success |
| `36253597553` | 2026-09-26T15:55:05Z | 2026-09-26 23:55:05 | `workflow_dispatch` | success |
| `36253312901` | 2026-09-26T15:50:07Z | 2026-09-26 23:50:07 | `workflow_dispatch` | success |

相鄰 runs 約 5 分鐘，因此在本 evidence 時點，runtime **尚未**符合目標 `0,15,30,45` / 15 分鐘 cadence。

## Acceptance consequence

- README / OpenSpec delta 可以先改為目標 15 分鐘契約。
- `tasks.md` 的 external scheduler runtime 切換與 post-change live evidence 必須保持未完成。
- 未取得至少三個連續、約 15 分鐘間隔的 live `workflow_dispatch` runs 前，不得宣稱 migration complete。
