# Tasks: public-ci-automation-hub

## 0. Governance / Boundary

- [x] 0.1 Confirm `Automation-Hub` is the public orchestration repository.
- [x] 0.2 Confirm six target repositories remain private.
- [x] 0.3 Confirm current priority is restoring CI while private Actions quota is unavailable.
- [x] 0.4 Establish public-safe aliases `repo-01` through `repo-06`.
- [x] 0.5 Prohibit publishing the alias-to-private-repository mapping in committed files.
- [ ] 0.6 Validate this OpenSpec change with the repository-supported OpenSpec strict command once CLI/config is available.

## 1. Repository Safety Skeleton

- [x] 1.1 Add `.gitignore` entries for `workspace/`, `repos/`, `tmp/`, `.env*`, and `*.log`.
- [x] 1.2 Add `SECURITY.md` describing public-repo/private-source boundaries.
- [x] 1.3 Add README architecture and manual-run instructions without private repository names.
- [x] 1.4 Ensure no committed config contains private repository names or clone URLs.

## 2. Secret Contract

- [x] 2.1 Document required secret `PRIVATE_REPOS_READ_TOKEN`.
- [x] 2.2 Document required secret `PRIVATE_REPOS_JSON`.
- [x] 2.3 Require the token to be fine-grained, selected-repository only, Contents read-only + Metadata read.
- [x] 2.4 Do not create, print, retrieve, or rotate secret values from repository code.
- [x] 2.5 Add a preflight failure if either required secret is unavailable.

## 3. Manual Dispatch Workflow

- [x] 3.1 Create a `workflow_dispatch` workflow accepting only a public-safe target alias; Phase 1 checks the private target's default branch only.
- [x] 3.2 Restrict alias values to `repo-01` through `repo-06`.
- [x] 3.3 Set workflow permissions to `contents: read`.
- [x] 3.4 Add per-target concurrency control.
- [x] 3.5 Add a bounded job timeout.
- [x] 3.6 Do not add `pull_request_target`.

## 4. Safe Target Resolution / Clone

- [x] 4.1 Resolve alias from `PRIVATE_REPOS_JSON` at runtime.
- [x] 4.2 Fail closed for unknown/empty/malformed targets.
- [x] 4.3 Mask the resolved repository identifier before subsequent commands.
- [x] 4.4 Clone into `workspace/` using `PRIVATE_REPOS_READ_TOKEN`.
- [x] 4.5 Avoid printing clone URL or remote configuration; redact the checkout's origin URL after clone.
- [x] 4.6 Use shallow fetch where compatible with target CI.
- [x] 4.7 Add `always()` cleanup removing private workspace.

## 5. CI Adapter

- [x] 5.1 Detect package manager from lockfile without modifying the checkout.
- [x] 5.2 Run repository-native dependency install for supported Node package managers.
- [x] 5.3 Run `lint` if present; otherwise mark SKIP.
- [x] 5.4 Run `typecheck` if present; otherwise mark SKIP.
- [x] 5.5 Run `test` if present; otherwise mark SKIP.
- [x] 5.6 Run `build` if present; otherwise mark SKIP.
- [x] 5.7 Do not invent missing package scripts.
- [ ] 5.8 Add explicit reviewed adapters for non-Node targets that need more than clone/adapter-SKIP validation.

## 6. Public Log / Artifact Gate

- [x] 6.1 Prohibit `cat`/dump of source files, notes, `.env`, or full environment.
- [x] 6.2 Prohibit `set -x` around authentication or target resolution.
- [x] 6.3 Disable source/workspace artifact upload.
- [x] 6.4 Do not cache `workspace/` or private source.
- [x] 6.5 Emit only sanitized stage status and safe aggregate metrics.
- [x] 6.6 Review failed runs #1–#3 and successful repo-01 run #4 for leakage; no known private repository names were found in the fetched job log and artifact count was zero.

## 7. One-Target Pilot

- [x] 7.1 User manually added `PRIVATE_REPOS_READ_TOKEN` with selected-repository read-only scope.
- [x] 7.2 User manually added `PRIVATE_REPOS_JSON`; runtime mapping is stored only as a GitHub Actions Secret.
- [x] 7.3 Run public-runner preflight and read-only private archive checkout for the pilot alias.
- [x] 7.4 Verify successful repo-01 run log contains no known private repository name and no source artifact; token and runtime target identifier remained masked.
- [x] 7.5 Repository-native sanitized CI adapter is implemented and ready for pilot execution.
- [x] 7.6 Record repo-01 evidence: package-json PASS, npm PASS, install PASS, canonical check:ci PASS; 15 test files / 135 tests passed.
- [x] 7.7 Phase 1 checkout is an archive without `.git`; the CI step receives no private-repository token, so the run has no repository write path.

