from code_health.languages import Language
from code_health.syntax import parameter_groups, parameter_list, text


def function_name(function, language: Language) -> str:
    own = own_name(function)
    if own is not None:
        return ".".join([*class_names(function, language), own])
    parent = _enclosing_function(function, language)
    prefix = f"{function_name(parent, language)}." if parent else ""
    callee = _callee_name(function)
    return prefix + (f"{callee} callback" if callee else "<anonymous>")


def disambiguate(names: list[str], functions: list, language: Language) -> list[str]:
    result = list(names)
    for name in set(names):
        indexes = [i for i, n in enumerate(names) if n == name]
        if len(indexes) > 1:
            renamed = _renamed(name, [functions[i] for i in indexes], language)
            for i, new_name in zip(indexes, renamed, strict=True):
                result[i] = new_name
    return result


def _renamed(name: str, functions: list, language: Language) -> list[str]:
    typed = [f"{name}({_parameter_types(function, language)})" for function in functions]
    if language.overloads_by_type and len(set(typed)) == len(typed):
        return typed
    return [name if n == 0 else f"{name} #{n + 1}" for n in range(len(functions))]


def own_name(function) -> str | None:
    special = _SPECIAL_NAMES.get(function.type)
    if special:
        return special(function)
    if name := function.child_by_field_name("name"):
        accessor = next((c.type for c in function.children if c.type in ("get", "set")), None)
        return f"{accessor} {text(name)}" if accessor else text(name)
    return _assigned_name(function)


def _assigned_name(function) -> str | None:
    parent = function.parent
    if parent.type in _ASSIGNMENTS:
        left = parent.child_by_field_name("left")
        return text(_member_name(left) or left)
    for field in _NAME_FIELDS.get(parent.type, ()):
        if name := parent.child_by_field_name(field):
            return text(name)
    return None


def class_names(node, language: Language) -> list[str]:
    names = []
    node = node.parent
    while node is not None:
        if node.type in language.classes and (name := node.child_by_field_name("name")):
            names.insert(0, text(name))
        node = node.parent
    return names


def _accessor_name(accessor) -> str:
    owner = accessor.parent.parent
    owner_name = owner.child_by_field_name("name")
    return f"{text(owner_name) if owner_name else 'this'}.{text(accessor.child_by_field_name('name'))}"


_SPECIAL_NAMES = {
    "accessor_declaration": _accessor_name,
    "destructor_declaration": lambda f: f"~{text(f.child_by_field_name('name'))}",
    "operator_declaration": lambda f: f"operator {text(f.child_by_field_name('operator'))}",
    "conversion_operator_declaration": lambda f: f"operator {text(f.child_by_field_name('type'))}",
}

_NAME_FIELDS = {
    "variable_declarator": ("name",),
    "public_field_definition": ("name",),
    "field_definition": ("property",),
    "pair": ("key",),
}

_ASSIGNMENTS = frozenset({"assignment_expression", "assignment"})
_ARGUMENT_WRAPPERS = frozenset({"argument", "keyword_argument"})
_ARGUMENT_LISTS = frozenset({"arguments", "argument_list"})
_MEMBER_ACCESS = frozenset({"member_expression", "member_access_expression", "attribute"})


def _member_name(node):
    if node.type not in _MEMBER_ACCESS:
        return None
    return next((m for f in ("property", "name", "attribute") if (m := node.child_by_field_name(f))), None)


def _callee_name(function) -> str | None:
    parent = function.parent
    if parent.type in _ARGUMENT_WRAPPERS:
        parent = parent.parent
    if parent.type not in _ARGUMENT_LISTS:
        return None
    call = parent.parent
    callee = next(
        (c for field in ("function", "constructor", "type") if (c := call.child_by_field_name(field))), None
    )
    if callee is None:
        return None
    return text(_member_name(callee) or callee)


def _parameter_types(function, language: Language) -> str:
    params = parameter_list(function, language)
    if params is None:
        return ""
    return ", ".join(_group_type(group) for group in parameter_groups(params, language))


def _group_type(group) -> str:
    if len(group) == 1 and (type_node := group[0].child_by_field_name("type")):
        return text(type_node)
    return " ".join(text(node) for node in group[:-1]) or text(group[0])


def _enclosing_function(node, language: Language):
    node = node.parent
    while node is not None and node.type not in language.functions:
        node = node.parent
    return node
