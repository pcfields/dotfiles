from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

BASH = language_for_path("x.sh")


def measure_sh(source: str):
    return measure_file(source.encode(), BASH)


def function_named(source: str, name: str = "f"):
    (function,) = [f for f in measure_sh(source).functions if f.name == name]
    return function


def in_function(body: str):
    return function_named(f"f() {{\n{body}\n}}\n")


def test_function_names_and_script():
    source = "f() { :; }\nfunction g { :; }\nfunction h() { :; }\n"

    assert [f.name for f in measure_sh(source).functions] == ["<script>", "f", "g", "h"]


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a; then :; elif b; then :; else :; fi", 3),
        ("for x in a b; do :; done", 2),
        ("for ((i = 0; i < 3; i++)); do :; done", 2),
        ("while a; do :; done", 2),
        ("until a; do :; done", 2),
        ("case $x in a|b) :;; c) :;; *) :;; esac", 3),
        ("a && b || c", 3),
        ("[[ -n $a && -z $b ]]", 2),
        ("echo hi | grep h", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_function(body).cyclomatic == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a; then if b; then if c; then :; fi; fi; fi", 3),
        ("if a; then :; elif b; then :; elif c; then if d; then :; fi; fi", 2),
        ("for x in a; do while b; do case $x in a) if c; then :; fi;; esac; done; done", 4),
    ],
)
def test_max_nesting(body, expected):
    assert in_function(body).max_nesting == expected


def test_bumps():
    body = "for x in a; do if x; then :; fi; done\nwhile b; do if c; then :; fi; done"

    assert in_function(body).bumps == 2


@pytest.mark.parametrize(
    ("body", "line"),
    [
        ("if [[ -n $a && -z $b ]]; then :; fi", 2),
        ("if c; then :; elif [[ -n $a && -z $b ]]; then :; fi", 2),
        ("while [[ -n $a && -z $b ]]; do :; done", 2),
    ],
)
def test_conditions_are_recorded(body, line):
    assert Condition(line=line, operators=1) in in_function(body).conditions


def test_script_measures_top_level_code():
    script = function_named("if a && b; then\n  for x in y; do :; done\nfi\nf() { if z; then :; fi; }\n", "<script>")

    assert (script.cyclomatic, script.max_nesting) == (4, 2)


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "bash"
    lf = measure_file((fixtures / "smells.sh").read_bytes(), BASH)
    crlf = measure_file((fixtures / "smells-crlf.sh").read_bytes(), BASH)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "describe", 4, 11, 10),
        ("Deep Nested Complexity", "deep", 20, 4, 4),
        ("Bumpy Road", "bumpy", 32, 2, 2),
        ("Complex Conditional", "eligible", 44, 2, 2),
        ("Large Method", "large", 50, 72, 70),
    ]
