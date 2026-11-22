from code_health.repo import (
    Commit,
    Coupling,
    RepoFile,
    average_health,
    change_frequency,
    churn,
    coupling,
    healthy_but_busy,
    hotspot_health,
    least_healthy,
    parse_log,
    refactor_first,
    worst_file,
    worst_findings,
)
from code_health.score import band
from code_health.smells import Finding

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


def repo_file(path, score, commits=0, loc=100, authors=1, findings=()):
    return RepoFile(path=path, score=score, band=band(score), loc=loc, commits=commits, authors=authors, findings=findings)


FILES = [
    repo_file("hot.ts", 4.0, commits=10, loc=300),
    repo_file("calm.ts", 10.0, commits=20, loc=100),
    repo_file("warm.ts", 8.0, commits=5, loc=100),
    repo_file("cold.ts", 2.0, commits=0, loc=500),
]


def paths(rows):
    return [row.path for row in rows]


def test_refactor_first_ranks_by_commits_times_debt():
    assert paths(refactor_first(FILES, top=10)) == ["hot.ts", "warm.ts"]


def test_change_frequency_ranks_by_commits():
    assert paths(change_frequency(FILES, top=2)) == ["calm.ts", "hot.ts"]


def test_healthy_but_busy_lists_changed_green_files():
    assert paths(healthy_but_busy(FILES, top=10)) == ["calm.ts"]


def test_least_healthy_lists_non_green_files_worst_first():
    assert paths(least_healthy(FILES, top=10)) == ["cold.ts", "hot.ts", "warm.ts"]


def test_average_health_is_weighted_by_lines():
    assert average_health(FILES) == 4.0


def test_hotspot_health_is_weighted_by_commits_over_the_busiest_files():
    assert hotspot_health(FILES, top=2) == 8.0
    assert hotspot_health([], top=2) is None


def test_worst_file():
    assert worst_file(FILES).path == "cold.ts"
    assert worst_file([]) is None


def test_worst_findings_rank_by_penalty():
    small = Finding("Large Method", "a", 1, 70, 70)
    big = Finding("Deep Nested Complexity", "b", 9, 8, 4)
    files = [repo_file("a.ts", 9.0, findings=(small,)), repo_file("b.ts", 5.0, findings=(big,))]

    assert [(path, f.function) for path, f in worst_findings(files, top=10)] == [("b.ts", "b"), ("a.ts", "a")]
