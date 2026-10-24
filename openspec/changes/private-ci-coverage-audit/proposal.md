# Proposal: Correct private CI coverage decisions

## Problem

The detector chooses the latest bridge job by alias but stores only its `status` and `started_at`. For completed jobs, it skips dispatch whenever the job started after the repository's latest `pushed_at`, without checking the job conclusion or whether any verification stage passed. A failed or unverified run can therefore suppress a needed run and appear covered. The runtime alias mapping is secret-only, so default branch mapping cannot be independently verified from this public repository.

## Proposed change

Make detector coverage decisions require evidence that the latest completed CI job succeeded and performed at least one target verification stage, and that its start is not older than the latest push. Make a green run with no verification stage fail so the PR status cannot report success. Preserve alias-only public output and keep all private repository names, refs, source, and credentials out of logs. Report unverifiable alias mappings and default branch coverage without guessing. Include Automation-Hub itself alongside the six aliases in the health audit output.

Do not add or expose the mapping in this public repository. If no authorized private-repository view is available, mark alias-to-repository and default-branch verification `UNVERIFIED`.

## Scope

`.github/workflows/detect-private-changes.yml`, shared CI adapter/reporting in `scripts/common/` and `.github/workflows/private-ci.yml`, plus focused safe regression checks.
