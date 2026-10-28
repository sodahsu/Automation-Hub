## MODIFIED Requirements

### Requirement: Private CI MUST publish sanitized stage evidence

Private CI **MUST** serialize the existing stage rows into a versioned JSON evidence file and publish that file as a run-scoped artifact. This behavior follows cross-repository change `hub-stage-evidence-20261028`, section "跨倉契約 v1".

#### Scenario: Stage evidence is published

- **WHEN** a target CI run reaches its summary publication steps
- **THEN** the CI script **MUST** write UTF-8 JSON from the same rows used by the Markdown summary
- **AND** the JSON **MUST** contain only `schemaVersion`, `target`, and `stages` at the top level
- **AND** each stage **MUST** contain only its name and enumerated status
- **AND** the workflow **MUST** upload one `stage-evidence.json` file as `hub-stage-evidence-<alias>` with `if: always()`, `if-no-files-found: warn`, and 30-day retention
- **AND** an upload failure **MUST NOT** change the CI job conclusion
- **AND** the security audit **MUST** allow this sole sanitized artifact only in `private-ci.yml` and reject other workflows, additional artifact steps, or path changes

#### Scenario: Failure details and invalid stage names

- **WHEN** a stage status includes a parenthetical reason, or any stage name fails `^[A-Za-z0-9:_-]{1,64}$`
- **THEN** the JSON **MUST NOT** contain the parenthetical reason
- **AND** if a name is invalid, `stages` **MUST** be empty

#### Scenario: Evidence output is disabled

- **WHEN** the optional fourth `run-ci.sh` argument is empty
- **THEN** the script **MUST NOT** write an evidence file
- **AND** existing Markdown output and exit codes **MUST** remain unchanged
