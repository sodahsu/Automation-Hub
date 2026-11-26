# Design

## Dependency installation

Node-family aliases require exactly one supported lockfile. Missing or conflicting lockfiles produce a failed `package-lock` stage; installation uses `npm ci`, `pnpm install --frozen-lockfile`, or Yarn immutable/frozen mode. Bun lockfiles are recognized for ambiguity detection, but the Bun adapter remains a `SKIP` pending separate review and does not install dependencies or run scripts. Package manager lockfile mismatch errors remain failures and are never retried with an unlocked command.

The `repo-06` adapter's only installed Python package is PyYAML. A Hub-owned requirements lock pins its version and accepted PyPI SHA-256 digests, and pip runs with `--require-hashes`. `repo-05` does not install project dependencies; its OpenSpec CLI invocation remains pinned to the existing exact version.

## Lifecycle script assessment

| Alias | Assessment | Decision |
| --- | --- | --- |
| `repo-01` | Generic Node adapter; no repository-specific lifecycle inventory is available in the public Hub checkout. | Keep enabled; disabling could break checks. |
| `repo-02` | Generic Node adapter; no repository-specific lifecycle inventory is available in the public Hub checkout. | Keep enabled; disabling could break checks. |
| `repo-03` | npm CI gate; installation lifecycle hooks may provide binaries or generated files needed by `check:ci`. | Keep enabled. |
| `repo-04` | Portable CI entrypoint is repository-defined; its install-time prerequisites cannot be confirmed from the public Hub checkout. | Keep enabled. |
| `repo-05` | Python contract adapter with no project dependency install; no npm lifecycle stage. | Not applicable. |
| `repo-06` | Python health adapter; PyYAML is installed as a hash-pinned Python dependency, not through a Node package manager lifecycle. | Not applicable. |

## Public output and response

Treat the runner as a shared execution environment, not a sandbox. Logs, summaries, and artifacts are public. Unexpected dependency behavior or public output requires disabling affected workflow triggers, containing exposed material, investigating, and documenting re-enable criteria before restoration.

## Compatibility

Do not change caller inputs, status context, job names, or stage evidence format. Preserve current alias-specific required stage behavior.
