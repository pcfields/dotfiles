import json
from dataclasses import asdict
from pathlib import Path

from code_health.repo import MAX_COMMIT_FILES, MIN_SHARED_COMMITS, Coupling, RepoFile

STATE_DIR = ".code-health"
TREND_LENGTH = 12
TOP_FUNCTIONS = 12


def snapshot(report: dict, files: list[RepoFile], run: dict) -> dict:
    overview = report["overview"]
    worst = overview["worst_file"] or {}
    return {
        "date": run["date"],
        "commit": run["commit"],
        "branch": run["branch"],
        "path": report["path"],
        "since": report["since"],
        "scorer_version": report["scorer_version"],
        "files_scored": overview["files_scored"],
        "files_not_scored": overview["files_not_scored"],
        "average_health": overview["average_health"],
        "hotspot_health": overview["hotspot_health"],
        "worst_file": worst.get("path"),
        "worst_score": worst.get("score"),
        "scores": {f.path: f.score for f in files},
    }


def trend(snapshots: list[dict], path: str, scorer_version: str) -> list[dict]:
    same = [s for s in snapshots if s.get("path") == path and s.get("scorer_version") == scorer_version]
    keys = ("date", "commit", "average_health", "hotspot_health", "worst_file", "worst_score")
    return [{key: s.get(key) for key in keys} for s in same[-TREND_LENGTH:]]


def page_data(report: dict, files: list[RepoFile], couplings: list[Coupling], run: dict) -> dict:
    functions = sorted(
        ({"path": f.path, "name": name, "line": line, "cyclomatic": cc, "loc": loc} for f in files
         for name, line, cc, loc in f.functions),
        key=lambda fn: (-fn["cyclomatic"], -fn["loc"], fn["path"]),
    )
    return {
        "meta": {
            **run,
            "since": report["since"],
            "path": report["path"],
            "scorer_version": report["scorer_version"],
            "max_commit_files": MAX_COMMIT_FILES,
            "min_shared_commits": MIN_SHARED_COMMITS,
        },
        "report": report,
        "files": [_file_data(f) for f in files],
        "coupling": [asdict(c) for c in couplings],
        "functions": functions[:TOP_FUNCTIONS],
        "snapshots": report.get("trend", []),
    }


def read_snapshots(root: Path) -> list[dict]:
    try:
        lines = (root / STATE_DIR / "snapshots.jsonl").read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    return [json.loads(line) for line in lines if line.strip()]


def save_run(root: Path, entry: dict, data: dict) -> None:
    folder = root / STATE_DIR
    (folder / "repo").mkdir(parents=True, exist_ok=True)
    with (folder / "snapshots.jsonl").open("a", encoding="utf-8") as file:
        file.write(json.dumps(entry) + "\n")
    (folder / "repo" / "data.json").write_text(json.dumps(data), encoding="utf-8")


def _file_data(f: RepoFile) -> dict:
    return {
        "path": f.path,
        "score": f.score,
        "band": f.band,
        "loc": f.loc,
        "commits": f.commits,
        "authors": f.authors,
        "findings": [asdict(finding) for finding in f.findings],
    }
