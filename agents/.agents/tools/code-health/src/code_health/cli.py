import argparse
import datetime
import json
import os
import sys
from collections import Counter
from dataclasses import replace
from pathlib import Path

import tree_sitter_language_pack as pack

from code_health import episodes, gitio, history, state
from code_health.accept import AcceptError, Target, candidates, record, select
from code_health.config import (
    CONFIG_FILE,
    DEFAULT_CONFIG,
    Config,
    ConfigError,
    is_excluded,
    parse_config,
)
from code_health.harness import claude
from code_health.languages import language_for_path
from code_health.repo import (
    RepoFile,
    RepoInput,
    build_report,
    churn,
    coupling,
    format_repo,
    is_binary,
    is_prose_or_data,
    parse_log,
)
from code_health.report import (
    FileReport,
    describe,
    format_review,
    format_score_line,
    review_source,
    to_json,
)
from code_health.safeguard import (
    CheckContext,
    FileCheck,
    check_file,
    format_safeguard,
    is_checked,
    safeguard_json,
)

SAFEGUARD_FAILED = 2


def main(argv: list[str] | None = None) -> int:
    # A Windows console on a legacy code page can't encode every path name.
    sys.stdout.reconfigure(errors="replace")
    try:
        args = _parser().parse_args(sys.argv[1:] if argv is None else argv)
    except SystemExit as stop:
        return 0 if stop.code == 0 else 1
    try:
        output, code = _run(args)
    except (ToolError, gitio.GitError, ConfigError) as error:
        print(f"code-health: {error}", file=sys.stderr)
        return 1
    except pack.Error as error:
        print(f"code-health: cannot load a grammar (it downloads on first use): {error}", file=sys.stderr)
        return 1
    if output:
        print(output)
    return code


class ToolError(Exception):
    pass


def _run(args: argparse.Namespace) -> tuple[str, int]:
    handlers = {
        "mark-turn": lambda: (_mark_turn(Path.cwd(), args.session), 0),
        "accept": lambda: _accept(Path.cwd(), args),
        "repo": lambda: _run_repo(args),
        "episode": lambda: (_run_episode(Path.cwd(), args), 0),
        "safeguard": lambda: _run_safeguard(args),
    }
    return handlers.get(args.command, lambda: _run_files(args))()


def _run_episode(cwd: Path, args: argparse.Namespace) -> str:
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
    lines = Path(transcript).read_text(encoding="utf-8", errors="replace").splitlines() if transcript else None
    global_dir = os.environ.get(history.HISTORY_ENV)
    if not global_dir and episodes.ended(pending):
        _note_missing_history_dir()
    for episode in episodes.ended(pending):
        record = _episode_record(episode, lines, session)
        history.append_local_episode(root, {**record, "files": episode["files"], "session": episode["session"],
                                            "started": episode["started"], "ended": episode["ended"]})
        if global_dir:
            history.append_global_episode(Path(global_dir), record)
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
    config = _working_config(root)
    states = []
    for path in paths:
        relative = _repo_relative(root, path)
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


def _run_repo(args: argparse.Namespace) -> tuple[str, int]:
    report = _repo_report(Path.cwd(), args)
    return (json.dumps(report, indent=2) if args.json else format_repo(report)), 0


def _run_safeguard(args: argparse.Namespace) -> tuple[str, int]:
    checks, notes = _safeguard_checks(Path.cwd(), args.base, args.session if args.since_turn else None)
    verdict = safeguard_json(checks, notes)
    if args.episode:
        _track_episode_safely(args, checks)
    output = json.dumps(verdict, indent=2) if args.json else format_safeguard(checks, notes)
    return output, SAFEGUARD_FAILED if verdict["verdict"] == "fail" else 0


def _track_episode_safely(args: argparse.Namespace, checks: list[FileCheck]) -> None:
    # Bookkeeping must never change the safeguard's verdict.
    try:
        _track_safeguard_episode(gitio.repo_root(Path.cwd()), args, checks)
    except (OSError, ValueError, gitio.GitError) as error:
        print(f"code-health: episode not recorded: {error}", file=sys.stderr)


def _track_safeguard_episode(root: Path, args: argparse.Namespace, checks: list[FileCheck]) -> None:
    gitio.ensure_excluded(root, f"/{history.STATE_DIR}/")
    pending = episodes.tick(history.read_pending(root), args.session)
    now = datetime.datetime.now(datetime.UTC)
    worse = [check.path for check in checks if check.status == "worse"]
    if worse:
        pending = episodes.start_episode(pending, episodes.Step("safeguard-fix", args.session, _file_states(root, worse), now))
    else:
        pending = _end_open(root, pending, episodes.Step("safeguard-fix", args.session, [], now))
    history.write_pending(root, _flush(root, pending, args.session, args.transcript))


