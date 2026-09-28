# 任務：claude-window-trigger

## 1. Workflow

- [x] 1.1 建立獨立 `claude-window-trigger.yml`。
- [x] 1.2 加入 Asia/Taipei timezone-aware schedule。
- [x] 1.3 每日排定 07:07、12:07、17:07、22:07。
- [x] 1.4 加入 `workflow_dispatch`，預設 dry-run。
- [x] 1.5 加入單一 concurrency group 與 3 分鐘 timeout。
- [x] 1.6 權限縮限為 `contents: read`。

## 2. Cost / Safety Guard

- [x] 2.1 Scheduled live 必須由 `CLAUDE_WINDOW_TRIGGER_ENABLED=true` 顯式開啟。
- [x] 2.2 Live 只讀取 `CLAUDE_CODE_OAUTH_TOKEN`。
- [x] 2.3 偵測到 `ANTHROPIC_API_KEY` 時 fail closed。
- [x] 2.4 不使用 `actions/checkout`。
- [x] 2.5 固定最短 prompt。
- [x] 2.6 固定 `max-turns=1`。
- [x] 2.7 禁止常用 Claude Code tools。
- [x] 2.8 不設定高成本模型 fallback。
- [x] 2.9 不建立 retry loop。

## 3. 文件

- [x] 3.1 文件化啟用條件、Secret 與 Variable。
- [x] 3.2 文件化目前帳號未準備 OAuth 時應保持 disabled。
- [x] 3.3 文件化「28 windows」仍需實測 reset 行為，不能由 workflow 存在本身推論。

## 4. 驗證

- [ ] 4.1 合併到 default branch 後確認四個 scheduled events 可被 GitHub 識別。
- [ ] 4.2 先以 dry-run 驗證 workflow。
- [ ] 4.3 設定 Claude OAuth 後手動 live 一次。
- [ ] 4.4 連續至少兩個工作日記錄 Claude Usage / reset time。
- [ ] 4.5 實測成立後再把 `CLAUDE_WINDOW_TRIGGER_ENABLED` 設為 `true`。
