# Private CI Runner 設定

本文件描述 Automation-Hub private CI 的受控 runner 前置條件。它不包含 registration token、private repository mapping 或任何 credential。

## Runner 邊界

- Runner group：`private-ci-relay`
- Required labels：`self-hosted`、`private-ci`
- Runner access：只允許 Automation-Hub 的 `private-ci.yml` workflow 使用
- Workflow ref：只允許 Hub `main`
- 不把 runner 註冊到 Public source repository、六倉或一般 cloud-agent workflow
- 不使用裸 `self-hosted` 作為 fallback label

Labels 不是唯一安全邊界；GitHub Settings 的 runner group allow-list、受控主機權限、網路出口與 ephemeral cleanup 必須同時成立。

## Registration

1. 在 Automation-Hub repository Settings → Actions → Runners 建立受控 runner，取得短期 registration token。
2. 在受控主機安裝與 GitHub runner 相容的 runtime，使用 token 註冊 `private-ci` label。
3. 將 runner 設為只接受允許的 workflow，確認 `gh api repos/sodahsu/Automation-Hub/actions/runners` 顯示 online 且 labels 正確。
4. Registration token 只進 runner 本機設定，不進 shell history、repository、Issue、PR 或 log。
5. 完成驗收後，token 不再重用；ephemeral worker 在 request 結束後移除或重置。

## 驗收

- 觸發 baseline `repo-04` smoke test，確認 job 的 runner label 是 `private-ci`。
- 確認 Public log 沒有 private repository name、source、ref、SHA、token 或 raw adapter output。
- 觸發 PR exact-SHA mode 前，先確認 PR head SHA 前後穩定；head 變更必須 fail closed。
- Runner offline 時，workflow 只能 unavailable／queued，不得改排 `ubuntu-latest`。
