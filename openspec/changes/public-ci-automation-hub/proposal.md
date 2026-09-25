# Proposal: public-ci-automation-hub

## Why

The six private repositories currently depend on GitHub-hosted Actions for CI, but the private-repository Actions quota is exhausted. CI therefore cannot be relied on for lint, typecheck, test, build, or repository health checks.

The recovery path is to keep all six source repositories private while running the CI workload from the public `Automation-Hub` repository. The hub will obtain read-only access to a selected private repository at runtime through a least-privilege fine-grained token, execute repository-native checks on a standard public GitHub-hosted runner, and emit only a sanitized status summary.

Because this repository is public, the design must protect not only source content and credentials but also private-repository metadata. Committed configuration therefore uses aliases `repo-01` through `repo-06`; the real alias-to-repository mapping stays in GitHub Secrets.

## What Changes

1. Establish `Automation-Hub` as a public CI orchestrator for six private repositories.
2. Add a manually triggered CI workflow that accepts a public-safe target alias.
3. Resolve the real private repository at runtime from a secret mapping.
4. Clone the selected private repository with a read-only fine-grained token.
5. Detect the repository's existing package manager and repository-native CI commands.
6. Run available install / lint / typecheck / test / build checks without modifying source.
7. Add strict log, artifact, cache, timeout, concurrency, and cleanup controls.
8. Keep production deployment and every private-repository write path outside Phase 1.
9. Preserve existing private-repository workflows as rollback/reference; do not delete them during recovery.

## Scope

- `Automation-Hub` only.
- Six private targets represented publicly as `repo-01` through `repo-06`.
- Public GitHub-hosted standard runner execution.
- Read-only clone and CI/health validation.
- Initial trigger: `workflow_dispatch`.
- Safe summaries that expose PASS / FAIL / SKIP and step names, not private source content.

## Non-Goals

- Do not change any private repository to public.
- Do not publish private repository names in committed files.
- Do not write, commit, push, tag, merge, or open automated PRs against private repositories in Phase 1.
- Do not deploy to production.
- Do not modify Vercel, Cloudflare, Pages, release, database, billing, branch-protection, or repository-visibility settings.
- Do not rotate or create tokens from workflow code.
- Do not upload a private checkout, build output containing private source, notes, or environment files as artifacts.
- Do not delete or disable existing private-repository workflows as part of the initial recovery.
- Do not assume all six repositories share the same runtime or package manager.

## Acceptance

- `Automation-Hub` remains public and target repositories remain private.
- No committed file contains a private repository's real name or clone URL.
- Target selection is by alias only.
- Real repository mapping and read token are supplied through GitHub Secrets.
- Phase 1 token permissions are limited to selected repositories with read-only contents/metadata access.
- A manual run can select one alias, clone that target, and execute its supported CI checks on the public runner.
- Missing optional scripts are reported as `SKIP`, not treated as invented requirements.
- CI never modifies or pushes the private checkout.
- Logs do not intentionally print source files, notes, environment values, token values, or repository mapping.
- Resolved private repository identifiers are masked before use in subsequent steps.
- Artifacts are disabled by default.
- Repository source directories are not cached.
- Jobs have bounded timeouts and concurrency control.
- Failure output identifies the failing stage without dumping private source content.
- The private workspace is removed at the end of the job.
- Existing private workflows remain available as rollback/reference.
