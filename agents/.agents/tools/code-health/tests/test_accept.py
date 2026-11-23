import json
import os
import subprocess
import sys

import pytest
from gitrepo import CLEAN, commit, nested, write

from code_health.cli import main

needs_pty = pytest.mark.skipif(sys.platform == "win32", reason="the pty module is POSIX-only")

IGNORE = "// code-health: ignore Deep Nested Complexity -- legacy\n"


def accept_in_terminal(repo, answer: str, *args: str) -> tuple[int, str]:
    import pty

    pid, fd = pty.fork()
    if pid == 0:
        os.chdir(repo)
        os.execvpe(sys.executable, [sys.executable, "-m", "code_health", "accept", *args], os.environ)
    output, sent = b"", False
    while True:
        try:
            data = os.read(fd, 1024)
        except OSError:
            break
        if not data:
            break
        output += data
        if not sent and b"Type yes" in output:
            os.write(fd, answer.encode() + b"\n")
            sent = True
    _, status = os.waitpid(pid, 0)
    return os.waitstatus_to_exitcode(status), output.decode(errors="replace")


def accepted_records(state):
    files = list(state.glob("*/accepted.jsonl"))
    return [json.loads(line) for f in files for line in f.read_text().splitlines()]


def safeguard_code(capsys) -> int:
    code = main(["safeguard"])
    capsys.readouterr()
    return code


ACCEPT_DEEP = ["src/app.ts", "--smell", "Deep Nested Complexity", "--reason", "port it next sprint"]


@pytest.mark.parametrize("stdin", [{"stdin": subprocess.DEVNULL}, {"input": "yes\n"}], ids=["null device", "piped yes"])
def test_accept_refuses_without_a_terminal(repo, state, stdin):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))

    result = subprocess.run(
        [sys.executable, "-m", "code_health", "accept", *ACCEPT_DEEP],
        cwd=repo,
        capture_output=True,
        text=True,
        check=False,
        **stdin,
    )

    assert result.returncode == 1
    assert "needs an interactive terminal" in result.stderr
    assert accepted_records(state) == []


@needs_pty
def test_yes_records_the_acceptance_and_the_safeguard_passes(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))
    assert safeguard_code(capsys) == 2

    code, output = accept_in_terminal(repo, "yes", *ACCEPT_DEEP)

    assert code == 0, output
    assert "Deep Nested Complexity  f:1  depth 4 (limit 4)" in output
    (record,) = accepted_records(state)
    assert set(record) == {"file", "smell", "function", "hash", "value", "reason", "date", "scorer_version"}
    assert (record["file"], record["function"], record["reason"]) == ("src/app.ts", "f", "port it next sprint")
    assert safeguard_code(capsys) == 0


@needs_pty
def test_safeguard_shows_accepted_findings(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))
    accept_in_terminal(repo, "yes", *ACCEPT_DEEP)

    main(["safeguard"])
    out, _ = capsys.readouterr()

    assert "  ok accepted  Deep Nested Complexity  f:1  depth 4 (limit 4)" in out.splitlines()


@needs_pty
def test_any_other_answer_writes_nothing(repo, state):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))

    code, _ = accept_in_terminal(repo, "y", *ACCEPT_DEEP)

    assert code == 1
    assert accepted_records(state) == []


@needs_pty
def test_acceptance_lapses_when_the_function_changes(repo, state, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4))
    accept_in_terminal(repo, "yes", *ACCEPT_DEEP)
    write(repo, "src/app.ts", nested(4).replace("return 0;", "return 2;"))

    assert safeguard_code(capsys) == 2


@needs_pty
def test_accepting_a_new_ignore_comment(repo, state, capsys):
    commit(repo, {"src/app.ts": nested(4)})
    write(repo, "src/app.ts", IGNORE + nested(4))
    assert safeguard_code(capsys) == 2

    code, _ = accept_in_terminal(repo, "yes", "src/app.ts", "--smell", "Ignore Comment", "--reason", "legacy")

    assert code == 0
    assert safeguard_code(capsys) == 0


@needs_pty
def test_unknown_finding_is_an_error(repo, state):
    commit(repo, {"src/app.ts": CLEAN})

    code, output = accept_in_terminal(repo, "yes", *ACCEPT_DEEP)

    assert code == 1
    assert "no Deep Nested Complexity finding in src/app.ts" in output


@needs_pty
def test_ambiguous_smell_needs_a_function(repo, state):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(4, "a") + nested(4, "b"))

    code, output = accept_in_terminal(repo, "yes", *ACCEPT_DEEP)

    assert code == 1
    assert "found in a, b: pass --function" in output
    code, _ = accept_in_terminal(repo, "yes", *ACCEPT_DEEP, "--function", "b")
    assert code == 0
