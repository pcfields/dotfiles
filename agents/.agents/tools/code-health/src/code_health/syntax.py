from code_health.languages import Language


def text(node) -> str:
    return node.text.decode()


def parameter_list(function, language: Language):
    return next((c for c in function.children if c.type in language.parameter_lists), None)


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
