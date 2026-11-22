from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

PYTHON = language_for_path("x.py")


def measure_py(source: str):
    return measure_file(source.encode(), PYTHON)


def names(source: str) -> list[str]:
    return [function.name for function in measure_py(source).functions]


def function_named(source: str, name: str = "f"):
    (function,) = [f for f in measure_py(source).functions if f.name == name]
    return function


def in_function(body: str):
    lines = "\n".join(f"    {line}" for line in body.splitlines())
    return function_named(f"def f(a, b, c):\n{lines}\n")


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        ("def f():\n    pass\n", ["<script>", "f"]),
        ("class C:\n    def m(self):\n        pass\n", ["<script>", "C.m"]),
        ("class C:\n    class D:\n        async def m(self):\n            pass\n", ["<script>", "C.D.m"]),
        ("@decorator\ndef f():\n    pass\n", ["<script>", "f"]),
        ("def f():\n    def inner():\n        pass\n", ["<script>", "f", "inner"]),
        ("square = lambda x: x * x\n", ["<script>", "square"]),
        ("class C:\n    def m(self):\n        self.h = lambda: 1\n", ["<script>", "C.m", "C.h"]),
        ("def f(xs):\n    return sorted(xs, key=lambda v: v)\n", ["<script>", "f", "f.sorted callback"]),
        ("def f(xs):\n    return xs.map(lambda v: v)\n", ["<script>", "f", "f.map callback"]),
    ],
)
def test_function_names(source, expected):
    assert names(source) == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a:\n    pass\nelif b:\n    pass\nelse:\n    pass", 3),
        ("for x in a:\n    pass\nelse:\n    pass", 2),
        ("while a:\n    pass", 2),
        ("match a:\n    case 1 | 2:\n        pass\n    case [x]:\n        pass\n    case _:\n        pass", 3),
        ("try:\n    pass\nexcept E:\n    pass\nexcept F:\n    pass\nfinally:\n    pass", 3),
        ("return 1 if a else 2", 2),
        ("return a and b or c", 3),
        ("return [x for x in a if x]", 3),
        ("with open(a) as f:\n    pass", 1),
        ("return not a", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_function(body).cyclomatic == expected


def test_lambda_branches_do_not_count_toward_the_function():
    assert in_function("return sorted(a, key=lambda v: 1 if v else 2)").cyclomatic == 1


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if a:\n    if b:\n        if c:\n            pass", 3),
        ("if a:\n    pass\nelif b:\n    pass\nelif c:\n    if a:\n        pass", 2),
        ("for x in a:\n    while b:\n        try:\n            pass\n        except E:\n            pass", 3),
        ("match a:\n    case 1:\n        if b:\n            pass", 2),
        ("with a:\n    with b:\n        if c:\n            pass", 1),
    ],
)
def test_max_nesting(body, expected):
    assert in_function(body).max_nesting == expected


def test_bumps():
    body = "for x in a:\n    if x:\n        pass\nwhile b:\n    if c:\n        pass"

    assert in_function(body).bumps == 2


@pytest.mark.parametrize(
    ("signature", "expected"),
    [
        ("def f():", 0),
        ("def f(a, b=1, *args, c: int, d: int = 2, **kw):", 6),
        ("def f(a, /, b, *, c):", 3),
    ],
)
def test_parameter_count(signature, expected):
    assert function_named(f"{signature}\n    pass\n").parameters == expected


def test_self_and_cls_do_not_count():
    source = "class C:\n    def m(self, a):\n        pass\n    @classmethod\n    def n(cls, a, b):\n        pass\n"

    assert [(f.name, f.parameters) for f in measure_py(source).functions[1:]] == [("C.m", 1), ("C.n", 2)]


def test_init_is_a_constructor():
    functions = measure_py("class C:\n    def __init__(self, a):\n        pass\n    def m(self):\n        pass\n").functions

    assert [(f.name, f.is_constructor) for f in functions[1:]] == [("C.__init__", True), ("C.m", False)]


@pytest.mark.parametrize(
    ("body", "line"),
    [
        ("if a and b:\n    pass", 2),
        ("if c:\n    pass\nelif a and b:\n    pass", 4),
        ("while a and b:\n    pass", 2),
        ("return 1 if a and b else 2", 2),
    ],
)
def test_conditions_are_recorded(body, line):
    conditions = in_function(body).conditions

    assert Condition(line=line, operators=1) in conditions


def test_script_measures_top_level_code_outside_functions():
    source = "import os\n\nif os.name == 'nt' and a:\n    for x in y:\n        if x:\n            pass\n\ndef f():\n    if a:\n        pass\n"

    script = function_named(source, "<script>")

    assert (script.line, script.cyclomatic, script.max_nesting, script.parameters) == (1, 5, 3, 0)
    assert script.conditions == (Condition(line=3, operators=1), Condition(line=5, operators=0))


def test_script_is_exempt_from_large_method():
    source = "".join(f"X{i} = {i}\n" for i in range(80))

    assert find_smells(measure_py(source)) == ()


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "python"
    lf = measure_file((fixtures / "smells.py").read_bytes(), PYTHON)
    crlf = measure_file((fixtures / "smells-crlf.py").read_bytes(), PYTHON)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "describe", 4, 11, 10),
        ("Deep Nested Complexity", "deep", 28, 4, 4),
        ("Bumpy Road", "bumpy", 37, 2, 2),
        ("Complex Conditional", "eligible", 49, 2, 2),
        ("Large Method", "large", 54, 72, 70),
        ("Excess Function Arguments", "Shipper.ship", 132, 5, 5),
    ]
