#!/usr/bin/env python3
from pathlib import Path
import sys

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

for path, text in workflow_text.items():
    require("pull_request_target:" not in text, f"{path.name}: 禁止 pull_request_target")
    require("actions/upload-artifact" not in text, f"{path.name}: 禁止 private-source Artifact upload")
    require("actions/cache" not in text, f"{path.name}: 禁止 source/workspace cache")
    require("persist-credentials: true" not in text, f"{path.name}: persist-credentials 不得為 true")

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
print("- artifact/cache prohibitions: PASS")
print("- command-file isolation / cleanup: PASS")
print("- common token-prefix scan: PASS")
