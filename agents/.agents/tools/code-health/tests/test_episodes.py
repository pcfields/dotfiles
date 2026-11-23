from datetime import UTC, datetime

import pytest

from code_health.episodes import (
    GLOBAL_KEYS,
    Step,
    end_episode,
    generic_record,
    loc_band,
    start_episode,
    tick,
)
from code_health.harness.claude import TokenCount

T0 = datetime(2026, 11, 20, 10, 0, tzinfo=UTC)
T1 = datetime(2026, 11, 20, 10, 14, tzinfo=UTC)


BASE_STATE = {
    "path": "src/payment.ts",
    "language": "typescript",
    "score": 4.1,
    "loc": 45,
    "functions": 1,
    "findings": {"Complex Method": 1, "Deep Nested Complexity": 1},
}


def state(path="src/payment.ts", **overrides):
    return {**BASE_STATE, "path": path, **overrides}


def started(kind="safeguard-fix", session="s1"):
    return start_episode([], Step(kind, session, [state()], T0))


def test_start_opens_one_episode_with_one_iteration():
    (episode,) = started()

    assert (episode["kind"], episode["session"], episode["iterations"], episode["ended"]) == (
        "safeguard-fix", "s1", 1, None,
    )
    assert episode["files"] == ["src/payment.ts"]


def test_starting_again_keeps_the_open_episode_and_adds_new_files():
    pending = start_episode(started(), Step("safeguard-fix", "s1", [state("src/b.ts")], T1))

    assert len(pending) == 1
    assert pending[0]["files"] == ["src/payment.ts", "src/b.ts"]
    assert pending[0]["started"] == T0.isoformat()


def test_other_sessions_and_kinds_get_their_own_episodes():
    pending = start_episode(started(), Step("uplift", "s1", [state()], T1))
    pending = start_episode(pending, Step("safeguard-fix", "s2", [state()], T1))

    assert [(e["kind"], e["session"]) for e in pending] == [("safeguard-fix", "s1"), ("uplift", "s1"), ("safeguard-fix", "s2")]


def test_tick_counts_turns_of_open_episodes_in_the_session():
    pending = tick(tick(started(), session="s1"), session="other")

    assert pending[0]["iterations"] == 2


def test_end_records_the_after_state_and_time():
    pending = end_episode(started(), Step("safeguard-fix", "s1", [state(score=10.0, findings={})], T1))

    assert pending[0]["ended"] == T1.isoformat()
    assert pending[0]["after"][0]["score"] == 10.0
    assert tick(pending, session="s1")[0]["iterations"] == 1


def test_end_without_an_open_episode_changes_nothing():
    assert end_episode([], Step("uplift", "s1", [], T1)) == []


def ended_episode(**kwargs):
    pending = start_episode([], Step("safeguard-fix", "s1", [state(), state("src/b.ts", score=9.0, loc=155, findings={"Complex Method": 1})], T0))
    pending = tick(pending, session="s1")
    return end_episode(pending, Step("safeguard-fix", "s1", [state(score=10.0, findings={}, functions=3), state("src/b.ts", score=10.0, loc=150, findings={})], T1, **kwargs))[0]


def test_generic_record_has_only_the_allowlisted_keys_and_no_names():
    tokens = TokenCount(input=16, output=177, cache_creation=200, cache_read=7100, model="claude-opus-5-5")

    record = generic_record(ended_episode(tests_passed=True), tokens, token_method="claude-transcript-window", harness="claude-code")

    assert set(record) == GLOBAL_KEYS
    text = repr(record)
    assert "payment" not in text and "src/" not in text and ".ts" not in text and "s1" not in text
    assert record == {
        "date": "2026-11-20",
        "scorer_version": "2",
        "kind": "safeguard-fix",
        "language": "typescript",
        "loc_band": "100-500",
        "functions": 4,
        "score_before": 7.9,
        "score_after": 10.0,
        "findings_before": {"Complex Method": 2, "Deep Nested Complexity": 1},
        "findings_after": {},
        "iterations": 2,
        "duration_s": 840,
        "tests_passed": True,
        "tokens": {"input": 16, "output": 177, "cache_creation": 200, "cache_read": 7100},
        "token_method": "claude-transcript-window",
        "model": "claude-opus-5-5",
        "harness": "claude-code",
    }


def test_generic_record_without_tokens():
    record = generic_record(ended_episode(), None, token_method="none", harness="unknown")

    assert (record["tokens"], record["model"], record["tests_passed"]) == (
        {"input": 0, "output": 0, "cache_creation": 0, "cache_read": 0}, None, None,
    )


@pytest.mark.parametrize(
    ("loc", "band"),
    [(0, "<100"), (99, "<100"), (100, "100-500"), (499, "100-500"), (500, "500-1000"), (1999, "1000-2000"), (2000, "2000+")],
)
def test_loc_band(loc, band):
    assert loc_band(loc) == band
