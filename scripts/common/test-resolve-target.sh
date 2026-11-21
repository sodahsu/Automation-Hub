#!/usr/bin/env bash
set -Eeuo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
resolver="$root/scripts/common/resolve-target.py"
valid='{"repo-01":"owner/one","repo-02":"owner/two","repo-03":"owner/three","repo-04":"owner/four","repo-05":"owner/five","repo-06":"owner/six"}'
TARGET_ALIAS=repo-04 PRIVATE_REPOS_JSON="$valid" python3 "$resolver" | grep -qx 'owner/four'
for pair in \
  'repo-07|{"repo-07":"owner/extra"}' \
  'repo-01|{"repo-01":"owner/one","repo-07":"owner/extra"}' \
  'repo-01|{"repo-01":"owner/one","repo-02":"owner/one"}' \
  'repo-01|{"repo-01":"not/a/repo/slug"}' \
  'repo-01|{"repo-01":null}' \
  'repo-02|{"repo-01":"owner/one"}'; do
  target="${pair%%|*}"; mapping="${pair#*|}"
  if TARGET_ALIAS="$target" PRIVATE_REPOS_JSON="$mapping" python3 "$resolver" >/dev/null 2>&1; then
    echo "unexpected mapping acceptance: $target" >&2; exit 1
  fi
done
echo 'target eligibility tests passed'
