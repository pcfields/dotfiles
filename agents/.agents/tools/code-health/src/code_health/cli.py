import argparse
import datetime
import json
import sys
from pathlib import Path

import tree_sitter_language_pack as pack

from code_health import gitio, state
from code_health.accept import AcceptError, Target, candidates, record, select
from code_health.config import (
    CONFIG_FILE,
    DEFAULT_CONFIG,
    Config,
    ConfigError,
    is_excluded,
    parse_config,
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
    if args.command == "mark-turn":
        return _mark_turn(Path.cwd(), args.session), 0
    if args.command == "accept":
        return _accept(Path.cwd(), args)
    if args.command == "safeguard":
        checks, notes = _safeguard_checks(Path.cwd(), args.base, args.session if args.since_turn else None)
        verdict = safeguard_json(checks, notes)
        output = json.dumps(verdict, indent=2) if args.json else format_safeguard(checks, notes)
        return output, SAFEGUARD_FAILED if verdict["verdict"] == "fail" else 0
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
    accept = commands.add_parser("accept", help="accept a finding for now (asks in a terminal)")
    accept.add_argument("file")
    accept.add_argument("--smell", required=True)
    accept.add_argument("--function")
    accept.add_argument("--reason", required=True)
    mark = commands.add_parser("mark-turn", help="record HEAD as the start of a turn")
    mark.add_argument("--session", default="default", help="a name for the agent session")
    return parser
