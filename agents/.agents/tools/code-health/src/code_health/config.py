import re
import tomllib
from dataclasses import dataclass
from functools import lru_cache

from code_health.smells import DEFAULT_LIMITS, SMELLS

CONFIG_FILE = ".code-health.toml"

DEFAULT_EXCLUDES = (
    "*.min.js",
    "*.min.css",
    "vendor/",
    "node_modules/",
    "dist/",
    "build/",
    "bin/",
    "obj/",
    "*.Designer.cs",
    "*.g.cs",
    "*.generated.*",
)

TEST_FILES = ("*.test.*", "*.spec.*", "test_*.py", "**/tests/**", "**/*Tests/**")


class ConfigError(Exception):
    pass


@dataclass(frozen=True)
class Rule:
    paths: tuple[str, ...]
    limits: tuple[tuple[str, float], ...] = ()
    weights: tuple[tuple[str, float], ...] = ()


@dataclass(frozen=True)
class Config:
    exclude: tuple[str, ...]
    rules: tuple[Rule, ...]


def parse_config(text: str | None) -> Config:
    data = _load(text)
    unknown = set(data) - {"exclude", "rules"}
    if unknown:
        raise ConfigError(f"unknown setting: {', '.join(sorted(unknown))}")
    exclude = _strings(data.get("exclude", []), "exclude")
    rules = tuple(_rule(entry) for entry in _tables(data.get("rules", []), "rules"))
    return Config(exclude=DEFAULT_EXCLUDES + exclude, rules=(_TEST_RULE, *rules))


_TEST_RULE = Rule(paths=TEST_FILES, weights=(("Large Method", 0.5),))
DEFAULT_CONFIG = Config(exclude=DEFAULT_EXCLUDES, rules=(_TEST_RULE,))


def is_excluded(config: Config, path: str) -> bool:
    return any(matches(pattern, path) for pattern in config.exclude)


def rules_for(config: Config, path: str) -> tuple[dict[str, float], dict[str, float]]:
    limits = dict(DEFAULT_LIMITS)
    weights: dict[str, float] = {}
    for rule in config.rules:
        if any(matches(pattern, path) for pattern in rule.paths):
            limits.update(rule.limits)
            weights.update(rule.weights)
    return limits, weights


def matches(pattern: str, path: str) -> bool:
    normalized = path.replace("\\", "/").removeprefix("./")
    return _compile(pattern).search(normalized) is not None


@lru_cache(maxsize=256)
def _compile(pattern: str) -> re.Pattern:
    directory = pattern.endswith("/")
    body = pattern.rstrip("/")
    anchored = "/" in body
    regex = _glob_to_regex(body)
    prefix = "^" if anchored else "(?:^|/)"
    suffix = "/" if directory else "(?:$|/)"
    return re.compile(prefix + regex + suffix)


def _glob_to_regex(glob: str) -> str:
    parts = []
    i = 0
    while i < len(glob):
        if glob.startswith("**/", i):
            parts.append("(?:.*/)?")
            i += 3
        elif glob.startswith("**", i):
            parts.append(".*")
            i += 2
        elif glob[i] == "*":
            parts.append("[^/]*")
            i += 1
        elif glob[i] == "?":
            parts.append("[^/]")
            i += 1
        else:
            parts.append(re.escape(glob[i]))
            i += 1
    return "".join(parts)


def _load(text: str | None) -> dict:
    if not text:
        return {}
    try:
        return tomllib.loads(text)
    except tomllib.TOMLDecodeError as error:
        raise ConfigError(f"{CONFIG_FILE} is not valid TOML: {error}") from error


def _rule(entry: dict) -> Rule:
    if "paths" not in entry:
        raise ConfigError("every [[rules]] needs paths")
    return Rule(
        paths=_strings(entry["paths"], "paths"),
        limits=_smell_numbers(entry.get("limits", {}), "limits", known=set(DEFAULT_LIMITS)),
        weights=_smell_numbers(entry.get("weights", {}), "weights", known=SMELLS),
    )


def _smell_numbers(table: object, name: str, known: set[str]) -> tuple[tuple[str, float], ...]:
    if not isinstance(table, dict):
        raise ConfigError(f"{name} must be a table of smell = number")
    for smell, value in table.items():
        if smell not in known:
            raise ConfigError(f"unknown smell: {smell}")
        if isinstance(value, bool) or not isinstance(value, int | float):
            raise ConfigError(f"{name}.{smell} must be a number")
    return tuple(table.items())


def _strings(value: object, name: str) -> tuple[str, ...]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ConfigError(f"{name} must be a list of strings")
    return tuple(value)


def _tables(value: object, name: str) -> list[dict]:
    if not isinstance(value, list) or not all(isinstance(item, dict) for item in value):
        raise ConfigError(f"{name} must be a list of tables")
    return value
