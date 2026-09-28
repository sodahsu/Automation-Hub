## ADDED Requirements

### Requirement: OpenSpec validation SHALL run for scoped pull requests

Automation-Hub SHALL run the existing OpenSpec strict validation workflow for pull requests targeting `main` when the changed paths include `openspec/**` or `.github/workflows/validate-openspec.yml`. The workflow SHALL listen for `opened`, `synchronize`, `reopened`, and `ready_for_review` events.

#### Scenario: Scoped pull request is opened or updated

- **WHEN** a pull request targets `main` and changes an OpenSpec path or the validation workflow
- **AND** the event action is `opened`, `synchronize`, `reopened`, or `ready_for_review`
- **THEN** the OpenSpec validation workflow SHALL be scheduled
- **AND** it SHALL use the existing strict validation command

#### Scenario: Unscoped pull request is opened or updated

- **WHEN** a pull request targets `main` but changes none of the scoped paths
- **THEN** this workflow SHALL NOT be scheduled solely because of that pull request

#### Scenario: Existing triggers remain available

- **WHEN** an `openspec/**` change is pushed to `main`
- **THEN** the existing `push` validation SHALL remain available
- **AND** `workflow_dispatch` SHALL remain available for manual execution

#### Scenario: Concurrent pull requests validate independently

- **WHEN** two different pull requests run the workflow concurrently
- **THEN** one PR's run SHALL NOT cancel the other PR's run
- **AND** a newer run for the same PR MAY cancel its older run

#### Scenario: Workflow permissions remain read-only

- **WHEN** the workflow runs for any supported event
- **THEN** it SHALL retain `contents: read`
- **AND** it SHALL NOT require private repository credentials or write permissions
