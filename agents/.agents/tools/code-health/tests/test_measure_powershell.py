from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

POWERSHELL = language_for_path("x.ps1")


def measure_ps(source: str):
    return measure_file(source.encode(), POWERSHELL)


def function_named(source: str, name: str = "F"):
    (function,) = [f for f in measure_ps(source).functions if f.name == name]
    return function


def in_function(body: str):
    return function_named(f"function F {{\n{body}\n}}\n")


def test_function_names_and_script():
    source = "function Get-X { 1 }\nfilter Select-Y { $_ }\nclass K {\n  K() { }\n  [int] M() { return 1 }\n}\n"

    functions = measure_ps(source).functions

    assert [(f.name, f.is_constructor) for f in functions] == [
        ("<script>", False),
        ("Get-X", False),
        ("Select-Y", False),
        ("K.K", True),
        ("K.M", False),
    ]


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        ("function F { param([string]$A, [int]$B = 1, [switch]$C) 1 }", 3),
        ("function F($A, $B) { 1 }", 2),
        ("function F { 1 }", 0),
        ("class K {\n  [int] F([int]$a, [int]$b) { return 1 }\n}", 2),
    ],
)
def test_parameter_count(source, expected):
    name = "K.F" if source.startswith("class") else "F"
    assert function_named(source, name).parameters == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if ($a) { } elseif ($b) { } else { }", 3),
        ("foreach ($x in $a) { }", 2),
        ("for ($i = 0; $i -lt 3; $i++) { }", 2),
        ("while ($a) { }", 2),
        ("do { } until ($a)", 2),
        ("switch ($a) {\n  'x' { }\n  'y' { }\n  default { }\n}", 3),
        ("try { } catch [IOException] { } catch { } finally { }", 3),
        ("$r = $a -and $b -or $c", 3),
        ("$a | ForEach-Object { if ($_) { } }", 2),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_function(body).cyclomatic == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if ($a) { if ($b) { if ($c) { } } }", 3),
        ("if ($a) { } elseif ($b) { } elseif ($c) { if ($d) { } }", 2),
        ("foreach ($x in $a) { while ($b) { try { } catch { } } }", 3),
    ],
)
def test_max_nesting(body, expected):
    assert in_function(body).max_nesting == expected


def test_bumps():
    body = "foreach ($x in $a) { if ($x) { } }\nwhile ($b) { if ($c) { } }"

    assert in_function(body).bumps == 2


@pytest.mark.parametrize(
    "body",
    [
        "if ($a -and $b) { }",
        "if ($c) { } elseif ($a -and $b) { }",
        "while ($a -and $b) { }",
        "do { } while ($a -and $b)",
    ],
)
def test_conditions_are_recorded(body):
    assert Condition(line=2, operators=1) in in_function(body).conditions


@pytest.mark.parametrize(
    "source",
    [
        "$a = $b ?? 'x'\n",
        "switch ($a) { 'x' { } 'y' { } }\n",
        "$x = $a ? 1 : 2\n",
        "docker tag ${svc}:latest $registry/${svc}:main\n",
    ],
    ids=["null coalescing", "one-line switch", "ternary", "braced variable before a colon"],
)
def test_known_parse_gaps(source):
    assert measure_ps(source).parse_errors > 0


@pytest.mark.parametrize(
    "number",
    ["1MB", "1KB", "1Gb", "1.5MB", "0x10MB", "1L", "1D", "1E3", "0XFF"],
)
def test_uppercase_letters_in_a_number_after_an_operator_parse(number):
    assert measure_ps(f"$x = $a / {number}\n").parse_errors == 0


def test_uppercase_number_after_a_unary_minus_parses():
    assert measure_ps("$x = -1MB\n").parse_errors == 0


@pytest.mark.parametrize("left", ["$a", "${a b}", "$env:X", "$a.Count"])
def test_uppercase_number_subtracted_without_spaces_parses(left):
    assert measure_ps(f"$x = {left}-1MB\n").parse_errors == 0


def test_uppercase_numbers_keep_line_numbers_and_conditions():
    function = function_named("$x = $a / 1MB\nfunction F {\n  if ($a -gt 1MB) { }\n}\n")

    assert function.line == 2
    assert [condition.line for condition in function.conditions] == [3]


def test_a_number_inside_a_function_name_keeps_its_case():
    assert function_named("function Get-1MB { }\n", "Get-1MB").line == 1


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "powershell"
    lf = measure_file((fixtures / "smells.ps1").read_bytes(), POWERSHELL)
    crlf = measure_file((fixtures / "smells-crlf.ps1").read_bytes(), POWERSHELL)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "Get-Description", 3, 11, 10),
        ("Deep Nested Complexity", "Test-Deep", 20, 4, 4),
        ("Bumpy Road", "Get-Bumpy", 33, 2, 2),
        ("Complex Conditional", "Test-Eligible", 45, 2, 2),
        ("Large Method", "Get-Large", 51, 72, 70),
        ("Excess Function Arguments", "Send-Order", 124, 5, 5),
        ("Excess Function Arguments", "Orders.Orders", 130, 8, 8),
    ]
