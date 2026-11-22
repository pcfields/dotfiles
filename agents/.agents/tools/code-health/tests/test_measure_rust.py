from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

RUST = language_for_path("x.rs")


def measure_rs(source: str):
    return measure_file(source.encode(), RUST)


def function_named(source: str, name: str = "f"):
    (function,) = [f for f in measure_rs(source).functions if f.name == name]
    return function


def in_function(body: str):
    return function_named(f"fn f(a: i32, b: i32, c: i32) {{\n{body}\n}}\n")


def test_function_names():
    source = (
        "impl Cart { fn new() -> Self { Self {} } fn m(&self) { let v = xs.iter().map(|x| x * 2); } }\n"
        "impl Display for Cart { fn fmt(&self) {} }\n"
        "trait T { fn sig(&self); fn d(&self) {} }\n"
        "mod inner { fn g() { let h = |y: i32| y; } }\n"
    )

    assert [f.name for f in measure_rs(source).functions] == [
        "Cart.new",
        "Cart.m",
        "Cart.m.map callback",
        "Cart.fmt",
        "T.d",
        "g",
        "h",
    ]


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a > 0 { } else if b > 0 { } else { }", 3),
        ("for x in xs { }", 2),
        ("while a > 0 { }", 2),
        ("loop { break; }", 2),
        ("match a { 1 | 2 => 1, 3 => 2, _ => 3 };", 3),
        ("let r = a > 0 && b > 0 || c > 0;", 3),
        ("let r = f()?;", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_function(body).cyclomatic == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a > 0 { if b > 0 { if c > 0 { } } }", 3),
        ("if a > 0 { } else if b > 0 { } else if c > 0 { if a > 1 { } }", 2),
        ("for x in xs { while a > 0 { match x { _ => { if b > 0 { } } } } }", 4),
    ],
)
def test_max_nesting(body, expected):
    assert in_function(body).max_nesting == expected


def test_self_is_not_a_parameter():
    assert function_named("impl C { fn f(&self, a: i32) {} }", "C.f").parameters == 1


@pytest.mark.parametrize("body", ["if a > 0 && b > 0 { }", "while a > 0 && b > 0 { }"])
def test_conditions_are_recorded(body):
    assert Condition(line=2, operators=1) in in_function(body).conditions


def test_doc_comments_are_not_code():
    source = "/// Docs\n/// more\n//! inner\nfn f() {\n    1\n}\n"

    assert measure_rs(source).loc == 3


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "rust"
    lf = measure_file((fixtures / "smells.rs").read_bytes(), RUST)
    crlf = measure_file((fixtures / "smells-crlf.rs").read_bytes(), RUST)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "describe", 3, 11, 10),
        ("Deep Nested Complexity", "deep", 19, 4, 4),
        ("Bumpy Road", "bumpy", 32, 2, 2),
        ("Complex Conditional", "eligible", 44, 2, 2),
        ("Large Method", "large", 50, 72, 70),
        ("Excess Function Arguments", "Shipper.ship", 124, 5, 5),
    ]
