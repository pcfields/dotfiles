import argparse
import datetime
from dataclasses import replace
from pathlib import Path

from code_health import gitio, history
from code_health.config import Config, is_excluded
from code_health.repo import (
    RepoFile,
    RepoInput,
    build_report,
    churn,
    coupling,
    is_binary,
    is_prose_or_data,
    parse_log,
)
from code_health.report import review_source
from code_health.workspace import repo_relative, working_config


def repo_report(cwd: Path, args: argparse.Namespace) -> dict:
    root = gitio.repo_root(cwd)
    pathspec = repo_relative(root, args.path)
    pathspec = "" if pathspec == "." else pathspec
    config = working_config(root)
    files, not_scored = [], []
    for path in gitio.source_files(root, pathspec):
        scored = _score_repo_file(root, path, config)
        if isinstance(scored, RepoFile):
            files.append(scored)
        elif scored:
            not_scored.append((path, scored))
    commits = parse_log(gitio.change_log(root, args.since, pathspec))
    changes = churn(commits, {f.path for f in files})
    files = [replace(f, commits=changes.get(f.path, (0, 0))[0], authors=changes.get(f.path, (0, 0))[1]) for f in files]
    report = build_report(RepoInput(args.since, pathspec or ".", commits, files, not_scored, args.top))
    return _save_run(root, report, files, coupling(commits, {f.path for f in files}))


def _save_run(root: Path, report: dict, files: list[RepoFile], couplings) -> dict:
    run = {
        "repo": root.name,
        "date": datetime.date.today().isoformat(),
        "commit": gitio.head_commit(root) or "",
        "branch": gitio.current_branch(root),
    }
    entry = history.snapshot(report, files, run)
    previous = history.read_snapshots(root)
    report = {**report, "trend": history.trend([*previous, entry], report["path"], report["scorer_version"])}
    gitio.ensure_excluded(root, f"/{history.STATE_DIR}/")
    history.save_run(root, entry, history.page_data(report, files, couplings, run))
    return report


def _score_repo_file(root: Path, path: str, config: Config) -> RepoFile | str | None:
    if is_prose_or_data(path):
        return None
    try:
        source = (root / path).read_bytes()
    except OSError:
        return None
    if is_binary(source):
        return None
    if is_excluded(config, path):
        return "excluded"
    report = review_source(path, source, config)
    if report.score is None:
        return report.reason
    functions = tuple((f.name, f.line, f.cyclomatic, f.loc) for f in report.metrics.functions)
    return RepoFile(path, report.score, report.band, report.metrics.loc, findings=report.findings, functions=functions)
