# Automation Hub — OpenSpec Project

## Purpose

`Automation-Hub` is a public orchestration repository used to run CI and repository health checks for six private repositories without moving their source code, notes, or deployment credentials into this repository.

The immediate objective is to restore CI capability while private-repository GitHub-hosted Actions quota is unavailable.

## Governance

- This repository is public. Treat every committed file, workflow, log, artifact, cache key, and summary as public information.
- Private repository names, clone URLs, source code, note content, environment values, deployment credentials, and tokens SHALL NOT be committed here.
- Private repositories are addressed by public-safe aliases only: `repo-01` through `repo-06`.
- The alias-to-repository mapping SHALL be provided at runtime through GitHub Secrets or another non-public configuration channel.
- Phase 1 access SHALL be read-only.
- Production deployment, billing changes, repository visibility changes, branch protection changes, secret rotation, and writes to private repositories are outside the initial scope.
- Existing workflows inside private repositories SHALL remain untouched until the hub is validated and an explicit migration decision is made.

## OpenSpec Workflow

Behavioral or architectural changes to this repository SHOULD be captured under:

`openspec/changes/<change-id>/`

An active change SHOULD contain:

- `proposal.md`
- `design.md`
- `tasks.md`
- `review.md`
- `specs/**/spec.md`

Canonical capabilities MAY be promoted later to `openspec/specs/` after implementation and review.

## Initial Change

The initial change is:

`public-ci-automation-hub`

It defines the emergency read-only public-runner architecture for restoring CI across six private repositories.
