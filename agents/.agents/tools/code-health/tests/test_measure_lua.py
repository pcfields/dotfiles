from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

LUA = language_for_path("x.lua")


def measure_lua(source: str):
    return measure_file(source.encode(), LUA)


def function_named(source: str, name: str = "f"):
    (function,) = [f for f in measure_lua(source).functions if f.name == name]
    return function


def in_function(body: str):
    return function_named(f"local function f(a, b, c)\n{body}\nend\n")


def test_function_names():
    source = (
        "function M.f(a) end\n"
        "function M:g(x) end\n"
        "local function h() end\n"
        "M.k = function(y) end\n"
        "local t = { cb = function() end }\n"
        "local function setup()\n  vim.keymap.set('n', 'x', function() return 1 end)\nend\n"
    )

    assert [f.name for f in measure_lua(source).functions] == [
        "<script>",
        "M.f",
        "M:g",
        "h",
        "M.k",
        "cb",
        "setup",
        "setup.set callback",
    ]


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a then elseif b then else end", 3),
        ("for i = 1, 3 do end", 2),
        ("for _, v in ipairs(a) do end", 2),
        ("while a do end", 2),
        ("repeat until a", 2),
        ("return a and b or c", 3),
        ("return not a", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_function(body).cyclomatic == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a then if b then if c then end end end", 3),
        ("if a then elseif b then elseif c then if a then end end", 2),
        ("for i = 1, 3 do while a do repeat until b end end", 3),
    ],
)
def test_max_nesting(body, expected):
    assert in_function(body).max_nesting == expected


def test_parameters_include_varargs():
    assert function_named("function f(a, b, ...) end").parameters == 3


@pytest.mark.parametrize(
    "body",
    ["if a and b then end", "if c then elseif a and b then end", "while a and b do end", "repeat until a and b"],
)
def test_conditions_are_recorded(body):
    assert Condition(line=2, operators=1) in in_function(body).conditions


def test_comment_lines_are_not_code():
    source = "-- a comment\n--[[ a\nblock comment ]]\nlocal function f()\n  return 1 -- trailing\nend\n"

    metrics = measure_lua(source)

    assert (metrics.loc, function_named(source).loc) == (3, 3)


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "lua"
    lf = measure_file((fixtures / "smells.lua").read_bytes(), LUA)
    crlf = measure_file((fixtures / "smells-crlf.lua").read_bytes(), LUA)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "M.describe", 4, 11, 10),
        ("Deep Nested Complexity", "M.deep", 29, 4, 4),
        ("Bumpy Road", "M.bumpy", 42, 2, 2),
        ("Complex Conditional", "M.eligible", 54, 2, 2),
        ("Large Method", "M.large", 60, 72, 70),
        ("Excess Function Arguments", "M.ship", 133, 5, 5),
    ]
