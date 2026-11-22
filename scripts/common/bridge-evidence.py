import json
import os
from pathlib import Path
import re
import sys


CONTEXT = "automation-hub/private-ci"
STAGES = set("""
adapter package-json package-lock package-manager install local-git-baseline
unit-tests candidate-contract architecture-json architecture-doc openspec-strict
python-deps skill-sync health-unit-tests metadata-normalizer vault-health followup-radar
stale-fact-audit hub-drift index-drift relation-health memory-health source-link-format
claim-harvest source-backlog portable-ci-entrypoint check:ci lint typecheck test build
""".split())
SETUP = set("package-json package-lock package-manager install local-git-baseline python-deps".split())
STATUSES = {"PASS", "FAIL", "ADVISORY", "SKIP"}


def status_gate(path, sha, url, phase):
    data = json.loads(path.read_text())
    if data["sha"] != sha or not isinstance(data["statuses"], list):
        raise ValueError
    matching = [entry for entry in data["statuses"] if entry["context"] == CONTEXT]
    if not matching:
        if data["total_count"] != len(data["statuses"]):
            raise ValueError
        return phase == "claim" and url.endswith("/attempts/1")
    if len(matching) != 1:
        raise ValueError
    status = matching[0]
    previous_url = status["target_url"]
    if phase == "report":
        return previous_url == url and status["state"] == "pending"
    run_url, attempt = url.rsplit("/attempts/", 1)
    if attempt == "1" or not isinstance(previous_url, str):
        return False
    if previous_url == run_url:
        return True
    previous = re.fullmatch(re.escape(run_url) + r"/attempts/([1-9][0-9]*)", previous_url)
    return previous is not None and int(previous[1]) < int(attempt)


def read_stages(path, alias):
    if path.stat().st_size > 16384:
        raise ValueError
    data = json.loads(path.read_text())
    if (set(data) != {"schemaVersion", "target", "stages"} or type(data["schemaVersion"]) is not int
            or data["schemaVersion"] != 1
            or data["target"] != alias or not isinstance(data["stages"], list) or not data["stages"]):
        raise ValueError
    stages = data["stages"]
    names = set()
    for stage in stages:
        if (set(stage) != {"name", "status"} or stage["name"] not in STAGES
                or stage["name"] in names or stage["status"] not in STATUSES):
            raise ValueError
        names.add(stage["name"])
    return stages


def publish(path):
    alias, mode, outcome, run_id, attempt = (
        os.environ[key] for key in ("TARGET_ALIAS", "RUN_MODE", "RUNNER_OUTCOME", "GITHUB_RUN_ID", "GITHUB_RUN_ATTEMPT")
    )
    if (not re.fullmatch(r"repo-0[1-6]", alias) or mode not in {"pr", "default"}
            or not all(re.fullmatch(r"[1-9][0-9]*", number) for number in (run_id, attempt))):
        raise ValueError
    result = "INFRASTRUCTURE_ERROR"
    stages = []
    try:
        stages = read_stages(path, alias)
        path.write_text(json.dumps({"schemaVersion": 1, "target": alias, "stages": stages}) + "\n")
        failed = [stage["name"] for stage in stages if stage["status"] == "FAIL"]
        passed = {stage["name"] for stage in stages if stage["status"] == "PASS"}
        verified = bool(passed - SETUP - {"stale-fact-audit"})
        required = {"repo-03": {"package-json", "package-lock", "install", "check:ci"},
                    "repo-04": {"install", "portable-ci-entrypoint"}}.get(alias, set())
        if outcome == "PASSED" and verified and required <= passed and not failed:
            result = "PASSED"
        elif outcome == "FAILED" and failed and not SETUP.intersection(failed):
            result = "FAILED"
        elif outcome == "UNVERIFIED" and not verified:
            result = "UNVERIFIED"
    except (OSError, ValueError, TypeError, KeyError):
        stages = []
        path.unlink(missing_ok=True)

    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as summary:
        kind = "exact PR head" if mode == "pr" else "default branch (not PR evidence)"
        print(f"## {alias}: {result}\n\nRun {run_id}, attempt {attempt} · {kind}\n", file=summary)
        if stages:
            print("| Stage | Status |\n| --- | --- |", file=summary)
            for stage in stages:
                print(f"| {stage['name']} | {stage['status']} |", file=summary)
    with open(os.environ["GITHUB_OUTPUT"], "a") as outputs:
        print(f"ci_outcome={result}", file=outputs)
        for name in ("pass", "fail", "skip"):
            print(f"{name}_count={sum(stage['status'] == name.upper() for stage in stages)}", file=outputs)


try:
    if sys.argv[1] == "publish":
        publish(Path(sys.argv[2]))
    elif sys.argv[1] in {"claim", "report"}:
        phase, status_path, sha, url = sys.argv[1:]
        print(str(status_gate(Path(status_path), sha, url, phase)).lower())
    else:
        raise ValueError
except (OSError, ValueError, TypeError, KeyError, IndexError):
    sys.exit("Invalid or unavailable bridge evidence.")
