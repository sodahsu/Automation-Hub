# Design: Private CI coverage audit

The detector must distinguish a completed run from a passing and meaningful verification. Its history record should include the job conclusion and sanitized verification counts (or equivalent public-safe evidence), and only a completed successful run with at least one non-setup verification PASS may cover a push. Missing history, failed/cancelled/skipped jobs, and UNVERIFIED runs must cause a retry or an explicit non-healthy decision; a running job may produce WAIT only when its start time is not older than the latest push.

The target repository archive request without a SHA uses its default branch; do not infer or expose the secret alias mapping. The detector's `ref: main` selects the public Automation-Hub workflow revision and is not a private target branch. Preserve the six public aliases and do not log private command output. Mark default-branch mapping `UNVERIFIED` when no authorized private view exists.

The health audit should report six monitored aliases plus Automation-Hub, each with a current revision/result or an explicit `UNVERIFIED` state. Alias mappings must be validated in the private runtime and must never be committed or included in public logs or reports.

## Validation and safety

- Add focused self-checks for passing, failing, cancelled, skipped, unverified, stale-revision and `dev`-default-branch cases.
- Run the repository's security audit and focused adapter/detector checks; inspect a live run using only sanitized summaries and error messages.
- Rollback: revert the detector and adapter change together; retain the preceding workflow behavior and documented `UNVERIFIED` limitation. No private source or secret changes are part of this change.