def _end_open(root: Path, pending: list[dict], step) -> list[dict]:
    episode = next((e for e in episodes.still_open(pending) if e["kind"] == step.kind and e["session"] == step.session), None)
    if episode is None:
        return pending
    return episodes.end_episode(pending, replace(step, states=_file_states(root, episode["files"])))


def _run_files(args: argparse.Namespace) -> tuple[str, int]:
    root = _optional_repo_root(Path.cwd())
    config = _working_config(root)
    reports = [
        review_source(path, source, config, _repo_relative(root, path)) for path, source in _read_files(args.files)
    ]
    return _render(args.command, reports, as_json=args.json), 0


def _optional_repo_root(cwd: Path) -> Path | None:
    try:
        return gitio.repo_root(cwd)
    except gitio.GitError:
        return None


def _working_config(root: Path | None) -> Config:
    if root is None or not (root / CONFIG_FILE).is_file():
        return DEFAULT_CONFIG
    return parse_config((root / CONFIG_FILE).read_text(encoding="utf-8"))


def _repo_relative(root: Path | None, path: str) -> str:
    if root is None:
        return path
    try:
        return Path(path).resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path


def _repo_report(cwd: Path, args: argparse.Namespace) -> dict:
    root = gitio.repo_root(cwd)
    pathspec = _repo_relative(root, args.path)
    pathspec = "" if pathspec == "." else pathspec
    config = _working_config(root)
    files, not_scored = [], []
    for path in gitio.source_files(root, pathspec):
        scored = _score_repo_file(root, path, config)
        if isinstance(scored, RepoFile):
            files.append(scored)
        elif scored:
            not_scored.append((path, scored))
    commits = parse_log(gitio.change_log(root, args.since, pathspec))
    changes = churn(commits, {f.path for f in files})
    files = [replace(f, commits=changes.get(f.path, (0, 0))[0], authors=changes.get(f.path, (0, 0))[1]) for f in files]
    report = build_report(RepoInput(args.since, pathspec or ".", commits, files, not_scored, args.top))
    return _save_run(root, report, files, coupling(commits, {f.path for f in files}))


def _save_run(root: Path, report: dict, files: list[RepoFile], couplings) -> dict:
    run = {
        "repo": root.name,
        "date": datetime.date.today().isoformat(),
        "commit": gitio.head_commit(root) or "",
        "branch": gitio.current_branch(root),
    }
    entry = history.snapshot(report, files, run)
    previous = history.read_snapshots(root)
    report = {**report, "trend": history.trend([*previous, entry], report["path"], report["scorer_version"])}
    gitio.ensure_excluded(root, f"/{history.STATE_DIR}/")
    history.save_run(root, entry, history.page_data(report, files, couplings, run))
    return report


def _score_repo_file(root: Path, path: str, config: Config) -> RepoFile | str | None:
    if is_prose_or_data(path):
        return None
    try:
        source = (root / path).read_bytes()
    except OSError:
        return None
    if is_binary(source):
        return None
    if is_excluded(config, path):
        return "excluded"
    report = review_source(path, source, config)
    if report.score is None:
        return report.reason
    functions = tuple((f.name, f.line, f.cyclomatic, f.loc) for f in report.metrics.functions)
    return RepoFile(path, report.score, report.band, report.metrics.loc, findings=report.findings, functions=functions)


def _accept(cwd: Path, args: argparse.Namespace) -> tuple[str, int]:
    if not sys.stdin.isatty():
        raise ToolError("accept needs an interactive terminal: run it yourself, not through an agent")
    root = gitio.repo_root(cwd)
    path = _repo_relative(root, args.file)
    report = review_source(args.file, _read(Path(args.file)), _working_config(root), path)
    try:
        finding = select(candidates(report.findings, report.ignores), path, args.smell, args.function)
    except AcceptError as error:
        raise ToolError(str(error)) from error
    print(f"{path}  {finding.smell}  {finding.function}:{finding.line}  {describe(finding)}")
    print(f"Reason: {args.reason}")
    if input("Type yes to accept: ").strip() != "yes":
        return "Not accepted.", 1
    today = datetime.date.today().isoformat()
    entry = record(Target(path, finding, report.digest_for(finding.function)), args.reason, today)
    state.append_accepted(root, entry)
    return "Accepted.", 0


def _mark_turn(cwd: Path, session: str) -> str:
    root = gitio.repo_root(cwd)
    if head := gitio.head_commit(root):
        state.write_turn_base(root, session, head)
    return ""


