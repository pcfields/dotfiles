from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

TYPESCRIPT = language_for_path("x.ts")


def measure_ts(source: str):
    return measure_file(source.encode(), TYPESCRIPT)


def only_function(source: str):
    (function,) = measure_ts(source).functions
    return function


def test_empty_function_has_baseline_metrics():
    function = only_function("function f() {}")

    assert (function.name, function.line) == ("f", 1)
    assert function.cyclomatic == 1
    assert function.max_nesting == 0
    assert function.parameters == 0


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if (a) {}", 2),
        ("if (a) {} else {}", 2),
        ("if (a) {} else if (b) {} else {}", 3),
        ("for (let i = 0; i < n; i++) {}", 2),
        ("for (const x of xs) {}", 2),
        ("for (const k in o) {}", 2),
        ("while (a) {}", 2),
        ("do {} while (a);", 2),
        ("switch (a) { case 1: break; case 2: break; default: break; }", 3),
        ("try {} catch (e) {} finally {}", 2),
        ("return a ? 1 : 2;", 2),
        ("return a && b;", 2),
        ("return a || b;", 2),
        ("return a ?? b;", 2),
        ("a &&= b; a ||= b; a ??= b;", 4),
        ("return a + b;", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert only_function(f"function f() {{ {body} }}").cyclomatic == expected


def test_condition_records_its_boolean_operators():
    function = only_function("function f() {\n  if (a && b || c) {}\n}")

    assert function.cyclomatic == 4
    assert function.conditions == (Condition(line=2, operators=2),)


@pytest.mark.parametrize(
    "body",
    [
        "while (a && b) {}",
        "do {} while (a && b);",
        "for (let i = 0; i < n && ok; i++) {}",
        "return a && b ? 1 : 2;",
    ],
)
def test_loop_and_ternary_conditions_are_recorded(body):
    assert only_function(f"function f() {{ {body} }}").conditions == (Condition(line=1, operators=1),)


def test_nullish_and_operators_outside_conditions_are_not_conditions():
    function = only_function("function f() { const x = a ?? b; return c && d; }")

    assert function.conditions == ()


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if (a) { if (b) { if (c) {} } }", 3),
        ("if (a) {} else if (b) {} else if (c) { if (d) {} }", 2),
        ("for (const x of xs) { while (a) { do {} while (b); } }", 3),
        ("switch (a) { case 1: if (b) {} }", 2),
        ("try { if (a) {} } catch (e) { if (b) {} }", 2),
        ("return a ? (b ? 1 : 2) : 3;", 0),
        ("if (a) {} if (b) {}", 1),
    ],
)
def test_max_nesting(body, expected):
    assert only_function(f"function f() {{ {body} }}").max_nesting == expected


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("for (const x of xs) { if (x) {} } while (a) { if (b) {} }", 2),
        ("for (const x of xs) { if (x) {} } if (a) {}", 1),
        ("if (a) {} if (b) {} if (c) {}", 0),
        ("const x = 1;", 0),
    ],
)
def test_bumps_count_top_level_blocks_nested_two_deep(body, expected):
    assert only_function(f"function f() {{ {body} }}").bumps == expected


def test_expression_bodied_arrow_has_no_bumps():
    assert only_function("const f = (a) => a ? 1 : 2;").bumps == 0


@pytest.mark.parametrize(
    ("signature", "expected"),
    [
        ("function f(a, b = 1, c?: number) {}", 3),
        ("function f(a, { b, c }, ...rest) {}", 3),
        ("function f(this: Window, a: number) {}", 1),
        ("function f(a /* first */, b) {}", 2),
    ],
)
def test_parameter_count(signature, expected):
    assert only_function(signature).parameters == expected


def test_constructor_is_marked_and_counts_parameter_properties():
    functions = measure_ts(
        "class Cart { constructor(private readonly a: A, public b: B, c: C) {} count() { return 0; } }"
    ).functions

    assert [(f.name, f.is_constructor, f.parameters) for f in functions] == [
        ("Cart.constructor", True, 3),
        ("Cart.count", False, 0),
    ]


