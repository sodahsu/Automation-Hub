# Proposal

## Why

Dependency setup in the public CI bridge should fail closed when a project cannot prove its dependency selection from a lockfile. Public workflow output also needs to state the limits of runner isolation and the response to unexpected dependency or output behavior.

## What Changes

- Require exactly one supported lockfile for Node-family adapters that install dependencies and use each supported package manager's frozen installation mode.
- Lock the bridge's PyYAML dependency by version and package hashes.
- Keep lifecycle scripts enabled for every applicable alias because the available evidence does not establish that disabling them preserves each existing required stage.
- Document public output handling and containment guidance in `SECURITY.md`.

## Authorization Evidence

2026-11-27: the repository owner, acting through the coordinating agent, authorized implementation before work began. This records the delivery approval without including non-public issue context.

## Impact

The bridge adapter's setup behavior and public security guidance change. Caller inputs, status context, job names, and stage evidence schema remain unchanged.
