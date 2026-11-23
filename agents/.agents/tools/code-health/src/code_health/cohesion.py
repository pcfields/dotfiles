from code_health.languages import Language
from code_health.naming import class_names, own_name
from code_health.syntax import name_node, text

_RECEIVERS = frozenset({"this", "self"})
_MEMBER_ACCESS = {
    "member_expression": ("object", "property"),
    "member_access_expression": ("expression", "name"),
    "attribute": ("object", "attribute"),
    "field_expression": ("value", "field"),
}


def low_cohesion(root, language: Language) -> tuple[tuple[str, int, int], ...]:
    results = []
    for node in _descendants(root, stop=frozenset()):
        if node.type in language.classes:
            groups = _groups(node, language)
            results.append((_qualified_name(node, language), node.start_point.row + 1, groups))
    return tuple(results)


def _groups(cls, language: Language) -> int:
    methods = _methods(cls, language)
    declared = _declared_members(cls) if language.bare_member_access else frozenset()
    names = frozenset(methods)
    uses = {name: _members_used(node, declared) for name, node in methods.items()}
    stateful = [name for name, used in uses.items() if used - names]
    return _components(stateful, uses, names)


def _components(stateful: list[str], uses: dict[str, set[str]], names: frozenset[str]) -> int:
    parent = {name: name for name in stateful}

    def find(name: str) -> str:
        while parent[name] != name:
            name = parent[name]
        return name

    for i, a in enumerate(stateful):
        for b in stateful[i + 1 :]:
            linked = (uses[a] - names) & (uses[b] - names) or b in uses[a] or a in uses[b]
            if linked:
                parent[find(a)] = find(b)
    return len({find(name) for name in stateful})


def _methods(cls, language: Language) -> dict[str, object]:
    methods = {}
    for node in _descendants(cls, stop=language.functions | language.classes):
        if _is_method(node, language):
            name = own_name(node, language)
            if name and not _is_accessor(node, name):
                methods[name] = node
    return methods


def _is_method(node, language: Language) -> bool:
    is_function = node.type in language.functions and node.is_named
    return is_function and not _is_constructor(node, language)


def _is_accessor(node, name: str) -> bool:
    # Property accessors are data access: each touches only its own backing field.
    return node.type == "accessor_declaration" or name.startswith(("get ", "set "))


def _is_constructor(node, language: Language) -> bool:
    return node.type in language.constructors or own_name(node, language) in language.constructor_names


def _members_used(method, declared: frozenset[str]) -> set[str]:
    used = set()
    for node in _descendants(method, stop=frozenset()):
        if node.type in _MEMBER_ACCESS:
            member = _own_member(node)
            if member:
                used.add(member)
        elif node.type == "identifier" and text(node) in declared:
            used.add(text(node))
    return used


def _own_member(access) -> str | None:
    receiver_field, member_field = _MEMBER_ACCESS[access.type]
    receiver = access.child_by_field_name(receiver_field)
    member = access.child_by_field_name(member_field)
    if receiver is None or member is None:
        return None
    return text(member) if text(receiver) in _RECEIVERS else None


def _declared_members(cls) -> frozenset[str]:
    names = set()
    for node in _descendants(cls, stop=frozenset({"block", "arrow_expression_clause"})):
        if node.type == "variable_declarator" or node.type.endswith(("property_declaration", "method_declaration")):
            name = node.child_by_field_name("name")
            if name is not None:
                names.add(text(name))
    return frozenset(names)


def _qualified_name(cls, language: Language) -> str:
    own = name_node(cls, language) or cls.child_by_field_name("type")
    return ".".join([*class_names(cls, language), text(own) if own else "<class>"])


def _descendants(node, stop: frozenset[str]):
    stack = list(reversed(node.children))
    while stack:
        current = stack.pop()
        yield current
        if current.type not in stop:
            stack.extend(reversed(current.children))
