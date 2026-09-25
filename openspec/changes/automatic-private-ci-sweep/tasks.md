# Tasks: automatic-private-ci-sweep

## 1. Workflow trigger

- [x] Add a scheduled trigger to the existing Private CI Bridge.
- [x] Preserve `workflow_dispatch` with the current six alias choices.
- [x] Use a public-safe alias matrix for scheduled runs.
- [x] Keep manual runs to a one-item matrix containing the selected alias.
- [x] Add a `main` push regression trigger limited to `.github/workflows/private-ci.yml` and `scripts/common/**`.

## 2. Execution behavior

- [x] Set `fail-fast: false`.
- [x] Limit matrix parallelism to two.
- [x] Move per-target concurrency to job scope using the matrix alias.
- [x] Reuse the existing private checkout and CI adapter path without duplication.

## 3. Security boundary

- [x] Do not add private-repository write access.
- [x] Do not add a second token.
- [x] Keep target mapping in `PRIVATE_REPOS_JSON` only.
- [x] Keep source artifacts/caches disabled.
- [x] Preserve sanitized summary and temporary command-file isolation.
- [x] Preserve always-run workspace/auth cleanup.

## 4. Validation

- [x] Confirm GitHub parses the updated workflow: push-triggered regression run #17 was created from the new workflow.
- [ ] Manually dispatch one alias after the matrix refactor and confirm PASS.
- [ ] Observe the first scheduled sweep and confirm six aliases are created with max two concurrent.
- [ ] Review scheduled-run logs/artifacts for the same leakage criteria used in Phase 1.

## 5. Future option

- [ ] Consider a near-real-time webhook/GitHub App event bridge only if three-hour polling is too slow.

## 6. Hub regression trigger

- [x] Push regression is scoped to `main` only.
- [x] Push regression is path-filtered to workflow/adapter code only.
- [x] Regression run #17 was automatically created after the trigger commit.
- [x] Initial observation confirms `max-parallel: 2`: repo-01 and repo-02 started first while later aliases waited.
