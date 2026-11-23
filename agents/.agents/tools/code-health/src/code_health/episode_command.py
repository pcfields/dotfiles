import argparse
import datetime
import os
import sys
from collections import Counter
from dataclasses import replace
from pathlib import Path

from code_health import episodes, gitio, history, state
from code_health.harness import claude
from code_health.languages import language_for_path
from code_health.report import review_source
from code_health.workspace import repo_relative, working_config


def run_episode(cwd: Path, args: argparse.Namespace) -> str:
    root = gitio.repo_root(cwd)
    gitio.ensure_excluded(root, f"/{history.STATE_DIR}/")
    pending = history.read_pending(root)
    now = datetime.datetime.now(datetime.UTC)
    if args.action == "start":
        states = _file_states(root, args.files)
        pending = episodes.start_episode(pending, episodes.Step(args.kind, args.session, states, now))
    elif args.action == "end":
        tests = {"yes": True, "no": False}.get(args.tests_passed)
        pending = _end_open(root, pending, episodes.Step(args.kind, args.session, [], now, tests))
    else:
        pending = _flush(root, pending, args.session, args.transcript)
    history.write_pending(root, pending)
    return ""


def _flush(root: Path, pending: list[dict], session: str, transcript: str | None) -> list[dict]:
    lines = _read_transcript(transcript)
    global_dir = os.environ.get(history.HISTORY_ENV)
    if not global_dir and episodes.ended(pending):
        _note_missing_history_dir()
    for episode in episodes.ended(pending):
        _append_records(root, episode, _episode_record(episode, lines, session))
    return episodes.still_open(pending)


def _note_missing_history_dir() -> None:
    if state.note_once("history-dir"):
        print(f"code-health: {history.HISTORY_ENV} is not set, so episodes are recorded only in this repo", file=sys.stderr)


def _episode_record(episode: dict, lines: list[str] | None, session: str) -> dict:
    if lines is None:
        return episodes.generic_record(episode, None, token_method="none", harness="unknown")
    window = (datetime.datetime.fromisoformat(episode["started"]), datetime.datetime.fromisoformat(episode["ended"]))
    tokens = claude.count_tokens(lines, *window)
    method = "claude-transcript-window" if episode["session"] == session else "partial"
    return episodes.generic_record(episode, tokens, token_method=method, harness=claude.HARNESS)


def _file_states(root: Path, paths: list[str]) -> list[dict]:
    config = working_config(root)
    states = []
    for path in paths:
        relative = repo_relative(root, path)
        try:
            source = (root / relative).read_bytes()
        except OSError:
            continue
        report = review_source(relative, source, config)
        if report.score is None:
            continue
        functions = [f for f in report.metrics.functions if f.name != "<script>"]
        states.append({
            "path": relative,
            "language": language_for_path(relative).name,
            "score": report.score,
            "loc": report.metrics.loc,
            "functions": len(functions),
            "findings": dict(Counter(f.smell for f in report.findings)),
        })
    return states


def track_safely(cwd: Path, session: str, transcript: str | None, checks: list) -> None:
    # Bookkeeping must never change the safeguard's verdict.
    try:
        root = gitio.repo_root(cwd)
        _track(root, session, transcript, [check.path for check in checks if check.status == "worse"])
        _record_turn(root, session, transcript, checks)
    except (OSError, ValueError, gitio.GitError) as error:
        print(f"code-health: episode not recorded: {error}", file=sys.stderr)


def _track(root: Path, session: str, transcript: str | None, worse: list[str]) -> None:
    gitio.ensure_excluded(root, f"/{history.STATE_DIR}/")
    pending = episodes.tick(history.read_pending(root), session)
    now = datetime.datetime.now(datetime.UTC)
    if worse:
        pending = episodes.start_episode(pending, episodes.Step("safeguard-fix", session, _file_states(root, worse), now))
    else:
        pending = _end_open(root, pending, episodes.Step("safeguard-fix", session, [], now))
    history.write_pending(root, _flush(root, pending, session, transcript))


def _record_turn(root: Path, session: str, transcript: str | None, checks: list) -> None:
    scored = [check for check in checks if check.after is not None]
    started = state.read_turn_started(root, session)
    if not scored or started is None:
        return
    change = _change(scored, session, started, datetime.datetime.now(datetime.UTC))
    _append_records(root, change, _episode_record(change, _read_transcript(transcript), session))


def _change(scored: list, session: str, started: datetime.datetime, now: datetime.datetime) -> dict:
    return {
        "kind": "change",
        "session": session,
        "files": [check.path for check in scored],
        "started": started.isoformat(),
        "ended": now.isoformat(),
        "iterations": 1,
        "baseline": [_state(check, before=True) for check in scored if check.before is not None],
        "after": [_state(check, before=False) for check in scored],
        "tests_passed": None,
    }


def _append_records(root: Path, episode: dict, record: dict) -> None:
    local = {key: episode[key] for key in ("files", "session", "started", "ended")}
    history.append_local_episode(root, {**record, **local})
    if global_dir := os.environ.get(history.HISTORY_ENV):
        history.append_global_episode(Path(global_dir), record)


def _state(check, before: bool) -> dict:
    statuses = ("existing", "worse", "fixed") if before else ("new", "worse", "existing", "accepted")
    findings = Counter(c.finding.smell for c in check.changes if c.status in statuses)
    return {
        "path": check.path,
        "language": check.language,
        "score": check.before if before else check.after,
        "loc": (check.loc_before if before else check.loc_after) or 0,
        "functions": check.functions,
        "findings": dict(findings),
    }


def _read_transcript(transcript: str | None) -> list[str] | None:
    return Path(transcript).read_text(encoding="utf-8", errors="replace").splitlines() if transcript else None


def _end_open(root: Path, pending: list[dict], step) -> list[dict]:
    episode = next((e for e in episodes.still_open(pending) if e["kind"] == step.kind and e["session"] == step.session), None)
    if episode is None:
        return pending
    return episodes.end_episode(pending, replace(step, states=_file_states(root, episode["files"])))
