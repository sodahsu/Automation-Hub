# Automation Hub — OpenSpec 專案

## 目的

`Automation-Hub` 是一個公開的 CI 協調儲存庫，用來替六個 private repositories 執行 CI 與 repository health checks，同時避免把 private source code、筆記內容或 deployment credentials 搬進本 Public repo。

最初目標是：當 private-repository GitHub-hosted Actions quota 無法使用時，仍能恢復 CI 能力。

## 治理原則

- 本儲存庫為 Public。所有已 commit 的檔案、workflow、log、artifact、cache key 與 summary 都必須視為公開資訊。
- Private repository 名稱、clone URL、source code、note content、environment value、deployment credential 與 token 不得 commit 到這裡。
- Private repositories 只能使用 public-safe alias：`repo-01`～`repo-06`。
- Alias-to-repository mapping 必須在 runtime 透過 GitHub Secrets 或其他非公開設定提供。
- Private repository access 必須維持 read-only。
- Production deployment、billing 變更、repository visibility 變更、branch protection 變更、secret rotation，以及對 private repositories 的寫入，都不在本專案初始範圍內。
- Private repositories 既有 workflow 保持不動，除非另有明確核准。
- Public log 必須採 sanitized output；不得輸出 private source、完整 environment 或 private repository identifier。
- Private workspace、暫存 command files 與 credential helper 必須在成功或失敗後 cleanup。

## 自動化原則

- Manual `workflow_dispatch` 必須保留，供立即執行單一 alias。
- Private change detector 可以定時 polling，但不得因此增加 private repository write access。
- Detector 只可用 Public Hub 自己的 `actions: write` 觸發既有 workflow。
- Hub 自身 workflow/adapter 變更時，可以跑六倉 regression。
- 自動化不得把 private alias mapping、commit metadata 或 source artifact 長期保存到 Public repo。

## 驗證

交付前至少確認：

- 六個 alias 都能在 Public runner 執行。
- Private credential 維持 selected-repository read-only。
- Public logs 沒有 known private repository name hit。
- Artifact count 為 0，除非另有明確且經 review 的 public-safe artifact。
- Cleanup、masking、command-file isolation 正常。
- OpenSpec strict validation 在可用時通過。

## Change 歸檔規則

- `openspec/changes/` 只保留仍在進行中的 change。
- Change 的必要 task、驗證與 review 全部完成後，必須立即歸檔，不長期留在 active 區。
- 歸檔目的地為 `openspec/changes/archive/`。
- 歸檔前不得為了「看起來完成」而把沒有證據的 task 勾成完成。
- 若仍有 runtime observation、security review、strict validation 或其他 acceptance item 未完成，change 必須繼續留在 active 區。
- 歸檔後保留 proposal、design、tasks、review、spec 與驗證紀錄，作為歷史決策證據。


## OpenSpec 自動驗證

- `.github/workflows/validate-openspec.yml` 會在 `openspec/**` 變更時自動執行。
- 驗證命令：`npx --yes @fission-ai/openspec@1.8.0 validate --all --strict`。
- 驗證 workflow 只需要 `contents: read`，不持有 private repository credential。
