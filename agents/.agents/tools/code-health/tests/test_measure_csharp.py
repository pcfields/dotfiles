from pathlib import Path

import pytest
from code_health.languages import language_for_path
from code_health.measure import Condition, measure_file
from code_health.smells import find_smells

CSHARP = language_for_path("x.cs")


def measure_cs(source: str):
    return measure_file(source.encode(), CSHARP)


def names(source: str) -> list[str]:
    return [function.name for function in measure_cs(source).functions]


def in_method(body: str):
    (function,) = [f for f in measure_cs(f"class C {{ void M() {{ {body} }} }}").functions if f.name == "C.M"]
    return function


@pytest.mark.parametrize(
    ("source", "expected"),
    [
        ("class Svc { void M() { } }", ["Svc.M"]),
        ("namespace A.B; class Svc { void M() { } }", ["Svc.M"]),
        ("class Outer { class Inner { void M() { } } }", ["Outer.Inner.M"]),
        ("struct S { void M() { } } interface I { void N() { } } record R { void O() { } }", ["S.M", "I.N", "R.O"]),
        ("class Svc { Svc() { } ~Svc() { } }", ["Svc.Svc", "Svc.~Svc"]),
        ("class C { public static C operator +(C a, C b) => a; public static implicit operator int(C c) => 0; }",
         ["C.operator +", "C.operator int"]),
        ("class C { int P { get { return 1; } set { } } }", ["C.P.get", "C.P.set"]),
        ("class C { int this[int i] { get { return i; } } }", ["C.this.get"]),
        ("class C { event E Changed { add { } remove { } } }", ["C.Changed.add", "C.Changed.remove"]),
        ("class C { void M() { int Local() { return 1; } } }", ["C.M", "C.Local"]),
        ("class C { void M() { Func<int> f = () => 1; } }", ["C.M", "C.f"]),
        ("class C { void M() { list.Select(x => x); } }", ["C.M", "C.M.Select callback"]),
        ("class C { void M() { new Thread(() => { }); } }", ["C.M", "C.M.Thread callback"]),
        ("class C { void M() { h.Click += delegate (object s, E e) { }; } }", ["C.M", "C.Click"]),
        ("class C { int Q => 2; }", []),
        ("interface I { void N(); }", []),
    ],
)
def test_function_names(source, expected):
    assert names(source) == expected


def test_overloads_are_named_by_parameter_types():
    source = "class C { void M(int a) { } void M(string s, List<int> xs) { } void N() { } }"

    assert names(source) == ["C.M(int)", "C.M(string, List<int>)", "C.N"]


def test_primary_constructor_on_a_class_is_a_constructor():
    (ctor, method) = measure_cs("class Svc(IRepo repo, ILog log) { void M() { } }").functions

    assert (ctor.name, ctor.line, ctor.is_constructor, ctor.parameters) == ("Svc.<primary constructor>", 1, True, 2)
    assert method.name == "Svc.M"


def test_positional_record_parameters_are_not_a_constructor():
    assert names("record R(int A, string B); record struct S(int A);") == []


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if (a) { } else if (b) { } else { }", 3),
        ("for (int i = 0; i < n; i++) { }", 2),
        ("foreach (var x in xs) { }", 2),
        ("while (a) { }", 2),
        ("do { } while (a);", 2),
        ("switch (a) { case 1: case 2: break; case 3: break; default: break; }", 4),
        ("var r = a switch { 1 => 2, > 5 => 3, _ => 4 };", 3),
        ("try { } catch (IOException) { } catch (Exception e) when (e != null) { } finally { }", 3),
        ("var r = a ? 1 : 2;", 2),
        ("var r = a && b || c;", 3),
        ("var r = a ?? b; c ??= d;", 3),
        ("var r = x is > 0 and < 10 or 42;", 3),
        ("var r = a + b;", 1),
    ],
)
def test_cyclomatic_counts_each_decision(body, expected):
    assert in_method(body).cyclomatic == expected


def test_lambda_branches_do_not_count_toward_the_method():
    assert in_method("list.Where(x => x > 0 && x < 9).Select(x => x ? 1 : 2);").cyclomatic == 1


@pytest.mark.parametrize(
    ("body", "expected"),
    [
        ("if (a) { if (b) { if (c) { } } }", 3),
        ("if (a) { } else if (b) { } else if (c) { if (d) { } }", 2),
        ("if (a) if (b) M();", 2),
        ("foreach (var x in xs) { while (a) { do { } while (b); } }", 3),
        ("switch (a) { case 1: if (b) { } break; }", 2),
        ("try { if (a) { } } catch { if (b) { } }", 2),
        ("using (var s = Open()) { lock (o) { if (a) { } } }", 1),
    ],
)
def test_max_nesting(body, expected):
    assert in_method(body).max_nesting == expected


def test_bumps():
    body = "foreach (var x in xs) { if (x) { } } while (a) { if (b) { } }"

    assert in_method(body).bumps == 2


def test_expression_bodied_member_has_no_bumps():
    (function,) = measure_cs("class C { int M(int a) => a > 0 ? 1 : 2; }").functions

    assert (function.cyclomatic, function.bumps) == (2, 0)


@pytest.mark.parametrize(
    ("signature", "expected"),
    [
        ("void M()", 0),
        ("void M(int a, string b = null, out int c)", 3),
        ("void M(int a, params int[] rest)", 2),
        ("void M(this string s, int a)", 2),
        ("void M(int a /* first */, int b)", 2),
    ],
)
def test_parameter_count(signature, expected):
    (function,) = measure_cs(f"class C {{ {signature} {{ }} }}").functions

    assert function.parameters == expected


def test_constructors_are_marked():
    functions = measure_cs("class C { C(int a) { } void M() { } }").functions

    assert [(f.name, f.is_constructor) for f in functions] == [("C.C", True), ("C.M", False)]


@pytest.mark.parametrize(
    "body",
    [
        "if (a && b) { }",
        "while (a && b) { }",
        "do { } while (a && b);",
        "for (int i = 0; i < n && ok; i++) { }",
        "var r = a && b ? 1 : 2;",
    ],
)
def test_conditions_are_recorded(body):
    assert in_method(body).conditions == (Condition(line=1, operators=1),)


def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin():
    fixtures = Path(__file__).parent / "fixtures" / "csharp"
    lf = measure_file((fixtures / "smells.cs").read_bytes(), CSHARP)
    crlf = measure_file((fixtures / "smells-crlf.cs").read_bytes(), CSHARP)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Excess Function Arguments", "Orders.<primary constructor>", 4, 8, 8),
        ("Excess Function Arguments", "Orders.Orders", 6, 9, 8),
        ("Complex Method", "Orders.Describe", 11, 11, 10),
        ("Deep Nested Complexity", "Orders.Deep", 29, 4, 4),
        ("Bumpy Road", "Orders.Bumpy", 47, 2, 2),
        ("Complex Conditional", "Orders.Eligible", 61, 2, 2),
        ("Large Method", "Orders.Large", 63, 73, 70),
        ("Excess Function Arguments", "Orders.Ship", 137, 5, 5),
    ]