## 8. Six-Target Rollout

- [x] 8.1 Add all six alias mappings in Secret only, not committed config.
- [x] 8.2 Validate each alias independently. repo-01, repo-02, repo-03, repo-04, and repo-06 PASS; repo-05 adapter runs correctly and surfaces a real private target contract failure.
- [x] 8.3 Confirm each target's package manager/runtime assumptions. repo-01 through repo-04 use Node 22 paths, repo-05 uses Python + Node 20.19.0 for OpenSpec, and repo-06 uses Python with sparse Git metadata for Vault Health.
- [x] 8.4 Confirm each target's supported CI stages. Generic Node `check:ci`, repo-04 dedicated governance/architecture adapter, repo-05 candidate-contract adapter, and repo-06 Vault Health adapter are all exercised.
- [x] 8.5 Confirm content-heavy targets use safe aggregate-only logging; repo-06 published only sanitized stage statuses, with no private report body or known private repository name in the fetched public log.
- [ ] 8.6 Run a six-target manual health sweep and capture sanitized summary.

## 9. Existing Private Workflows

- [x] 9.1 Leave existing private workflows unchanged during recovery.
- [ ] 9.2 Document which checks are now duplicated by the hub after each pilot target is mapped.
- [x] 9.3 Do not delete/disable private workflows without a separate explicit approval.
- [x] 9.4 Keep production deployment workflows outside this migration.

## 10. Follow-up Automation — Separate Decision

- [ ] 10.1 After manual hub stability, evaluate scheduled polling or event bridge.
- [ ] 10.2 If automatic triggering is required, create a separate OpenSpec change.
- [x] 10.3 Do not add private-repo write access merely to obtain automatic triggers.

## 11. Review / Completion

- [ ] 11.1 Independent security review of real-run logs, masking, artifacts, permissions, and cleanup.
- [x] 11.2 Verify committed repository content contains no known private target identifier or secret value.
- [x] 11.3 Verify repo-01 public-runner CI works end-to-end while private-repository hosted Actions quota remains unavailable.
- [ ] 11.4 Command-file isolation hardening is verified on repo-01; keep Phase 1 open while validating additional targets/adapters.

## Implementation checkpoint — 2026-09-25

Implemented on `main`:

- `.gitignore`
- `SECURITY.md`
- `README.md`
- `.github/workflows/private-ci.yml`
- `scripts/common/run-ci.sh`

Runtime configuration is complete. repo-01 and repo-02 have both passed end-to-end on the public runner; rollout is proceeding alias by alias.

## Security hardening checkpoint — after repo-01 run #4

