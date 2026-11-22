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
    return head_commit(root) or EMPTY_TREE


def head_commit(root: Path) -> str | None:
    try:
        return _git(root, "rev-parse", "--verify", "--quiet", "HEAD").decode().strip()
    except GitError:
        return None


def changed_files(root: Path, base: str) -> list[ChangedFile]:
    tracked = _parse_name_status(_git(root, "diff", "--name-status", "-M", "-z", base, "--"))
    untracked = _git(root, "ls-files", "--others", "--exclude-standard", "-z").decode().split("\0")
    return tracked + [ChangedFile(path, None) for path in untracked if path]


def source_files(root: Path, pathspec: str) -> list[str]:
    output = _git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--", pathspec or ".")
    return sorted({path for path in output.decode().split("\0") if path})


def change_log(root: Path, since: str, pathspec: str) -> str:
    output = _git(
        root, "log", f"--since={since}", "--no-merges", "--format=%x01%an", "--name-only", "--", pathspec or "."
    )
    return output.decode(errors="replace")


def current_branch(root: Path) -> str:
    return _git(root, "branch", "--show-current").decode().strip()


def ensure_excluded(root: Path, line: str) -> None:
    exclude = root / _git(root, "rev-parse", "--git-path", "info/exclude").decode().strip()
    existing = exclude.read_text(encoding="utf-8").splitlines() if exclude.is_file() else []
    if line in existing:
        return
    exclude.parent.mkdir(parents=True, exist_ok=True)
    with exclude.open("a", encoding="utf-8") as file:
        if existing and existing[-1] != "":
            file.write("\n")
        file.write(line + "\n")


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
