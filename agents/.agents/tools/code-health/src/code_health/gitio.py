import subprocess
from dataclasses import dataclass
from pathlib import Path

EMPTY_TREE = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
_GIT = ["git", "-c", "core.quotePath=false", "-c", "submodule.recurse=false"]


class GitError(Exception):
    pass


@dataclass(frozen=True)
class ChangedFile:
    path: str
    base_path: str | None


def repo_root(cwd: Path) -> Path:
    return Path(_git(cwd, "rev-parse", "--show-toplevel").decode().strip())


def base_commit(root: Path, base: str | None) -> str:
    if base is not None:
        return _git(root, "merge-base", base, "HEAD").decode().strip()
    try:
        return _git(root, "rev-parse", "--verify", "--quiet", "HEAD").decode().strip()
    except GitError:
        return EMPTY_TREE


def changed_files(root: Path, base: str) -> list[ChangedFile]:
    tracked = _parse_name_status(_git(root, "diff", "--name-status", "-M", "-z", base, "--"))
    untracked = _git(root, "ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")
    return tracked + [ChangedFile(path, None) for path in untracked if path]


def read_at(root: Path, ref: str, path: str) -> bytes:
    return _git(root, "show", f"{ref}:{path}")


def _parse_name_status(output: bytes) -> list[ChangedFile]:
    fields = output.decode().split("\0")
    changes = []
    i = 0
    while i < len(fields) - 1:
        status = fields[i]
        if status[0] in "RC":
            changes.append(ChangedFile(fields[i + 2], fields[i + 1]))
            i += 3
            continue
        if status[0] == "A":
            changes.append(ChangedFile(fields[i + 1], None))
        elif status[0] != "D":
            changes.append(ChangedFile(fields[i + 1], fields[i + 1]))
        i += 2
    return changes


def _git(cwd: Path, *args: str) -> bytes:
    try:
        result = subprocess.run([*_GIT, *args], cwd=cwd, capture_output=True, check=False)
    except OSError as error:
        raise GitError(f"cannot run git: {error}") from error
    if result.returncode != 0:
        raise GitError(result.stderr.decode(errors="replace").strip() or f"git {args[0]} failed")
    return result.stdout
