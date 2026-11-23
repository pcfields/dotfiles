import json
from datetime import UTC, datetime, timedelta

import pytest
from gitrepo import CLEAN, commit, nested, write

from code_health.cli import main
from code_health.episodes import GLOBAL_KEYS
from code_health.history import machine_name

pytestmark = pytest.mark.usefixtures("state")


def transcript(tmp_path, *offsets_and_outputs):
    now = datetime.now(UTC)
    lines = [
        json.dumps({
            "type": "assistant",
            "timestamp": (now + timedelta(seconds=offset)).isoformat(),
            "message": {"id": f"msg_{i}", "model": "claude-opus-5-5",
                        "usage": {"input_tokens": 1, "output_tokens": output,
                                  "cache_creation_input_tokens": 0, "cache_read_input_tokens": 0}},
        })
        for i, (offset, output) in enumerate(offsets_and_outputs)
    ]
    path = tmp_path / "transcript.jsonl"
    path.write_text("\n".join(lines) + "\n")
    return str(path)


@pytest.fixture
def global_dir(tmp_path, monkeypatch):
    folder = tmp_path / "history"
    monkeypatch.setenv("CODE_HEALTH_HISTORY_DIR", str(folder))
    return folder


def episode(capsys, *args):
    code = main(["episode", *args])
    out, err = capsys.readouterr()
    return code, out, err


def global_records(folder, kind=None):
    files = sorted(folder.glob("episodes*.jsonl"))
    assert [f.name for f in files] in ([], [f"episodes-{machine_name()}.jsonl"])
    records = [json.loads(line) for f in files for line in f.read_text().splitlines()]
    return [r for r in records if (r["kind"] != "change" if kind is None else r["kind"] == kind)]


def records(path):
    return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []


def uplift(repo, capsys, *end_args, during=lambda: None):
    commit(repo, {"src/app.ts": nested(5)})
    assert episode(capsys, "start", "--kind", "uplift", "--session", "s1", "src/app.ts")[0] == 0
    result = during()
    write(repo, "src/app.ts", CLEAN)
    assert episode(capsys, "end", "--kind", "uplift", "--session", "s1", *end_args)[0] == 0
    return result


def test_flush_writes_the_local_and_global_records(repo, global_dir, tmp_path, capsys):
    path = uplift(
        repo, capsys, "--tests-passed", "yes", during=lambda: transcript(tmp_path, (-600, 999), (0, 40), (0, 2), (600, 7))
    )

    code, _, _ = episode(capsys, "flush", "--session", "s1", "--transcript", path)

    (local,) = records(repo / ".code-health" / "episodes.jsonl")
    (generic,) = global_records(global_dir)
    assert code == 0
    assert set(generic) == GLOBAL_KEYS
    assert (generic["score_before"], generic["score_after"], generic["tests_passed"]) == (7.9, 10.0, True)
    assert (generic["token_method"], generic["harness"], generic["model"]) == (
        "claude-transcript-window", "claude-code", "claude-opus-5-5",
    )
    assert generic["tokens"]["output"] == 42
    assert "src/app.ts" not in json.dumps(generic)
    assert (local["files"], local["session"], local["tokens"]) == (["src/app.ts"], "s1", generic["tokens"])
    assert json.loads((repo / ".code-health" / "pending.json").read_text()) == []


def test_episode_from_another_session_is_partial(repo, global_dir, tmp_path, capsys):
    path = uplift(repo, capsys, during=lambda: transcript(tmp_path, (0, 5)))

    episode(capsys, "flush", "--session", "s2", "--transcript", path)

    assert global_records(global_dir)[0]["token_method"] == "partial"


def test_flush_without_a_transcript_records_no_tokens(repo, global_dir, capsys):
    uplift(repo, capsys)

    episode(capsys, "flush")

    (generic,) = global_records(global_dir)
    assert (generic["token_method"], generic["harness"], generic["model"]) == ("none", "unknown", None)


