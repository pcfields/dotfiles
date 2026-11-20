from collections.abc import Iterable
from dataclasses import dataclass

from code_health.smells import Finding

FAILING = frozenset({"new", "worse"})


@dataclass(frozen=True)
class Change:
    status: str
    finding: Finding
    before_value: int | None


def compare(before: Iterable[Finding], after: Iterable[Finding]) -> tuple[Change, ...]:
    previous = {_key(finding): finding for finding in before}
    current = {_key(finding) for finding in after}
    changes = [_classify(finding, previous.get(_key(finding))) for finding in after]
    fixed = [Change("fixed", old, old.value) for key, old in previous.items() if key not in current]
    return tuple(changes + fixed)


def _classify(finding: Finding, old: Finding | None) -> Change:
    if old is None:
        return Change("new", finding, None)
    status = "worse" if finding.value > old.value else "existing"
    return Change(status, finding, old.value)


def fails(changes: Iterable[Change]) -> bool:
    return any(change.status in FAILING for change in changes)


def _key(finding: Finding) -> tuple[str, str]:
    return (finding.smell, finding.function)
