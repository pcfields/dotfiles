import re
from collections.abc import Mapping
from dataclasses import dataclass

from code_health.measure import SCRIPT, FileMetrics, FunctionMetrics

FILE = "<file>"
INVALID_IGNORE = "Invalid Ignore Comment"
NEW_IGNORE = "Ignore Comment"
MOCKED_OWN_MODULE = "Mocked Own Module"
LARGE_ASSERTION_BLOCK = "Large Assertion Block"
OVERALL_COMPLEXITY = "Overall Code Complexity"


@dataclass(frozen=True)
class Finding:
    smell: str
    function: str
    line: int
    value: int
    limit: int


DEFAULT_LIMITS = {
    "Complex Method": 10,
    "Deep Nested Complexity": 4,
    "Bumpy Road": 2,
    "Complex Conditional": 2,
    "Large Method": 70,
    "Excess Function Arguments": 5,
    "Excess Function Arguments (constructor)": 8,
    "Large File": 1000,
    "Mocked Own Module": 1,
    "Large Assertion Block": 8,
    "Overall Code Complexity": 6,
}
OVERALL_MIN_FUNCTIONS = 5


def find_smells(metrics: FileMetrics, limits: Mapping[str, float] = DEFAULT_LIMITS) -> tuple[Finding, ...]:
    findings = [finding for function in metrics.functions for finding in _function_findings(function, limits)]
    findings += _overall_complexity(metrics, limits)
    if metrics.own_module_mocks:
        first = metrics.own_module_mocks[0]
        findings.append(Finding(MOCKED_OWN_MODULE, FILE, first, len(metrics.own_module_mocks), limits[MOCKED_OWN_MODULE]))
    if metrics.loc >= limits["Large File"]:
        findings.append(Finding("Large File", FILE, 1, metrics.loc, limits["Large File"]))
    return tuple(findings)


def _function_findings(function: FunctionMetrics, limits: Mapping[str, float]) -> list[Finding]:
    arguments = "Excess Function Arguments (constructor)" if function.is_constructor else "Excess Function Arguments"
    measurements = [
        ("Complex Method", function.cyclomatic, function.line, limits["Complex Method"]),
        ("Deep Nested Complexity", function.max_nesting, function.line, limits["Deep Nested Complexity"]),
        ("Bumpy Road", function.bumps, function.line, limits["Bumpy Road"]),
        ("Complex Conditional", *_worst_condition(function), limits["Complex Conditional"]),
        ("Large Method", function.loc, function.line, limits["Large Method"]),
        ("Excess Function Arguments", function.parameters, function.line, limits[arguments]),
        (LARGE_ASSERTION_BLOCK, function.assertion_run, function.line, limits[LARGE_ASSERTION_BLOCK]),
    ]
    return [
        Finding(smell, function.name, line, value, limit)
        for smell, value, line, limit in measurements
        if value >= limit and not (smell == "Large Method" and _is_container(function))
    ]


# Top-level script code, module-wrapping IIFEs and test-suite blocks are long
# because they hold other code, each piece of which is measured on its own.
_TEST_GROUP = re.compile(r"(?:^|\.)(?:describe|context|suite) callback(?: #\d+)?$")


def _is_container(function: FunctionMetrics) -> bool:
    return function.wraps_module or function.name == SCRIPT or _TEST_GROUP.search(function.name) is not None


def _overall_complexity(metrics: FileMetrics, limits: Mapping[str, float]) -> list[Finding]:
    functions = [f for f in metrics.functions if f.name != SCRIPT]
    if len(functions) < OVERALL_MIN_FUNCTIONS:
        return []
    average = round(sum(f.cyclomatic for f in functions) / len(functions), 1)
    limit = limits[OVERALL_COMPLEXITY]
    return [Finding(OVERALL_COMPLEXITY, FILE, 1, average, limit)] if average >= limit else []


def _worst_condition(function: FunctionMetrics) -> tuple[int, int]:
    worst = max(function.conditions, key=lambda c: c.operators, default=None)
    return (worst.operators, worst.line) if worst else (0, function.line)


FIX_HINTS = {
    "Complex Method": "Extract Function; Decompose Conditional",
    "Deep Nested Complexity": "Replace Nested Conditional with Guard Clauses; Extract Function",
    "Bumpy Road": "Extract Function per bump",
    "Complex Conditional": "Decompose Conditional; Explaining variable",
    "Large Method": "Extract Function; Split Phase",
    "Excess Function Arguments": "Introduce Parameter Object",
    "Large File": "Split the module by responsibility",
    OVERALL_COMPLEXITY: "Extract Function from the branchiest functions; split the module by responsibility",
    LARGE_ASSERTION_BLOCK: "Assert on one expected object; split the test by behavior",
    MOCKED_OWN_MODULE: "Test through the public interface; use an in-memory fake instead of mocking your own module",
    INVALID_IGNORE: "Write `code-health: ignore <Smell> -- <reason>`, or remove it",
    NEW_IGNORE: "Fix the finding instead, or ask the user to accept the ignore comment",
}

SMELLS = frozenset(FIX_HINTS)
MEASURED_SMELLS = frozenset(FIX_HINTS) - {INVALID_IGNORE, NEW_IGNORE}
