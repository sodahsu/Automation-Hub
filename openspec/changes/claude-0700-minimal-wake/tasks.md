# 任務：claude-0700-minimal-wake

## 1. Workflow 實作

- [x] 建立分支 `feat/claude-0700-wake`。
- [x] 新增 `.github/workflows/claude-0700-wake.yml`。
- [x] 設定每天 07:00、timezone `Asia/Taipei`。
- [x] 保留 `workflow_dispatch`。
- [x] 使用 GitHub-hosted `ubuntu-latest`。
- [x] 設定短 job timeout。
- [x] 加入 concurrency group，避免同一 wake job 重疊。

## 2. Claude 最小觸發

- [x] 使用 `anthropics/claude-code-action@v1`。
- [x] OAuth secret key 指向 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`。
- [x] Prompt 僅要求 `Reply exactly: OK`，並明確禁止讀檔、工具與 repository mutation。
- [x] 設定 `--max-turns 1`。
- [x] 使用低成本 Claude model。
- [x] 不加入 retry loop。

## 3. 權限與公開 Repo 安全

- [x] Workflow permissions 僅 `contents: read`。
- [x] Checkout 使用 `persist-credentials: false`。
- [x] 不加入 private repository credential。
- [x] 不加入 private repository alias mapping。
- [x] 不在 committed file 中保存 OAuth token value。
- [x] 不建立 repository write step。

## 4. OpenSpec

- [x] 建立 active change `claude-0700-minimal-wake`。
- [x] 建立 proposal。
- [x] 建立 requirement delta spec。
- [x] 建立 tasks checklist。
- [ ] OpenSpec strict validation 通過。

## 5. 帳號認證

- [ ] 以指定 Claude 帳號執行 `claude setup-token`。
- [ ] 在 Automation-Hub Actions Secrets 建立 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`。
- [ ] 確認 Actions log 不會輸出 token。

## 6. Manual smoke test

- [ ] 由 `workflow_dispatch` 手動啟動一次。
- [ ] Workflow run 結論為 success。
- [ ] Claude step 正常完成單回合。
- [ ] 無 repository mutation。
- [ ] 無額外 Agent / tool execution。
- [ ] Actions log 無 OAuth token 洩漏。

## 7. Scheduled runtime 驗證

- [ ] 合併至 default branch 後確認 scheduled workflow 為 enabled。
- [ ] 在本機 Mac 關閉或不在線情況下觀察一筆 07:00 scheduled run。
- [ ] 確認 trigger event 為 `schedule`。
- [ ] 確認 runner 為 GitHub-hosted。
- [ ] 記錄實際開始時間與排程延遲。
- [ ] 確認 Claude request 成功。

## 8. 額度行為觀察

- [ ] 僅記錄 07:00 request 對 Claude usage window 的實際結果。
- [ ] 不把單次觀察推論為固定 reset contract。
- [ ] 若未來確認需要多階段 wake，另開 OpenSpec change，不在本 change 擴張。

## 9. 完成與歸檔

- [ ] Manual smoke test、scheduled runtime 驗證與 strict validation 全部完成。
- [ ] 補上 review / runtime evidence。
- [ ] 完成後才移至 `openspec/changes/archive/`。
