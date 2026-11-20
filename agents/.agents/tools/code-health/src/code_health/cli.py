import argparse
import json
import sys
from pathlib import Path

import tree_sitter_language_pack as pack

from code_health.report import (
    FileReport,
    format_review,
    format_score_line,
    review_source,
    to_json,
)


def main(argv: list[str] | None = None) -> int:
    try:
        args = _parser().parse_args(sys.argv[1:] if argv is None else argv)
    except SystemExit as stop:
        return 0 if stop.code == 0 else 1
    try:
        reports = _review_files(args.files)
    except ToolError as error:
        print(f"code-health: {error}", file=sys.stderr)
        return 1
    print(_render(args.command, reports, as_json=args.json))
    return 0


class ToolError(Exception):
    pass


def _review_files(paths: list[str]) -> list[FileReport]:
    try:
        sources = [(path, Path(path).read_bytes()) for path in paths]
    except OSError as error:
        raise ToolError(f"cannot read {error.filename}: {error.strerror}") from error
    try:
        return [review_source(path, source) for path, source in sources]
    except pack.Error as error:
        raise ToolError(f"cannot load a grammar (it downloads on first use): {error}") from error


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
    return parser
