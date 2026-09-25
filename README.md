# Automation-Hub

Public, read-only CI orchestration for private repositories.

The hub exists to run validation on standard public GitHub-hosted runners while target source repositories remain private. It supports manual single-target runs, an automatic six-target sweep every three hours, and a six-target regression sweep when the hub's own workflow/adapter code changes on `main`. All target access remains read-only, public output is sanitized, and production deployment is out of scope.

## Architecture

~~~text
workflow_dispatch
      |
      v
repo-01 .. repo-06          public aliases only
      |
      v
PRIVATE_REPOS_JSON           GitHub Secret
      |
      v
private repository           resolved only at runtime
      |
      |  PRIVATE_REPOS_READ_TOKEN
      v
ephemeral workspace/
      |
      +--> install
      +--> lint      (if present)
      +--> typecheck (if present)
      +--> test      (if present)
      +--> build     (if present)
      |
      v
sanitized PASS / FAIL / SKIP summary
~~~

## Required GitHub Actions secrets

Create these manually under Settings → Secrets and variables → Actions.

### PRIVATE_REPOS_READ_TOKEN

Use a fine-grained GitHub personal access token restricted to the selected private repositories.

Phase 1 repository permissions:

- Contents: Read-only
- Metadata: Read

Do not grant write access for this change.

### PRIVATE_REPOS_JSON

JSON object mapping public aliases to private repository identifiers.

Keep the real values only in the secret. Conceptual shape:

~~~json
{
  "repo-01": "<owner/private-repository>",
  "repo-02": "<owner/private-repository>",
  "repo-03": "<owner/private-repository>",
  "repo-04": "<owner/private-repository>",
  "repo-05": "<owner/private-repository>",
  "repo-06": "<owner/private-repository>"
}
~~~

Do not commit the real mapping.

## Run CI manually

1. Open Actions.
2. Select Private CI Bridge (read-only).
3. Choose Run workflow.
4. Pick repo-01 through repo-06.
5. Run.

The first implementation always checks out the target repository's default branch. This avoids exposing private branch/ref names through a public workflow input.

## Supported project adapter

The initial adapter supports Node-family repositories that contain package.json.

Package manager detection:

- pnpm-lock.yaml → pnpm
- package-lock.json → npm
- yarn.lock → yarn
- bun.lock / bun.lockb → recognized but not executed until a reviewed Bun adapter is added

The workflow runs only scripts that already exist in the target:

1. dependency install
2. `check:ci` when the repository already defines it
3. otherwise fall back to `lint` / `typecheck` / `test` / `build` when present

Missing optional scripts are reported as SKIP.

Repositories without a supported adapter are cloned and reported as adapter SKIP; the hub does not invent commands or modify the target to make it fit.

## Public-log policy

Command output from private-repository CI is captured to ephemeral local files and is not printed by default.

The public summary contains only:

- target alias;
- adapter/package manager;
- stage name;
- PASS / FAIL / SKIP;
- exit code for a failed stage.

No private source artifact is uploaded.

## OpenSpec

Current changes:

- `openspec/changes/public-ci-automation-hub/` — Phase 1 read-only CI recovery and six-target rollout.
- `openspec/changes/automatic-private-ci-sweep/` — automatic three-hour sweep and hub-code regression trigger.

Implementation follows both changes' security, migration, and validation gates.

## Actions command-file isolation

Private-repository CI executes with temporary replacements for `GITHUB_STEP_SUMMARY`, `GITHUB_OUTPUT`, `GITHUB_ENV`, and `GITHUB_PATH`. This prevents target tooling from directly injecting summaries, outputs, environment mutations, or PATH mutations into the public orchestration job. The temporary command files are deleted during the always-run cleanup step; only the hub-generated sanitized summary is published.

## Alias-specific validation

Most Node targets use the repository's existing `check:ci` when available. `repo-04` is an exception: its private CI contains broader governance and architecture gates than its package-level aggregate script. The hub therefore applies an additional read-only adapter for `repo-04` covering ShellCheck, governance, architecture, skill routing/audit, runner integration, spec-governance, spec-truth-gate, and the repository's existing `check:ci`. The adapter creates only a local temporary Git baseline with no remote and no credentials, then removes the workspace during cleanup.

## repo-05 contract adapter

`repo-05` is not a package-manager CI target. The hub mirrors its private candidate-contract workflow with Python unit tests, candidate contract validation, architecture contract validation, and strict OpenSpec validation. For this alias the hub configures Node 20.19.0 to match the original CI workflow. The separate scheduled upstream-watch workflow is not executed as part of normal CI because it is monitoring/reporting rather than a source-validation gate.

## repo-06 Vault Health adapter

`repo-06` is a large content repository. The hub uses a sparse read-only Git checkout matching its Vault Health scope rather than downloading the full repository archive. The checkout retains local Git metadata for read-only health inventory logic but removes every remote before CI begins. The adapter runs only structural/read-only Vault Health gates and suppresses all target-generated report bodies from public logs. Schedule-only reports and AI generation/retry workflows are intentionally excluded.


## 自動偵測 private repo 變更

Automation-Hub 每 5 分鐘執行一次唯讀偵測：

~~~text
2-57/5 * * * *
~~~

偵測器不會固定重跑六倉。它會：

1. 以 alias 讀取六個 private repo 的最新 push 時間。
2. 查詢該 alias 最近一次 Public CI job 的開始時間。
3. 如果最近 CI 已在最新 push 之後開始，標記為 `SKIP`。
4. 如果有更新的 push，才透過 Public Automation-Hub 自己的 `workflow_dispatch` 執行該 alias。
5. 如果該 alias 已有 CI 執行中，先 `WAIT`，下一輪 5 分鐘再判斷，避免重複排隊。

偵測器不保存 private commit SHA，也不新增 private repo write 權限。它沿用既有 read-only private credential；只有 Public Automation-Hub 自己的 detector job 具有 `actions: write`，用途僅限觸發既有 CI workflow。

這個偵測採用 repository push activity 作為保守訊號，因此其他 branch 的 push 可能造成一次額外 CI，但不會因此公開 private repo 名稱或原始碼。

手動 `workflow_dispatch` 仍保留，若需要立即檢查可直接執行單一 alias。

當 Hub 自己的 `.github/workflows/private-ci.yml` 或 `scripts/common/**` 在 `main` 變更時，仍會自動跑一次六倉 regression，用來驗證 orchestration code 本身。
