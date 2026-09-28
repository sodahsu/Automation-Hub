# Proposal: align-claude-code-action-version

## Why

`claude-0700-wake.yml:31` 固定 `anthropics/claude-code-action@756cc22e19660d20e8cc9496b4f242475a7f7790`（註解 `# v1`），而 ObsidianBook（`.github/workflows/claude.yml`、`retry-claude-quota.yml`）與 soda-cloud-agent（`.github/workflows/claude.yml`）固定的是 `@9171db3e57d6a3140a37ddc2ba92788584e0ead6`（同樣註記 `# v1`）。兩個 SHA 不同卻都自稱 `v1`，需要查清楚哪一個才是目前真正的 `v1`，才知道該對齊哪一邊。

## Investigation

以 `git ls-remote --tags https://github.com/anthropics/claude-code-action`（唯讀，對公開 repo）查證：

- 浮動 tag `v1` 解引用（`v1^{}`）後指向 commit `756cc22e19660d20e8cc9496b4f242475a7f7790`。
- 該 commit 同時是固定版本 tag `v1.0.235` 指向的 commit。
- `9171db3e57d6a3140a37ddc2ba92788584e0ead6` 對應固定版本 tag `v1.0.234`——比 `v1.0.235` 舊一個 patch release。
- 抓到的 `v1.0.x` 系列 tag 最高只到 `v1.0.235`，沒有更新的 `v1.0.236+`。

**結論：Automation-Hub 目前釘的 SHA 已經是目前的 `v1`（`v1.0.235`），不是落後的那一個。落後的反而是 ObsidianBook 與 soda-cloud-agent，它們釘在舊一版的 `v1.0.234`。**

## What Changes

- 本 change **不修改** `claude-0700-wake.yml`——它已經對齊目前的 `v1`，沒有需要「追上」的落差。
- 記錄本次調查方法與結論（tag 解引用 + 版本號比較），供日後任何一邊要升級/降級 pin 時查核依據。
- 不在本 change 內修改 ObsidianBook 或 soda-cloud-agent 的 workflow：兩者都不屬於 Automation-Hub 的範圍，且依指示，若判定是其他 repo 落後，不動它們，只記錄發現。

## Capabilities

無現有 `openspec/specs/` capability 契約規範跨 repo 的 `claude-code-action` 版本要保持一致；本 change 不新增、不修改任何 capability 契約。也不與仍在進行中的 `claude-0700-minimal-wake` change 衝突——該 change 定義「第三方 Actions MUST 固定 immutable commit SHA」，本次調查只確認釘的是哪一顆、是否跟上游 `v1` 對齊，兩者互不重寫。

## Impact

- Automation-Hub 端沒有程式碼變更；`claude-0700-minimal-wake` change 既有的驗收項目與 pending tasks 不受影響。
- 發現 ObsidianBook 與 soda-cloud-agent 落後一個 patch release（`v1.0.234` → `v1.0.235`）。這不在本 change 範圍內處理，建議另外為那兩個 repo 各自開 change 決定是否跟進更新。
- 已跑過的檢查：`ruby -ryaml -e 'YAML.load_file(ARGV[0])' .github/workflows/claude-0700-wake.yml` 通過（檔案未變動，此為確認基準狀態合法）。
