from collections import defaultdict
from typing import NamedTuple

from code_health.languages import Language

WINDOW = 10
# A window must mix line shapes: a uniform list (registrations, a lookup
# table) repeats its own shape without being copied logic.
_MIN_SHAPES = 4
_TRIVIAL_TOKENS = 3
_IMPORTS = ("import", "using", "from", "require", "use", "package", "#include")
# Code inside these is logic even when it sits in a property or field declaration.
_EXPRESSION_BODIES = frozenset({"arrow_expression_clause", "lambda_expression", "arrow_function"})
# TypeScript puts the ; after a property in the enclosing body, not the property.
_SEPARATORS = (";", ",")


class Row(NamedTuple):
    number: int
    signature: str
    declarative: bool


def duplicated_runs(root, language: Language) -> tuple[tuple[int, int], ...]:
    rows = _meaningful_rows(root, language)
    first_seen: dict[tuple[str, ...], int] = {}
    repeats = []
    for index in range(len(rows) - WINDOW + 1):
        window_rows = rows[index : index + WINDOW]
        window = tuple(row.signature for row in window_rows)
        # Copied data declarations (model properties, fields) aren't copied logic.
        if len(set(window)) < _MIN_SHAPES or all(row.declarative for row in window_rows):
            continue
        if index - first_seen.setdefault(window, index) >= WINDOW:
            repeats.append(index)
    return tuple((rows[first].number, last - first + WINDOW) for first, last in _consecutive_groups(repeats))


def _consecutive_groups(indices: list[int]) -> list[tuple[int, int]]:
    groups: list[tuple[int, int]] = []
    for index in indices:
        if groups and index == groups[-1][1] + 1:
            groups[-1] = (groups[-1][0], index)
        else:
            groups.append((index, index))
    return groups


def _meaningful_rows(root, language: Language) -> list[Row]:
    leaves = _leaves_by_row(root, language)
    return [
        Row(row + 1, " ".join(token for token, _ in line), _is_declarative(line))
        for row, line in sorted(leaves.items())
        if len(line) > _TRIVIAL_TOKENS and line[0][0] not in _IMPORTS
    ]


def _is_declarative(line: list[tuple[str, bool]]) -> bool:
    return all(declarative for token, declarative in line if token not in _SEPARATORS)


def _leaves_by_row(root, language: Language) -> dict[int, list[tuple[str, bool]]]:
    leaves: dict[int, list[tuple[str, bool]]] = defaultdict(list)
    logic = language.function_bodies | _EXPRESSION_BODIES
    stack = [(root, False)]
    while stack:
        node, declarative = stack.pop()
        if node.type in language.comments:
            continue
        if node.type in language.declarations:
            declarative = True
        elif node.type in logic:
            declarative = False
        if node.child_count == 0 and node.end_byte > node.start_byte:
            leaves[node.start_point.row].append((_normal(node), declarative))
        stack.extend((child, declarative) for child in reversed(node.children))
    return leaves


def _normal(leaf) -> str:
    kind = leaf.type
    if "identifier" in kind or kind in ("variable", "name", "word"):
        return "ID"
    if any(part in kind for part in ("string", "number", "integer", "float", "literal", "char")):
        return "LIT"
    return leaf.text.decode(errors="replace")
