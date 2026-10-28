#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
runner="$root/scripts/common/run-ci.sh"
real_python3="$(command -v python3)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin" "$tmp/repo-03"
printf '%s\n' '{"name":"stage-evidence-test","version":"1.0.0","scripts":{"check:ci":"true"}}' > "$tmp/repo-03/package.json"
printf '%s\n' '{"name":"stage-evidence-test","version":"1.0.0","lockfileVersion":3,"packages":{"":{"name":"stage-evidence-test","version":"1.0.0"}}}' > "$tmp/repo-03/package-lock.json"
cat > "$tmp/bin/npm" <<'SH'
#!/usr/bin/env bash
if [[ "$1" == ci ]]; then exit 0; fi
if [[ "$1" == run && "$2" == check:ci ]]; then exit "${CHECK_CI_RC:-0}"; fi
exit 99
SH
chmod +x "$tmp/bin/npm"

assert_json() {
  "$real_python3" - "$1" "$2" "$3" <<'PY'
import json
import sys

path, target, expected = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
assert list(data) == ["schemaVersion", "target", "stages"], data
assert data["schemaVersion"] == 1, data
assert data["target"] == target, data
assert isinstance(data["stages"], list), data
if expected:
    assert any(stage["status"] == expected for stage in data["stages"]), data
    assert all(set(stage) == {"name", "status"} for stage in data["stages"]), data
PY
  "$real_python3" -m json.tool "$1" >/dev/null
}

summary="$tmp/pass.md"
evidence="$tmp/pass/stage-evidence.json"
PATH="$tmp/bin:$PATH" bash "$runner" "$tmp/repo-03" "$summary" repo-03 "$evidence" >/dev/null 2>&1
assert_json "$evidence" repo-03 PASS

summary="$tmp/fail.md"
evidence="$tmp/fail/stage-evidence.json"
rc=0
PATH="$tmp/bin:$PATH" CHECK_CI_RC=7 bash "$runner" "$tmp/repo-03" "$summary" repo-03 "$evidence" >/dev/null 2>&1 || rc=$?
[[ "$rc" == 7 ]] || { echo "FAIL exit code changed: $rc" >&2; exit 1; }
assert_json "$evidence" repo-03 FAIL
! grep -q 'exit 7' "$evidence" || { echo "failure reason leaked into JSON" >&2; exit 1; }
grep -q 'FAIL (exit 7)' "$summary"

mkdir -p "$tmp/repo-06" "$tmp/python-bin"
cat > "$tmp/python-bin/python3" <<'SH'
#!/usr/bin/env bash
if [[ "$*" == *stale-fact-audit.py* ]]; then exit 9; fi
if [[ "$1" == -c ]]; then exec "$REAL_PYTHON3" "$@"; fi
exit 0
SH
chmod +x "$tmp/python-bin/python3"
evidence="$tmp/repo-06/stage-evidence.json"
REAL_PYTHON3="$real_python3" PATH="$tmp/python-bin:$PATH" bash "$runner" "$tmp/repo-06" "$tmp/repo-06.md" repo-06 "$evidence" >/dev/null 2>&1
assert_json "$evidence" repo-06 ADVISORY
"$real_python3" - "$evidence" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    statuses = {stage["status"] for stage in json.load(f)["stages"]}
assert {"PASS", "ADVISORY", "SKIP"} <= statuses, statuses
PY

mkdir -p "$tmp/unsupported"
evidence="$tmp/skip/stage-evidence.json"
rc=0
bash "$runner" "$tmp/unsupported" "$tmp/skip.md" repo-01 "$evidence" >/dev/null 2>&1 || rc=$?
[[ "$rc" == 1 ]] || { echo "unverified SKIP exit code changed: $rc" >&2; exit 1; }
assert_json "$evidence" repo-01 SKIP

evidence="$tmp/empty/stage-evidence.json"
before_count="$(find "$tmp" -name stage-evidence.json | wc -l | tr -d ' ')"
rc=0
bash "$runner" "$tmp/unsupported" "$tmp/empty.md" repo-01 '' >/dev/null 2>&1 || rc=$?
[[ "$rc" == 1 ]] || { echo "empty evidence parameter changed the existing exit code: $rc" >&2; exit 1; }
after_count="$(find "$tmp" -name stage-evidence.json | wc -l | tr -d ' ')"
[[ "$before_count" == "$after_count" ]] || { echo "empty evidence parameter wrote a file" >&2; exit 1; }

mkdir -p "$tmp/repo-03-missing-package"
evidence="$tmp/early/stage-evidence.json"
rc=0
bash "$runner" "$tmp/repo-03-missing-package" "$tmp/early.md" repo-03 "$evidence" >/dev/null 2>&1 || rc=$?
[[ "$rc" == 2 ]] || { echo "repo-03 preflight exit code changed: $rc" >&2; exit 1; }
assert_json "$evidence" repo-03 FAIL

evidence="$tmp/no-workspace/stage-evidence.json"
summary="$tmp/no-workspace.md"
rc=0
bash "$runner" "$tmp/does-not-exist" "$summary" repo-03 "$evidence" >/dev/null 2>&1 || rc=$?
[[ "$rc" == 2 ]] || { echo "missing-workspace preflight exit code changed: $rc" >&2; exit 1; }
[[ ! -e "$summary" && ! -e "$evidence" ]] || { echo "missing-workspace preflight unexpectedly wrote output" >&2; exit 1; }

evidence="$tmp/invalid-name/stage-evidence.json"
mkdir -p "$tmp/repo-04/architecture"
printf '%s\n' '{"name":"stage-evidence-test","version":"1.0.0","scripts":{}}' > "$tmp/repo-04/package.json"
printf '%s\n' '{"name":"stage-evidence-test","version":"1.0.0","lockfileVersion":3,"packages":{"":{"name":"stage-evidence-test","version":"1.0.0"}}}' > "$tmp/repo-04/package-lock.json"
printf '%s\n' '{"repositories":[{"repository":"owner/project","portableCiEntrypoint":"true"}]}' > "$tmp/repo-04/architecture/repos.json"
mutated="$(sed 's/portable-ci-entrypoint/portable.ci.entrypoint/g' "$runner")"
rc=0
PATH="$tmp/bin:$PATH" PRIVATE_REPOSITORY=owner/project RUNNER_TEMP="$tmp" bash -c "$mutated" test-runner "$tmp/repo-04" "$tmp/invalid-name.md" repo-04 "$evidence" >/dev/null 2>&1 || rc=$?
[[ "$rc" == 0 ]] || { echo "invalid-name fixture did not complete: $rc" >&2; exit 1; }
"$real_python3" - "$evidence" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
assert list(data) == ["schemaVersion", "target", "stages"], data
assert data["target"] == "repo-04" and data["stages"] == [], data
PY

echo "stage evidence tests passed"
