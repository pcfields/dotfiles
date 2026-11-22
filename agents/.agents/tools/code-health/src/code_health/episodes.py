from collections import Counter
from dataclasses import dataclass
from datetime import datetime

from code_health.score import SCORER_VERSION

GLOBAL_KEYS = frozenset(
    {
        "date", "scorer_version", "kind", "language", "loc_band", "functions",
        "score_before", "score_after", "findings_before", "findings_after",
        "iterations", "duration_s", "tests_passed", "tokens", "token_method", "model", "harness",
    }
)
KINDS = ("safeguard-fix", "uplift")
_BANDS = ((100, "<100"), (500, "100-500"), (1000, "500-1000"), (2000, "1000-2000"))


@dataclass(frozen=True)
class Step:
    kind: str
    session: str
    states: list[dict]
    now: datetime
    tests_passed: bool | None = None


def start_episode(pending: list[dict], step: Step) -> list[dict]:
    open_episode = _open(pending, step.kind, step.session)
    states = step.states
    if open_episode is None:
        episode = {
            "kind": step.kind,
            "session": step.session,
            "files": [s["path"] for s in states],
            "started": step.now.isoformat(),
            "iterations": 1,
            "baseline": states,
            "ended": None,
            "after": None,
            "tests_passed": None,
        }
        return [*pending, episode]
    new = [s for s in states if s["path"] not in open_episode["files"]]
    grown = {
        **open_episode,
        "files": [*open_episode["files"], *(s["path"] for s in new)],
        "baseline": [*open_episode["baseline"], *new],
    }
    return [grown if e is open_episode else e for e in pending]


def tick(pending: list[dict], session: str) -> list[dict]:
    return [
        {**e, "iterations": e["iterations"] + 1} if e["session"] == session and e["ended"] is None else e for e in pending
    ]


def end_episode(pending: list[dict], step: Step) -> list[dict]:
    open_episode = _open(pending, step.kind, step.session)
    if open_episode is None:
        return pending
    ended = {**open_episode, "ended": step.now.isoformat(), "after": step.states, "tests_passed": step.tests_passed}
    return [ended if e is open_episode else e for e in pending]


def generic_record(episode: dict, tokens, token_method: str, harness: str) -> dict:
    before, after = _combined(episode["baseline"]), _combined(episode["after"])
    started, ended = datetime.fromisoformat(episode["started"]), datetime.fromisoformat(episode["ended"])
    return {
        "date": ended.date().isoformat(),
        "scorer_version": SCORER_VERSION,
        "kind": episode["kind"],
        "language": after["language"] or before["language"],
        "loc_band": loc_band(after["loc"]),
        "functions": after["functions"],
        "score_before": before["score"],
        "score_after": after["score"],
        "findings_before": before["findings"],
        "findings_after": after["findings"],
        "iterations": episode["iterations"],
        "duration_s": int((ended - started).total_seconds()),
        "tests_passed": episode["tests_passed"],
        "tokens": {
            "input": tokens.input if tokens else 0,
            "output": tokens.output if tokens else 0,
            "cache_creation": tokens.cache_creation if tokens else 0,
            "cache_read": tokens.cache_read if tokens else 0,
        },
        "token_method": token_method,
        "model": tokens.model if tokens else None,
        "harness": harness,
    }


def loc_band(loc: int) -> str:
    return next((band for limit, band in _BANDS if loc < limit), "2000+")


def ended(pending: list[dict]) -> list[dict]:
    return [e for e in pending if e["ended"] is not None]


def still_open(pending: list[dict]) -> list[dict]:
    return [e for e in pending if e["ended"] is None]


def _open(pending: list[dict], kind: str, session: str) -> dict | None:
    return next((e for e in pending if e["kind"] == kind and e["session"] == session and e["ended"] is None), None)


def _combined(states: list[dict]) -> dict:
    loc = sum(s["loc"] for s in states)
    languages: Counter[str] = Counter()
    findings: Counter[str] = Counter()
    for s in states:
        languages[s["language"]] += s["loc"]
        findings.update(s["findings"])
    score = round(sum(s["score"] * s["loc"] for s in states) / loc, 1) if loc else None
    return {
        "loc": loc,
        "functions": sum(s["functions"] for s in states),
        "score": score,
        "findings": dict(sorted(findings.items())),
        "language": languages.most_common(1)[0][0] if languages else None,
    }