def _safeguard_checks(
    cwd: Path, base: str | None, turn_session: str | None
) -> tuple[list[FileCheck], tuple[str, ...]]:
    root = gitio.repo_root(cwd)
    commit = _turn_base(root, turn_session) if turn_session else gitio.base_commit(root, base)
    base_text = _config_at(root, commit)
    config = parse_config(base_text)
    context = CheckContext(config, tuple(state.read_accepted(root)))
    checks = []
    for change in gitio.changed_files(root, commit):
        if not is_checked(change.path) or is_excluded(config, change.path):
            continue
        after = _read(root / change.path)
        before = gitio.read_at(root, commit, change.base_path) if change.base_path else None
        checks.append(check_file(change.path, before, after, context))
    return checks, _config_notes(root, base_text)


def _config_at(root: Path, commit: str) -> str | None:
    try:
        return gitio.read_at(root, commit, CONFIG_FILE).decode("utf-8")
    except gitio.GitError:
        return None


def _same_text(a: str | None, b: str | None) -> bool:
    if a is None or b is None:
        return a is b
    return a.replace("\r\n", "\n") == b.replace("\r\n", "\n")


def _config_notes(root: Path, base_text: str | None) -> tuple[str, ...]:
    path = root / CONFIG_FILE
    working = path.read_bytes().decode("utf-8") if path.is_file() else None
    if _same_text(working, base_text):
        return ()
    return (f"{CONFIG_FILE} changed; it takes effect once committed",)


def _turn_base(root: Path, session: str) -> str:
    recorded = state.read_turn_base(root, session)
    if recorded:
        try:
            return gitio.base_commit(root, recorded)
        except gitio.GitError:
            pass
    return gitio.base_commit(root, None)


def _read_files(paths: list[str]) -> list[tuple[str, bytes]]:
    return [(path, _read(Path(path))) for path in paths]


def _read(path: Path) -> bytes:
    try:
        return path.read_bytes()
    except OSError as error:
        raise ToolError(f"cannot read {error.filename}: {error.strerror}") from error


def _render(command: str, reports: list[FileReport], as_json: bool) -> str:
    if as_json:
        return json.dumps(to_json(reports, include_findings=command == "review"), indent=2)
    if command == "review":
        return "\n\n".join(format_review(report) for report in reports)
    return "\n".join(format_score_line(report) for report in reports)


def _parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="code-health")
    commands = parser.add_subparsers(dest="command", required=True)
    for name, help_text in [("score", "score each file"), ("review", "score and list findings")]:
        command = commands.add_parser(name, help=help_text)
        command.add_argument("files", nargs="+")
        command.add_argument("--json", action="store_true", help="print JSON")
    safeguard = commands.add_parser("safeguard", help="fail if changed files gained or worsened findings")
    since = safeguard.add_mutually_exclusive_group()
    since.add_argument("--base", help="compare with the merge-base of this ref instead of HEAD")
    since.add_argument("--since-turn", action="store_true", help="compare with the commit mark-turn recorded")
    safeguard.add_argument("--session", default="default", help="the session mark-turn recorded for")
    safeguard.add_argument("--json", action="store_true", help="print JSON")
    safeguard.add_argument("--episode", action="store_true", help="track a safeguard-fix episode for this session")
    safeguard.add_argument("--transcript", help="a Claude Code transcript, to count an episode's tokens")
    accept = commands.add_parser("accept", help="accept a finding for now (asks in a terminal)")
    accept.add_argument("file")
    accept.add_argument("--smell", required=True)
    accept.add_argument("--function")
    accept.add_argument("--reason", required=True)
    repo = commands.add_parser("repo", help="rank the repo's files by change frequency and health")
    repo.add_argument("path", nargs="?", default=".")
    repo.add_argument("--since", default="12 months ago", help="how far back to read history")
    repo.add_argument("--top", type=int, default=15, help="rows per table")
    repo.add_argument("--json", action="store_true", help="print JSON")
    episode = commands.add_parser("episode", help="record a stretch of refactoring work and what it cost")
    episode.add_argument("action", choices=("start", "end", "flush"))
    episode.add_argument("files", nargs="*")
    episode.add_argument("--kind", choices=episodes.KINDS, default="uplift")
    episode.add_argument("--session", default="default")
    episode.add_argument("--tests-passed", choices=("yes", "no"))
    episode.add_argument("--transcript", help="a Claude Code transcript, to count tokens")
    mark = commands.add_parser("mark-turn", help="record HEAD as the start of a turn")
    mark.add_argument("--session", default="default", help="a name for the agent session")
    return parser