- [x] Detect that private test tooling can write to the public `GITHUB_STEP_SUMMARY` even when stdout/stderr are suppressed.
- [x] Isolate `GITHUB_STEP_SUMMARY`, `GITHUB_OUTPUT`, `GITHUB_ENV`, and `GITHUB_PATH` to temporary sink files during untrusted private-repository CI execution.
- [x] Remove the private command-file sink directory during `always()` cleanup.
- [x] Re-run repo-01 (#5) and confirm private tooling no longer injects its own Job Summary content; only the hub-generated sanitized summary remains.

## Rollout checkpoint — repo-02 run #6

- [x] repo-02 read-only archive checkout PASS.
- [x] Node 22 / npm install PASS.
- [x] Canonical `check:ci` PASS.
- [x] Sanitized summary only; no private-generated Job Summary content.
- [x] No known private repository name hit in fetched job log.
- [x] Artifact count 0.

## Rollout checkpoint — repo-03 run #7

- [x] repo-03 read-only archive checkout PASS.
- [x] Node 22 / npm install PASS.
- [x] Canonical `check:ci` PASS.
- [x] Sanitized summary only; no private-generated Job Summary content.
- [x] No known private repository name hit in fetched job log.
- [x] Artifact count 0.

## Rollout checkpoint — repo-04 run #8

- [x] Generic read-only checkout / Node 22 / npm / `check:ci` path PASS.
- [x] Sanitized log review PASS; zero artifacts; no known private repository name hits.
- [x] Compare against the target's original private CI and identify coverage gap: package-level `check:ci` alone does not represent ShellCheck, governance, architecture, skill routing/audit, and spec-governance gates.
- [x] Add a dedicated public-safe `repo-04` adapter that mirrors the read-only validation gates without deployment, PR classification, or artifact upload.
- [x] Re-run repo-04 using the dedicated adapter and resolve runner/tooling compatibility gaps; all dedicated gates PASS.

## Runner correctness fix — after repo-04 dedicated-adapter run

- [x] Detect `run_stage()` exit-code propagation bug where a failing command could be reported as `FAIL (exit 0)` and the overall job could remain green.
- [x] Fix `run_stage()` to capture the command exit code inside the `else` branch and propagate the real non-zero status.
- [x] Re-run repo-04 under corrected failure semantics; ShellCheck behavior is now trustworthy.

## repo-04 ShellCheck semantic alignment

- [x] Confirm the original private CI runs ShellCheck with `severity: error` and excludes SC1090 / SC1091.
- [x] Update the public bridge repo-04 adapter to use the same ShellCheck severity semantics.
- [x] Re-run repo-04 after severity alignment; shellcheck-scripts and shellcheck-skills both PASS.

## Rollout checkpoint — repo-04 final dedicated-adapter run

- [x] All dedicated repo-04 gates PASS: ShellCheck, governance, architecture tests/contract/drift, skill resolver, registry, routing audit/matrix, runner integration, skill audit, shared-path audit, spec-governance, spec-truth-gate, and `check:ci`.
- [x] Fetched public job log contains no known private repository name hits.
- [x] Artifact count 0.
- [x] No private-generated Job Summary content.

## repo-05 adapter readiness

- [x] Inspect original `candidate-contract.yml`.
- [x] Add read-only adapter for unit tests, candidate contract validation, architecture JSON/doc validation, and OpenSpec strict validation.
- [x] Align repo-05 Node runtime with original private CI: Node 20.19.0.
- [x] Keep scheduled `upstream-watch` outside the per-run CI adapter; it is a separate monitoring concern.
- [x] Run repo-05 through the public bridge: adapter executes correctly and surfaces a real candidate-contract failure in the private target (one overdue active review checkpoint).

## repo-06 adapter readiness

- [x] Inspect the target's read-only Vault Health workflow and separate source-validation gates from write-oriented AI workflows.
- [x] Add a sparse read-only checkout path for repo-06 matching the target workflow's health-check scope instead of downloading the full large repository.
- [x] Preserve local Git metadata for `git ls-files` health logic while removing all remotes after checkout.
- [x] Add read-only Vault Health adapter: Python dependency setup, health unit tests, managed-skill sync, metadata normalizer, vault health, follow-up radar, advisory stale-fact audit, Hub/index drift gates, relation structural gate, canonical memory health, and source-link dry-run check.
- [x] Keep schedule-only claim harvest/backlog reporting out of manual CI and keep all AI generation/retry workflows out of the hub.
- [x] Replace YAML-sensitive askpass heredoc with a deterministic `printf`-generated helper.
- [x] Run repo-06 through the public bridge and resolve sparse-checkout authentication compatibility; final run PASS.

## repo-05 validation result

- [x] Public bridge reached the dedicated repo-05 adapter.
- [x] Unit tests PASS.
- [x] `candidate-contract` correctly fails on a real private-repository lifecycle rule rather than a bridge/runtime defect.
- [x] Exactly one active candidate is overdue: its `reviewBy` date is 2026-09-24 while status remains `researching` on 2026-09-25.
- [x] No automatic private-repository mutation was performed; status/date requires an explicit lifecycle decision in the private repo.

## repo-06 final validation result

- [x] Sparse read-only checkout PASS using the selected-repository PAT only during clone/materialization.
- [x] All remotes removed before CI execution.
- [x] python-deps PASS.
- [x] health-unit-tests PASS.
- [x] skill-sync PASS.
- [x] metadata-normalizer PASS.
- [x] vault-health PASS.
- [x] followup-radar PASS.
- [x] stale-fact-audit PASS.
- [x] hub-drift PASS.
- [x] index-drift PASS.
- [x] relation-health PASS.
- [x] memory-health PASS.
- [x] source-link-format PASS.
- [x] claim-harvest / source-backlog correctly SKIP because they are schedule-only.
- [x] Fetched public log contains no known private repository name hits and no private report body; `Vault Health` appears only in public adapter comments.
- [x] Artifact count 0.
