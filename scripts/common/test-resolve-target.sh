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
python3 - "$root/.github/workflows/private-ci.yml" <<'PY'
import re
import sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
job = None
checkout_seen = False
references = 0
for index, line in enumerate(lines):
    match = re.match(r"^  ([A-Za-z0-9_-]+):\s*$", line)
    if match:
        job = match.group(1)
        checkout_seen = False
    if "uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1" in line and "persist-credentials: false" in "\n".join(lines[index:index+5]):
        checkout_seen = True
    if "scripts/common/resolve-target.py" in line:
        references += 1
        assert checkout_seen, f"{job} references resolver before checking out trusted Hub code"
assert references > 0, "workflow no longer references the target resolver"
PY
echo 'target eligibility tests passed'
