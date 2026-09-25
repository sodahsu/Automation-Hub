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
- [ ] 8.2 Validate each alias independently. repo-01, repo-02, and repo-03 are PASS; repo-04 generic path PASS but requires dedicated-adapter revalidation.
- [ ] 8.3 Confirm each target's package manager/runtime assumptions. repo-01, repo-02, and repo-03 are confirmed Node 22 + npm.
- [ ] 8.4 Confirm each target's supported CI stages. repo-01, repo-02, and repo-03 are confirmed canonical `check:ci`.
- [ ] 8.5 Confirm content-heavy targets use safe aggregate-only logging.
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
- [ ] Re-run repo-04 using the dedicated adapter and resolve any runner/tooling compatibility gaps.
