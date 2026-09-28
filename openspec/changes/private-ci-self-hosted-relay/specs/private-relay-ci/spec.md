## ADDED Requirements

### Requirement: Private CI MUST execute on a controlled self-hosted runner

Private source CI **MUST** run only on a runner matching `self-hosted` and the reviewed `private-ci` label. The workflow **MUST NOT** fall back to a GitHub-hosted runner when the controlled runner is unavailable.

#### Scenario: Controlled runner unavailable

- **WHEN** no online runner matches the `private-ci` label
- **THEN** the request **MUST** remain unavailable or queued
- **AND** the workflow **MUST NOT** retrieve private source on `ubuntu-latest` or another public runner

#### Scenario: Untrusted workflow ref

- **WHEN** the workflow ref is not `refs/heads/main`
- **THEN** the workflow **MUST** fail before injecting private credentials
- **AND** it **MUST NOT** execute target source or CI commands

### Requirement: Private CI MUST separate baseline and PR provenance

The workflow **MUST** distinguish `baseline` from `pr-exact-sha` mode. Baseline results **MUST** carry default-branch provenance. PR results **MUST** carry pull-request-head provenance and **MUST NOT** be consumed by default-branch baseline detection.

#### Scenario: Baseline request

- **WHEN** a manual or detector request has no PR request
- **THEN** the relay **MUST** resolve the target default branch and execute that revision
- **AND** the public summary **MUST** identify baseline mode without exposing private identity

#### Scenario: PR exact-SHA request

- **WHEN** a manual request supplies a positive numeric PR number for supported `repo-04`
- **AND** the private PR is open, same-repository, and targets the target default branch
- **THEN** the relay **MUST** resolve the PR head SHA through read-only API metadata
- **AND** execute the existing repo-04 adapter against that exact SHA
- **AND** re-check the PR head after execution before publishing PASS

### Requirement: Unsafe PR requests MUST fail closed

PR mode **MUST** reject non-numeric PR numbers, closed or merged PRs, fork heads, wrong base repositories, wrong base branches, malformed head SHA, unavailable metadata, head changes, unsupported aliases, and non-main Hub workflow refs.

#### Scenario: PR head changes during execution

- **WHEN** the read-only post-run head SHA differs from the pre-run head SHA or cannot be read
- **THEN** the result **MUST** be failed or unverified
- **AND** the workflow **MUST NOT** publish a valid PASS

### Requirement: Private credentials MUST stay in the relay boundary

Private source credentials **MUST** be injected only into checkout/metadata steps on the controlled runner. Target CI **MUST NOT** receive private read tokens, Hub dispatch tokens, runner registration tokens, or unbounded environment dumps.

#### Scenario: Target adapter executes

- **WHEN** `scripts/common/run-ci.sh` runs a repository-native adapter
- **THEN** private credentials **MUST NOT** be present in the target process environment
- **AND** raw stdout/stderr **MUST** remain in runner temporary storage

### Requirement: Public output MUST be sanitized and cleanup MUST be terminal-state complete

Public output **MUST** contain only alias, mode, allow-listed stage status, exit code, and duration. It **MUST NOT** contain private repository identifiers, branch/ref, PR number, SHA, source path, raw logs, API response, or token. Workspace and temporary sensitive files **MUST** be removed after success, failure, timeout, cancellation, and validation rejection.

#### Scenario: Any terminal state

- **WHEN** CI succeeds, fails, times out, is cancelled, or rejects a request
- **THEN** cleanup **MUST** attempt to remove workspace, metadata, archive, head context, askpass, command sinks, and raw logs
- **AND** the result **MUST** preserve baseline/PR provenance without publishing private identity
