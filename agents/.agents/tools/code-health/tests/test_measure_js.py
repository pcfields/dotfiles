from pathlib import Path

import pytest

from code_health.languages import language_for_path
from code_health.measure import measure_file
from code_health.smells import find_smells

FIXTURES = Path(__file__).parent / "fixtures"


def measure_as(extension: str, source: str):
    return measure_file(source.encode(), language_for_path(f"x.{extension}"))


@pytest.mark.parametrize(("folder", "extension"), [("javascript", "js"), ("jsx", "jsx"), ("tsx", "tsx")])
def test_smell_fixture_reports_each_smell_and_matches_its_crlf_twin(folder, extension):
    language = language_for_path(f"x.{extension}")
    lf = measure_file((FIXTURES / folder / f"smells.{extension}").read_bytes(), language)
    crlf = measure_file((FIXTURES / folder / f"smells-crlf.{extension}").read_bytes(), language)

    assert crlf == lf
    assert lf.parse_errors == 0
    assert [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(lf)] == [
        ("Complex Method", "describe", 3, 11, 10),
        ("Deep Nested Complexity", "deep", 30, 4, 4),
        ("Bumpy Road", "bumpy", 43, 2, 2),
        ("Complex Conditional", "eligible", 55, 2, 2),
        ("Large Method", "large", 61, 72, 70),
        ("Excess Function Arguments", "ship", 134, 5, 5),
    ]


@pytest.mark.parametrize("extension", ["js", "jsx", "tsx"])
def test_jsx_and_js_specific_names(extension):
    source = (
        "const ids = function* () { yield 1; };\n"
        "class Cart { handle = () => 1; }\n"
        "module.exports.load = function () {};\n"
    )

    assert [f.name for f in measure_as(extension, source).functions] == ["ids", "Cart.handle", "load"]


@pytest.mark.parametrize("extension", ["jsx", "tsx"])
def test_conditional_rendering_counts_as_a_decision(extension):
    source = "function Badge({ user }) { return <span>{user.admin && <b>admin</b>}{user.vip ? 'v' : ''}</span>; }"

    (badge,) = measure_as(extension, source).functions

    assert (badge.name, badge.cyclomatic, badge.parameters) == ("Badge", 3, 1)
