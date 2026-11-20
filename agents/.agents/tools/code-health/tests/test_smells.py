from dataclasses import replace

import pytest
from code_health.measure import Condition, FileMetrics, FunctionMetrics
from code_health.smells import Finding, find_smells

CLEAN = FunctionMetrics(
    name="f",
    line=3,
    loc=10,
    is_constructor=False,
    cyclomatic=1,
    max_nesting=0,
    parameters=0,
    bumps=0,
    conditions=(),
)


def smells_of(function=CLEAN, file_loc=100):
    return find_smells(FileMetrics(loc=file_loc, parse_errors=0, functions=(function,)))


def test_clean_function_has_no_findings():
    assert smells_of() == ()


@pytest.mark.parametrize(
    ("smell", "field", "under", "limit"),
    [
        ("Complex Method", "cyclomatic", 9, 10),
        ("Deep Nested Complexity", "max_nesting", 3, 4),
        ("Bumpy Road", "bumps", 1, 2),
        ("Large Method", "loc", 69, 70),
        ("Excess Function Arguments", "parameters", 4, 5),
    ],
)
def test_function_smell_fires_at_its_limit(smell, field, under, limit):
    assert smells_of(replace(CLEAN, **{field: under})) == ()
    assert smells_of(replace(CLEAN, **{field: limit})) == (
        Finding(smell=smell, function="f", line=3, value=limit, limit=limit),
    )


def test_constructor_allows_more_parameters():
    constructor = replace(CLEAN, name="Cart.constructor", is_constructor=True)

    assert smells_of(replace(constructor, parameters=7)) == ()
    assert smells_of(replace(constructor, parameters=8)) == (
        Finding(smell="Excess Function Arguments", function="Cart.constructor", line=3, value=8, limit=8),
    )


def test_complex_conditional_reports_the_worst_condition():
    conditions = (Condition(line=4, operators=1), Condition(line=7, operators=3), Condition(line=9, operators=2))

    assert smells_of(replace(CLEAN, conditions=conditions)) == (
        Finding(smell="Complex Conditional", function="f", line=7, value=3, limit=2),
    )


def test_single_operator_conditions_are_fine():
    assert smells_of(replace(CLEAN, conditions=(Condition(line=4, operators=1),))) == ()


def test_large_file_is_reported_against_the_file():
    assert smells_of(file_loc=999) == ()
    assert smells_of(file_loc=1000) == (
        Finding(smell="Large File", function="<file>", line=1, value=1000, limit=1000),
    )
