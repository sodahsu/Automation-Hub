"""Network-free tests for the public-only Colab notebook contract."""
import contextlib
import copy
import io
import json
import hashlib
import math
from pathlib import Path
import sys
import types
import unittest

BASE = Path(__file__).resolve().parents[1]
NOTEBOOK = BASE / "synthetic_markdown_index.ipynb"
SCHEMA = BASE / "report.schema.json"


def load_notebook():
    return json.loads(NOTEBOOK.read_text(encoding="utf-8"))


def code_cell(index):
    return "".join(load_notebook()["cells"][index]["source"])


def core():
    env = {}
    exec(compile(code_cell(2), "notebook-core", "exec"), env)
    return env


class SyntheticDatasetTests(unittest.TestCase):
    def setUp(self):
        self.env = core()

    def test_fixture_is_bounded_reproducible_and_marked(self):
        first = self.env["make_synthetic_documents"](120)
        second = self.env["make_synthetic_documents"](120)
        self.assertEqual(first, second)
        self.assertEqual(len(first), 120)
        self.assertTrue(all(d["markdown"].startswith("SYNTHETIC_PUBLIC_DEMO\n") for d in first))
        self.assertEqual(len({d["id"] for d in first}), 120)
        self.assertTrue(self.env["validate_synthetic_documents"](first))

    def test_bad_count_fails_closed(self):
        for count in (99, 501, True, 120.0):
            with self.subTest(count=count), self.assertRaises(ValueError):
                self.env["make_synthetic_documents"](count)

    def test_non_synthetic_or_malformed_input_fails_closed(self):
        docs = self.env["make_synthetic_documents"]()
        changes = [
            ("markdown", "Unmarked source text"),
            ("id", "outside-1"),
            ("title", "Private source"),
            ("topic", "private"),
            ("markdown", "SYNTHETIC_PUBLIC_DEMO\n" + "X" * 2100),
        ]
        for key, value in changes:
            bad = copy.deepcopy(docs)
            bad[0][key] = value
            with self.subTest(key=key, value=value[:30]), self.assertRaises(ValueError):
                self.env["validate_synthetic_documents"](bad)

    def test_extra_field_and_duplicates_fail_closed(self):
        docs = self.env["make_synthetic_documents"]()
        docs[0]["private_text"] = "not allowed"
        with self.assertRaises(ValueError):
            self.env["validate_synthetic_documents"](docs)
        docs = self.env["make_synthetic_documents"]()
        docs[0]["id"] = docs[1]["id"]
        with self.assertRaises(ValueError):
            self.env["validate_synthetic_documents"](docs)


class PublicReportTests(unittest.TestCase):
    def setUp(self):
        self.env = core()
        self.report = self.env["build_public_report"](
            count=120, dimension=384, revision="1110a243fdf4706b3f48f1d95db1a4f5529b4d41",
            runtime="CPU", gpu_requested=False, elapsed_seconds=2.5,
        )

    def test_schema_matches_allowlisted_fields(self):
        schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
        self.assertFalse(schema["additionalProperties"])
        self.assertEqual(set(schema["required"]), set(self.report))
        self.assertEqual(set(schema["properties"]), set(self.report))
        self.assertTrue(self.env["validate_public_report"](self.report))
        self.assertIsNone(self.report["compute_units_observed"])
        self.assertEqual(self.report["experiment"], "colab-synthetic-poc")

    def test_extra_fields_and_forged_cu_fail_closed(self):
        for k, v in (("source", "secret"), ("embedding", [1.0]), ("path", "/home/private")):
            bad = {**self.report, k: v}
            with self.subTest(field=k), self.assertRaises(ValueError):
                self.env["validate_public_report"](bad)
        bad = {**self.report, "compute_units_observed": 3.5}
        with self.assertRaises(ValueError):
            self.env["validate_public_report"](bad)

    def test_malformed_dimensions_sha_counts_and_nan_fail(self):
        invalid = (
            ("embedding_dimension", True), ("document_count", True),
            ("chunk_count", 100), ("model_revision", "main"),
            ("elapsed_seconds", math.nan), ("elapsed_seconds", -1),
            ("gpu_requested", 1), ("status", "CI_PASSED"),
            ("runtime_mode", "TPU"),
        )
        for k, v in invalid:
            bad = {**self.report, k: v}
            with self.subTest(field=k, value=v), self.assertRaises(ValueError):
                self.env["validate_public_report"](bad)

    def test_gpu_fallback_is_truthful(self):
        report = self.env["build_public_report"](
            count=120, dimension=384, revision="1110a243fdf4706b3f48f1d95db1a4f5529b4d41",
            runtime="CPU", gpu_requested=True, elapsed_seconds=1,
        )
        self.assertTrue(report["gpu_fallback"])
        self.assertFalse(self.report["gpu_fallback"])


