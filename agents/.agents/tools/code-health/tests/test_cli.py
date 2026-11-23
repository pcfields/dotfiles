import json
import os
import subprocess
import sys
from pathlib import Path

from code_health.cli import main

CALIBRATION = Path(__file__).parent / "fixtures" / "calibration"
V1 = str(CALIBRATION / "payment-v1.ts")
V3 = str(CALIBRATION / "payment-v3.ts")


def run(capsys, *argv):
    code = main(list(argv))
    out, err = capsys.readouterr()
    return code, out, err


def test_score_prints_score_band_and_path(capsys):
    assert run(capsys, "score", V3) == (0, f"10.0  green       {V3}\n", "")


def test_score_prints_one_line_per_file_in_order(capsys):
    code, out, _ = run(capsys, "score", V1, V3)

    assert (code, out.splitlines()) == (0, [f" 4.1  yellow      {V1}", f"10.0  green       {V3}"])


def test_unsupported_and_unparseable_files_are_not_scored(capsys, tmp_path):
    sql = tmp_path / "schema.sql"
    sql.write_text("select 1;")
    broken = tmp_path / "broken.ts"
    broken.write_text("function f( {")

    code, out, _ = run(capsys, "score", str(sql), str(broken))

    assert (code, out.splitlines()) == (
        0,
        [
            f"   -  not scored  {sql} (unsupported language)",
            f"   -  not scored  {broken} (parse errors)",
        ],
    )


def test_missing_file_fails_with_a_message(capsys, tmp_path):
    missing = tmp_path / "nope.ts"

    code, out, err = run(capsys, "score", str(missing))

    assert (code, out) == (1, "")
    assert f"code-health: cannot read {missing}" in err


def test_no_command_prints_usage_and_fails(capsys):
    code, _, err = run(capsys)

    assert code == 1
    assert "usage:" in err


def test_score_json(capsys, tmp_path):
    sql = tmp_path / "schema.sql"
    sql.write_text("select 1;")

    code, out, _ = run(capsys, "score", "--json", V3, str(sql))

    assert code == 0
    assert json.loads(out) == {
        "scorer_version": "6",
        "files": [
            {"path": V3, "score": 10.0, "band": "green"},
            {"path": str(sql), "score": None, "band": "not scored", "reason": "unsupported language"},
        ],
    }


def test_review_lists_findings_with_units_and_fix_hints(capsys):
    code, out, _ = run(capsys, "review", V1)

    assert code == 0
    assert out.splitlines() == [
        f"{V1}  4.1  yellow",
        "  Complex Method          processPayment:3  complexity 15 (limit 10)",
        "                          fix: Extract Function; Decompose Conditional",
        "  Deep Nested Complexity  processPayment:3  depth 9 (limit 4)",
        "                          fix: Replace Nested Conditional with Guard Clauses; Extract Function",
        "  Complex Conditional     processPayment:8  2 operators (limit 2)",
        "                          fix: Decompose Conditional; Explaining variable",
    ]


def test_review_of_clean_and_unscored_files(capsys, tmp_path):
    sql = tmp_path / "schema.sql"
    sql.write_text("select 1;")

    code, out, _ = run(capsys, "review", V3, str(sql))

    assert (code, out.splitlines()) == (
        0,
        [f"{V3}  10.0  green", "  no findings", "", f"{sql}  not scored (unsupported language)"],
    )


def test_review_json_includes_findings_and_fixes(capsys):
    code, out, _ = run(capsys, "review", "--json", V1)

    (report,) = json.loads(out)["files"]
    assert (code, report["score"], report["band"]) == (0, 4.1, "yellow")
    assert report["findings"][0] == {
        "smell": "Complex Method",
        "function": "processPayment",
        "line": 3,
        "value": 15,
        "limit": 10,
        "fix": "Extract Function; Decompose Conditional",
    }


def test_module_entry_point_runs_end_to_end():
    result = subprocess.run(
        [sys.executable, "-m", "code_health", "score", V3], capture_output=True, text=True, check=False
    )

    assert (result.returncode, result.stdout) == (0, f"10.0  green       {V3}\n")


def test_text_output_survives_a_console_that_cannot_encode_the_path(tmp_path):
    source = tmp_path / "café-日本.ts"
    source.write_text("function f() {}\n")

    result = subprocess.run(
        [sys.executable, "-m", "code_health", "score", str(source)],
        capture_output=True,
        env={**os.environ, "PYTHONIOENCODING": "ascii"},
        check=False,
    )

    assert result.returncode == 0
    assert result.stdout.decode("ascii").startswith("10.0  green")


def test_grammars_reports_every_language_and_the_cache(capsys):
    code, out, _ = run(capsys, "grammars")

    assert code == 0
    for name in ("bash", "csharp", "javascript", "lua", "powershell", "python", "rust", "tsx", "typescript"):
        assert name in out
    assert "cache:" in out
