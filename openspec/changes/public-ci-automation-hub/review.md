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

- GitHub Actions Secrets are configured and working with selected-repository read-only access.
- repo-01 and repo-02 have completed real private read-only checkouts from the public runner.
- Successful and failed runs have been reviewed for leakage; current sanitized-path checks show no known private repository name hits and zero artifacts.
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
- [x] Required GitHub Secrets are configured.
- [x] Public-runner read-only checkout has been executed successfully.
- [x] Log-leakage validation has been executed on failed and successful runs.
- [x] Node/npm canonical `check:ci` adapter has passed end-to-end.
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

This change is now **operational for the validated Node/npm targets and continuing through staged six-target rollout**.

The repository-side Phase 1 implementation is active. repo-01 and repo-02 have passed end-to-end with read-only archive checkout, sanitized CI execution, command-file isolation, and zero artifacts. Remaining aliases should be validated one at a time before Phase 1 sign-off.

This review does not authorize production deployment migration, write access to any private repository, public disclosure of target identities, or deletion/disablement of existing private workflows.

## Pilot Evidence — repo-01 run #4

- Result: PASS.
- Public runner completed the read-only archive checkout, Node setup, dependency install, and canonical `check:ci` path.
- Sanitized bridge result: `package-json` PASS, package manager npm PASS, install PASS, `check:ci` PASS.
- Test evidence exposed by the target before hardening: 15 test files / 135 tests passed.
- Connector-side log review found no occurrences of the known private repository names checked for this implementation pass.
- Artifact count: 0.
- The successful run revealed one additional boundary: private test tooling could append its own report to `GITHUB_STEP_SUMMARY`. The workflow has since been hardened so child CI receives isolated temporary command-file paths for `GITHUB_STEP_SUMMARY`, `GITHUB_OUTPUT`, `GITHUB_ENV`, and `GITHUB_PATH`. This hardening still requires one real-run verification before Phase 1 sign-off.

## Security Hardening Verification — repo-01 run #5

- Result: PASS.
- The private target completed read-only checkout, Node setup, install, and canonical `check:ci` successfully.
- Public Job Summary contained only the hub-generated sanitized target/stage table.
- The prior private-generated Vitest Test Report did not appear.
- Connector-side log review found no known private repository name hits.
- Artifact count remained 0.
- `GITHUB_STEP_SUMMARY`, `GITHUB_OUTPUT`, `GITHUB_ENV`, and `GITHUB_PATH` isolation is therefore verified for the pilot path.

## Rollout Evidence — repo-02 run #6

- Result: PASS.
- Read-only archive checkout completed successfully.
- Node 22 / npm install completed successfully.
- Canonical `check:ci` completed successfully.
- Public Job Summary contained only the hub-generated sanitized target/stage table.
- Connector-side log review found no known private repository name hits.
- Artifact count: 0.

## Rollout Evidence — repo-03 run #7

- Result: PASS.
- Read-only archive checkout completed successfully.
- Node 22 / npm install completed successfully.
- Canonical `check:ci` completed successfully.
- Public Job Summary contained only the hub-generated sanitized target/stage table.
- Connector-side log review found no known private repository name hits.
- Artifact count: 0.

## Coverage Review — repo-04 run #8

- Generic bridge result: PASS.
- Security boundary: PASS (no known private repository name hits in fetched log; artifact count 0; no private Job Summary injection).
- Coverage finding: the target's original private CI contains substantially more validation than its package-level `check:ci`, including ShellCheck, governance, architecture contracts/drift, skill resolver/routing/integration audits, skill audit, spec-governance tests, and spec-truth-gate.
- Action: a dedicated `repo-04` adapter has been added to mirror those read-only gates. Event classification, deployment/mutation, and failure-artifact upload remain intentionally excluded from the public bridge.
- Status: requires a fresh repo-04 run before this alias can be marked equivalent enough for recovery use.

## Runner Correctness Finding — repo-04 dedicated-adapter run

The dedicated adapter exposed a harness bug in `run_stage()`: failure status was read after the `if` statement rather than inside the failing branch. In Bash this could yield status 0, producing contradictory `FAIL (exit 0)` rows and allowing the job to finish green. The helper has been corrected to capture `$?` immediately in the `else` branch and return the real non-zero code. The repo-04 adapter must be re-run before its ShellCheck state is considered valid.

## repo-04 ShellCheck Alignment

The first corrected dedicated-adapter run exposed a real non-zero ShellCheck status, but comparison with the original private CI showed a semantic mismatch: the private workflow configures ShellCheck with `severity: error`, while the bridge initially used ShellCheck's default severity handling. The bridge has been corrected to use `--severity=error` and the same SC1090 / SC1091 exclusions. A new repo-04 run is required before concluding that the private repository itself has ShellCheck errors.

