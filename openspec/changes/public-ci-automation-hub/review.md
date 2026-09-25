---
title: "Public CI Automation Hub Review"
tags:
  - OpenSpec/Review
  - CI/GitHubActions
  - Security/PublicPrivateBoundary
date: 2026-09-25
type: review
status: active
source: ai-assisted
---

# Public CI Automation Hub Review

## Pre-implementation Findings

- The public `Automation-Hub` repository exists and is the intended orchestration location.
- The current operational problem is exhausted private-repository GitHub-hosted Actions quota, so existing private CI cannot be treated as available capacity.
- Six private repositories are in scope, but their real names are deliberately not recorded in this public repository.
- Phase 1 can restore CI without changing repository visibility and without writing to target repositories.
- The public/private boundary makes log hygiene, artifact policy, cache policy, and metadata masking first-class requirements rather than optional hardening.
- A manual `workflow_dispatch` path is sufficient for emergency recovery and avoids requiring a private-repository Action to trigger the public hub.
- Automatic per-push triggering is not solved by this Phase 1 design and is intentionally deferred.

## Implementation Checkpoint — 2026-09-25

Implemented on `main`:

- `.gitignore` blocks private checkout, environment, log, and report paths.
- `SECURITY.md` defines the public/private security boundary and incident response.
- `README.md` documents the two required Secrets and manual-run flow without revealing target identities.
- `.github/workflows/private-ci.yml` provides manual alias selection, read-only permissions, secret preflight, masked runtime target resolution, shallow private clone, origin redaction, Node runtime setup, sanitized CI execution, summary output, timeout, concurrency, and always-run cleanup.
- `scripts/common/run-ci.sh` detects supported Node package managers and runs existing install/lint/typecheck/test/build stages while suppressing private command output from public logs.
- Public repository search found no occurrences of the known private target repository names checked during this implementation pass.
- Official GitHub Actions are pinned to current major lines used by this implementation (`actions/checkout@v7`, `actions/setup-node@v7`); automatic package-manager caching is explicitly disabled.

Not yet executed:

- The required GitHub Actions Secrets have not been added by the user.
- No real private checkout has run from the public runner.
- No successful/failing real CI logs have been reviewed for leakage.
- No non-Node target adapter beyond safe SKIP behavior has been approved.

## Readiness Sign-off

- [x] Problem and recovery objective are defined.
- [x] Public repository / private target boundary is defined.
- [x] Read-only first principle is defined.
- [x] Private repository identities are excluded from committed configuration.
- [x] Production deploy is excluded.
- [x] Private-repository mutation is excluded.
- [x] Existing private workflows are preserved.
- [x] Rollback requires no private source change.
- [x] Public workflow and sanitized CI adapter are implemented.
- [ ] Required GitHub Secrets have not yet been added.
- [ ] No public-runner clone has yet been executed.
- [ ] No log-leakage validation has yet been executed.
- [ ] No target CI adapter has yet passed end-to-end.
- [ ] Automatic triggering has not been designed and is not authorized by this change.

## Security Review Gate

Before declaring implementation ready for six-target use, independently verify:

1. no private repository name is committed;
2. target identifiers are masked before use;
3. token values are never printed;
4. no private checkout is uploaded as artifact;
5. workspace/source directories are not cached;
6. failure logs do not dump source content;
7. cleanup runs on success and failure;
8. token permissions remain read-only and selected-repository scoped;
9. workflow cannot push to a target repository;
10. `pull_request_target` is not used with private-repository credentials.

## Conclusion

This change is now **implementation-ready but runtime-blocked on manual Secret configuration**.

The repository-side Phase 1 skeleton is in place. The next authorized operation is to add the two GitHub Actions Secrets, map one pilot alias, manually dispatch the workflow, and review both success and failure behavior before expanding to all six targets.

This review does not authorize production deployment migration, write access to any private repository, public disclosure of target identities, or deletion/disablement of existing private workflows.
