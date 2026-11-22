from code_health.languages import Language


def text(node) -> str:
    return node.text.decode()


def parameter_list(function, language: Language):
    direct = _first_of(function.children, language.parameter_lists)
    if direct is not None or not language.nested_parameter_lists:
        return direct
    return _search_below(function, language, depth=3)


def _search_below(function, language: Language, depth: int):
    level = list(function.children)
    for _ in range(depth):
        if (found := _first_of(level, language.parameter_lists)) is not None:
            return found
        level = [child for node in level if node.type not in language.functions for child in node.children]
    return None


def _first_of(nodes, kinds):
    return next((node for node in nodes if node.type in kinds), None)


def name_node(node, language: Language):
    return node.child_by_field_name("name") or next(
        (c for c in node.children if c.type in language.name_nodes), None
    )


def parameter_groups(params, language: Language) -> list[list]:
    groups: list[list] = [[]]
    for child in params.children:
        if child.type == ",":
            groups.append([])
        elif child.is_named and child.type not in language.comments:
            groups[-1].append(child)
    return [group for group in groups if group]


def body(function, language: Language):
    return function.child_by_field_name("body") or next(
        (c for c in function.children if c.type in language.function_bodies), None
    )
