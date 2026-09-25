# Proposal: automatic-private-ci-sweep

## Why

Phase 1 restored read-only CI for all six private targets through the public Automation-Hub, but every run still requires a manual `workflow_dispatch`. Because the private repositories currently cannot rely on their own GitHub-hosted Actions quota, the automation layer must originate from the public hub rather than from a private-repository workflow.

The safest next step is a scheduled public sweep that reuses the already-validated private CI bridge. It must not add private-repository write access, publish target identities, or duplicate the tested CI adapters.

## What Changes

1. Extend the existing Private CI Bridge workflow with a scheduled trigger.
2. Keep manual single-target dispatch unchanged.
3. On schedule, expand execution to aliases `repo-01` through `repo-06`.
4. Use `fail-fast: false` so one failing target does not suppress the remaining targets.
5. Limit scheduled parallelism to two targets at a time.
6. Preserve the existing read-only token, secret mapping, sanitized logs, zero-artifact policy, and cleanup behavior.
7. Add a hub-only push regression trigger for changes to the bridge workflow or shared adapter code on `main`.
8. Keep deployment, private-repository mutation, and private-repository push-event bridge infrastructure out of this change.

## Schedule

The public sweep runs every three hours at minute 23 UTC:

```text
23 */3 * * *
```

The non-zero minute intentionally avoids the most common top-of-hour scheduling hotspot.

## Scope

- Automation-Hub only.
- Existing `.github/workflows/private-ci.yml`.
- Six public-safe aliases only.
- Scheduled CI sweep plus existing manual single-target execution.
- Hub-only push regression sweep when bridge code changes on `main`.

## Non-Goals

- No private repository workflow edits.
- No private repository write token.
- No private-repository webhook relay, GitHub App event bridge, or external server.
- No production deploy migration.
- No public alias-to-repository mapping.
- No cache/artifact containing private source.
- No disabling of existing private workflows.

## Acceptance

- Manual dispatch still runs exactly one selected alias.
- Scheduled dispatch runs all six aliases.
- A failure in one scheduled alias does not cancel the remaining aliases.
- At most two target jobs run concurrently in one scheduled sweep.
- Existing sanitized CI adapters are reused without duplicating their implementation.
- Token remains selected-repository and read-only.
- No private repository name is committed or printed intentionally.
- Existing cleanup and command-file isolation remain active.
