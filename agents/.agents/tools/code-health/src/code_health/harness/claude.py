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
    messages = _messages_in_window(lines, start, end)
    usages = [usage for usage, _ in messages]
    models = Counter(model for _, model in messages if model)
    return TokenCount(
        input=_total(usages, "input_tokens"),
        output=_total(usages, "output_tokens"),
        cache_creation=_total(usages, "cache_creation_input_tokens"),
        cache_read=_total(usages, "cache_read_input_tokens"),
        model=models.most_common(1)[0][0] if models else None,
    )


def _messages_in_window(lines: Iterable[str], start: datetime, end: datetime) -> list[tuple[dict, str | None]]:
    seen: dict[str, tuple[dict, str | None]] = {}
    for message in _assistant_messages(lines):
        when = _timestamp(message)
        if when is not None and start <= when <= end:
            inner = message.get("message", {})
            seen.setdefault(inner.get("id") or f"line-{len(seen)}", (inner.get("usage") or {}, inner.get("model")))
    return list(seen.values())


def _total(usages: list[dict], field: str) -> int:
    return sum(usage.get(field, 0) for usage in usages)


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
