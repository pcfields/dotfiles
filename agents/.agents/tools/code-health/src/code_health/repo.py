from collections import Counter
from dataclasses import dataclass
from itertools import combinations

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
