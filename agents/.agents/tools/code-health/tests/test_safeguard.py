import json

from gitrepo import CLEAN, commit, git, nested, write

from code_health.cli import main


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


def test_since_turn_catches_a_regression_committed_during_the_turn(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    assert main(["mark-turn", "--session", "s1"]) == 0
    commit(repo, {"src/app.ts": nested(4)})

    assert safeguard(capsys)[0] == 0
    assert safeguard(capsys, "--since-turn", "--session", "s1")[0] == 2


def test_since_turn_without_a_mark_compares_with_head(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    commit(repo, {"src/app.ts": nested(4)})

    assert safeguard(capsys, "--since-turn", "--session", "unmarked")[0] == 0


def test_turn_marks_are_kept_per_session(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    main(["mark-turn", "--session", "early"])
    commit(repo, {"src/app.ts": nested(4)})
    main(["mark-turn", "--session", "late"])

    assert safeguard(capsys, "--since-turn", "--session", "early")[0] == 2
    assert safeguard(capsys, "--since-turn", "--session", "late")[0] == 0


def test_mark_turn_in_a_repo_without_commits_is_harmless(repo, state, capsys):
    write(repo, "src/app.ts", nested(4))

    assert main(["mark-turn", "--session", "s1"]) == 0
    assert safeguard(capsys, "--since-turn", "--session", "s1")[0] == 2


def test_since_turn_and_base_cannot_be_combined(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})

    assert safeguard(capsys, "--since-turn", "--base", "main")[0] == 1


LOOSE_NESTING = '[[rules]]\npaths = ["src/**"]\nlimits = { "Deep Nested Complexity" = 9 }\n'


def test_review_uses_the_repo_config(repo, capsys):
    commit(repo, {"src/app.ts": nested(4), ".code-health.toml": LOOSE_NESTING})

    code = main(["review", "src/app.ts"])
    out, _ = capsys.readouterr()

    assert (code, out.splitlines()[1]) == (0, "  no findings")


def test_safeguard_uses_the_config_from_the_base_commit(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, ".code-health.toml", LOOSE_NESTING)
    write(repo, "src/app.ts", nested(4))

    code, out, _ = safeguard(capsys)

    assert code == 2
    assert "! .code-health.toml changed; it takes effect once committed" in out.splitlines()


def test_committed_config_applies_from_the_next_base(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN, ".code-health.toml": LOOSE_NESTING})
    write(repo, "src/app.ts", nested(4))

    assert safeguard(capsys)[0] == 0


def test_excluded_files_are_not_checked(repo, capsys):
    commit(repo, {".code-health.toml": 'exclude = ["gen/**"]\n'})
    write(repo, "gen/client.ts", nested(5))
    write(repo, "node_modules/lib/index.js", nested(5))

    assert safeguard(capsys)[:2] == (0, "code-health safeguard: PASS (0 files checked)\n")


def test_invalid_config_is_a_tool_error(repo, capsys):
    commit(repo, {".code-health.toml": "exclude = [", "src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))

    code, _, err = safeguard(capsys)

    assert code == 1
    assert "not valid TOML" in err


def test_test_files_weigh_large_methods_at_half(repo, capsys):
    body = "".join(f"  x += {i};\n" for i in range(80))
    commit(repo, {"src/a.ts": f"function f(x) {{\n{body}}}\n", "src/a.test.ts": f"function f(x) {{\n{body}}}\n"})

    main(["score", "src/a.ts", "src/a.test.ts"])
    out, _ = capsys.readouterr()

    assert [line.split()[0] for line in out.splitlines()] == ["8.7", "9.3"]


BRANCHY = "export function f(a) {\n" + "".join(f"  if (a === {i}) return {i};\n" for i in range(10)) + "  return 0;\n}\n"
IGNORE = "// code-health: ignore Complex Method -- lookup table\n"


def test_new_ignore_comment_fails_until_accepted(repo, capsys):
    commit(repo, {"src/app.ts": BRANCHY})
    write(repo, "src/app.ts", IGNORE + BRANCHY)

    code, out, _ = safeguard(capsys)

    assert code == 2
    assert "  x new       Ignore Comment  f:1  new ignore comment" in out.splitlines()
    assert '  code-health accept src/app.ts --smell "Ignore Comment" --function f --reason "<why>"' in out.splitlines()


def test_committed_ignore_comment_passes(repo, capsys):
    commit(repo, {"src/app.ts": IGNORE + BRANCHY})
    write(repo, "src/app.ts", IGNORE + BRANCHY.replace("return 0;", "return -1;"))

    assert safeguard(capsys)[0] == 0


def test_new_invalid_ignore_comment_fails(repo, capsys):
    commit(repo, {"src/app.ts": BRANCHY})
    write(repo, "src/app.ts", "// code-health: ignore Complex Method\n" + BRANCHY)

    code, out, _ = safeguard(capsys)

    assert code == 2
    assert "Invalid Ignore Comment" in out


def test_crlf_config_is_not_reported_as_changed(repo, capsys):
    (repo / ".code-health.toml").write_bytes(LOOSE_NESTING.replace("\n", "\r\n").encode())
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", CLEAN.replace("a;", "a + 1;"))

    code, out, _ = safeguard(capsys)

    assert code == 0
    assert "changed; it takes effect once committed" not in out
