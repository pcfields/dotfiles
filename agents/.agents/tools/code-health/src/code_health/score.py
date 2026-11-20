import math
from collections.abc import Iterable, Mapping

from code_health.smells import Finding

SCORER_VERSION = "1"

DECAY = 0.12
OVERAGE_FACTOR = 2.0
CAP = 4.0
BASE = {"Deep Nested Complexity": 1.5, "Complex Method": 1.25}


def score_file(findings: Iterable[Finding], weights: Mapping[str, float] | None = None) -> float:
    weights = weights or {}
    total = sum(_penalty(finding, weights.get(finding.smell, 1.0)) for finding in findings)
    return round(1 + 9 * math.exp(-DECAY * total), 1)


def band(score: float) -> str:
    if score >= 9:
        return "green"
    return "yellow" if score >= 4 else "red"


def _penalty(finding: Finding, weight: float) -> float:
    base = BASE.get(finding.smell, 1.0)
    over = (finding.value - finding.limit) / finding.limit
    return weight * min(base * (1 + OVERAGE_FACTOR * over), CAP * base)
