# Security Policy

## Public repository boundary

This repository is public. Treat every committed file, workflow log, job summary, artifact, cache key, issue, and pull request as publicly visible.

## Private target rules

- Private repositories are referenced in committed files only by aliases repo-01 through repo-06.
- Real repository identifiers belong only in the PRIVATE_REPOS_JSON GitHub Actions secret.
- The read credential belongs only in the PRIVATE_REPOS_READ_TOKEN GitHub Actions secret.
- Phase 1 access is read-only.
- Private source, notes, environment files, credentials, repository mappings, and clone URLs must not be committed or uploaded as artifacts.
- Do not print full environments, source files, note bodies, remote URLs, or secret-derived values in Actions logs.
- Do not use set -x in authentication or target-resolution steps.
- Do not cache workspace/, private source trees, .env files, credentials, or source-bearing bundles.

## Workflow restrictions

The Phase 1 workflow must not:

- push, tag, merge, or create branches in a private target;
- perform production deployment;
- rotate secrets;
- change repository visibility, billing, or branch protection;
- use pull_request_target with private-repository credentials;
- upload the private checkout as an artifact.

## Incident response

If private content or a credential is exposed:

1. Disable the affected workflow.
2. Revoke or rotate the exposed credential immediately.
3. Remove public artifacts/log references where GitHub permits it.
4. Review the target repository for unauthorized writes.
5. Open a new OpenSpec change before re-enabling the affected capability.
