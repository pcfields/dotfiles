from dataclasses import replace

from code_health.delta import Change, compare, fails
from code_health.smells import Finding

BASE = Finding(smell="Complex Method", function="f", line=1, value=12, limit=10)


def finding(**overrides):
    return replace(BASE, **overrides)


def test_unchanged_findings_are_existing_and_pass():
    changes = compare(before=(finding(),), after=(finding(line=5),))

    assert changes == (Change(status="existing", finding=finding(line=5), before_value=12),)
    assert not fails(changes)


def test_new_finding_fails():
    changes = compare(before=(), after=(finding(),))

    assert changes == (Change(status="new", finding=finding(), before_value=None),)
    assert fails(changes)


def test_higher_value_is_worse_and_fails():
    changes = compare(before=(finding(value=12),), after=(finding(value=14),))

    assert changes == (Change(status="worse", finding=finding(value=14), before_value=12),)
    assert fails(changes)


def test_lower_value_is_existing_and_passes():
    changes = compare(before=(finding(value=14),), after=(finding(value=12),))

    assert changes == (Change(status="existing", finding=finding(value=12), before_value=14),)
    assert not fails(changes)


def test_finding_that_is_gone_is_fixed():
    old = finding(smell="Bumpy Road", value=2, limit=2)

    changes = compare(before=(old, finding()), after=(finding(),))

    assert changes == (
        Change(status="existing", finding=finding(), before_value=12),
        Change(status="fixed", finding=old, before_value=2),
    )
    assert not fails(changes)


def test_same_smell_in_another_function_is_new():
    changes = compare(before=(finding(function="a"),), after=(finding(function="b"),))

    assert [change.status for change in changes] == ["new", "fixed"]
