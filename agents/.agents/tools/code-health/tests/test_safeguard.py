import json
import subprocess

import pytest

from code_health.cli import main

CLEAN = "export function f(a) {\n  return a;\n}\n"


def nested(depth: int, name: str = "f") -> str:
    opening = "".join(f"{'  ' * (i + 1)}if (a{i}) {{\n" for i in range(depth))
    closing = "".join(f"{'  ' * (i + 1)}}}\n" for i in reversed(range(depth)))
    return f"export function {name}(a) {{\n{opening}{'  ' * (depth + 1)}return 1;\n{closing}  return 0;\n}}\n"


@pytest.fixture
def repo(tmp_path, monkeypatch):
    root = tmp_path / "repo"
    root.mkdir()
    git(root, "init", "-q", "-b", "main")
    monkeypatch.chdir(root)
    return root


def git(root, *args):
    subprocess.run(
        ["git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", *args],
        cwd=root,
        check=True,
        capture_output=True,
    )


def write(root, path, text):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


def commit(root, files: dict[str, str]):
    for path, text in files.items():
        write(root, path, text)
    git(root, "add", "-A")
    git(root, "commit", "-q", "-m", "change")


def safeguard(capsys, *args):
    code = main(["safeguard", *args])
    out, err = capsys.readouterr()
    return code, out, err


def safeguard_json(capsys, *args):
    code, out, _ = safeguard(capsys, "--json", *args)
    return code, json.loads(out)


def test_no_changes_pass(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})

    assert safeguard(capsys) == (0, "code-health safeguard: PASS (0 files checked)\n", "")


FOOTER = [
    'Refactor until no "x" lines remain, then run `code-health safeguard` again.',
    "Lower numbers with worse readability is a failure: don't split code into",
    "pieces too small to follow. If a finding has to stay, ask the user. Only",
    "they can run, in a terminal:",
]


def test_new_finding_fails_with_the_review_card(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))

    code, out, _ = safeguard(capsys)

    assert code == 2
    assert out.splitlines() == [
        "code-health safeguard: FAIL (1 file checked, 1 got worse)",
        "",
        "src/app.ts  10.0 -> 8.5  worse",
        "  x new       Deep Nested Complexity  f:1  depth 4 (limit 4)",
        "              fix: Replace Nested Conditional with Guard Clauses; Extract Function",
        "",
        *FOOTER,
        '  code-health accept src/app.ts --smell "Deep Nested Complexity" --function f --reason "<why>"',
    ]


def test_worse_finding_shows_its_old_value(repo, capsys):
    commit(repo, {"src/app.ts": nested(4)})
    write(repo, "src/app.ts", nested(5))

    code, out, _ = safeguard(capsys)

    assert code == 2
    assert "src/app.ts  8.5 -> 7.9  worse" in out.splitlines()
    assert "  x worse     Deep Nested Complexity  f:1  depth 5, was 4 (limit 4)" in out.splitlines()


def test_file_with_existing_findings_that_did_not_get_worse_passes(repo, capsys):
    commit(repo, {"src/app.ts": nested(6)})
    write(repo, "src/app.ts", nested(6).replace("return 0;", "return 2;"))

    code, out, _ = safeguard(capsys)

    assert code == 0
    assert out.splitlines()[:3] == [
        "code-health safeguard: PASS (1 file checked)",
        "",
        "src/app.ts  7.3 -> 7.3  same",
    ]
    assert "  ! existing  Deep Nested Complexity  f:1  depth 6 (limit 4)" in out.splitlines()


def test_fixed_finding_is_reported(repo, capsys):
    commit(repo, {"src/app.ts": nested(4)})
    write(repo, "src/app.ts", CLEAN)

    code, out, _ = safeguard(capsys)

    assert code == 0
    assert out.splitlines()[2:] == ["src/app.ts  8.5 -> 10.0  better", "  ok fixed    Deep Nested Complexity  f"]


def test_new_untracked_files_are_checked_against_an_empty_baseline(repo, capsys):
    commit(repo, {"README.md": "hi\n"})
    write(repo, "src/clean.ts", CLEAN)
    write(repo, "src/deep.ts", nested(4))

    code, report = safeguard_json(capsys)

    assert code == 2
    assert [(f["path"], f["before"], f["after"], f["status"]) for f in report["files"]] == [
        ("src/clean.ts", None, 10.0, "same"),
        ("src/deep.ts", None, 8.5, "worse"),
    ]
    assert report["files"][1]["findings"][0]["status"] == "new"


def test_ignored_deleted_and_unsupported_files_are_skipped(repo, capsys):
    commit(repo, {".gitignore": "build/\n", "src/old.ts": CLEAN, "db/schema.sql": "select 1;\n"})
    write(repo, "build/out.ts", nested(5))
    (repo / "src" / "old.ts").unlink()
    write(repo, "db/schema.sql", "select 2;\n")

    assert safeguard(capsys)[:2] == (0, "code-health safeguard: PASS (0 files checked)\n")


def test_staged_and_unstaged_changes_are_both_checked(repo, capsys):
    commit(repo, {"src/a.ts": CLEAN, "src/b.ts": CLEAN})
    write(repo, "src/a.ts", nested(4, "a"))
    git(repo, "add", "src/a.ts")
    write(repo, "src/b.ts", nested(4, "b"))

    _, report = safeguard_json(capsys)

    assert [f["path"] for f in report["files"]] == ["src/a.ts", "src/b.ts"]


def test_renamed_file_is_compared_with_its_old_path(repo, capsys):
    git(repo, "config", "diff.renames", "false")
    commit(repo, {"src/old.ts": nested(5)})
    git(repo, "mv", "src/old.ts", "src/new.ts")
    write(repo, "src/new.ts", nested(5).replace("return 0;", "return 2;"))

    code, report = safeguard_json(capsys)

    assert code == 0
    assert [(f["path"], f["before"], f["status"]) for f in report["files"]] == [("src/new.ts", 7.9, "same")]


def test_unusual_file_names_are_handled(repo, capsys):
    commit(repo, {"src/café menu.ts": CLEAN})
    write(repo, "src/café menu.ts", nested(4))

    _, report = safeguard_json(capsys)

    assert [f["path"] for f in report["files"]] == ["src/café menu.ts"]


def test_base_compares_with_the_merge_base(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    git(repo, "checkout", "-q", "-b", "feature")
    commit(repo, {"src/app.ts": nested(4)})

    assert safeguard(capsys)[0] == 0
    assert safeguard(capsys, "--base", "main")[0] == 2


def test_runs_from_a_subdirectory_with_paths_from_the_root(repo, capsys, monkeypatch):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))
    monkeypatch.chdir(repo / "src")

    _, report = safeguard_json(capsys)

    assert [f["path"] for f in report["files"]] == ["src/app.ts"]


def test_repo_without_commits_checks_new_files(repo, capsys):
    write(repo, "src/app.ts", nested(4))

    assert safeguard(capsys)[0] == 2


def test_unknown_base_fails_as_a_tool_error(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})

    code, _, err = safeguard(capsys, "--base", "no-such-branch")

    assert code == 1
    assert err.startswith("code-health: ")


def test_outside_a_git_repo_is_a_tool_error(tmp_path, capsys, monkeypatch):
    monkeypatch.chdir(tmp_path)

    code, _, err = safeguard(capsys)

    assert code == 1
    assert err.startswith("code-health: ")
