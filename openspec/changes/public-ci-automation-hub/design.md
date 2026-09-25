# Design: public-ci-automation-hub

## Decision 1 — Public orchestrator, private source

`Automation-Hub` is the only public execution repository. It SHALL contain workflows, generic scripts, security policy, and public-safe aliases only.

The six target repositories remain private and are cloned into an ephemeral runner workspace only for the duration of a job.

No private checkout is copied back into `Automation-Hub`.

## Decision 2 — Do not commit private repository names

Committed configuration SHALL identify targets only as:

```text
repo-01
repo-02
repo-03
repo-04
repo-05
repo-06
```

The real mapping SHALL live in a GitHub Secret such as:

`PRIVATE_REPOS_JSON`

Conceptual shape only:

```json
{
  "repo-01": "<owner/private-repository>",
  "repo-02": "<owner/private-repository>"
}
```

The real values SHALL NOT appear in this repository.

Before any resolved repository identifier is used by a shell step, the workflow SHALL mask it with the GitHub log masking command.

## Decision 3 — Separate authentication from target mapping

Use two independent secrets:

- `PRIVATE_REPOS_READ_TOKEN` — fine-grained token scoped to the six selected private repositories, Phase 1 read-only.
- `PRIVATE_REPOS_JSON` — alias-to-repository mapping.

This prevents committed workflows from containing repository identities and prevents target configuration from being embedded into the token itself.

No write token is part of this change.

## Decision 4 — Manual dispatch is the emergency trigger

Initial recovery uses `workflow_dispatch` with an alias input.

Reason:

- it works even while private-repository Actions cannot run;
- it does not require modifying target repositories;
- it keeps the recovery path observable;
- it avoids introducing webhook/GitHub App infrastructure during the emergency fix.

Automatic polling, webhook dispatch, or per-commit orchestration MAY be proposed later as a separate change after the read-only hub is stable.

## Decision 5 — Clone through an ephemeral workspace

Each job SHALL:

1. resolve alias to repository from the secret mapping;
2. mask the resolved identifier;
3. create an ephemeral `workspace/`;
4. clone only the requested ref/depth required for CI;
5. run checks;
6. summarize status;
7. remove the workspace in an `always()` cleanup step.

The public repository's `.gitignore` SHALL exclude `workspace/`, `repos/`, `tmp/`, `.env*`, and logs.

## Decision 6 — Repository-native CI, no invented scripts

The hub MAY detect package manager by lockfile:

- `pnpm-lock.yaml` → pnpm
- `package-lock.json` → npm
- `yarn.lock` → yarn
- `bun.lock` / `bun.lockb` → bun

For Node-family repositories, the hub SHALL inspect available package scripts and execute supported checks in this order where present:

1. install
2. lint
3. typecheck
4. test
5. build

If a script does not exist, report `SKIP`.

The hub SHALL NOT edit `package.json`, create missing scripts, update lockfiles, install unrequested global project dependencies, or "fix" application code.

Non-Node repositories SHALL use explicitly reviewed repository-specific adapters rather than generic guessing.

## Decision 7 — Obsidian / content repositories require non-content logging

For content-heavy targets, especially vault-style repositories, checks MAY inspect files internally but SHALL NOT print note bodies or source documents into public Actions logs.

Allowed public output is aggregate status such as:

```text
Health check: PASS
Broken links: 0
Validation: PASS
```

File contents, note titles that are considered private metadata, and path dumps SHALL be avoided unless explicitly approved.

## Decision 8 — No source artifacts and no workspace cache

Phase 1 SHALL not upload artifacts by default.

Dependency-manager caches MAY be introduced only if they are proven to contain no private checkout or environment data.

Never cache:

- `workspace/`
- private source directories
- `.env*`
- credentials
- vault contents
- generated bundles that embed private source maps

## Decision 9 — Fail closed on mapping/auth problems

If any of the following occurs, the job SHALL stop before CI execution:

- alias is not in the secret mapping;
- resolved repository value is empty or malformed;
- clone authentication fails;
- requested ref cannot be resolved;
- token is unavailable.

The workflow SHALL NOT fall back to a public repository, a guessed repository name, or anonymous cloning.

## Decision 10 — Deployment remains where it is

Production deployment is deliberately excluded.

Existing private workflows that perform Vercel, Cloudflare, Pages, release, publish, migration, or other mutation duties remain unchanged.

The hub restores validation first; deployment migration requires a separate OpenSpec change.

## Decision 11 — Bounded execution

Every job SHALL define a timeout.

Per-target runs SHALL use concurrency groups so duplicate runs for the same alias do not create uncontrolled parallel work.

A failure in one target SHALL not expose or modify another target.

## Rollout

### Phase A — OpenSpec and public-safe skeleton
- Establish OpenSpec.
- Add security boundaries.
- Add generic manual workflow without secrets committed.

### Phase B — One-target pilot
- User adds the two required secrets manually.
- Select one alias as pilot through the secret mapping.
- Run clone + safe health check.
- Inspect logs for metadata/content leakage.

### Phase C — CI command validation
- Enable repository-native install/lint/typecheck/test/build for the pilot.
- Compare with repository-local or prior known-good CI behavior.

### Phase D — Remaining aliases
- Add remaining target mappings only in the private secret.
- Validate aliases one at a time.

### Phase E — Operational handoff
- Use the public hub as the temporary/primary CI path while private quota is unavailable.
- Keep original target workflows intact for rollback/reference.

### Phase F — Later automation decision
- Separately evaluate scheduled polling, GitHub App/webhook dispatch, or another event bridge.
- Do not silently expand this change into an eventing platform.

## Rollback

Rollback requires no change to private repositories.

1. Stop invoking the hub workflow.
2. Remove or rotate `PRIVATE_REPOS_READ_TOKEN`.
3. Remove `PRIVATE_REPOS_JSON`.
4. Keep or delete the public hub workflow as desired.
5. Original private repository workflows remain the reference path when quota/capacity returns.

## Evidence Required Before Declaring Phase 1 Complete

- successful read-only clone from public runner;
- token is masked and absent from logs;
- resolved repository identifier is masked;
- no private source appears in public logs;
- no private source artifact exists;
- no write occurred to the target repository;
- timeout and concurrency behavior confirmed;
- cleanup step ran;
- at least one target completed its repository-native CI checks.
