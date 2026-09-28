# Design: private-ci-self-hosted-relay

## 決策 1：Public Hub 只在受控 runner 執行 private CI

`private-ci.yml` 的 private CI job 使用 `runs-on: [self-hosted, private-ci]`，不再使用 GitHub-hosted `ubuntu-latest` 取得 private source。Runner group 的 repository allow-list、labels、network、ephemeral lifecycle 與 registration 由 GitHub Settings／受控主機管理，workflow 不自動註冊 runner。

Workflow 只由 Hub `main` 的 push 或手動 dispatch 執行；不接受 public PR event，不使用 `pull_request_target`。workflow 在注入 private secret 前驗證 `github.ref == refs/heads/main`。

## 決策 2：default 與 PR exact-SHA 是兩種 provenance

- `baseline`：relay 解析 target default branch，取得當下 commit，結果 provenance 為 `default-branch`。
- `pr-exact-sha`：只接受 positive numeric PR number，API 驗證 open、same repository、base default branch、non-fork，內部解析 head SHA；不接受 caller-provided ref/SHA。V1 只支援 `repo-04`。

PR head 在執行前寫入 runner-only context，執行後重新查詢；若 head 改變或查詢失敗，不產生有效 PASS。PR run 使用不同 job prefix，避免被 default baseline collector 收集。

## 決策 3：重用既有 adapter，不重建 CI

解壓／checkout 產生既有 `workspace/` 形狀後，沿用 `scripts/common/run-ci.sh`。repo-04 的 local baseline commit 只存在 ephemeral runner workspace，不能被視為 private repository commit。target step 不接 private read token、Hub token 或 runner registration token。

## 決策 4：Public output allowlist 與 best-effort cleanup

Public summary 只允許 alias、mode、stage、PASS/FAIL/SKIP、exit code、duration。所有 API response、archive、metadata、head context、askpass、command files、raw stage logs 與 workspace 都放在 runner temporary area，成功、失敗、timeout、cancel、驗證拒絕都走 cleanup。

cleanup 會先驗證 workspace 是本 job 的預期路徑，再 best-effort 移除，不讓單一 `rm` 失敗阻止其餘敏感檔案清除。

## 不變更

- `detect-private-changes.yml` 仍只 dispatch default-branch mode。
- Ai-agent 的 `hub_baseline_evidence.py` 與 remoteEvidence schema 不把 PR mode 當 baseline。
- GitHub-hosted public workflows `security-audit.yml`、`validate-openspec.yml` 保持 public-only。

## 驗證策略

- local：OpenSpec strict、security audit、YAML/shell syntax、diff check、adapter checks。
- runner：確認 runner online、label/group 正確且 private CI 不會落回 GitHub-hosted runner。
- remote：先 baseline repo-04 smoke，再以 PR #482 exact head 執行 PR mode，檢查 head stability、sanitized output、cleanup 與 provenance separation。
