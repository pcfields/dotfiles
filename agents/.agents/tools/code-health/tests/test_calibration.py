from pathlib import Path

from code_health.languages import language_for_path
from code_health.measure import measure_file
from code_health.score import score_file
from code_health.smells import find_smells

CALIBRATION = Path(__file__).parent / "fixtures" / "calibration"


def review(version: int):
    path = CALIBRATION / f"payment-v{version}.ts"
    findings = find_smells(measure_file(path.read_bytes(), language_for_path(path)))
    return score_file(findings), findings


def test_v1_nested_payment_scores_low_and_names_its_smells():
    score, findings = review(1)

    assert score <= 4.5
    assert {("Complex Method", "processPayment"), ("Deep Nested Complexity", "processPayment")} <= {
        (f.smell, f.function) for f in findings
    }


def test_v2_guard_clauses_score_between_v1_and_ten():
    score, findings = review(2)

    assert review(1)[0] < score < 10.0
    assert any(f.function == "processPayment" for f in findings)


def test_v3_small_functions_score_ten():
    assert review(3) == (10.0, ())
