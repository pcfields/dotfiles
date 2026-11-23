import re

import pytest

from code_health.config import (
    ConfigError,
    is_excluded,
    matches,
    parse_config,
    rules_for,
)


@pytest.mark.parametrize(
    ("pattern", "path", "expected"),
    [
        ("*.min.js", "app.min.js", True),
        ("*.min.js", "web/js/app.min.js", True),
        ("*.min.js", "app.js", False),
        ("vendor/", "vendor/lib.ts", True),
        ("vendor/", "src/vendor/lib.ts", True),
        ("vendor/", "src/vendorish/lib.ts", False),
        ("vendor/", "vendor.ts", False),
        ("legacy/**", "legacy/a/b.ts", True),
        ("legacy/**", "src/legacy/a.ts", False),
        ("src/*.ts", "src/a.ts", True),
        ("src/*.ts", "src/deep/a.ts", False),
        ("**/tests/**", "tests/a.py", True),
        ("**/tests/**", "pkg/tests/deep/a.py", True),
        ("**/*Tests/**", "Orders.Tests/OrderTests.cs", True),
        ("*.Designer.cs", "Forms/Main.Designer.cs", True),
    ],
)
def test_matches(pattern, path, expected):
    assert matches(pattern, path) is expected


def test_windows_paths_match_like_posix_paths():
    assert matches("vendor/", "src\\vendor\\lib.ts")
    assert matches("legacy/**", ".\\legacy\\a.ts")


def test_defaults_exclude_generated_and_vendored_code():
    config = parse_config(None)

    assert is_excluded(config, "node_modules/x/index.js")
    assert is_excluded(config, "dist/app.js")
    assert is_excluded(config, "src/Model.g.cs")
    assert is_excluded(config, "api/client.generated.ts")
    assert not is_excluded(config, "src/app.ts")


def test_user_exclusions_add_to_the_defaults():
    config = parse_config('exclude = ["legacy/**"]')

    assert is_excluded(config, "legacy/old.ts")
    assert is_excluded(config, "node_modules/x.js")


def test_default_rules_and_test_file_weight():
    limits, weights = rules_for(parse_config(None), "src/app.ts")
    test_limits, test_weights = rules_for(parse_config(None), "src/app.test.ts")

    assert limits["Complex Method"] == 10
    assert limits["Excess Function Arguments (constructor)"] == 8
    assert weights == {}
    assert test_limits == limits
    assert test_weights == {"Large Method": 0.5}


def test_later_rules_win_for_matching_paths():
    config = parse_config(
        """
[[rules]]
paths = ["src/legacy/**"]
limits = { "Large Method" = 120, "Complex Method" = 15 }

[[rules]]
paths = ["src/legacy/hot.ts"]
limits = { "Large Method" = 90 }
weights = { "Bumpy Road" = 0 }
"""
    )

    assert rules_for(config, "src/legacy/hot.ts")[0]["Large Method"] == 90
    assert rules_for(config, "src/legacy/hot.ts")[0]["Complex Method"] == 15
    assert rules_for(config, "src/legacy/hot.ts")[1] == {"Bumpy Road": 0}
    assert rules_for(config, "src/app.ts")[0]["Large Method"] == 70


@pytest.mark.parametrize(
    ("text", "message"),
    [
        ("exclude = [", "not valid TOML"),
        ('exclude = "x"', "exclude must be a list of strings"),
        ('[[rules]]\npaths = ["a"]\nlimits = { "Big Method" = 1 }', "unknown smell: Big Method"),
        ('[[rules]]\nlimits = { "Large Method" = 1 }', "every [[rules]] needs paths"),
        ('[[rules]]\npaths = ["a"]\nweights = { "Large Method" = "x" }', "must be a number"),
        ('colour = "red"', "unknown setting: colour"),
    ],
)
def test_invalid_config_is_an_error(text, message):
    with pytest.raises(ConfigError, match=re.escape(message)):
        parse_config(text)


def test_hand_written_scripts_in_build_and_bin_folders_are_scored():
    config = parse_config(None)

    assert not is_excluded(config, "build/deploy.ps1")
    assert not is_excluded(config, "bin/setup.sh")
    assert is_excluded(config, "src/App/obj/Debug/App.AssemblyInfo.cs")
