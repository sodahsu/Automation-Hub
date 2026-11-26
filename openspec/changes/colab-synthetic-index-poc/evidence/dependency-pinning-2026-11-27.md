# Dependency Pinning Validation — 2026-11-27

## Changes

- Hugging Face model `sentence-transformers/all-MiniLM-L6-v2` uses immutable revision `1110a243fdf4706b3f48f1d95db1a4f5529b4d41` (40-character commit SHA). The notebook no longer resolves a moving model reference at runtime; it passes this exact revision to model loading and stops on load failure.
- `experiments/colab/requirements.lock` pins the complete direct and transitive Python dependency set to exact versions. Before installation, the notebook downloads this lock file and verifies SHA-256 `00575bb836ace58789cb66b962ea0d68e46d27e06ac61f2843686c65687b8eb9`.
- Package artifact hashes are not in the lock. Generating a pip-tools hash lock did not complete in the available environment; the checked-in lock therefore provides exact version pinning and an integrity check for the lock file, not per-distribution hash verification.

## Validation

| Command | Result |
| --- | --- |
| `python3 -m unittest discover -s experiments/colab/tests -v` | Exit 0; 11 tests run, 10 passed, 1 skipped because NumPy is not installed |
| `python3 scripts/security/audit.py` | Exit 0; Security audit PASS, 5 workflows checked |
| `npx --yes @fission-ai/openspec@1.8.0 validate --all --strict --json` | Exit 0; 4/4 items passed |

The skipped optional fake-model test and live Colab observations remain outstanding; this evidence does not claim a live model download, CPU/GPU run, or Compute Units measurement.