def test_without_a_history_dir_the_global_record_is_skipped_with_one_note(repo, capsys, monkeypatch):
    monkeypatch.delenv("CODE_HEALTH_HISTORY_DIR", raising=False)
    uplift(repo, capsys)

    _, _, first = episode(capsys, "flush")
    commit(repo, {"src/app.ts": CLEAN})
    uplift(repo, capsys)
    _, _, second = episode(capsys, "flush")

    assert "CODE_HEALTH_HISTORY_DIR" in first
    assert second == ""
    assert len(records(repo / ".code-health" / "episodes.jsonl")) == 2


def test_open_episodes_are_not_flushed(repo, global_dir, capsys):
    commit(repo, {"src/app.ts": nested(5)})
    episode(capsys, "start", "--kind", "uplift", "--session", "s1", "src/app.ts")

    episode(capsys, "flush")

    assert global_records(global_dir) == []
    assert len(json.loads((repo / ".code-health" / "pending.json").read_text())) == 1


def test_end_without_an_open_episode_is_harmless(repo, capsys):
    commit(repo, {"src/app.ts": CLEAN})

    assert episode(capsys, "end", "--kind", "uplift", "--session", "s1")[0] == 0


def test_state_folder_is_kept_out_of_git(repo, capsys):
    commit(repo, {"src/app.ts": nested(5)})

    episode(capsys, "start", "--kind", "uplift", "--session", "s1", "src/app.ts")

    assert "/.code-health/" in (repo / ".git" / "info" / "exclude").read_text().splitlines()


def safeguard_episode(capsys, *args):
    code = main(["safeguard", "--since-turn", "--session", "s1", "--episode", *args])
    capsys.readouterr()
    return code


def test_safeguard_fix_episode_runs_from_failure_to_pass(repo, global_dir, tmp_path, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    main(["mark-turn", "--session", "s1"])
    write(repo, "src/app.ts", nested(5))
    assert safeguard_episode(capsys) == 2
    path = transcript(tmp_path, (0, 30))
    write(repo, "src/app.ts", CLEAN)

    assert safeguard_episode(capsys, "--transcript", path) == 0

    (generic,) = global_records(global_dir)
    assert (generic["kind"], generic["iterations"], generic["score_before"], generic["score_after"]) == (
        "safeguard-fix", 2, 7.9, 10.0,
    )
    assert (generic["tokens"]["output"], generic["token_method"]) == (30, "claude-transcript-window")


def test_passing_safeguard_without_an_episode_records_nothing(repo, global_dir, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", CLEAN.replace("a;", "a + 1;"))

    assert safeguard_episode(capsys) == 0
    assert global_records(global_dir) == []


def test_further_failures_count_as_iterations(repo, global_dir, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(5))
    safeguard_episode(capsys)
    safeguard_episode(capsys)
    write(repo, "src/app.ts", CLEAN)
    safeguard_episode(capsys)

    assert global_records(global_dir)[0]["iterations"] == 3


def test_episode_errors_never_change_the_safeguard_verdict(repo, tmp_path, capsys):
    commit(repo, {"src/app.ts": CLEAN})
    write(repo, "src/app.ts", nested(5))

    code = main(["safeguard", "--session", "s1", "--episode", "--transcript", str(tmp_path / "gone.jsonl")])
    _, err = capsys.readouterr()

    assert code == 2
    assert "episode not recorded" in err


def test_each_turn_that_changes_scored_files_is_recorded(repo, global_dir, tmp_path, capsys):
    commit(repo, {"src/app.ts": CLEAN, "README.md": "hi\n"})
    main(["mark-turn", "--session", "s1"])
    path = transcript(tmp_path, (0, 25))
    write(repo, "src/app.ts", nested(5))

    safeguard_episode(capsys, "--transcript", path)

    (change,) = global_records(global_dir, kind="change")
    assert set(change) == GLOBAL_KEYS
    assert (change["score_before"], change["score_after"], change["language"]) == (10.0, 7.9, "typescript")
    assert change["findings_after"] == {"Deep Nested Complexity": 1}
    assert (change["tokens"]["output"], change["token_method"]) == (25, "claude-transcript-window")


def test_turns_without_scored_changes_are_not_recorded(repo, global_dir, capsys):
    commit(repo, {"src/app.ts": CLEAN, "README.md": "hi\n"})
    main(["mark-turn", "--session", "s1"])
    write(repo, "README.md", "changed\n")

    safeguard_episode(capsys)

    assert global_records(global_dir, kind="change") == []
