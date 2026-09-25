# Automation-Hub

Public, read-only CI orchestration for private repositories.

The hub exists to run validation on standard public GitHub-hosted runners while target source repositories remain private. The initial implementation is deliberately narrow: manual dispatch, read-only checkout, repository-native CI, sanitized public output, and no production deployment.

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

Current change:

openspec/changes/public-ci-automation-hub/

Implementation follows that change's security and migration gates.

## Actions command-file isolation

Private-repository CI executes with temporary replacements for `GITHUB_STEP_SUMMARY`, `GITHUB_OUTPUT`, `GITHUB_ENV`, and `GITHUB_PATH`. This prevents target tooling from directly injecting summaries, outputs, environment mutations, or PATH mutations into the public orchestration job. The temporary command files are deleted during the always-run cleanup step; only the hub-generated sanitized summary is published.

## Alias-specific validation

Most Node targets use the repository's existing `check:ci` when available. `repo-04` is an exception: its private CI contains broader governance and architecture gates than its package-level aggregate script. The hub therefore applies an additional read-only adapter for `repo-04` covering ShellCheck, governance, architecture, skill routing/audit, runner integration, spec-governance, spec-truth-gate, and the repository's existing `check:ci`. The adapter creates only a local temporary Git baseline with no remote and no credentials, then removes the workspace during cleanup.
