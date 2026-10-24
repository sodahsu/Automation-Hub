# Tasks: Private CI coverage audit

- [ ] Confirm the six runtime aliases map to the intended repositories and identify each default branch through an authorized private view; record only alias and conclusion in public evidence, or mark `UNVERIFIED` if inaccessible.
- [ ] Update detector coverage selection to reject failed, cancelled, skipped, unverified, and stale CI as coverage.
- [ ] Ensure the health output explicitly covers repo-01 through repo-06 and Automation-Hub, marking missing evidence `UNVERIFIED`.
- [ ] Add focused regression checks for success, failure, skipped, unverified, stale revision, in-progress, and `dev` branch cases.
- [ ] Run focused checks, security audit, and inspect the resulting live sanitized summary; record command exit codes and run IDs.

## Rollback

Revert the workflow and shared-adapter changes together. Keep the prior workflow files and restore the explicit `UNVERIFIED` reporting behavior if any adapter change is rolled back separately.
