from datetime import UTC, datetime
from pathlib import Path

from code_health.harness.claude import TokenCount, count_tokens

TRANSCRIPT = (Path(__file__).parent / "fixtures" / "claude" / "transcript.jsonl").read_text().splitlines()
START = datetime(2026, 11, 20, 10, 0, 0, tzinfo=UTC)
END = datetime(2026, 11, 20, 10, 5, 0, tzinfo=UTC)


def test_counts_each_message_once_inside_the_window():
    assert count_tokens(TRANSCRIPT, START, END) == TokenCount(
        input=16, output=177, cache_creation=200, cache_read=7100, model="claude-opus-5-5"
    )


def test_window_with_no_messages_counts_nothing():
    early = datetime(2026, 1, 1, tzinfo=UTC)

    assert count_tokens(TRANSCRIPT, early, early) == TokenCount(0, 0, 0, 0, None)


def test_window_edges_are_inclusive():
    exact = datetime(2026, 11, 20, 10, 1, 0, tzinfo=UTC)

    assert count_tokens(TRANSCRIPT, exact, exact).output == 50
