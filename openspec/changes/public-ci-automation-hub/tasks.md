# Tasks: public-ci-automation-hub

## 0. Governance / Boundary

- [x] 0.1 Confirm `Automation-Hub` is the public orchestration repository.
- [x] 0.2 Confirm six target repositories remain private.
- [x] 0.3 Confirm current priority is restoring CI while private Actions quota is unavailable.
- [x] 0.4 Establish public-safe aliases `repo-01` through `repo-06`.
- [x] 0.5 Prohibit publishing the alias-to-private-repository mapping in committed files.
- [ ] 0.6 Validate this OpenSpec change with the repository-supported OpenSpec strict command once CLI/config is available.

## 1. Repository Safety Skeleton

- [ ] 1.1 Add `.gitignore` entries for `workspace/`, `repos/`, `tmp/`, `.env*`, and `*.log`.
- [ ] 1.2 Add `SECURITY.md` describing public-repo/private-source boundaries.
- [ ] 1.3 Add README architecture and manual-run instructions without private repository names.
- [ ] 1.4 Ensure no committed config contains private repository names or clone URLs.

## 2. Secret Contract

- [ ] 2.1 Document required secret `PRIVATE_REPOS_READ_TOKEN`.
- [ ] 2.2 Document required secret `PRIVATE_REPOS_JSON`.
- [ ] 2.3 Require the token to be fine-grained, selected-repository only, Contents read-only + Metadata read.
- [ ] 2.4 Do not create, print, retrieve, or rotate secret values from repository code.
- [ ] 2.5 Add a preflight failure if either required secret is unavailable.

## 3. Manual Dispatch Workflow

- [ ] 3.1 Create a `workflow_dispatch` workflow accepting target alias and optional ref.
- [ ] 3.2 Restrict alias values to `repo-01` through `repo-06`.
- [ ] 3.3 Set workflow permissions to `contents: read`.
- [ ] 3.4 Add per-target concurrency control.
- [ ] 3.5 Add a bounded job timeout.
- [ ] 3.6 Do not add `pull_request_target`.

## 4. Safe Target Resolution / Clone

- [ ] 4.1 Resolve alias from `PRIVATE_REPOS_JSON` at runtime.
- [ ] 4.2 Fail closed for unknown/empty/malformed targets.
- [ ] 4.3 Mask the resolved repository identifier before subsequent commands.
- [ ] 4.4 Clone into `workspace/` using `PRIVATE_REPOS_READ_TOKEN`.
- [ ] 4.5 Avoid printing clone URL or remote configuration.
- [ ] 4.6 Use shallow fetch where compatible with target CI.
- [ ] 4.7 Add `always()` cleanup removing private workspace.

## 5. CI Adapter

- [ ] 5.1 Detect package manager from lockfile without modifying the checkout.
- [ ] 5.2 Run repository-native dependency install.
- [ ] 5.3 Run `lint` if present; otherwise mark SKIP.
- [ ] 5.4 Run `typecheck` if present; otherwise mark SKIP.
- [ ] 5.5 Run `test` if present; otherwise mark SKIP.
- [ ] 5.6 Run `build` if present; otherwise mark SKIP.
- [ ] 5.7 Do not invent missing package scripts.
- [ ] 5.8 Route non-Node targets to explicit reviewed adapters.

## 6. Public Log / Artifact Gate

- [ ] 6.1 Prohibit `cat`/dump of source files, notes, `.env`, or full environment.
- [ ] 6.2 Prohibit `set -x` around authentication or target resolution.
- [ ] 6.3 Disable source/workspace artifact upload.
- [ ] 6.4 Do not cache `workspace/` or private source.
- [ ] 6.5 Emit only sanitized stage status and safe aggregate metrics.
- [ ] 6.6 Review a failed run as well as a successful run for leakage.

## 7. One-Target Pilot

- [ ] 7.1 User manually adds `PRIVATE_REPOS_READ_TOKEN`.
- [ ] 7.2 User manually adds `PRIVATE_REPOS_JSON` with only one pilot alias initially.
- [ ] 7.3 Run clone-only preflight from public runner.
- [ ] 7.4 Verify no target source/name/token leakage beyond approved masked metadata.
- [ ] 7.5 Enable repository-native CI adapter for pilot.
- [ ] 7.6 Record PASS/FAIL/SKIP evidence.
- [ ] 7.7 Confirm target repository has no new commits/tags/branches from the run.

## 8. Six-Target Rollout

- [ ] 8.1 Add remaining alias mappings in Secret only, not committed config.
- [ ] 8.2 Validate each alias independently.
- [ ] 8.3 Confirm each target's package manager/runtime assumptions.
- [ ] 8.4 Confirm each target's supported CI stages.
- [ ] 8.5 Confirm content-heavy targets use safe aggregate-only logging.
- [ ] 8.6 Run a six-target manual health sweep and capture sanitized summary.

## 9. Existing Private Workflows

- [ ] 9.1 Leave existing private workflows unchanged during recovery.
- [ ] 9.2 Document which checks are now duplicated by the hub.
- [ ] 9.3 Do not delete/disable private workflows without a separate explicit approval.
- [ ] 9.4 Keep production deployment workflows outside this migration.

## 10. Follow-up Automation — Separate Decision

- [ ] 10.1 After manual hub stability, evaluate scheduled polling or event bridge.
- [ ] 10.2 If automatic triggering is required, create a separate OpenSpec change.
- [ ] 10.3 Do not add private-repo write access merely to obtain automatic triggers.

## 11. Review / Completion

- [ ] 11.1 Independent security review of logs, masking, artifacts, permissions, and cleanup.
- [ ] 11.2 Verify repository diff contains no secret or private target identifier.
- [ ] 11.3 Verify public-runner CI works while private-repository hosted Actions quota remains unavailable.
- [ ] 11.4 Mark Phase 1 complete only after at least one real target passes end-to-end.
