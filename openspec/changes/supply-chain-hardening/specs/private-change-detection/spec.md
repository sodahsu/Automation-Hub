## ADDED Requirements

### Requirement: Private CI dependency setup MUST use locked versions

Private CI **MUST** install project dependencies only from a supported, unambiguous lockfile using the package manager's frozen mode. A missing, conflicting, or inconsistent lockfile **MUST** fail setup without retrying an unlocked installation. Bridge-managed Python dependencies **MUST** use pinned versions and package hashes.

#### Scenario: Supported package manager lockfile is valid

- **WHEN** an alias has exactly one supported package-manager lockfile and it agrees with the project manifest
- **THEN** setup **MUST** use the matching frozen install command
- **AND** a successful install **MUST** proceed to that alias's existing required stages

#### Scenario: Lockfile is missing, conflicting, or inconsistent

- **WHEN** a Node-family alias has no supported lockfile, more than one supported lockfile, or a lockfile that does not match its manifest
- **THEN** setup **MUST** fail
- **AND** setup **MUST NOT** attempt an unlocked install

#### Scenario: Bridge-managed Python dependency is absent

- **WHEN** the content health adapter needs its bridge-managed Python dependency
- **THEN** installation **MUST** use the pinned requirements lock with hash verification
- **AND** an unavailable or mismatched locked artifact **MUST** fail the dependency stage
