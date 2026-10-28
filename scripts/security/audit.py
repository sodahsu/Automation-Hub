#!/usr/bin/env python3
from pathlib import Path
import sys
import yaml

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
PRIVATE_CI = WORKFLOWS / "private-ci.yml"
DETECTOR = WORKFLOWS / "detect-private-changes.yml"
RUN_CI = ROOT / "scripts" / "common" / "run-ci.sh"

errors: list[str] = []

def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

workflow_files = sorted(WORKFLOWS.glob("*.yml")) + sorted(WORKFLOWS.glob("*.yaml"))
workflow_text = {p: p.read_text(encoding="utf-8") for p in workflow_files}
workflow_data = {p.name: yaml.safe_load(text) or {} for p, text in workflow_text.items()}

def artifact_upload_steps(workflow: dict) -> list[dict]:
    steps = []
    for job in (workflow.get("jobs") or {}).values():
        steps.extend(
            step for step in job.get("steps", [])
            if isinstance(step, dict) and str(step.get("uses", "")).startswith("actions/upload-artifact@")
        )
    return steps

def artifact_policy_issues(workflows: dict[str, dict]) -> list[str]:
    issues = []
    for name, workflow in workflows.items():
        steps = artifact_upload_steps(workflow)
        if name != "private-ci.yml" and steps:
            issues.append(f"{name}: actions/upload-artifact 僅允許用於 private-ci.yml 的去敏 stage evidence")

    private_steps = artifact_upload_steps(workflows.get("private-ci.yml", {}))
    if len(private_steps) != 1:
        issues.append("private-ci.yml: 必須恰有一個 stage evidence upload-artifact step")
    elif private_steps:
        artifact = private_steps[0]
        fields = artifact.get("with") or {}
        path = fields.get("path")
        if path != "${{ runner.temp }}/stage-evidence/stage-evidence.json":
            issues.append("private-ci.yml: artifact path 必須精確為 runner.temp 下的 stage-evidence.json")
        if isinstance(path, str) and ("workspace" in path.lower() or any(char in path for char in "*?[]")):
            issues.append("private-ci.yml: artifact path 不得包含 workspace 路徑或萬用字元")
        name = fields.get("name")
        if not isinstance(name, str) or not name.startswith("hub-stage-evidence-"):
            issues.append("private-ci.yml: artifact name 必須以 hub-stage-evidence- 開頭")
        retention = fields.get("retention-days")
        if isinstance(retention, bool) or not isinstance(retention, int) or not 1 <= retention <= 30:
            issues.append("private-ci.yml: artifact retention-days 必須是 1 至 30 的整數")
    return issues

def check_artifact_policy_self_test() -> None:
    def workflow(*steps: dict) -> dict:
        return {"jobs": {"ci": {"steps": list(steps)}}}

    valid_step = {
        "uses": "actions/upload-artifact@" + "a" * 40,
        "with": {
            "name": "hub-stage-evidence-repo-01",
            "path": "${{ runner.temp }}/stage-evidence/stage-evidence.json",
            "retention-days": 30,
        },
    }
    valid = {"private-ci.yml": workflow(valid_step)}
    if artifact_policy_issues(valid):
        raise RuntimeError("security audit artifact policy self-check rejected its valid fixture")

    other_workflow = {**valid, "detect-private-changes.yml": workflow(valid_step)}
    if not any("detect-private-changes.yml" in issue for issue in artifact_policy_issues(other_workflow)):
        raise RuntimeError("security audit artifact policy self-check accepted an upload in another workflow")

    duplicate = {"private-ci.yml": workflow(valid_step, valid_step)}
    if not any("恰有一個" in issue for issue in artifact_policy_issues(duplicate)):
        raise RuntimeError("security audit artifact policy self-check accepted multiple upload steps")

    wrong_path_step = {**valid_step, "with": {**valid_step["with"], "path": "workspace/**"}}
    wrong_path = {"private-ci.yml": workflow(wrong_path_step)}
    if not any("artifact path" in issue for issue in artifact_policy_issues(wrong_path)):
        raise RuntimeError("security audit artifact policy self-check accepted an unsafe path")

check_artifact_policy_self_test()
for issue in artifact_policy_issues(workflow_data):
    require(False, issue)

for path, text in workflow_text.items():
    require("pull_request_target:" not in text, f"{path.name}: 禁止 pull_request_target")
    require("actions/cache" not in text, f"{path.name}: 禁止 source/workspace cache")
    require("persist-credentials: true" not in text, f"{path.name}: persist-credentials 不得為 true")

    for line in text.splitlines():
        stripped = line.strip()
        if not stripped.startswith("uses: actions/"):
            continue
        ref = stripped.split("@", 1)[1].split()[0] if "@" in stripped else ""
        require(
            len(ref) == 40 and all(ch in "0123456789abcdef" for ch in ref.lower()),
            f"{path.name}: GitHub Actions 必須固定到 immutable commit SHA"
        )

private_ci = PRIVATE_CI.read_text(encoding="utf-8")
detector = DETECTOR.read_text(encoding="utf-8")
run_ci = RUN_CI.read_text(encoding="utf-8")

require("permissions:\n  contents: read" in private_ci, "private-ci.yml 必須維持 contents: read")
require("actions: write" not in private_ci, "private-ci.yml 不得擁有 actions: write")
require("actions: write" in detector, "detector 必須明確宣告 actions: write 以 dispatch Public Hub workflow")

for path, text in workflow_text.items():
    if path != DETECTOR:
        require("actions: write" not in text, f"{path.name}: actions: write 只能存在 detector")

require("rm -rf workspace" in private_ci, "private-ci.yml 必須 cleanup private workspace")
require("private-ci-command-files" in private_ci, "private-ci.yml 必須 cleanup command-file isolation directory")
require("automation-hub-git-askpass.sh" in private_ci, "private-ci.yml 必須 cleanup temporary Git askpass")
require("set -x" not in private_ci, "private-ci.yml 禁止 set -x")
require("set -x" not in detector, "detector 禁止 set -x")
require("set -x" not in run_ci, "run-ci.sh 禁止 set -x")
require("GITHUB_STEP_SUMMARY" in private_ci and "GITHUB_OUTPUT" in private_ci and "GITHUB_ENV" in private_ci and "GITHUB_PATH" in private_ci,
        "private-ci.yml 必須保留 GitHub command-file isolation")

# Scan text files for common token prefixes without embedding the literal prefix in source.
forbidden_prefixes = ["gh" + "p_", "github" + "_pat_"]
scan_suffixes = {".md", ".yml", ".yaml", ".sh", ".py", ".json"}
for path in ROOT.rglob("*"):
    if not path.is_file() or path.suffix.lower() not in scan_suffixes:
        continue
    if ".git" in path.parts:
        continue
    text = path.read_text(encoding="utf-8", errors="ignore")
    for prefix in forbidden_prefixes:
        require(prefix not in text, f"{path.relative_to(ROOT)}: 發現疑似 token prefix")

if errors:
    print("Security audit: FAIL")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)

print("Security audit: PASS")
print(f"- workflows checked: {len(workflow_files)}")
print("- private CI permission boundary: PASS")
print("- detector actions permission scope: PASS")
print("- sanitized stage artifact exception / cache prohibitions: PASS")
print("- command-file isolation / cleanup: PASS")
print("- common token-prefix scan: PASS")
print("- third-party GitHub Actions immutable SHA pinning: PASS")
