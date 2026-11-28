# Proposal

## Why

`repo-06` currently cannot receive `automation-hub/private-ci` evidence before merge, even though its read-only CI adapter already supports a sparse checkout. This leaves PRs without exact-head evidence when local evidence is the only available path.

## What Changes

- Enable the existing exact-SHA PR mode for `repo-06`.
- Fetch and detach-checkout the requested 40-character SHA before materializing the existing sparse path list.
- Include `repo-06` in the detector's existing open, non-Draft PR scan, exact-SHA deduplication, and claim flow.
- Preserve the sanitized summary, masking, and status-reporting paths.

## Impact

PR validation and detector behavior expand to `repo-06`. No input, status context, permissions, or stage evidence schema changes are intended.
