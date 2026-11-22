from collections.abc import Iterable, Mapping
from dataclasses import dataclass

from code_health.score import SCORER_VERSION
from code_health.smells import NEW_IGNORE, Finding


class AcceptError(Exception):
    pass


@dataclass(frozen=True)
class Target:
    path: str
    finding: Finding
    digest: str


def candidates(findings: Iterable[Finding], ignores: Iterable) -> list[Finding]:
    return [*findings, *(Finding(NEW_IGNORE, i.function, i.line, 1, 1) for i in ignores)]


def select(candidates: list[Finding], path: str, smell: str, function: str | None) -> Finding:
    matching = [c for c in candidates if c.smell == smell and function in (None, c.function)]
    if not matching:
        where = f" in {function}" if function else ""
        raise AcceptError(f"no {smell} finding{where} in {path}")
    if len(matching) > 1:
        names = ", ".join(sorted({c.function for c in matching}))
        raise AcceptError(f"{smell} is found in {names}: pass --function")
    return matching[0]


def record(target: Target, reason: str, today: str) -> dict:
    return {
        "file": target.path,
        "smell": target.finding.smell,
        "function": target.finding.function,
        "hash": target.digest,
        "value": target.finding.value,
        "reason": reason,
        "date": today,
        "scorer_version": SCORER_VERSION,
    }


def is_accepted(records: Iterable[Mapping], target: Target) -> bool:
    return any(record_matches(r, target) for r in records)


def record_matches(entry: Mapping, target: Target) -> bool:
    wanted = record(target, reason="", today="")
    return all(entry.get(key) == wanted[key] for key in ("file", "smell", "function", "hash"))
