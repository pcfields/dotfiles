from dataclasses import dataclass

import tree_sitter_language_pack as pack

from code_health.languages import Language
from code_health.naming import function_name, own_name


@dataclass(frozen=True)
class Condition:
    line: int
    operators: int


@dataclass(frozen=True)
class FunctionMetrics:
    name: str
    line: int
    loc: int
    is_constructor: bool
    cyclomatic: int
    max_nesting: int
    parameters: int
    bumps: int
    conditions: tuple[Condition, ...]


@dataclass(frozen=True)
class FileMetrics:
    loc: int
    parse_errors: int
    functions: tuple[FunctionMetrics, ...]


def measure_file(source: bytes, language: Language) -> FileMetrics:
    root = pack.get_parser(language.grammar).parse(source).root_node
    code_rows = _code_rows(root, language)
    functions = [
        _measure_function(node, language, code_rows)
        for node in _descendants(root)
        if node.type in language.functions
    ]
    return FileMetrics(
        loc=len(code_rows),
        parse_errors=sum(1 for node in _descendants(root) if node.is_error or node.is_missing),
        functions=tuple(functions),
    )


def _code_rows(root, language: Language) -> frozenset[int]:
    return frozenset(
        row
        for node in _descendants(root)
        if node.child_count == 0
        and node.type not in language.comments
        and node.end_byte > node.start_byte
        for row in range(node.start_point.row, node.end_point.row + 1)
    )


def _measure_function(node, language: Language, code_rows: frozenset[int]) -> FunctionMetrics:
    return FunctionMetrics(
        name=function_name(node, language),
        line=node.start_point.row + 1,
        loc=sum(1 for row in range(node.start_point.row, node.end_point.row + 1) if row in code_rows),
        is_constructor=own_name(node) in language.constructor_names,
        cyclomatic=1 + _count_decisions(node, language),
        max_nesting=_max_nesting(node, language),
        parameters=_count_parameters(node, language),
        bumps=_count_bumps(node, language),
        conditions=_conditions(node, language),
    )


def _count_bumps(function, language: Language) -> int:
    body = function.child_by_field_name("body")
    if body is None or body.type not in language.function_bodies:
        return 0
    return sum(
        1
        for statement in body.named_children
        if statement.type not in language.functions
        and _max_nesting(statement, language, _adds_nesting(statement, body, language)) >= 2
    )


def _conditions(function, language: Language) -> tuple[Condition, ...]:
    return tuple(
        Condition(
            line=condition.start_point.row + 1,
            operators=_count_boolean_operators(condition, language),
        )
        for node in _own_descendants(function, language)
        if node.type in language.conditionals
        and (condition := node.child_by_field_name("condition")) is not None
    )


def _count_boolean_operators(node, language: Language) -> int:
    nodes = [node, *_own_descendants(node, language)]
    return sum(1 for n in nodes if not n.is_named and n.type in language.boolean_operators)


def _max_nesting(node, language: Language, depth: int = 0) -> int:
    deepest = depth
    stack = [(node, depth)]
    while stack:
        current, current_depth = stack.pop()
        deepest = max(deepest, current_depth)
        stack.extend(
            (child, current_depth + _adds_nesting(child, current, language))
            for child in current.children
            if child.type not in language.functions
        )
    return deepest


def _adds_nesting(node, parent, language: Language) -> bool:
    return node.type in language.nesting and parent.type not in language.else_clauses


def _count_decisions(function, language: Language) -> int:
    decisions = language.branches | language.loops
    return sum(
        1
        for node in _own_descendants(function, language)
        if node.type in decisions or (not node.is_named and node.type in language.decision_operators)
    )


def _own_descendants(node, language: Language):
    return _descendants(node, enter=lambda child: child.type not in language.functions)


def _count_parameters(function, language: Language) -> int:
    params = next((c for c in function.children if c.type in language.parameter_lists), None)
    if params is None:
        return 0
    return sum(1 for p in params.named_children if p.type not in language.comments and not _is_this_parameter(p))


def _is_this_parameter(parameter) -> bool:
    return parameter.named_child_count > 0 and parameter.named_children[0].type == "this"


def _descendants(node, enter=lambda child: True):
    stack = list(reversed(node.children))
    while stack:
        current = stack.pop()
        yield current
        if enter(current):
            stack.extend(reversed(current.children))
