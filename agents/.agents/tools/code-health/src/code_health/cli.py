import argparse
import datetime
import json
import sys
from pathlib import Path

import tree_sitter_language_pack as pack

from code_health import (
    episode_command,
    episodes,
    gitio,
    repo_command,
    safeguard_command,
    state,
)
from code_health.accept import AcceptError, Target, candidates, record, select
from code_health.config import (
    ConfigError,
)
from code_health.repo import (
    format_repo,
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
    format_safeguard,
    safeguard_json,
)
from code_health.workspace import (
    ToolError,
    optional_repo_root,
    read_source,
    repo_relative,
    working_config,
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


def _run(args: argparse.Namespace) -> tuple[str, int]:
    handlers = {
        "mark-turn": lambda: (_mark_turn(Path.cwd(), args.session), 0),
        "accept": lambda: _accept(Path.cwd(), args),
        "repo": lambda: _run_repo(args),
        "episode": lambda: (episode_command.run_episode(Path.cwd(), args), 0),
        "safeguard": lambda: _run_safeguard(args),
    }
    return handlers.get(args.command, lambda: _run_files(args))()


def _run_repo(args: argparse.Namespace) -> tuple[str, int]:
    report = repo_command.repo_report(Path.cwd(), args)
    return (json.dumps(report, indent=2) if args.json else format_repo(report)), 0


def _run_safeguard(args: argparse.Namespace) -> tuple[str, int]:
    checks, notes = safeguard_command.safeguard_checks(Path.cwd(), args.base, args.session if args.since_turn else None)
    verdict = safeguard_json(checks, notes)
    if args.episode:
        worse = [check.path for check in checks if check.status == "worse"]
        episode_command.track_safely(Path.cwd(), args.session, args.transcript, worse)
    output = json.dumps(verdict, indent=2) if args.json else format_safeguard(checks, notes)
    return output, SAFEGUARD_FAILED if verdict["verdict"] == "fail" else 0


def _run_files(args: argparse.Namespace) -> tuple[str, int]:
    root = optional_repo_root(Path.cwd())
    config = working_config(root)
    reports = [
        review_source(path, source, config, repo_relative(root, path)) for path, source in _read_files(args.files)
    ]
    return _render(args.command, reports, as_json=args.json), 0


def _accept(cwd: Path, args: argparse.Namespace) -> tuple[str, int]:
    if not sys.stdin.isatty():
        raise ToolError("accept needs an interactive terminal: run it yourself, not through an agent")
    root = gitio.repo_root(cwd)
    path = repo_relative(root, args.file)
    report = review_source(args.file, read_source(Path(args.file)), working_config(root), path)
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


def _read_files(paths: list[str]) -> list[tuple[str, bytes]]:
    return [(path, read_source(Path(path))) for path in paths]


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
