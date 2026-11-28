#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd "$(dirname "$0")/../.." && pwd)"
python3 - "$root" <<'PY'
from pathlib import Path
import subprocess
import sys
import tempfile

import yaml

root = Path(sys.argv[1])
workflow = yaml.safe_load((root / '.github/workflows/private-ci.yml').read_text())
mode_step = next(step for step in workflow['jobs']['resolve']['steps'] if step.get('id') == 'mode')
mode_script = mode_step['run']

def select_mode(target, sha):
    with tempfile.TemporaryDirectory() as directory:
        output = Path(directory) / 'output'
        result = subprocess.run(['bash', '-c', mode_script], env={
            'PATH': __import__('os').environ['PATH'], 'EVENT_NAME': 'workflow_dispatch',
            'INPUT_TARGET': target, 'INPUT_SHA': sha, 'GITHUB_OUTPUT': str(output),
        }, capture_output=True, text=True)
        return result, output.read_text() if output.exists() else ''

sha = 'a' * 40
result, output = select_mode('repo-06', sha)
assert result.returncode == 0 and output == 'mode=pr\n', (result, output)
result, _ = select_mode('repo-06', 'a' * 39)
assert result.returncode != 0, result
result, output = select_mode('repo-01', sha)
assert result.returncode == 0 and output == 'mode=pr\n', (result, output)
result, output = select_mode('repo-06', '')
assert result.returncode == 0 and output == 'mode=default\n', (result, output)

ci_steps = workflow['jobs']['ci']['steps']
clone_script = next(step['run'] for step in ci_steps if step.get('name') == 'Resolve and clone private target')
assert 'git -C workspace fetch --depth=1 origin "${HEAD_SHA}"' in clone_script
assert 'git -C workspace checkout --detach FETCH_HEAD' in clone_script
assert '"$(git -C workspace rev-parse HEAD)" != "${HEAD_SHA}"' in clone_script
assert '90_System' in clone_script and '.github/workflows' in clone_script
assert 'automation-hub-git-fetch.log' in clone_script  # git diagnostics stay out of public logs

resolve_steps = workflow['jobs']['resolve']['steps']
claim_script = next(step['run'] for step in resolve_steps if step.get('id') == 'claim')
report_steps = workflow['jobs']['report']['steps']
report_script = next(step['run'] for step in report_steps if step.get('name') == 'Write final commit status')

def assert_denied_status_fails_closed(script, expected):
    marker = 'if [[ ! "${http_code}" =~ ^2[0-9][0-9]$ ]]; then'
    lines = script.splitlines()
    start = next(index for index, line in enumerate(lines) if marker in line)
    end = next(index for index in range(start + 1, len(lines)) if lines[index].strip() == 'fi')
    guard = '\n'.join(lines[start:end + 1])
    result = subprocess.run(['bash', '-c', 'http_code=403; state=error\n' + guard],
                            capture_output=True, text=True)
    assert result.returncode == 1 and expected in result.stdout, (result, guard)

assert_denied_status_fails_closed(claim_script, 'Unable to write pending status (HTTP 403).')
assert_denied_status_fails_closed(report_script, 'Unable to write error status (HTTP 403).')

detector = yaml.safe_load((root / '.github/workflows/detect-private-changes.yml').read_text())
detector_script = detector['jobs']['detect']['steps'][0]['run']
assert 'aliases=(repo-01 repo-02 repo-03 repo-04 repo-05 repo-06)' in detector_script
pr_scan = detector_script[detector_script.index('pr_failures=0'):]
assert '[[ "${alias}" == "repo-06" ]] && continue' not in pr_scan
assert 'unique[]' in pr_scan and 'automation-hub/private-ci' in pr_scan

print('private-ci PR workflow tests passed')
PY