class NotebookStructureTests(unittest.TestCase):
    def test_notebook_is_valid_clean_and_self_contained(self):
        nb = load_notebook()
        self.assertEqual(nb["nbformat"], 4)
        self.assertEqual(nb["cells"][0]["cell_type"], "markdown")
        for i, cell in enumerate(nb["cells"]):
            if cell["cell_type"] == "code":
                self.assertIsNone(cell["execution_count"], i)
                self.assertEqual(cell["outputs"], [], i)
        self.assertEqual(nb["cells"][2]["source"][0].strip(), "# UNIT:CORE")
        self.assertIn('USE_GPU = False', code_cell(4))
        self.assertIn('SAVE_PUBLIC_REPORT = False', code_cell(8))
        self.assertIn('token=False', code_cell(4))
        self.assertIn("requirements.lock", code_cell(1))
        self.assertIn("PINNED_MODEL_REVISION", code_cell(4))
        self.assertNotIn("model_info", code_cell(4))
        lock_digest = hashlib.sha256((BASE / "requirements.lock").read_bytes()).hexdigest()
        self.assertIn(lock_digest, code_cell(1))
        for idx in (2, 3, 4, 5, 6, 8):
            compile(code_cell(idx), f"notebook-cell-{idx}", "exec")

    def test_no_private_input_or_automation_hooks(self):
        executable = "\n".join(code_cell(i) for i in (2, 3, 4, 5, 6, 8))
        for bad in (
            "os.environ", "input(", "drive.mount", "userdata.get",
            "git clone", "workflow_dispatch", "actions: write", "PRIVATE_REPOS_",
            "gh auth", "requests.post", "subprocess", "eval(",
        ):
            self.assertNotIn(bad, executable)
        self.assertNotIn("execution_count\": 1", NOTEBOOK.read_text(encoding="utf-8"))

    def test_offline_full_path_mocked_model(self):
        """Exercise all non-install cells with a deterministic fake public model, no network or auth."""
        try:
            import numpy as np
        except ImportError:
            self.skipTest("Optional NumPy not installed; core safety tests still run")

        fake_torch = types.ModuleType("torch")
        fake_torch.cuda = types.SimpleNamespace(is_available=lambda: False)
        fake_st = types.ModuleType("sentence_transformers")

        class FakeModel:
            def __init__(self, *args, **kwargs):
                if (args[0] != "sentence-transformers/all-MiniLM-L6-v2" or kwargs["token"] is not False
                        or kwargs["revision"] != "1110a243fdf4706b3f48f1d95db1a4f5529b4d41"):
                    raise AssertionError("Unexpected public model args")
            def encode(self, strings, **kwargs):
                arr = []
                for s in strings:
                    low = s.lower()
                    v = np.array([low.count(w) + 0.1 for w in ("graph", "testing", "product", "design", "automation", "analytics")], dtype=float)
                    arr.append(v / np.linalg.norm(v))
                return np.asarray(arr)

        fake_st.SentenceTransformer = FakeModel
        originals = {k: sys.modules.get(k) for k in ("torch", "sentence_transformers")}
        try:
            sys.modules.update({"torch": fake_torch, "sentence_transformers": fake_st})
            env = {}
            with contextlib.redirect_stdout(io.StringIO()) as output:
                for i in (2, 3, 4, 5, 6, 8):
                    exec(compile(code_cell(i), f"test-cell-{i}", "exec"), env)
            report = env["public_report"]
            self.assertEqual(report["status"], "PASS")
            self.assertEqual(report["runtime_mode"], "CPU")
            self.assertEqual(report["embedding_dimension"], 6)
            self.assertNotIn("Synthetic graph note", output.getvalue())
            self.assertNotIn("synthetic://", output.getvalue())
            self.assertTrue(env["validate_public_report"](report))
        finally:
            for key, value in originals.items():
                if value is None:
                    sys.modules.pop(key, None)
                else:
                    sys.modules[key] = value


if __name__ == "__main__":
    unittest.main()