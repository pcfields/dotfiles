import hashlib
import json
import os
import re
import sys
from collections.abc import Mapping
from pathlib import Path


def state_dir(env: Mapping[str, str] | None = None, platform: str | None = None, home: Path | None = None) -> Path:
    env = os.environ if env is None else env
    platform = sys.platform if platform is None else platform
    home = Path.home() if home is None else home
    if override := env.get("CODE_HEALTH_STATE_DIR"):
        return Path(override)
    if platform == "win32":
        base = env.get("LOCALAPPDATA") or str(home / "AppData" / "Local")
        return Path(base) / "code-health"
    base = env.get("XDG_STATE_HOME") or str(home / ".local" / "state")
    return Path(base) / "code-health"


def repo_key(root: str | Path, platform: str | None = None) -> str:
    platform = sys.platform if platform is None else platform
    text = str(root)
    if platform == "win32":
        text = text.replace("\\", "/").lower()
    return hashlib.sha256(text.encode()).hexdigest()[:16]


def read_turn_base(root: Path, session: str) -> str | None:
    try:
        return _turn_file(root, session).read_text().strip() or None
    except OSError:
        return None


def write_turn_base(root: Path, session: str, commit: str) -> None:
    path = _turn_file(root, session)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(commit + "\n")


def _turn_file(root: Path, session: str) -> Path:
    safe_session = re.sub(r"[^A-Za-z0-9_.-]", "_", session) or "default"
    return state_dir() / repo_key(root) / "turns" / f"{safe_session}.base"


def read_accepted(root: Path) -> list[dict]:
    try:
        lines = _accepted_file(root).read_text(encoding="utf-8").splitlines()
    except OSError:
        return []
    records = []
    for line in lines:
        try:
            records.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return records


def append_accepted(root: Path, record: dict) -> Path:
    path = _accepted_file(root)
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as file:
        file.write(json.dumps(record) + "\n")
    return path


def _accepted_file(root: Path) -> Path:
    return state_dir() / repo_key(root) / "accepted.jsonl"
