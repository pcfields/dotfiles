import json
import re
import subprocess
import sys
from pathlib import Path

from gitrepo import CLEAN, commit, nested

from code_health.cli import main

BUILD_REPORT = Path(__file__).resolve().parents[3] / "skills" / "repo-health" / "scripts" / "build-report.py"


def build(repo, *args) -> subprocess.CompletedProcess:
    return subprocess.run(
        [sys.executable, str(BUILD_REPORT), str(repo / ".code-health" / "repo"), *args],
        capture_output=True, text=True, check=False,
    )


def page_json(html: str, name: str) -> dict:
    match = re.search(rf"const {name} = (.*?);\n", html)
    return json.loads(match.group(1).replace("<\\/", "</"))


def run_repo(repo, capsys):
    main(["repo", "--json"])
    capsys.readouterr()


def test_builds_the_page_from_the_saved_data(repo, capsys):
    commit(repo, {"src/hot.ts": nested(4), "src/calm.ts": CLEAN})
    run_repo(repo, capsys)

    result = build(repo)

    assert result.returncode == 0, result.stderr
    html = (repo / ".code-health" / "repo" / "report.html").read_text()
    data = page_json(html, "DATA")
    hot = next(row for row in data["files"] if row[0] == "src/hot.ts")
    assert hot[2:5] == [8.5, "y", 1]
    assert [f["smell"] for f in hot[6]] == ["Deep Nested Complexity"]
    assert data["overview"]["files_scored"] == 2
    assert len(data["snapshots"]) == 1
    assert "/*DATA*/" not in html and "/*FINDINGS*/" not in html


def test_targets_with_unknown_paths_are_dropped(repo, capsys):
    commit(repo, {"src/hot.ts": nested(4)})
    run_repo(repo, capsys)
    findings = {"verdict": "One hotspot.", "targets": [
        {"path": "src/hot.ts", "issues": ["Deep nesting"], "fix": "Guard clauses"},
        {"path": "src/missing.ts", "issues": ["?"], "fix": "?"},
    ]}
    (repo / ".code-health" / "repo" / "findings.json").write_text(json.dumps(findings))

    result = build(repo)

    html = (repo / ".code-health" / "repo" / "report.html").read_text()
    assert [t["path"] for t in page_json(html, "FINDINGS")["targets"]] == ["src/hot.ts"]
    assert "1 target left out" in result.stdout


def test_script_closing_tags_in_data_are_escaped(repo, capsys):
    commit(repo, {"src/hot.ts": nested(4)})
    run_repo(repo, capsys)
    (repo / ".code-health" / "repo" / "findings.json").write_text(json.dumps({"verdict": "</script><b>x</b>"}))

    build(repo)

    html = (repo / ".code-health" / "repo" / "report.html").read_text()
    assert "</script><b>" not in html
    assert page_json(html, "FINDINGS")["verdict"] == "</script><b>x</b>"


def test_missing_data_is_a_clear_error(tmp_path):
    result = subprocess.run(
        [sys.executable, str(BUILD_REPORT), str(tmp_path)], capture_output=True, text=True, check=False
    )

    assert result.returncode != 0
    assert "run code-health repo first" in result.stderr


def test_page_declares_utf8(repo, capsys):
    commit(repo, {"src/hot.ts": nested(4)})
    run_repo(repo, capsys)

    build(repo)

    assert (repo / ".code-health" / "repo" / "report.html").read_text().startswith('<meta charset="utf-8">')
