from code_health.languages import language_for_path
from code_health.measure import measure_file
from code_health.smells import find_smells


def smells(path: str, source: str):
    return [(f.smell, f.function, f.line, f.value, f.limit) for f in find_smells(measure_file(source.encode(), language_for_path(path)))]


def test_mocking_own_modules_is_flagged_once_per_file():
    source = (
        "import { vi } from 'vitest';\n"
        "vi.mock('./repository');\n"
        "jest.mock('../shared/clock', () => ({ now: () => 1 }));\n"
        "vi.mock('axios');\n"
        "vi.doMock(`./mailer`);\n"
    )

    assert smells("a.test.ts", source) == [("Mocked Own Module", "<file>", 2, 3, 1)]


def test_mocking_packages_is_fine():
    assert smells("a.test.ts", "vi.mock('axios');\njest.mock('@company/sdk');\n") == []


def test_review_describes_the_new_smells():
    from code_health.report import format_review, review_source

    report = review_source("a.test.ts", b"vi.mock('./a');\nvi.mock('./b');\n")

    assert "  Mocked Own Module  <file>:1  2 mocks (limit 1)" in format_review(report).splitlines()


def asserts(template: str, count: int, indent: str = "  ") -> str:
    return "".join(indent + template.format(i=i) + "\n" for i in range(count))


def test_a_long_run_of_assertions_is_flagged():
    source = "it('checks', () => {\n" + asserts("expect(row[{i}]).toBe({i});", 9) + "});\n"

    assert smells("a.test.ts", source) == [("Large Assertion Block", "it callback", 1, 9, 8)]


def test_a_run_broken_by_other_code_is_fine():
    source = (
        "it('checks', () => {\n" + asserts("expect(a[{i}]).toBe({i});", 5) + "  const b = load();\n"
        + asserts("expect(b[{i}]).toBe({i});", 5) + "});\n"
    )

    assert smells("a.test.ts", source) == []


def test_assertions_in_other_languages():
    python = "def test_rows():\n" + asserts("assert rows[{i}] == {i}", 8, "    ")
    csharp = "class T { void Rows() {\n" + asserts("Assert.Equal({i}, rows[{i}]);", 8) + "} }\n"
    rust = "fn rows() {\n" + asserts("assert_eq!(rows[{i}], {i});", 8) + "}\n"

    assert [s[0] for s in smells("test_a.py", python)] == ["Large Assertion Block"]
    assert [s[0] for s in smells("T.cs", csharp)] == ["Large Assertion Block"]
    assert [s[0] for s in smells("a.rs", rust)] == ["Large Assertion Block"]
