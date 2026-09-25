## ADDED Requirements

### Requirement: Public hub executes CI while target repositories remain private

The system SHALL execute Phase 1 CI from the public `Automation-Hub` repository while keeping all six target repositories private.

#### Scenario: CI is manually requested for a private target

- **WHEN** an authorized user manually dispatches the hub for a supported target alias
- **THEN** the job SHALL run on the public hub's standard GitHub-hosted runner
- **AND** the target repository SHALL remain private
- **AND** the workflow SHALL NOT change target repository visibility

### Requirement: Private target identity is runtime-only public metadata

Committed hub files SHALL use public-safe aliases `repo-01` through `repo-06`. The alias-to-private-repository mapping SHALL be supplied at runtime from a GitHub Secret and SHALL NOT be committed.

#### Scenario: Repository mapping is resolved

- **WHEN** the workflow resolves an alias to a private repository identifier
- **THEN** it SHALL mask the resolved identifier before subsequent commands
- **AND** SHALL NOT write the identifier into committed files, artifacts, or summaries

#### Scenario: Alias is unknown

- **WHEN** a requested alias is absent from the secret mapping
- **THEN** the workflow SHALL fail closed before clone
- **AND** SHALL NOT guess or fall back to another repository

### Requirement: Phase 1 private access is least-privilege read-only

The hub SHALL authenticate to selected private repositories using a fine-grained token whose Phase 1 repository permissions are limited to the read access required for clone/CI.

#### Scenario: Target checkout is prepared

- **WHEN** the hub clones a selected private repository
- **THEN** authentication SHALL come from a GitHub Secret
- **AND** the workflow SHALL NOT commit, push, tag, merge, or create branches in that repository

#### Scenario: Write capability is required

- **WHEN** a future use case requires write access
- **THEN** this Phase 1 workflow SHALL NOT silently expand token permissions
- **AND** write access SHALL require a separate reviewed OpenSpec change

### Requirement: CI uses repository-native checks without source modification

The hub SHALL execute only checks supported by the target repository's existing runtime/configuration and SHALL NOT modify application source or invent missing project scripts.

#### Scenario: Standard Node CI scripts exist

- **WHEN** the target repository exposes supported lint, typecheck, test, or build scripts
- **THEN** the hub SHALL run the applicable scripts using the repository's existing package-manager/lockfile contract

#### Scenario: Optional script is absent

- **WHEN** a target does not define an optional CI stage
- **THEN** the hub SHALL report that stage as `SKIP`
- **AND** SHALL NOT add or synthesize a replacement script

#### Scenario: Repository runtime is not safely recognized

- **WHEN** the generic adapter cannot determine a safe supported runtime
- **THEN** the job SHALL stop or route to an explicitly reviewed target adapter
- **AND** SHALL NOT mutate the checkout to make it fit the generic adapter

### Requirement: Public logs do not expose private source or secrets

The hub SHALL treat workflow logs as public output and SHALL minimize them to sanitized status information.

#### Scenario: CI succeeds

- **WHEN** CI stages complete
- **THEN** the summary MAY show target alias and PASS/FAIL/SKIP state
- **AND** SHALL NOT print token values, secret mappings, note bodies, source-file contents, environment files, or unapproved private identifiers

#### Scenario: CI fails

- **WHEN** a CI stage fails
- **THEN** the workflow SHALL identify the failing stage with the minimum diagnostic output needed
- **AND** SHALL NOT respond by dumping the private workspace or full environment

### Requirement: Private checkout is ephemeral and non-exportable

The private repository checkout SHALL exist only in an ephemeral runner workspace for the current job.

#### Scenario: Job completes or fails

- **WHEN** the job reaches cleanup
- **THEN** the workflow SHALL remove the private workspace
- **AND** cleanup SHALL be configured to run even after earlier step failure

#### Scenario: Artifact upload is considered

- **WHEN** the workflow would upload `workspace/`, source files, vault files, environment files, or source-bearing build output
- **THEN** the upload SHALL be rejected in Phase 1

### Requirement: Source checkout is not cached

The hub SHALL NOT cache private source directories or the whole private workspace.

#### Scenario: Dependency caching is later introduced

- **WHEN** a dependency-manager cache is proposed
- **THEN** it SHALL be limited to dependency cache material verified not to contain private source or credentials
- **AND** SHALL require explicit review before enablement

### Requirement: CI jobs are bounded and isolated

Each target execution SHALL have bounded runtime and concurrency behavior.

#### Scenario: Duplicate runs target the same alias

- **WHEN** multiple runs for the same target overlap
- **THEN** the workflow SHALL apply a target-scoped concurrency policy
- **AND** SHALL avoid uncontrolled duplicate execution

#### Scenario: CI hangs

- **WHEN** execution exceeds the configured job timeout
- **THEN** GitHub Actions SHALL terminate the job
- **AND** cleanup SHALL still be attempted

### Requirement: Production mutation remains outside the recovery path

The Phase 1 hub SHALL restore validation only and SHALL NOT perform production deployment or other production mutation.

#### Scenario: Existing target repository has deploy workflows

- **WHEN** a target repository contains deploy/release/publish workflows
- **THEN** those workflows SHALL remain outside this hub change
- **AND** this change SHALL NOT delete, disable, or rewrite them

### Requirement: Existing private workflows remain a rollback reference

The recovery implementation SHALL coexist with existing private-repository workflow definitions.

#### Scenario: Hub recovery is not acceptable

- **WHEN** the hub is disabled, fails security review, or private Actions capacity returns
- **THEN** no source rollback SHALL be required in any target repository
- **AND** the existing private workflows SHALL remain available as the prior reference path
