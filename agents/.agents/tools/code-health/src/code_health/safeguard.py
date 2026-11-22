from collections.abc import Iterable, Mapping
from dataclasses import asdict, dataclass, replace

from code_health.accept import Target, is_accepted
from code_health.config import DEFAULT_CONFIG, Config
from code_health.delta import FAILING, Change, compare, fails
from code_health.languages import language_for_path
from code_health.report import describe, review_source
from code_health.score import SCORER_VERSION
from code_health.smells import FIX_HINTS, NEW_IGNORE, Finding


@dataclass(frozen=True)
class FileCheck:
    path: str
    before: float | None
    after: float | None
    status: str
    changes: tuple[Change, ...] = ()
    reason: str | None = None


def is_checked(path: str) -> bool:
    return language_for_path(path) is not None


@dataclass(frozen=True)
class CheckContext:
    config: Config = DEFAULT_CONFIG
    accepted: tuple[Mapping, ...] = ()


NO_CONTEXT = CheckContext()


def check_file(
    path: str, before_source: bytes | None, after_source: bytes, context: CheckContext = NO_CONTEXT
) -> FileCheck:
    config = context.config
    after = review_source(path, after_source, config)
    if after.score is None:
        return FileCheck(path, None, None, "not scored", reason=after.reason)
    before = review_source(path, before_source, config) if before_source is not None else None
    before_score = before.score if before else None
    changes = compare(before.findings if before else (), after.findings) + _new_ignores(before, after)
    changes = tuple(_with_acceptance(change, path, after, context.accepted) for change in changes)
    return FileCheck(path, before_score, after.score, _status(changes, before_score, after.score), changes)


def _with_acceptance(change: Change, path: str, after, accepted: Iterable[Mapping]) -> Change:
    if change.status not in FAILING:
        return change
    if not is_accepted(accepted, Target(path, change.finding, after.digest_for(change.finding.function))):
        return change
    return replace(change, status="accepted")


def _new_ignores(before, after) -> tuple[Change, ...]:
    existing = {(i.smell, i.function) for i in before.ignores} if before else set()
    return tuple(
        Change("new", Finding(NEW_IGNORE, ignore.function, ignore.line, 1, 1), None)
        for ignore in after.ignores
        if (ignore.smell, ignore.function) not in existing
    )


def format_safeguard(checks: list[FileCheck], notes: tuple[str, ...] = ()) -> str:
    worse = sum(1 for check in checks if check.status == "worse")
    count = f"{len(checks)} file{'' if len(checks) == 1 else 's'} checked"
    if not worse:
        header = f"code-health safeguard: PASS ({count})"
    else:
        header = f"code-health safeguard: FAIL ({count}, {worse} got worse)"
    blocks = [header, *(["\n".join(f"! {note}" for note in notes)] if notes else []), *map(_format_check, checks)]
    if worse:
        blocks.append(_footer(checks))
    return "\n\n".join(blocks)


def safeguard_json(checks: list[FileCheck], notes: tuple[str, ...] = ()) -> dict:
    return {
        "verdict": "fail" if any(check.status == "worse" for check in checks) else "pass",
        "scorer_version": SCORER_VERSION,
        "notes": list(notes),
        "files": [_check_json(check) for check in checks],
    }


def _status(changes: tuple[Change, ...], before: float | None, after: float) -> str:
    if fails(changes):
        return "worse"
    if before is not None and after > before:
        return "better"
    return "same"


_MARKERS = {
    "new": "x new",
    "worse": "x worse",
    "existing": "! existing",
    "fixed": "ok fixed",
    "accepted": "ok accepted",
}


def _format_check(check: FileCheck) -> str:
    if check.after is None:
        return f"{check.path}  not scored ({check.reason})"
    before = "new" if check.before is None else f"{check.before:.1f}"
    lines = [f"{check.path}  {before} -> {check.after:.1f}  {check.status}"]
    width = max((len(change.finding.smell) for change in check.changes), default=0)
    for change in check.changes:
        lines.append(f"  {_MARKERS[change.status]:<10}  {change.finding.smell:<{width}}  {_detail(change)}".rstrip())
        if change.status in FAILING:
            lines.append(f"  {'':<10}  fix: {FIX_HINTS[change.finding.smell]}")
    return "\n".join(lines)


def _detail(change: Change) -> str:
    finding = change.finding
    if change.status == "fixed":
        return finding.function
    was = f", was {change.before_value}" if change.status == "worse" else ""
    return f"{finding.function}:{finding.line}  {describe(finding, was)}"


def _footer(checks: list[FileCheck]) -> str:
    accepts = [
        f'  code-health accept {check.path} --smell "{change.finding.smell}"'
        f' --function {change.finding.function} --reason "<why>"'
        for check in checks
        for change in check.changes
        if change.status in FAILING
    ]
    return "\n".join(
        [
            'Refactor until no "x" lines remain, then run `code-health safeguard` again.',
            "Lower numbers with worse readability is a failure: don't split code into",
            "pieces too small to follow. If a finding has to stay, ask the user. Only",
            "they can run, in a terminal:",
            *accepts,
        ]
    )


def _check_json(check: FileCheck) -> dict:
    data = {"path": check.path, "before": check.before, "after": check.after, "status": check.status}
    if check.reason:
        data["reason"] = check.reason
    else:
        data["findings"] = [
            {
                "status": change.status,
                **asdict(change.finding),
                "before_value": change.before_value,
                "fix": FIX_HINTS[change.finding.smell],
            }
            for change in check.changes
        ]
    return data
