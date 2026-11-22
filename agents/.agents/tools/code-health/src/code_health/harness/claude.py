import json
from collections import Counter
from collections.abc import Iterable
from dataclasses import dataclass
from datetime import datetime

HARNESS = "claude-code"


@dataclass(frozen=True)
class TokenCount:
    input: int
    output: int
    cache_creation: int
    cache_read: int
    model: str | None


def count_tokens(lines: Iterable[str], start: datetime, end: datetime) -> TokenCount:
    seen: dict[str, tuple[dict, str | None]] = {}
    for message in _assistant_messages(lines):
        when = _timestamp(message)
        if when is None or not start <= when <= end:
            continue
        inner = message.get("message", {})
        seen.setdefault(inner.get("id") or f"line-{len(seen)}", (inner.get("usage") or {}, inner.get("model")))
    usages = [usage for usage, _ in seen.values()]
    models = Counter(model for _, model in seen.values() if model)
    return TokenCount(
        input=sum(u.get("input_tokens", 0) for u in usages),
        output=sum(u.get("output_tokens", 0) for u in usages),
        cache_creation=sum(u.get("cache_creation_input_tokens", 0) for u in usages),
        cache_read=sum(u.get("cache_read_input_tokens", 0) for u in usages),
        model=models.most_common(1)[0][0] if models else None,
    )


def _assistant_messages(lines: Iterable[str]):
    for line in lines:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(entry, dict) and entry.get("type") == "assistant":
            yield entry


def _timestamp(entry: dict) -> datetime | None:
    try:
        return datetime.fromisoformat(entry["timestamp"])
    except (KeyError, TypeError, ValueError):
        return None