## repo-04 Final Dedicated-Adapter Verification

- Result: PASS.
- All mirrored read-only gates passed: ShellCheck scripts/skills, governance, architecture unit/contract/drift checks, skill resolver, registry, routing audit/matrix, runner integration, skill audit, shared-path audit, spec-governance tests, spec-truth-gate, and canonical `check:ci`.
- Connector-side log review found no known private repository name hits.
- Artifact count: 0.
- No private-generated Job Summary content was observed.
- repo-04 is now sufficiently covered for Phase 1 CI recovery.

## repo-05 Adapter Design

The target's primary CI workflow is contract-oriented rather than package-oriented. The public bridge now mirrors the read-only parts of that workflow: Python unit tests, candidate contract validation, architecture JSON/doc validation, and `@fission-ai/openspec@1.8.0 validate --all --strict`. The bridge uses Node 20.19.0 for this alias to match the original workflow. The separate scheduled upstream-watch workflow is intentionally not folded into per-run CI because it is external monitoring/reporting rather than a source-validation gate; it remains a later automation concern.

## repo-06 Adapter Design

The target is a large content repository whose primary validation path is a read-only Vault Health workflow. The bridge now uses a token-scoped sparse Git checkout for the same health-check directories instead of downloading the full repository archive. After checkout, all remotes are removed; local Git metadata is retained only because the target's health inventory uses `git ls-files`. The CI step receives no private-repository token.

The adapter mirrors the manual/read-only validation path: pinned PyYAML installation, health unit tests, managed skill sync, metadata normalizer check, vault health, follow-up radar, stale-fact audit as advisory, Hub and index drift gates, relation-graph structural validation, canonical memory health, and source-link dry-run validation. Schedule-only claim-harvest/backlog reporting is marked SKIP, and write-oriented Claude/Gemini/retry workflows remain outside this recovery change.

## repo-05 Real Target Result

The dedicated adapter is functioning correctly. Unit tests passed and the next stage, candidate-contract validation, failed on an actual private-repository lifecycle rule rather than an Automation-Hub defect. The private catalog contains exactly one active candidate whose review checkpoint expired on 2026-09-24 while its status remains `researching`; the candidate's decision record explicitly identifies that date as its review checkpoint. The hub intentionally leaves this red: silently converting the gate to advisory or auto-extending the date would no longer match the original private CI semantics. No private-repository content was modified.

## repo-06 Final Validation

- Result: PASS.
- The large content target completed sparse read-only checkout and all intended manual Vault Health gates successfully.
- The selected-repository PAT was used only for clone and lazy sparse materialization; all remotes were removed before CI execution.
- All structural/read-only stages passed: Python dependency setup, health unit tests, skill sync, metadata normalizer, vault health, follow-up radar, stale-fact audit, Hub drift, index drift, relation health, canonical memory health, and source-link dry-run validation.
- Schedule-only claim-harvest and source-backlog stages were correctly skipped.
- Public log review found no known private repository name hits and no private report body. The phrase `Vault Health` appears only in public orchestration comments.
- Artifact count: 0.

## Six-target Rollout Status

The public recovery path has now been exercised against all six aliases. Five targets complete successfully end-to-end. The remaining target, repo-05, reaches and executes its dedicated adapter correctly but fails on one genuine lifecycle contract violation in the private repository: an active research candidate whose review checkpoint expired on 2026-09-24. This is target debt, not bridge failure, so the hub preserves the red status instead of weakening or bypassing the private CI rule.

Operationally, Phase 1 has achieved its recovery objective: public GitHub-hosted Actions can read the selected private repositories with a fine-grained read-only token and execute sanitized CI without changing repository visibility or requiring private-repository hosted Actions minutes. Automatic per-push triggering and any private-repository mutation remain outside this change.

## repo-05 Closure Verification

The single genuine lifecycle debt surfaced by the bridge has been resolved in the private target. The expired reference-only research candidate was formally closed as `archived`; the stale review deadline was removed and the candidate decision now records the 2026-09-25 closure rationale. This avoids gaming the gate by extending a date without new evaluation evidence.

The existing repo-05 workflow run was then re-run as attempt #2. Result: PASS. Connector-side review found no known private repository name hits in the public job log and artifact count remained 0.

## Final Phase 1 Rollout State

All six aliases now execute successfully through the public Automation-Hub path. The recovery objective is met: private repositories remain private; the fine-grained token is selected-repository and read-only; public GitHub-hosted runners execute sanitized CI; private source/report bodies are not uploaded as artifacts; and no target repository write access is required for CI recovery.
