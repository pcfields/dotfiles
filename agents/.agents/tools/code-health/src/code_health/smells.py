from dataclasses import dataclass

from code_health.measure import FileMetrics, FunctionMetrics

FILE = "<file>"


@dataclass(frozen=True)
class Finding:
    smell: str
    function: str
    line: int
    value: int
    limit: int


def find_smells(metrics: FileMetrics) -> tuple[Finding, ...]:
    findings = [finding for function in metrics.functions for finding in _function_findings(function)]
    if metrics.loc >= LARGE_FILE_LIMIT:
        findings.append(Finding("Large File", FILE, 1, metrics.loc, LARGE_FILE_LIMIT))
    return tuple(findings)


LARGE_FILE_LIMIT = 1000


def _function_findings(function: FunctionMetrics) -> list[Finding]:
    measurements = [
        ("Complex Method", function.cyclomatic, function.line, 10),
        ("Deep Nested Complexity", function.max_nesting, function.line, 4),
        ("Bumpy Road", function.bumps, function.line, 2),
        ("Complex Conditional", *_worst_condition(function), 2),
        ("Large Method", function.loc, function.line, 70),
        ("Excess Function Arguments", function.parameters, function.line, 8 if function.is_constructor else 5),
    ]
    return [
        Finding(smell, function.name, line, value, limit)
        for smell, value, line, limit in measurements
        if value >= limit
    ]


def _worst_condition(function: FunctionMetrics) -> tuple[int, int]:
    worst = max(function.conditions, key=lambda c: c.operators, default=None)
    return (worst.operators, worst.line) if worst else (0, function.line)
