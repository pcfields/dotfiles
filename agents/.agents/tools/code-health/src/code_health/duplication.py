from collections import defaultdict

from code_health.languages import Language

WINDOW = 10
# A window must mix line shapes: a uniform list (registrations, a lookup
# table) repeats its own shape without being copied logic.
_MIN_SHAPES = 4
_TRIVIAL_TOKENS = 3
_IMPORTS = ("import", "using", "from", "require", "use", "package", "#include")


def duplicated_runs(root, language: Language) -> tuple[tuple[int, int], ...]:
    rows = _meaningful_rows(root, language)
    first_seen: dict[tuple[str, ...], int] = {}
    repeats = []
    for index in range(len(rows) - WINDOW + 1):
        window = tuple(signature for _, signature in rows[index : index + WINDOW])
        if len(set(window)) < _MIN_SHAPES:
            continue
        if index - first_seen.setdefault(window, index) >= WINDOW:
            repeats.append(index)
    return tuple((rows[first][0], last - first + WINDOW) for first, last in _consecutive_groups(repeats))


def _consecutive_groups(indices: list[int]) -> list[tuple[int, int]]:
    groups: list[tuple[int, int]] = []
    for index in indices:
        if groups and index == groups[-1][1] + 1:
            groups[-1] = (groups[-1][0], index)
        else:
            groups.append((index, index))
    return groups


def _meaningful_rows(root, language: Language) -> list[tuple[int, str]]:
    tokens = _tokens_by_row(root, language)
    return [
        (row + 1, " ".join(line))
        for row, line in sorted(tokens.items())
        if len(line) > _TRIVIAL_TOKENS and line[0] not in _IMPORTS
    ]


def _tokens_by_row(root, language: Language) -> dict[int, list[str]]:
    tokens: dict[int, list[str]] = defaultdict(list)
    stack = [root]
    while stack:
        node = stack.pop()
        if node.type in language.comments:
            continue
        if node.child_count == 0 and node.end_byte > node.start_byte:
            tokens[node.start_point.row].append(_normal(node))
        stack.extend(reversed(node.children))
    return tokens


def _normal(leaf) -> str:
    kind = leaf.type
    if "identifier" in kind or kind in ("variable", "name", "word"):
        return "ID"
    if any(part in kind for part in ("string", "number", "integer", "float", "literal", "char")):
        return "LIT"
    return leaf.text.decode(errors="replace")
