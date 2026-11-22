from pathlib import Path

import pytest
import tree_sitter_language_pack as pack

from code_health.languages import LANGUAGES, language_for_path

FIXTURES = Path(__file__).parent / "fixtures"
SAMPLES = sorted(FIXTURES.glob("*/sample.*"))


@pytest.mark.parametrize("sample", SAMPLES, ids=lambda p: p.parent.name)
def test_sample_parses_without_errors(sample):
    language = language_for_path(sample)
    tree = pack.get_parser(language.grammar).parse(sample.read_bytes())

    assert _error_nodes(tree.root_node) == []


def test_every_language_has_a_sample():
    covered = {language_for_path(sample).name for sample in SAMPLES}

    assert covered == {language.name for language in LANGUAGES}


@pytest.mark.parametrize("language", LANGUAGES, ids=lambda language: language.name)
def test_recorded_node_types_exist_in_the_grammar(language):
    grammar = pack.get_language(language.grammar)
    named = _named_kinds(language)
    anonymous = language.decision_operators
    either = {kind for kinds in language.branch_exclusions.values() for kind in kinds}

    missing = [kind for kind in named if grammar.id_for_node_kind(kind, True) is None]
    missing += [kind for kind in anonymous if grammar.id_for_node_kind(kind, False) is None]
    missing += [kind for kind in either if not _exists_either_way(grammar, kind)]

    assert sorted(missing) == []


def _named_kinds(language):
    return (
        language.functions
        | language.branches
        | language.loops
        | language.parameter_lists
        | language.conditionals
        | language.nesting
        | language.else_clauses
        | language.function_bodies
        | language.classes
        | language.comments
        | language.constructors
        | language.primary_constructor_owners
        | frozenset(language.branch_exclusions)
        | frozenset(language.condition_positions)
        | language.parameter_exclusions
    )


def _exists_either_way(grammar, kind):
    return grammar.id_for_node_kind(kind, True) is not None or grammar.id_for_node_kind(kind, False) is not None


@pytest.mark.parametrize(
    ("path", "expected"),
    [
        ("src/App.tsx", "tsx"),
        ("src/view.JSX", "javascript"),
        (r"C:\work\Service\OrderService.cs", "csharp"),
        ("install/setup.ps1", "powershell"),
        ("scripts/run.sh", "bash"),
        ("src/code_health/cli.py", "python"),
    ],
)
def test_language_for_path(path, expected):
    assert language_for_path(path).name == expected


def test_unknown_extensions_have_no_language():
    assert language_for_path("schema.sql") is None
    assert language_for_path("Makefile") is None


def test_powershell_null_coalescing_is_a_known_parse_gap():
    tree = pack.get_parser("powershell").parse(b"$a = $b ?? 'x'\n")

    assert tree.root_node.has_error


def _error_nodes(node):
    found = [(node.type, node.start_point)] if node.is_error or node.is_missing else []
    for child in node.children:
        found += _error_nodes(child)
    return found
