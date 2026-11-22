from collections import Counter
from dataclasses import asdict, dataclass
from itertools import combinations
from pathlib import PurePosixPath

from code_health.score import SCORER_VERSION, penalty
from code_health.smells import Finding

MAX_COMMIT_FILES = 50
MIN_SHARED_COMMITS = 3


@dataclass(frozen=True)
class Commit:
    author: str
    files: tuple[str, ...]


@dataclass(frozen=True)
class Coupling:
    shared: int
    degree: int
    a: str
    b: str


def parse_log(text: str) -> list[Commit]:
    commits = []
    for block in text.split("\x01")[1:]:
        author, *files = block.split("\n")
        commits.append(Commit(author, tuple(f for f in files if f)))
    return commits


def churn(commits: list[Commit], current: set[str]) -> dict[str, tuple[int, int]]:
    changes: Counter[str] = Counter()
    authors: dict[str, set[str]] = {}
    for commit in commits:
        for path in commit.files:
            if path in current:
                changes[path] += 1
                authors.setdefault(path, set()).add(commit.author)
    return {path: (count, len(authors[path])) for path, count in changes.items()}


def coupling(
    commits: list[Commit],
    current: set[str],
    min_shared: int = MIN_SHARED_COMMITS,
    max_files: int = MAX_COMMIT_FILES,
) -> list[Coupling]:
    shared: Counter[tuple[str, str]] = Counter()
    for commit in commits:
        files = sorted({f for f in commit.files if f in current})
        if len(files) <= max_files:
            shared.update(combinations(files, 2))
    changes = churn(commits, current)
    pairs = [
        Coupling(count, 200 * count // (changes[a][0] + changes[b][0]), a, b)
        for (a, b), count in shared.items()
        if count >= min_shared
    ]
    return sorted(pairs, key=lambda c: (-c.shared, -c.degree, c.a, c.b))


@dataclass(frozen=True)
class RepoFile:
    path: str
    score: float
    band: str
    loc: int
    commits: int = 0
    authors: int = 0
    findings: tuple[Finding, ...] = ()


def refactor_first(files: list[RepoFile], top: int) -> list[RepoFile]:
    debt = [f for f in files if f.commits and f.score < 10]
    return sorted(debt, key=lambda f: (-f.commits * (10 - f.score), f.path))[:top]


def change_frequency(files: list[RepoFile], top: int) -> list[RepoFile]:
    changed = [f for f in files if f.commits]
    return sorted(changed, key=lambda f: (-f.commits, f.path))[:top]


def healthy_but_busy(files: list[RepoFile], top: int) -> list[RepoFile]:
    return [f for f in change_frequency(files, len(files)) if f.band == "green"][:top]


def least_healthy(files: list[RepoFile], top: int) -> list[RepoFile]:
    unhealthy = [f for f in files if f.band != "green"]
    return sorted(unhealthy, key=lambda f: (f.score, -f.loc, f.path))[:top]


def average_health(files: list[RepoFile]) -> float | None:
    return _weighted(files, weight=lambda f: f.loc)


def hotspot_health(files: list[RepoFile], top: int) -> float | None:
    return _weighted(change_frequency(files, top), weight=lambda f: f.commits)


def worst_file(files: list[RepoFile]) -> RepoFile | None:
    return min(files, key=lambda f: (f.score, -f.loc, f.path), default=None)


def worst_findings(files: list[RepoFile], top: int) -> list[tuple[str, Finding]]:
    pairs = [(f.path, finding) for f in files for finding in f.findings]
    return sorted(pairs, key=lambda pair: (-penalty(pair[1], 1.0), pair[0], pair[1].line))[:top]


def _weighted(files: list[RepoFile], weight) -> float | None:
    total = sum(weight(f) for f in files)
    if not total:
        return None
    return round(sum(f.score * weight(f) for f in files) / total, 1)


@dataclass(frozen=True)
class RepoInput:
    since: str
    path: str
    commits: list[Commit]
    files: list[RepoFile]
    not_scored: list[tuple[str, str]]
    top: int


def build_report(data: RepoInput) -> dict:
    files, top = data.files, data.top
    current = {f.path for f in files}
    return {
        "scorer_version": SCORER_VERSION,
        "since": data.since,
        "path": data.path,
        "commits": len(data.commits),
        "authors": len({c.author for c in data.commits}),
        "overview": _overview(data),
        "refactor_first": [_file_row(f) for f in refactor_first(files, top)],
        "change_frequency": [_file_row(f) for f in change_frequency(files, top)],
        "healthy_but_busy": [_file_row(f) for f in healthy_but_busy(files, top)],
        "coupling": [asdict(c) for c in coupling(data.commits, current)[:top]],
        "author_density": _author_density(files, top),
        "least_healthy": [_file_row(f) for f in least_healthy(files, top)],
        "worst_findings": [{"path": path, **asdict(f)} for path, f in worst_findings(files, top)],
        "not_scored": _not_scored_summary(data.not_scored),
    }


def _overview(data: RepoInput) -> dict:
    files = data.files
    worst = worst_file(files)
    return {
        "files_scored": len(files),
        "files_not_scored": len(data.not_scored),
        "bands": {name: sum(1 for f in files if f.band == name) for name in ("green", "yellow", "red")},
        "average_health": average_health(files),
        "hotspot_health": hotspot_health(files, data.top),
        "worst_file": {"path": worst.path, "score": worst.score} if worst else None,
    }


def format_repo(report: dict) -> str:
    lines = ["## Overview", *_overview_lines(report)]
    for title, header, rows in _sections(report):
        lines += ["", f"## {title}", *_table(header, rows)]
    return "\n".join(lines)


def _overview_lines(report: dict) -> list[str]:
    overview = report["overview"]
    bands = overview["bands"]
    worst = overview["worst_file"]
    return [
        (
            f"window: since {report['since']}   path: {report['path'] or '.'}   "
            f"commits: {report['commits']}   authors: {report['authors']}"
        ),
        (
            f"files: {overview['files_scored']} scored, {overview['files_not_scored']} not scored   "
            f"bands: {bands['green']} green, {bands['yellow']} yellow, {bands['red']} red"
        ),
        (
            f"average health: {_number(overview['average_health'])} (weighted by lines)   "
            f"hotspot health: {_number(overview['hotspot_health'])} (busiest files, weighted by commits)"
        ),
        f"worst file: {worst['path']} {worst['score']}" if worst else "worst file: -",
    ]


def _sections(report: dict) -> list[tuple]:
    file_header = ("score", "band", "commits", "authors", "file", "smells")
    sections = [
        ("Refactor first (commits x (10 - score))", file_header, [_file_cells(r) for r in report["refactor_first"]]),
        ("Change frequency", file_header, [_file_cells(r) for r in report["change_frequency"]]),
        ("Healthy but busy", file_header, [_file_cells(r) for r in report["healthy_but_busy"]]),
        ("Change coupling", ("shared", "degree", "file", "changes with"),
         [(c["shared"], f"{c['degree']}%", c["a"], c["b"]) for c in report["coupling"]]),
        ("Author density", ("authors", "commits", "file"),
         [(a["authors"], a["commits"], a["path"]) for a in report["author_density"]]),
        ("Least healthy files", file_header, [_file_cells(r) for r in report["least_healthy"]]),
        ("Worst findings", ("smell", "location", "value", "limit", "file"),
         [(f["smell"], f"{f['function']}:{f['line']}", f["value"], f["limit"], f["path"])
          for f in report["worst_findings"]]),
        ("Not scored", ("files", "kind", "reason"),
         [(n["count"], n["kind"], n["reason"]) for n in report["not_scored"]]),
    ]
    return sections


def _file_row(f: RepoFile) -> dict:
    return {
        "path": f.path,
        "score": f.score,
        "band": f.band,
        "commits": f.commits,
        "authors": f.authors,
        "smells": sorted({finding.smell for finding in f.findings}),
    }


def _file_cells(row: dict) -> tuple:
    return (row["score"], row["band"], row["commits"], row["authors"], row["path"], ", ".join(row["smells"]))


def _author_density(files: list[RepoFile], top: int) -> list[dict]:
    shared = sorted((f for f in files if f.authors > 1), key=lambda f: (-f.authors, -f.commits, f.path))
    return [{"path": f.path, "authors": f.authors, "commits": f.commits} for f in shared[:top]]


def _not_scored_summary(not_scored: list[tuple[str, str]]) -> list[dict]:
    counts = Counter((PurePosixPath(path).suffix or PurePosixPath(path).name, reason) for path, reason in not_scored)
    return [{"kind": kind, "reason": reason, "count": count} for (kind, reason), count in sorted(counts.items())]


def _table(header: tuple, rows: list[tuple]) -> list[str]:
    if not rows:
        return ["(none)"]
    cells = [[str(c) for c in row] for row in [header, *rows]]
    widths = [max(len(row[i]) for row in cells) for i in range(len(header))]
    return ["  ".join(c.ljust(w) for c, w in zip(row, widths, strict=True)).rstrip() for row in cells]


def _number(value: float | None) -> str:
    return "-" if value is None else f"{value:.1f}"


DATA_SUFFIXES = frozenset(
    {
        ".md", ".markdown", ".rst", ".txt", ".json", ".jsonc", ".jsonl", ".yaml", ".yml", ".toml",
        ".lock", ".csv", ".tsv", ".svg", ".snap", ".map", ".log", ".ini", ".cfg", ".conf", ".xml",
        ".dump", ".bak",
    }
)


def is_prose_or_data(path: str) -> bool:
    suffix = PurePosixPath(path).suffix.lower()
    return not suffix or suffix in DATA_SUFFIXES


def is_binary(source: bytes) -> bool:
    return b"\0" in source[:8000]
