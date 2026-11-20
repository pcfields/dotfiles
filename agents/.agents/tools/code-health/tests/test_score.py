import pytest
from code_health.score import band, score_file
from code_health.smells import Finding


def finding(smell="Large Method", value=70, limit=70):
    return Finding(smell=smell, function="f", line=1, value=value, limit=limit)


def test_no_findings_scores_ten():
    assert score_file(()) == 10.0


def test_one_finding_at_its_limit_scores_nine():
    assert score_file((finding(),)) == 9.0


def test_further_over_the_limit_scores_lower():
    assert score_file((finding(value=140),)) < score_file((finding(value=90),)) < 9.0


def test_penalty_stops_growing_at_the_cap():
    assert score_file((finding(value=7000),)) == score_file((finding(value=70000),))


def test_nesting_and_complexity_weigh_more_than_other_smells():
    nesting = score_file((finding("Deep Nested Complexity", 4, 4),))
    complexity = score_file((finding("Complex Method", 10, 10),))

    assert nesting < complexity < 9.0


def test_findings_add_up():
    assert score_file((finding(), finding("Bumpy Road", 2, 2))) < 9.0


def test_lower_weight_softens_the_penalty():
    halved = score_file((finding(value=140),), weights={"Large Method": 0.5})

    assert score_file((finding(value=140),)) < halved < 10.0


def test_score_never_drops_below_one():
    many = tuple(finding("Complex Method", 1000, 10) for _ in range(50))

    assert score_file(many) == 1.0


@pytest.mark.parametrize(
    ("score", "expected"),
    [(10.0, "green"), (9.0, "green"), (8.9, "yellow"), (4.0, "yellow"), (3.9, "red"), (1.0, "red")],
)
def test_band(score, expected):
    assert band(score) == expected
