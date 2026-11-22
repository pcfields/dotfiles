from code_health.repo import Commit, Coupling, churn, coupling, parse_log

LOG = "\x01Ana\na.ts\nb.ts\n\n\x01Ben\na.ts\nold.ts\n\n\x01Ana\nb.ts\na.ts\n\n\x01Ana\na.ts\nb.ts\nc.ts\n"


def test_parse_log_reads_authors_and_files():
    assert parse_log(LOG) == [
        Commit("Ana", ("a.ts", "b.ts")),
        Commit("Ben", ("a.ts", "old.ts")),
        Commit("Ana", ("b.ts", "a.ts")),
        Commit("Ana", ("a.ts", "b.ts", "c.ts")),
    ]


def test_parse_log_of_nothing():
    assert parse_log("") == []


def test_churn_counts_commits_and_distinct_authors_of_current_files():
    assert churn(parse_log(LOG), {"a.ts", "b.ts", "c.ts"}) == {
        "a.ts": (4, 2),
        "b.ts": (3, 1),
        "c.ts": (1, 1),
    }


def test_coupling_keeps_pairs_with_enough_shared_commits():
    commits = parse_log(LOG)

    assert coupling(commits, {"a.ts", "b.ts", "c.ts"}, min_shared=3) == [Coupling(3, 85, "a.ts", "b.ts")]
    assert coupling(commits, {"a.ts", "b.ts", "c.ts"}, min_shared=1) == [
        Coupling(3, 85, "a.ts", "b.ts"),
        Coupling(1, 50, "b.ts", "c.ts"),
        Coupling(1, 40, "a.ts", "c.ts"),
    ]


def test_bulk_commits_do_not_count_toward_coupling():
    files = tuple(f"f{i}.ts" for i in range(51))
    commits = [Commit("Ana", files)] * 3

    assert coupling(commits, set(files), min_shared=3, max_files=50) == []
    assert churn(commits, set(files))["f0.ts"] == (3, 1)


def test_deleted_files_are_left_out():
    assert "old.ts" not in churn(parse_log(LOG), {"a.ts"})
    assert all("old.ts" not in (c.a, c.b) for c in coupling(parse_log(LOG), {"a.ts", "b.ts"}, min_shared=1))
