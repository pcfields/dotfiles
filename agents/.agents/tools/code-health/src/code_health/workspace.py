from pathlib import Path

from code_health import gitio
from code_health.config import CONFIG_FILE, DEFAULT_CONFIG, Config, parse_config


class ToolError(Exception):
    pass


def optional_repo_root(cwd: Path) -> Path | None:
    try:
        return gitio.repo_root(cwd)
    except gitio.GitError:
        return None


def working_config(root: Path | None) -> Config:
    if root is None or not (root / CONFIG_FILE).is_file():
        return DEFAULT_CONFIG
    return parse_config((root / CONFIG_FILE).read_text(encoding="utf-8"))


def repo_relative(root: Path | None, path: str) -> str:
    if root is None:
        return path
    try:
        return Path(path).resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return path


def read_source(path: Path) -> bytes:
    try:
        return path.read_bytes()
    except OSError as error:
        raise ToolError(f"cannot read {error.filename}: {error.strerror}") from error
