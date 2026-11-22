import re
from dataclasses import dataclass

from code_health.measure import SCRIPT, FunctionMetrics
from code_health.smells import FILE, INVALID_IGNORE, MEASURED_SMELLS, Finding

_DIRECTIVE = re.compile(r"code-health:\s*ignore\b(?P<rest>.*)")
_CLOSERS = ("*/", "#>", "-->", "]]")
_ANNOTATIONS = ("//", "#", "--", "/*", "*", "<#", "@", "[")


@dataclass(frozen=True)
class Ignore:
    smell: str
    function: str
    line: int
    reason: str


def find_ignores(source: bytes, functions: tuple[FunctionMetrics, ...]) -> tuple[list[Ignore], list[Finding]]:
    lines = source.decode("utf-8", errors="replace").splitlines()
    targets = _function_targets(lines, functions)
    header = set(_file_header(lines))
    ignores, invalid = [], []
    for index, line in enumerate(lines):
        match = _DIRECTIVE.search(line)
        if match is None:
            continue
        smell, reason = _parse(match["rest"])
        for function in _owners(index, smell, targets, header):
            if smell in MEASURED_SMELLS and reason:
                ignores.append(Ignore(smell, function, index + 1, reason))
            else:
                invalid.append(Finding(INVALID_IGNORE, function, index + 1, 1, 1))
    return ignores, invalid


def suppresses(ignore: Ignore, finding: Finding) -> bool:
    if ignore.smell != finding.smell:
        return False
    return ignore.function == finding.function or (ignore.function == FILE and finding.function in (FILE, SCRIPT))


def _owners(index: int, smell: str, targets: dict[int, list[str]], header: set[int]) -> list[str]:
    means_the_file = smell == "Large File" or index not in targets
    if index in header and means_the_file:
        return [FILE]
    return targets.get(index, [])


def _function_targets(lines: list[str], functions: tuple[FunctionMetrics, ...]) -> dict[int, list[str]]:
    targets: dict[int, list[str]] = {}
    for function in functions:
        if function.name == SCRIPT:
            continue
        index = function.line - 2
        while index >= 0 and _is_annotation(lines[index]):
            targets.setdefault(index, []).append(function.name)
            index -= 1
    return targets


def _file_header(lines: list[str]) -> list[int]:
    header = []
    for index, line in enumerate(lines):
        if not line.strip():
            continue
        if not _is_annotation(line):
            break
        header.append(index)
    return header


def _is_annotation(line: str) -> bool:
    return line.strip().startswith(_ANNOTATIONS)


def _parse(rest: str) -> tuple[str, str | None]:
    rest = rest.strip()
    for closer in _CLOSERS:
        rest = rest.removesuffix(closer).rstrip()
    smell, separator, reason = rest.partition("--")
    return smell.strip(), (reason.strip() or None) if separator else None