def names(source: str) -> list[str]:
    return [function.name for function in measure_ts(source).functions]


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        ("class Cart { count() {} get size() { return 0; } set size(v) {} }", ["Cart.count", "Cart.get size", "Cart.set size"]),
        ("class Cart { handle = () => 1; }", ["Cart.handle"]),
        ("const g = function () {}; let h = (x) => x;", ["g", "h"]),
        ("const o = { foo() {}, bar: () => 1 };", ["foo", "bar"]),
        ("obj.handler = () => {};", ["handler"]),
        ("function List() { items.map((x) => x); }", ["List", "List.map callback"]),
        ("function List() { setTimeout(() => {}); }", ["List", "List.setTimeout callback"]),
        ("function f() { return () => 1; }", ["f", "f.<anonymous>"]),
        ("export default () => {};", ["<anonymous>"]),
        ("abstract class A { m() {} }", ["A.m"]),
    ],
)
def test_function_names(source, expected):
    assert names(source) == expected


def test_nested_function_does_not_add_to_its_parent():
    outer, _, _ = measure_ts(
        "function outer() {\n"
        "  items.forEach((x) => { if (x) { if (x.y) {} } });\n"
        "  function inner() { for (const a of b) { if (a) {} } }\n"
        "}"
    ).functions

    assert (outer.cyclomatic, outer.max_nesting, outer.bumps) == (1, 0, 0)


def test_lines_of_code_skip_blank_and_comment_lines():
    source = """// header comment

/*
 * block comment
 */
function f() {
  const a = 1; // trailing comment counts

  const s = `multi
line
string`;
  return a;
}
"""
    metrics = measure_ts(source)

    assert metrics.loc == 7
    assert metrics.functions[0].loc == 7


def test_overload_signatures_are_not_functions():
    source = "function f(a: string): void;\nfunction f(a: number): void;\nfunction f(a: any) {}"

    assert [(f.name, f.line) for f in measure_ts(source).functions] == [("f", 3)]


def test_parse_errors_are_counted():
    assert measure_ts("function f( {").parse_errors > 0
    assert measure_ts("function f() {}").parse_errors == 0


def test_crlf_file_measures_the_same_as_its_lf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "typescript"
    lf = measure_file((fixtures / "metrics.ts").read_bytes(), TYPESCRIPT)
    crlf = measure_file((fixtures / "metrics-crlf.ts").read_bytes(), TYPESCRIPT)

    assert crlf == lf
    assert [(f.name, f.line, f.max_nesting, f.bumps) for f in lf.functions] == [
        ("Checkout.constructor", 4, 0, 0),
        ("Checkout.total", 9, 3, 2),
        ("describe", 32, 0, 0),
        ("describe.map callback", 32, 0, 0),
    ]


def test_constructor_call_callback_is_named_after_the_class():
    assert names("function load() { return new Promise((resolve) => resolve(1)); }") == [
        "load",
        "load.Promise callback",
    ]


def test_very_deep_expression_does_not_hit_the_recursion_limit():
    chain = " + ".join(["a"] * 5000)

    function = only_function(f"function f() {{ return {chain}; }}")

    assert (function.cyclomatic, function.max_nesting) == (1, 0)


def test_duplicate_callback_names_are_numbered():
    source = "function f() { a.map((x) => x); b.map((y) => y); }"

    assert names(source) == ["f", "f.map callback", "f.map callback #2"]


def test_bare_arrow_parameter_counts():
    assert only_function("const f = x => x;").parameters == 1


def test_describe_blocks_are_not_large_methods():
    tests = "".join(f"  it('case {i}', () => {{\n    expect({i}).toBe({i});\n  }});\n" for i in range(30))
    source = f"describe('suite', () => {{\n{tests}}});\ncontext('more', () => {{\n{tests}}});\n"

    smells = find_smells(measure_ts(source))

    assert [f.smell for f in smells] == []


def test_a_long_test_is_still_a_large_method():
    body = "".join(f"    const value{i} = load({i});\n" for i in range(80))
    source = f"describe('suite', () => {{\n  it('long', () => {{\n{body}  }});\n}});\n"

    assert [(f.smell, f.function) for f in find_smells(measure_ts(source))] == [
        ("Large Method", "describe callback.it callback"),
    ]


def test_import_types_are_a_known_parse_gap():
    assert measure_ts("let x: import('./a').B[] = [];\n").parse_errors > 0


def test_a_top_level_iife_is_not_a_large_method():
    helpers = "".join(f"  function helper{i}() {{\n    return {i};\n  }}\n" for i in range(40))
    source = f"(function () {{\n{helpers}}})();\n(() => {{\n{helpers}}})();\n"

    assert find_smells(measure_ts(source)) == ()


def test_a_long_default_export_is_still_a_large_method():
    body = "".join(f"  x += {i};\n" for i in range(80))
    source = f"export default (x) => {{\n{body}  return x;\n}};\n"

    assert [f.smell for f in find_smells(measure_ts(source))] == ["Large Method"]
