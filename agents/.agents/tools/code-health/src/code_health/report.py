from dataclasses import asdict, dataclass

from code_health.config import DEFAULT_CONFIG, Config, rules_for
from code_health.languages import language_for_path
from code_health.measure import measure_file
from code_health.score import SCORER_VERSION, band, score_file
from code_health.smells import FIX_HINTS, Finding, find_smells


@dataclass(frozen=True)
class FileReport:
    path: str
    score: float | None
    band: str
    findings: tuple[Finding, ...] = ()
    reason: str | None = None


def review_source(
    path: str, source: bytes, config: Config = DEFAULT_CONFIG, match_path: str | None = None
) -> FileReport:
    language = language_for_path(path)
    if language is None:
        return _not_scored(path, "unsupported language")
    metrics = measure_file(source, language)
    if metrics.parse_errors:
        return _not_scored(path, "parse errors")
    limits, weights = rules_for(config, match_path or path)
    findings = find_smells(metrics, limits)
    score = score_file(findings, weights)
    return FileReport(path=path, score=score, band=band(score), findings=findings)


def format_score_line(report: FileReport) -> str:
    if report.score is None:
        return f"   -  not scored  {report.path} ({report.reason})"
    return f"{report.score:4.1f}  {report.band:<10}  {report.path}"


def format_review(report: FileReport) -> str:
    if report.score is None:
        return f"{report.path}  not scored ({report.reason})"
    lines = [f"{report.path}  {report.score:.1f}  {report.band}"]
    width = max((len(finding.smell) for finding in report.findings), default=0)
    for finding in report.findings:
        location = f"{finding.function}:{finding.line}"
        lines.append(f"  {finding.smell:<{width}}  {location}  {describe(finding)}")
        lines.append(f"  {'':<{width}}  fix: {FIX_HINTS[finding.smell]}")
    if not report.findings:
        lines.append("  no findings")
    return "\n".join(lines)


def describe(finding: Finding, suffix: str = "") -> str:
    unit = _UNITS[finding.smell]
    measured = f"{unit} {finding.value}" if unit in _UNIT_FIRST else f"{finding.value} {unit}"
    return f"{measured}{suffix} (limit {finding.limit})"


_UNITS = {
    "Complex Method": "complexity",
    "Deep Nested Complexity": "depth",
    "Bumpy Road": "bumps",
    "Complex Conditional": "operators",
    "Large Method": "lines",
    "Excess Function Arguments": "parameters",
    "Large File": "lines",
}
_UNIT_FIRST = {"complexity", "depth"}


def to_json(reports: list[FileReport], include_findings: bool) -> dict:
    return {"scorer_version": SCORER_VERSION, "files": [_file_json(r, include_findings) for r in reports]}


def _file_json(report: FileReport, include_findings: bool) -> dict:
    data = {"path": report.path, "score": report.score, "band": report.band}
    if report.reason:
        data["reason"] = report.reason
    elif include_findings:
        data["findings"] = [
            {**asdict(finding), "fix": FIX_HINTS[finding.smell]} for finding in report.findings
        ]
    return data


def _not_scored(path: str, reason: str) -> FileReport:
    return FileReport(path=path, score=None, band="not scored", reason=reason)
