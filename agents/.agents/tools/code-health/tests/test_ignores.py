import pytest

from code_health.report import format_review, review_source
from code_health.smells import Finding

BRANCHY_TS = "function f(a) {\n" + "".join(f"  if (a === {i}) return {i};\n" for i in range(10)) + "  return 0;\n}\n"


def smells(report):
    return [(f.smell, f.function) for f in report.findings]


def test_ignore_comment_suppresses_the_finding():
    source = "// code-health: ignore Complex Method -- parser table, rewrite planned\n" + BRANCHY_TS

    report = review_source("a.ts", source.encode())

    assert (report.score, smells(report)) == (10.0, [])
    assert [(i.smell, i.function, i.reason) for i in report.ignored] == [
        ("Complex Method", "f", "parser table, rewrite planned")
    ]


def test_without_the_comment_the_finding_counts():
    assert smells(review_source("a.ts", BRANCHY_TS.encode())) == [("Complex Method", "f")]


@pytest.mark.parametrize(
    ("path", "source"),
    [
        ("a.py", "# code-health: ignore Excess Function Arguments -- mirrors the API\n@cached\ndef f(a, b, c, d, e):\n    pass\n"),
        (
            "A.cs",
            (
                "class C {\n  /// code-health: ignore Excess Function Arguments -- mirrors the API\n"
                "  [HttpGet]\n  void F(int a, int b, int c, int d, int e) { }\n}\n"
            ),
        ),
        ("a.lua", "-- code-health: ignore Excess Function Arguments -- mirrors the API\nlocal function f(a, b, c, d, e) end\n"),
        ("a.rs", "// code-health: ignore Excess Function Arguments -- mirrors the API\n#[inline]\nfn f(a: i32, b: i32, c: i32, d: i32, e: i32) {}\n"),
        ("a.ps1", "<# code-health: ignore Excess Function Arguments -- mirrors the API #>\nfunction F($a, $b, $c, $d, $e) { 1 }\n"),
        ("a.ts", "/* code-health: ignore Excess Function Arguments -- mirrors the API */\nfunction f(a, b, c, d, e) {}\n"),
    ],
)
def test_any_comment_syntax_and_decorators_in_between(path, source):
    report = review_source(path, source.encode())

    assert smells(report) == []
    assert [(i.smell, i.reason) for i in report.ignored] == [("Excess Function Arguments", "mirrors the API")]


def test_a_blank_line_breaks_the_association():
    source = "// code-health: ignore Complex Method -- not attached\n\n" + BRANCHY_TS

    assert smells(review_source("a.ts", source.encode())) == [("Complex Method", "f")]


def test_ignore_for_another_smell_does_not_suppress():
    source = "// code-health: ignore Large Method -- wrong smell\n" + BRANCHY_TS

    assert smells(review_source("a.ts", source.encode())) == [("Complex Method", "f")]


@pytest.mark.parametrize(
    "directive",
    ["// code-health: ignore Complex Method", "// code-health: ignore Complex Method --", "// code-health: ignore Big Method -- why"],
    ids=["no reason", "empty reason", "unknown smell"],
)
def test_invalid_ignore_comment_is_a_finding(directive):
    report = review_source("a.ts", f"{directive}\n{BRANCHY_TS}".encode())

    assert smells(report) == [("Complex Method", "f"), ("Invalid Ignore Comment", "f")]
    assert report.findings[1].line == 1


def test_file_level_ignore_for_large_file():
    body = "".join(f"export const v{i} = {i};\n" for i in range(1000))
    source = "// code-health: ignore Large File -- generated lookup table\n" + body

    report = review_source("a.ts", source.encode())

    assert (smells(report), [i.function for i in report.ignored]) == ([], ["<file>"])


def test_review_shows_ignored_findings():
    source = "// code-health: ignore Complex Method -- parser table\n" + BRANCHY_TS

    assert format_review(review_source("a.ts", source.encode())).splitlines() == [
        "a.ts  10.0  green",
        "  ~ ignored  Complex Method  f:2  parser table",
    ]


def test_invalid_ignore_comment_is_described():
    report = review_source("a.ts", ("// code-health: ignore Complex Method\n" + BRANCHY_TS).encode())

    assert "  Invalid Ignore Comment  f:1  needs `code-health: ignore <Smell> -- <reason>`" in format_review(report)
    assert isinstance(report.findings[1], Finding)


def test_large_file_ignore_above_the_first_function_still_means_the_file():
    body = "".join(f"  x += {i};\n" for i in range(1000))
    source = "// code-health: ignore Large File -- generated\nexport function f(x) {\n" + body + "}\n"

    report = review_source("a.ts", source.encode())

    assert "Large File" not in [f.smell for f in report.findings]
    assert [(i.smell, i.function) for i in report.ignored] == [("Large File", "<file>")]
