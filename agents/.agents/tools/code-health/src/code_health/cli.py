import argparse
import json
import sys
from pathlib import Path

import tree_sitter_language_pack as pack

from code_health import gitio, state
from code_health.report import (
    FileReport,
    format_review,
    format_score_line,
    review_source,
    to_json,
)
from code_health.safeguard import (
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
    except (ToolError, gitio.GitError) as error:
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
    if args.command == "safeguard":
        checks = _safeguard_checks(Path.cwd(), args.base, args.session if args.since_turn else None)
        verdict = safeguard_json(checks)
        output = json.dumps(verdict, indent=2) if args.json else format_safeguard(checks)
        return output, SAFEGUARD_FAILED if verdict["verdict"] == "fail" else 0
    reports = [review_source(path, source) for path, source in _read_files(args.files)]
    return _render(args.command, reports, as_json=args.json), 0


def _mark_turn(cwd: Path, session: str) -> str:
    root = gitio.repo_root(cwd)
    if head := gitio.head_commit(root):
        state.write_turn_base(root, session, head)
    return ""


def _safeguard_checks(cwd: Path, base: str | None, turn_session: str | None) -> list[FileCheck]:
    root = gitio.repo_root(cwd)
    commit = _turn_base(root, turn_session) if turn_session else gitio.base_commit(root, base)
    checks = []
    for change in gitio.changed_files(root, commit):
        if not is_checked(change.path):
            continue
        after = _read(root / change.path)
        before = gitio.read_at(root, commit, change.base_path) if change.base_path else None
        checks.append(check_file(change.path, before, after))
    return checks


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
    mark = commands.add_parser("mark-turn", help="record HEAD as the start of a turn")
    mark.add_argument("--session", default="default", help="a name for the agent session")
    return parser
