# Verification evidence

Authorization: On 2026-11-27, the repository owner, through the coordinating agent, approved implementation before work began.

Local verification results:

| Command | Exit | Result |
| --- | ---: | --- |
| `bash scripts/common/test-bridge-evidence.sh` | 0 | Passed |
| `bash scripts/common/test-resolve-target.sh` | 0 | Passed |
| `bash scripts/common/test-run-ci-portable.sh` | 0 | Passed |
| `bash scripts/common/test-stage-evidence.sh` | 2 | Local environment selected Python 3.12 ahead of its test's Python 3.9 shim; fixture then ran against an empty content workspace. |
| `PYTHON_BIN=/tmp/hub-python-test-shim bash scripts/common/test-stage-evidence.sh` | 0 | Passed with a temporary compatibility shim for the test's synthetic Python runtime; shim was outside the repository. |
| `bash scripts/wake/test-wake-guard.sh` | 0 | Passed |
| `python3 scripts/security/audit.py` | 0 | Passed |
| `npx --yes @fission-ai/openspec@1.8.0 validate --all --strict` | 0 | Passed |
| `python3 -m pip download --no-deps --require-hashes -r scripts/common/requirements.lock --dest /tmp/hub-lock-verify --platform manylinux2014_x86_64 --python-version 3.12 --implementation cp --abi cp312 --only-binary=:all:` | 0 | Hash-verified Linux Python 3.12 artifact resolution passed. |
| `git diff --check && bash -n scripts/common/run-ci.sh` | 0 | Passed |
| `actionlint .github/workflows/private-ci.yml` | 127 | Not run: `actionlint` is not installed in this environment. |

No hosted workflow or dispatch was triggered.
