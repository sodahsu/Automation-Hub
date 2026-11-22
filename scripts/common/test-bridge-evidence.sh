#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$root" <<'PY'
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

import yaml

root = Path(sys.argv[1])
helper = root / 'scripts/common/bridge-evidence.py'
runner = root / 'scripts/common/run-ci.sh'
sha = 'a' * 40
run = 'https://example.invalid/actions/runs/123'
first = run + '/attempts/1'
second = run + '/attempts/2'
other = 'https://example.invalid/actions/runs/456/attempts/1'
marker = 'synthetic-secret-placeholder'

with tempfile.TemporaryDirectory() as directory:
    temp = Path(directory)
    status = temp / 'status.json'

    def gate(phase, url, expected, previous=None, state='pending', response_sha=sha, count=None):
        entries = [] if previous is None else [dict(context='automation-hub/private-ci', target_url=previous, state=state)]
        status.write_text(json.dumps(dict(sha=response_sha, statuses=entries, total_count=len(entries) if count is None else count)))
        result = subprocess.run([sys.executable, str(helper), phase, str(status), sha, url], capture_output=True, text=True)
        if expected is None:
            assert result.returncode != 0 and not result.stdout, result
        else:
            assert result.returncode == 0 and result.stdout.strip() == str(expected).lower(), result

    gate('claim', first, True)
    gate('claim', first, False, first)
    gate('claim', other, False, first)
    gate('claim', other, False, first, 'error')
    gate('claim', second, True, first)
    gate('claim', second, True, run, 'failure')
    gate('claim', second, False, second)
    gate('claim', second, False, other)
    gate('claim', second, False)
    gate('claim', first, None, count=101)
    gate('claim', first, None, response_sha='b' * 40)
    gate('report', first, False, second)
    gate('report', second, True, second)
    gate('report', second, False, second, 'success')
    gate('report', second, False)

    source = temp / 'fixture'
    source.mkdir()
    binaries = temp / 'bin'
    binaries.mkdir()
    npm = binaries / 'npm'
    npm.write_text(f'#!/bin/bash\necho {marker}\nif [[ "$1" == ci ]]; then exit "${{INSTALL_RC:-0}}"; fi\nexit "${{CHECK_RC:-0}}"\n')
    npm.chmod(0o700)
    summary = temp / 'summary'
    output = temp / 'output'
    stage_evidence = temp / 'stage-evidence.json'
    outcome = temp / 'outcome'
    env = dict(os.environ, PATH=f'{binaries}:{os.environ["PATH"]}', RUNNER_TEMP=str(temp),
               GITHUB_STEP_SUMMARY=str(summary), GITHUB_OUTPUT=str(output), GITHUB_RUN_ID='123',
               GITHUB_RUN_ATTEMPT='2', RUN_MODE='pr', TARGET_ALIAS='repo-03', INPUT_SHA=sha)

    def publish(expected, runner_result):
        summary.write_text('')
        output.write_text('')
        subprocess.run([sys.executable, str(helper), 'publish', str(stage_evidence)],
                       env=dict(env, RUNNER_OUTCOME=runner_result), check=True)
        text = summary.read_text()
        assert f'repo-03: {expected}' in text and 'Run 123, attempt 2 · exact PR head' in text, text
        assert f'ci_outcome={expected}\n' in output.read_text(), output.read_text()
        assert sha not in text and marker not in text

    def run_case(expected, exit_code, **overrides):
        result = subprocess.run(['bash', str(runner), str(source), str(temp / 'raw-summary'),
                                 'repo-03', str(stage_evidence), str(outcome)],
                                env=dict(env, **overrides), capture_output=True, text=True)
        assert result.returncode == exit_code and marker not in result.stdout + result.stderr, result
        assert outcome.read_text().strip() == expected, outcome.read_text()
        publish(expected, expected)

    run_case('UNVERIFIED', 2)
    (source / 'package.json').write_text('{"scripts":{}}')
    (source / 'package-lock.json').write_text('{}')
    run_case('UNVERIFIED', 2)
    (source / 'package.json').write_text('{"scripts":{"check:ci":"true"}}')
    run_case('PASSED', 0)
    run_case('FAILED', 7, CHECK_RC='7')
    run_case('INFRASTRUCTURE_ERROR', 7, INSTALL_RC='7')
    run_case('INFRASTRUCTURE_ERROR', 127, CHECK_RC='127')
    stage_evidence.write_text(json.dumps(dict(schemaVersion=1, target='repo-03',
                                               stages=[dict(name=marker, status='PASS')])))
    publish('INFRASTRUCTURE_ERROR', 'PASSED')
    assert not stage_evidence.exists()
    publish('INFRASTRUCTURE_ERROR', 'PASSED')
    stage_evidence.write_text(json.dumps(dict(schemaVersion=1, target='repo-03',
                                               stages=[dict(name='install', status='PASS')])))
    publish('INFRASTRUCTURE_ERROR', 'PASSED')
    stage_evidence.write_text(json.dumps(dict(schemaVersion=1, target='repo-03',
                                               stages=[dict(name='lint', status='PASS')])))
    publish('INFRASTRUCTURE_ERROR', 'PASSED')

    detector = yaml.safe_load((root / '.github/workflows/detect-private-changes.yml').read_text())
    detector_body = detector['jobs']['detect']['steps'][0]['run']
    detector_script = 'set -Eeuo pipefail\naliases=(repo-01)\npr_failures=0\n\n' + detector_body[detector_body.index('for alias', detector_body.index('pr_failures=0')):]
    mock_curl = binaries / 'curl'
    mock_curl.write_text('''#!/bin/bash
set -eu
while (( $# )); do
  case "$1" in
    --output) output="$2"; shift ;;
    --data) payload="$2"; shift ;;
    https://*) url="$1" ;;
  esac
  shift
done
case "$url" in
  */pulls\?*) printf '[{"draft":false,"head":{"sha":"%s"}},{"draft":false,"head":{"sha":"%s"}}]' "$FIXTURE_SHA" "$FIXTURE_SHA" > "$output" ;;
  */commits/"$FIXTURE_SHA"/status\?*) printf '%s' "$FIXTURE_STATUS" > "$output" ;;
  */dispatches) printf '%s\\n' "$payload" >> "$DISPATCHES"; printf 204; exit 0 ;;
  *) exit 99 ;;
esac
printf 200
''')
    mock_curl.chmod(0o700)
    dispatches = temp / 'dispatches'
    detector_env = dict(env, PRIVATE_REPOS_JSON='{"repo-01":"example/fixture"}', PRIVATE_REPOS_READ_TOKEN='fixture',
                        HUB_TOKEN='fixture', GITHUB_REPOSITORY='example/hub', FIXTURE_SHA=sha, DISPATCHES=str(dispatches))
    for statuses, count, expected_rc in [([], 0, 0), ([dict(context='automation-hub/private-ci')], 1, 0), ([], 101, 1)]:
        fixture = json.dumps(dict(sha=sha, statuses=statuses, total_count=count))
        result = subprocess.run(['bash', '-c', detector_script], env=dict(detector_env, FIXTURE_STATUS=fixture),
                                capture_output=True, text=True)
        assert result.returncode == expected_rc, result
        assert not any(value in summary.read_text() for value in (sha, 'example/fixture'))
        assert [json.loads(line) for line in dispatches.read_text().splitlines()] == [dict(ref='main', inputs=dict(target='repo-01', sha=sha))]

print('bridge evidence tests passed')
PY
