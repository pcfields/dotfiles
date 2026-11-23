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


def branchy(name: str, branches: int) -> str:
    body = "".join(f"  if (a === {i}) return {i};\n" for i in range(branches))
    return f"function {name}(a) {{\n{body}  return 0;\n}}\n"


def test_a_file_of_many_middling_functions_is_flagged():
    source = "".join(branchy(f"f{i}", 6) for i in range(5))

    assert smells("a.ts", source) == [("Overall Code Complexity", "<file>", 1, 7.0, 6)]


def test_few_or_ordinary_functions_are_fine():
    assert smells("a.ts", "".join(branchy(f"f{i}", 6) for i in range(4))) == []
    assert smells("a.ts", "".join(branchy(f"f{i}", 4) for i in range(6))) == []


SHAPES = [
    "  const {p}Rows = await load({p}Source);",
    "  if (!{p}Rows.length) return [];",
    "  const {p}Totals = {p}Rows.map((row) => row.amount * rate);",
    "  log.info('loaded', {p}Rows.length);",
    "  for (const row of {p}Rows) {{ seen.add(row.id); }}",
]


def block(prefix: str, lines: int) -> str:
    return "".join(SHAPES[i % len(SHAPES)].format(p=prefix) + "\n" for i in range(lines))


def test_a_repeated_block_is_flagged_against_the_second_copy():
    source = f"function first() {{\n{block('a', 10)}}}\n\nfunction second() {{\n{block('b', 10)}}}\n"

    # The matching function headers belong to the run: 1 + 10 lines.
    assert smells("a.ts", source) == [("Code Duplication", "second", 14, 11, 10)]


def test_short_repeats_and_braces_are_fine():
    short = f"function first() {{\n{block('a', 8)}}}\nfunction second() {{\n{block('b', 8)}}}\n"
    braces = "".join(f"function f{i}() {{\n  if (x) {{\n  }}\n}}\n" for i in range(12))

    assert smells("a.ts", short) == []
    assert smells("a.ts", braces) == []


SPLIT_TS = """class Account {
  constructor(private repo, private mailer, private clock) {}
  load(id) { return this.repo.find(id); }
  save(a) { this.repo.save(a); }
  welcome(a) { this.mailer.send(a.email); }
  remind(a) { this.mailer.send(a.email, 'reminder'); }
  stamp(a) { a.at = this.clock.now(); }
  age(a) { return this.clock.now() - a.at; }
  static format(a) { return a.name; }
}
"""


def test_a_class_with_three_unrelated_groups_has_low_cohesion():
    assert smells("a.ts", SPLIT_TS) == [("Low Cohesion", "Account", 1, 3, 3)]


def test_methods_calling_each_other_belong_together():
    joined = SPLIT_TS.replace("age(a) { return this.clock.now() - a.at; }", "age(a) { this.save(a); return this.clock.now() - this.welcome(a); }")

    assert smells("a.ts", joined) == []


def test_cohesion_in_python_and_csharp():
    python = (
        "class Account:\n    def __init__(self, repo, mailer, clock):\n        self.repo = repo\n"
        "    def load(self, i):\n        return self.repo.find(i)\n"
        "    def welcome(self, a):\n        self.mailer.send(a)\n"
        "    def stamp(self, a):\n        a.at = self.clock.now()\n"
    )
    csharp = (
        "class Account {\n  private readonly IRepo _repo; private readonly IMailer _mailer; private readonly IClock _clock;\n"
        "  public Account Load(int id) { return _repo.Find(id); }\n"
        "  public void Welcome(Account a) { _mailer.Send(a.Email); }\n"
        "  public void Stamp(Account a) { a.At = this._clock.Now(); }\n}\n"
    )

    assert [s[:2] for s in smells("a.py", python)] == [("Low Cohesion", "Account")]
    assert [s[:2] for s in smells("A.cs", csharp)] == [("Low Cohesion", "Account")]


def test_property_accessors_are_not_method_groups():
    csharp = "class Button {\n" + "".join(
        f"  public int P{i} {{ get => (int)GetValue(P{i}Property); set => SetValue(P{i}Property, value); }}\n" for i in range(5)
    ) + "  void Toggle() { P0 = P1; }\n}\n"
    typescript = "class Box {\n" + "".join(f"  get p{i}() {{ return this._p{i}; }}\n" for i in range(5)) + "}\n"

    assert smells("B.cs", csharp) == []
    assert smells("b.ts", typescript) == []
