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
    run_case('INFRASTRUCTURE_ERROR', 1, CHECK_RC='1')
    run_case('INFRASTRUCTURE_ERROR', 7, CHECK_RC='7')
    run_case('INFRASTRUCTURE_ERROR', 7, INSTALL_RC='7')
    run_case('INFRASTRUCTURE_ERROR', 127, CHECK_RC='127')
    publish('INFRASTRUCTURE_ERROR', 'FAILED')
    stages = [dict(name=name, status='PASS') for name in ('package-json', 'package-lock', 'install', 'check:ci')]
    stage_evidence.write_text(json.dumps(dict(schemaVersion=1, target='repo-03',
                                               stages=stages + [dict(name='lint', status='UNVERIFIED')])))
    publish('INFRASTRUCTURE_ERROR', 'PASSED')
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
    detector_script = 'set -Eeuo pipefail\naliases=(repo-01)\n' + detector_body[detector_body.index('pr_failures=0'):]
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
  */pulls\?*) printf '[{"draft":false,"head":{"sha":"%s","repo":{"full_name":"example/fixture"}}},{"draft":false,"head":{"sha":"%s","repo":{"full_name":"EXAMPLE/FIXTURE"}}},{"draft":false,"head":{"sha":"unexpected-fork-sha","repo":{"full_name":"example/fork"}}}]' "$FIXTURE_SHA" "$FIXTURE_SHA" > "$output" ;;
  */commits/"$FIXTURE_SHA"/status\?*)
    if [[ -f "$CLAIM" && "${STALE_COMBINED:-0}" == 0 ]]; then
      jq --slurpfile claim "$CLAIM" '.statuses += [$claim[-1]] | .total_count += 1' <<<"$FIXTURE_STATUS" > "$output"
    else
      printf '%s' "$FIXTURE_STATUS" > "$output"
    fi ;;
  */commits/"$FIXTURE_SHA"/statuses\?*)
    if [[ "${HIDE_CLAIM:-0}" == 0 ]]; then
      jq -s '.' "$CLAIM" > "$output"
    else
      printf '[]' > "$output"
    fi ;;
  */statuses/"$FIXTURE_SHA")
    printf '%s\\n' "$payload" >> "$CLAIM_WRITES"
    if [[ "${REJECT_CLAIM:-0}" == 1 ]]; then printf 403; exit 0; fi
    jq -c --argjson id "$(wc -l < "$CLAIM_WRITES")" '. + {id: $id}' <<<"$payload" > "$output"
    cat "$output" >> "$CLAIM"
    printf 201; exit 0 ;;
  */dispatches)
    [[ -f "$CLAIM" ]] || exit 98
    printf '%s\\n' "$payload" >> "$DISPATCHES"
    if [[ "${LOSE_DISPATCH_RESPONSE:-0}" == 1 ]]; then exit 28; fi
    printf 204; exit 0 ;;
  *) exit 99 ;;
esac
printf 200
''')
    mock_curl.chmod(0o700)
    dispatches = temp / 'dispatches'
    claim = temp / 'claim.json'
    claim_writes = temp / 'claim-writes'
    detector_env = dict(env, PRIVATE_REPOS_JSON='{"repo-01":"example/fixture"}', PRIVATE_REPOS_READ_TOKEN='fixture',
                        STATUS_TOKEN='fixture', HUB_TOKEN='fixture', GITHUB_SERVER_URL='https://example.invalid',
                        GITHUB_REPOSITORY='example/hub', FIXTURE_SHA=sha, DISPATCHES=str(dispatches),
                        CLAIM=str(claim), CLAIM_WRITES=str(claim_writes))

    def sweep(expected_rc, statuses=(), count=0, **overrides):
        fixture = json.dumps(dict(sha=sha, statuses=list(statuses), total_count=count))
        result = subprocess.run(['bash', '-c', detector_script], env=dict(detector_env, FIXTURE_STATUS=fixture, **overrides),
                                capture_output=True, text=True)
        assert result.returncode == expected_rc, result
        assert not any(value in summary.read_text() for value in (sha, 'example/fixture'))

    def assert_counts(claim_count, dispatch_count):
        assert len(claim_writes.read_text().splitlines() if claim_writes.exists() else []) == claim_count
        assert [json.loads(line) for line in (dispatches.read_text().splitlines() if dispatches.exists() else [])] == [
            dict(ref='main', inputs=dict(target='repo-01', sha=sha))] * dispatch_count

    sweep(0, [dict(context='automation-hub/private-ci')], 1)
    sweep(1, count=101)
    assert_counts(0, 0)
    sweep(1, REJECT_CLAIM='1')
    assert_counts(1, 0)
    sweep(1, HIDE_CLAIM='1')
    sweep(0)
    assert_counts(2, 0)
    claim.unlink()
    sweep(0)
    sweep(0)
    sweep(0, GITHUB_RUN_ID='124', GITHUB_RUN_ATTEMPT='1')
    assert_counts(3, 1)
    sweep(1, STALE_COMBINED='1')
    assert_counts(4, 1)
    claim.unlink()
    sweep(1, LOSE_DISPATCH_RESPONSE='1')
    sweep(0)
    assert_counts(5, 2)

print('bridge evidence tests passed')
PY
