from code_health.history import machine_name


def test_machine_name_is_a_safe_file_name_part():
    assert machine_name("Peter's Laptop.local") == "peter-s-laptop.local"
    assert machine_name("DESKTOP-ABC123") == "desktop-abc123"
    assert machine_name("") == "unknown"


import json
import subprocess

import pytest

from code_health.cli import main


def git(cwd, *args):
    return subprocess.run(
        ["git", "-c", "user.name=t", "-c", "user.email=t@example.com", "-c", "commit.gpgsign=false", *args],
        cwd=cwd, check=True, capture_output=True, text=True,
    ).stdout


@pytest.fixture
def machines(tmp_path):
    remote = tmp_path / "remote.git"
    git(tmp_path, "init", "-q", "--bare", "-b", "main", str(remote))
    clones = []
    for name in ("a", "b"):
        git(tmp_path, "clone", "-q", str(remote), name)
        clones.append(tmp_path / name)
    (clones[0] / "README.md").write_text("history\\n")
    git(clones[0], "add", "-A")
    git(clones[0], "commit", "-q", "-m", "init")
    git(clones[0], "push", "-q", "-u", "origin", "main")
    git(clones[1], "pull", "-q", "origin", "main")
    git(clones[1], "branch", "-q", "--set-upstream-to=origin/main")
    return clones


def sync(capsys, monkeypatch, folder):
    monkeypatch.setenv("CODE_HEALTH_HISTORY_DIR", str(folder))
    code = main(["history", "sync"])
    out, err = capsys.readouterr()
    return code, out, err


def test_sync_shares_each_machines_records(machines, capsys, monkeypatch):
    a, b = machines
    (a / "episodes-a.jsonl").write_text(json.dumps({"kind": "uplift"}) + "\\n")
    (b / "episodes-b.jsonl").write_text(json.dumps({"kind": "safeguard-fix"}) + "\\n")

    assert sync(capsys, monkeypatch, a)[0] == 0
    assert sync(capsys, monkeypatch, b)[0] == 0
    assert sync(capsys, monkeypatch, a)[0] == 0

    assert sorted(p.name for p in a.glob("episodes-*.jsonl")) == ["episodes-a.jsonl", "episodes-b.jsonl"]


def test_sync_with_nothing_new_is_quiet(machines, capsys, monkeypatch):
    code, out, _ = sync(capsys, monkeypatch, machines[0])

    assert (code, "nothing new") == (0, out.strip().split(": ")[-1])


def test_sync_without_the_variable_is_an_error(capsys, monkeypatch):
    monkeypatch.delenv("CODE_HEALTH_HISTORY_DIR", raising=False)

    code = main(["history", "sync"])
    _, err = capsys.readouterr()

    assert code == 1
    assert "CODE_HEALTH_HISTORY_DIR" in err
