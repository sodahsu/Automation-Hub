# Proposal

## Why

需要在本機電腦未開機、Orca 未啟動的情況下，仍能每天於台灣時間 07:00 對指定 Claude 帳號建立一次最小有效請求。此功能只負責建立一次可驗證的雲端 wake request，不負責派工或控制 Claude 額度 reset。

## What Changes

- 新增 `.github/workflows/claude-0700-wake.yml`。
- 使用 GitHub-hosted `ubuntu-latest` runner，不依賴本機 Mac 或 self-hosted runner。
- 每天 07:00 以 `Asia/Taipei` timezone 觸發，並保留 `workflow_dispatch`。
- 使用 `CLAUDE_PISCEAN0619_OAUTH_TOKEN` 注入指定 Claude 帳號的 OAuth credential。
- Claude 請求限制為低成本模型、單回合、極短固定回應。
- 權限只允許 `contents: read` 與 Claude Code Action OIDC 所需的 `id-token: write`；不授予 repository content write。
- 第三方 GitHub Actions 固定到 immutable commit SHA。
- 不執行派工、不讀 private repositories、不修改 repository、不建立 PR / issue / commit。

## Capabilities

### New Capabilities

- `claude-minimal-wake`: 每天 07:00 透過 GitHub-hosted runner 對指定 Claude 帳號建立一次最小、單回合、可驗證的 wake request。

### Modified Capabilities

- 無。

## Impact

- `.github/workflows/claude-0700-wake.yml`: 新增每日 Claude wake workflow。
- `openspec/changes/claude-0700-minimal-wake/`: 定義行為、權限、安全邊界與驗收項目。
- GitHub Actions repository secret：需要 `CLAUDE_PISCEAN0619_OAUTH_TOKEN`。
- 不影響六個 private repositories、既有 private CI bridge、Orca 或本機排程。
