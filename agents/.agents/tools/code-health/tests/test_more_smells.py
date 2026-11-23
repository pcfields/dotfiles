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
