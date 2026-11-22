from dataclasses import dataclass

import tree_sitter_language_pack as pack

from code_health.languages import Language
from code_health.naming import class_names, disambiguate, function_name, own_name
from code_health.syntax import body, parameter_groups, parameter_list, text


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
    nodes = [node for node in _descendants(root) if _is_measured(node, language)]
    names = disambiguate([_name(node, language) for node in nodes], nodes, language)
    functions = [_measure(node, name, language, code_rows) for node, name in zip(nodes, names, strict=True)]
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


def _is_measured(node, language: Language) -> bool:
    if node.type in language.functions:
        return body(node, language) is not None
    return _primary_constructor(node, language) is not None


def _name(node, language: Language) -> str:
    if node.type in language.functions:
        return function_name(node, language)
    own = text(node.child_by_field_name("name"))
    return ".".join([*class_names(node, language), own, "<primary constructor>"])


def _measure(node, name: str, language: Language, code_rows: frozenset[int]) -> FunctionMetrics:
    if node.type not in language.functions:
        return _measure_primary_constructor(node, name, language, code_rows)
    return FunctionMetrics(
        name=name,
        line=node.start_point.row + 1,
        loc=_loc(node, code_rows),
        is_constructor=node.type in language.constructors or own_name(node) in language.constructor_names,
        cyclomatic=1 + _count_decisions(node, language),
        max_nesting=_max_nesting(node, language),
        parameters=_count_parameters(node, language),
        bumps=_count_bumps(node, language),
        conditions=_conditions(node, language),
    )


def _primary_constructor(node, language: Language):
    if node.type not in language.primary_constructor_owners:
        return None
    return parameter_list(node, language)


def _measure_primary_constructor(node, name: str, language: Language, code_rows) -> FunctionMetrics:
    params = _primary_constructor(node, language)
    return FunctionMetrics(
        name=name,
        line=node.start_point.row + 1,
        loc=_loc(params, code_rows),
        is_constructor=True,
        cyclomatic=1,
        max_nesting=0,
        parameters=_count_parameters(node, language),
        bumps=0,
        conditions=(),
    )


def _loc(node, code_rows: frozenset[int]) -> int:
    return sum(1 for row in range(node.start_point.row, node.end_point.row + 1) if row in code_rows)


def _count_bumps(function, language: Language) -> int:
    block = body(function, language)
    if block is None or block.type not in language.function_bodies:
        return 0
    return sum(
        1
        for statement in block.named_children
        if statement.type not in language.functions
        and _max_nesting(statement, language, _adds_nesting(statement, block, language)) >= 2
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
    if node.type not in language.nesting:
        return False
    is_else_if = parent.type in language.else_clauses or parent.child_by_field_name("alternative") == node
    return not is_else_if


def _count_decisions(function, language: Language) -> int:
    decisions = language.branches | language.loops
    return sum(
        1
        for node in _own_descendants(function, language)
        if (node.type in decisions and not _is_excluded_branch(node, language))
        or (not node.is_named and node.type in language.decision_operators)
    )


def _is_excluded_branch(node, language: Language) -> bool:
    excluded = language.branch_exclusions.get(node.type)
    return bool(excluded) and any(child.type in excluded for child in node.children)


def _own_descendants(node, language: Language):
    return _descendants(node, enter=lambda child: child.type not in language.functions)


def _count_parameters(function, language: Language) -> int:
    params = parameter_list(function, language)
    if params is None:
        return 0
    return sum(1 for group in parameter_groups(params, language) if not _is_this_parameter(group))


def _is_this_parameter(group) -> bool:
    first = group[0]
    return first.named_child_count > 0 and first.named_children[0].type == "this"


def _descendants(node, enter=lambda child: True):
    stack = list(reversed(node.children))
    while stack:
        current = stack.pop()
        yield current
        if enter(current):
            stack.extend(reversed(current.children))
