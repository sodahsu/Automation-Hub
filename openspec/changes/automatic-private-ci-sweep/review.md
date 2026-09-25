# Review: automatic-private-ci-sweep

## Design decision

The automation is implemented as a scheduled matrix inside the already-validated public bridge rather than as a separate dispatcher workflow. This avoids requiring `actions: write` on the public `GITHUB_TOKEN`, avoids another credential, and keeps all private checkout/CI behavior on the same tested code path.

## Security notes

- The schedule knows only aliases `repo-01` through `repo-06`.
- Real target identities remain inside `PRIVATE_REPOS_JSON`.
- The existing fine-grained PAT remains read-only and selected-repository scoped.
- No private repository is modified to obtain automatic triggering.
- Scheduled private-target runs are intentionally polling-based rather than private-repository push-event-based.

## Operational trade-off

A commit may wait up to roughly three hours before the next scheduled sweep. This is an explicit reliability/simplicity trade-off while private-repository Actions quota is unavailable. A future event bridge can reduce latency, but it would require additional infrastructure or credentials and is therefore outside this change.

## Validation status

Implementation is pending a manual post-refactor run and the first real scheduled sweep.

## Hub regression trigger

The bridge also runs a six-target regression when its own workflow or shared adapter code changes on `main`. This is deliberately path-scoped and does not create a private-repository event bridge. The first regression run was created automatically after the trigger commit, confirming that GitHub parsed the updated workflow. Initial job observation showed two targets running concurrently, matching `max-parallel: 2`.
