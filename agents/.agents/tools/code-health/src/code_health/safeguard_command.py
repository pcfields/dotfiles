from pathlib import Path

from code_health import gitio, state
from code_health.config import CONFIG_FILE, is_excluded, parse_config
from code_health.safeguard import CheckContext, FileCheck, check_file, is_checked
from code_health.workspace import read_source


def safeguard_checks(
    cwd: Path, base: str | None, turn_session: str | None
) -> tuple[list[FileCheck], tuple[str, ...]]:
    root = gitio.repo_root(cwd)
    commit = _turn_base(root, turn_session) if turn_session else gitio.base_commit(root, base)
    base_text = _config_at(root, commit)
    config = parse_config(base_text)
    context = CheckContext(config, tuple(state.read_accepted(root)))
    checks = []
    for change in gitio.changed_files(root, commit):
        if not is_checked(change.path) or is_excluded(config, change.path):
            continue
        after = read_source(root / change.path)
        before = gitio.read_at(root, commit, change.base_path) if change.base_path else None
        checks.append(check_file(change.path, before, after, context))
    return checks, _config_notes(root, base_text)


def _config_at(root: Path, commit: str) -> str | None:
    try:
        return gitio.read_at(root, commit, CONFIG_FILE).decode("utf-8")
    except gitio.GitError:
        return None


def _same_text(a: str | None, b: str | None) -> bool:
    if a is None or b is None:
        return a is b
    return a.replace("\r\n", "\n") == b.replace("\r\n", "\n")


def _config_notes(root: Path, base_text: str | None) -> tuple[str, ...]:
    path = root / CONFIG_FILE
    working = path.read_bytes().decode("utf-8") if path.is_file() else None
    if _same_text(working, base_text):
        return ()
    return (f"{CONFIG_FILE} changed; it takes effect once committed",)


def _turn_base(root: Path, session: str) -> str:
    recorded = state.read_turn_base(root, session)
    if recorded:
        try:
            return gitio.base_commit(root, recorded)
        except gitio.GitError:
            pass
    return gitio.base_commit(root, None)
