from code_health.languages import Language


def function_name(function, language: Language) -> str:
    own = own_name(function)
    if own is not None:
        return ".".join([*_class_names(function, language), own])
    parent = _enclosing_function(function, language)
    prefix = f"{function_name(parent, language)}." if parent else ""
    callee = _callee_name(function)
    return prefix + (f"{callee} callback" if callee else "<anonymous>")


def own_name(function) -> str | None:
    if name := function.child_by_field_name("name"):
        accessor = next((c.type for c in function.children if c.type in ("get", "set")), None)
        return f"{accessor} {_text(name)}" if accessor else _text(name)
    parent = function.parent
    if parent.type == "assignment_expression":
        left = parent.child_by_field_name("left")
        target = left.child_by_field_name("property") if left.type == "member_expression" else left
        return _text(target)
    for field in _NAME_FIELDS.get(parent.type, ()):
        if name := parent.child_by_field_name(field):
            return _text(name)
    return None


_NAME_FIELDS = {
    "variable_declarator": ("name",),
    "public_field_definition": ("name",),
    "field_definition": ("property",),
    "pair": ("key",),
}


def _callee_name(function) -> str | None:
    if function.parent.type != "arguments":
        return None
    call = function.parent.parent
    callee = call.child_by_field_name("function") or call.child_by_field_name("constructor")
    if callee is None:
        return None
    if callee.type == "member_expression":
        callee = callee.child_by_field_name("property")
    return _text(callee)


def _enclosing_function(node, language: Language):
    node = node.parent
    while node is not None and node.type not in language.functions:
        node = node.parent
    return node


def _class_names(function, language: Language) -> list[str]:
    names = []
    node = function.parent
    while node is not None:
        if node.type in language.classes and (name := node.child_by_field_name("name")):
            names.insert(0, _text(name))
        node = node.parent
    return names


def _text(node) -> str:
    return node.text.decode()
