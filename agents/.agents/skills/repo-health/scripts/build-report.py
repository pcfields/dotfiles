"""Turns the data `code-health repo` saves into one HTML page: a hotspot map,
a change-coupling wheel, a health trend, refactoring targets and charts.

usage: python build-report.py [<data dir>] [--findings <json>] [--out <html>]

The data dir defaults to .code-health/repo, --findings to <data dir>/findings.json
when it exists, and --out to <data dir>/report.html. Findings are what the agent
concluded after reading the code, so the page has no verdict or targets without
them:

  {"verdict": "One or two sentences.",
   "targets": [{"path": "src/a.cs", "issues": ["..."], "fix": "..."}]}

Text in findings may mark code with `backticks`. Standard library only.
"""
import argparse
import html
import json
import os
import sys

TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "report.html")


def main():
    args = parse_args()
    data = load_data(args.data)
    findings = load_findings(args.findings or os.path.join(args.data, "findings.json"))
    page_data = to_page(data)
    findings, dropped = known_targets(findings, {row[0] for row in page_data["files"]})
    out = args.out or os.path.join(args.data, "report.html")
    with open(TEMPLATE, encoding="utf-8") as f:
        page = render(f.read(), page_data, findings)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    note = f", {dropped} target left out (path not scored)" if dropped == 1 else (
        f", {dropped} targets left out (paths not scored)" if dropped else "")
    print(f"wrote {out} ({len(page_data['files'])} files, {len(page_data['coupling'])} coupled pairs, "
          f"{len(findings.get('targets', []))} targets{note})")


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("data", nargs="?", default=os.path.join(".code-health", "repo"))
    p.add_argument("--findings")
    p.add_argument("--out")
    return p.parse_args()


def load_data(folder):
    path = os.path.join(folder, "data.json")
    if not os.path.exists(path):
        sys.exit(f"missing {path}: run code-health repo first")
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def to_page(data):
    report, meta = data["report"], data["meta"]
    return {
        "title": f"{meta.get('repo', 'Repo')} Code Health",
        "meta": meta,
        "commits": report["commits"],
        "authors": report["authors"],
        "overview": report["overview"],
        "files": [file_row(f) for f in data["files"]],
        "coupling": [[c["shared"], c["degree"], c["a"], c["b"]] for c in data["coupling"]],
        "fns": [[f["cyclomatic"], f["loc"], f["name"], f["path"], f["line"]] for f in data["functions"]],
        "snapshots": data["snapshots"],
    }


def file_row(f):
    w = f.get("worst_function")
    worst = [w["cyclomatic"], w["loc"], w["name"], w["line"]] if w else None
    return [f["path"], f["loc"], f["score"], f["band"][0], f["commits"], f["authors"], f["findings"], worst]


def known_targets(findings, paths):
    targets = findings.get("targets", [])
    kept = [t for t in targets if t.get("path") in paths]
    return {**findings, "targets": kept}, len(targets) - len(kept)


def load_findings(path):
    if not os.path.exists(path):
        return {}
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def render(template, data, findings):
    return (template
            .replace("__TITLE__", html.escape(data["title"]), 1)
            .replace("/*DATA*/", script_json(data), 1)
            .replace("/*FINDINGS*/", script_json(findings), 1))


def script_json(value):
    # "</" would end the inline <script> early.
    return json.dumps(value, separators=(",", ":")).replace("</", "<\\/")


if __name__ == "__main__":
    main()
