import json
import subprocess

import pytest
from gitrepo import CLEAN, nested, write

from code_health.cli import main


def commit_as(root, author: str, files: dict[str, str | bytes], date: str = "2026-11-01T12:00:00"):
    for path, content in files.items():
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            target.write_bytes(content)
        else:
            target.write_text(content)
    env = {"GIT_AUTHOR_DATE": date, "GIT_COMMITTER_DATE": date}
    subprocess.run(["git", "add", "-A"], cwd=root, check=True)
    subprocess.run(
        ["git", "-c", f"user.name={author}", "-c", "user.email=x@example.com", "-c", "commit.gpgsign=false",
         "commit", "-q", "-m", "change"],
        cwd=root, check=True, env={**__import__("os").environ, **env},
    )


@pytest.fixture
def history(repo):
    commit_as(repo, "Ana", {
        "src/hot.ts": nested(4), "src/calm.ts": CLEAN, "src/cold.ts": nested(6),
        "db/schema.sql": "select 1;\n", "README.md": "# hi\n", "logo.png": b"\x89PNG\x00\x01",
        "gen/client.ts": nested(5), "src/broken.ts": "function f( {\n",
        ".code-health.toml": 'exclude = ["gen/**"]\n',
    }, date="2026-01-01T12:00:00")
    for i in range(3):
        author = "Ben" if i == 1 else "Ana"
        commit_as(repo, author, {
            "src/hot.ts": nested(4).replace("return 0;", f"return {i + 10};"),
            "src/calm.ts": CLEAN.replace("a;", f"a + {i};"),
        })
    return repo


def repo_json(capsys, *args):
    code = main(["repo", "--json", *args])
    out, _ = capsys.readouterr()
    return code, json.loads(out)


def test_overview(history, capsys):
    code, report = repo_json(capsys)

    assert code == 0
    assert (report["commits"], report["authors"]) == (4, 2)
    overview = report["overview"]
    assert (overview["files_scored"], overview["bands"]) == (3, {"green": 1, "yellow": 2, "red": 0})
    assert overview["worst_file"] == {"path": "src/cold.ts", "score": 7.3}


def test_rankings(history, capsys):
    _, report = repo_json(capsys)

    assert [f["path"] for f in report["refactor_first"]] == ["src/hot.ts", "src/cold.ts"]
    assert report["refactor_first"][0] == {
        "path": "src/hot.ts", "score": 8.5, "band": "yellow", "commits": 4, "authors": 2,
        "smells": ["Deep Nested Complexity"],
    }
    assert [f["path"] for f in report["change_frequency"]][:2] == ["src/calm.ts", "src/hot.ts"]
    assert [f["path"] for f in report["healthy_but_busy"]] == ["src/calm.ts"]
    assert report["coupling"] == [{"shared": 4, "degree": 100, "a": "src/calm.ts", "b": "src/hot.ts"}]
    assert report["author_density"] == [
        {"path": "src/calm.ts", "authors": 2, "commits": 4},
        {"path": "src/hot.ts", "authors": 2, "commits": 4},
    ]


def test_not_scored_files_are_summarised(history, capsys):
    _, report = repo_json(capsys)

    assert report["not_scored"] == [
        {"kind": ".sql", "reason": "unsupported language", "count": 1},
        {"kind": ".ts", "reason": "excluded", "count": 1},
        {"kind": ".ts", "reason": "parse errors", "count": 1},
    ]


def test_since_drops_older_commits(history, capsys):
    _, report = repo_json(capsys, "--since", "2026-06-01")

    assert report["commits"] == 3
    assert [f["path"] for f in report["refactor_first"]] == ["src/hot.ts"]


def test_path_limits_the_files(history, capsys):
    write(history, "lib/other.ts", nested(5))

    _, report = repo_json(capsys, "src")

    assert report["path"] == "src"
    assert report["overview"]["files_scored"] == 3


def test_top_limits_the_rows(history, capsys):
    _, report = repo_json(capsys, "--top", "1")

    assert len(report["refactor_first"]) == 1


def test_text_output_has_every_section(history, capsys):
    code = main(["repo"])
    out, _ = capsys.readouterr()

    headings = [line for line in out.splitlines() if line.startswith("## ")]
    assert code == 0
    assert headings == [
        "## Overview",
        "## Refactor first (commits x (10 - score))",
        "## Change frequency",
        "## Healthy but busy",
        "## Change coupling",
        "## Author density",
        "## Least healthy files",
        "## Worst findings",
        "## Not scored",
        "## Trend (same path and scorer version)",
    ]
    assert "worst file: src/cold.ts 7.3" in out


SNAPSHOT_KEYS = {
    "date", "commit", "branch", "path", "since", "scorer_version", "files_scored", "files_not_scored",
    "average_health", "hotspot_health", "worst_file", "worst_score", "scores",
}


def snapshots(repo):
    path = repo / ".code-health" / "snapshots.jsonl"
    return [json.loads(line) for line in path.read_text().splitlines()]


def test_each_run_appends_a_snapshot(history, capsys):
    repo_json(capsys)
    commit_as(history, "Ana", {"src/cold.ts": CLEAN})
    _, report = repo_json(capsys)

    first, second = snapshots(history)
    assert set(first) == SNAPSHOT_KEYS
    assert (first["worst_file"], first["worst_score"]) == ("src/cold.ts", 7.3)
    assert first["scores"]["src/hot.ts"] == 8.5
    assert second["scores"]["src/cold.ts"] == 10.0
    assert [t["commit"] for t in report["trend"]] == [first["commit"], second["commit"]]


def test_trend_only_compares_runs_of_the_same_path(history, capsys):
    repo_json(capsys)
    _, report = repo_json(capsys, "src")

    assert len(report["trend"]) == 1
    assert len(snapshots(history)) == 2


def test_state_folder_is_excluded_from_git_once(history, capsys):
    repo_json(capsys)
    repo_json(capsys)

    exclude = (history / ".git" / "info" / "exclude").read_text().splitlines()
    status = subprocess.run(
        ["git", "status", "--porcelain"], cwd=history, capture_output=True, text=True, check=True
    ).stdout
    assert exclude.count("/.code-health/") == 1
    assert ".code-health" not in status


def test_report_data_is_saved_for_the_page(history, capsys):
    repo_json(capsys)

    data = json.loads((history / ".code-health" / "repo" / "data.json").read_text())
    assert set(data) == {"meta", "report", "files", "coupling", "functions", "snapshots"}
    hot = next(f for f in data["files"] if f["path"] == "src/hot.ts")
    assert (hot["score"], hot["commits"], hot["findings"][0]["smell"]) == (8.5, 4, "Deep Nested Complexity")
    assert data["functions"][0]["cyclomatic"] >= data["functions"][-1]["cyclomatic"]
