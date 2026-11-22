from collections.abc import Mapping
from dataclasses import dataclass

from code_health.measure import SCRIPT, FileMetrics, FunctionMetrics

FILE = "<file>"
INVALID_IGNORE = "Invalid Ignore Comment"
NEW_IGNORE = "Ignore Comment"


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
}


def find_smells(metrics: FileMetrics, limits: Mapping[str, float] = DEFAULT_LIMITS) -> tuple[Finding, ...]:
    findings = [finding for function in metrics.functions for finding in _function_findings(function, limits)]
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
    ]
    return [
        Finding(smell, function.name, line, value, limit)
        for smell, value, line, limit in measurements
        if value >= limit and not (smell == "Large Method" and function.name == SCRIPT)
    ]


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
    INVALID_IGNORE: "Write `code-health: ignore <Smell> -- <reason>`, or remove it",
    NEW_IGNORE: "Fix the finding instead, or ask the user to accept the ignore comment",
}

SMELLS = frozenset(FIX_HINTS)
MEASURED_SMELLS = frozenset(FIX_HINTS) - {INVALID_IGNORE, NEW_IGNORE}
