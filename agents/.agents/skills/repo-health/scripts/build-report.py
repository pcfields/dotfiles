"""Turns the raw tables from `repo-health.sh --data <dir>` into one HTML page:
a hotspot map, a change-coupling wheel, refactoring targets and charts.

usage: python build-report.py <data dir> [--findings <json>] [--out <html>]

--findings defaults to <data dir>/findings.json when it exists, and --out to
<data dir>/report.html. Findings are what the agent concluded after reading the
code, so the page has no verdict or targets without them:

  {"verdict": "One or two sentences.",
   "targets": [{"path": "src/a.cs", "issues": ["..."], "fix": "..."}]}

Text in findings may mark code with `backticks`.
"""
import argparse
import html
import json
import os
import sys

TEMPLATE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "report.html")
TOP_FUNCTIONS = 12


def main():
    args = parse_args()
    data = load_data(args.data)
    findings = load_findings(args.findings or os.path.join(args.data, "findings.json"))
    out = args.out or os.path.join(args.data, "report.html")
    with open(TEMPLATE, encoding="utf-8") as f:
        page = render(f.read(), data, findings)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print(f"wrote {out} ({len(data['files'])} files, {len(data['coupling'])} coupled pairs, "
          f"{len(findings.get('targets', []))} targets)")


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("data")
    p.add_argument("--findings")
    p.add_argument("--out")
    return p.parse_args()


def load_data(folder):
    def rows(name):
        path = os.path.join(folder, name)
        if not os.path.exists(path):
            sys.exit(f"missing {path}: run repo-health.sh with --data {folder} first")
        with open(path, encoding="utf-8") as f:
            return [line.rstrip("\n").split("\t") for line in f if line.strip()]

    meta = dict((r + [""])[:2] for r in rows("meta"))
    churn = {r[0]: (int(r[1]), int(r[2])) for r in rows("churn")}
    functions = [function_row(r) for r in rows("functions")]
    commits, authors = (int(v) for v in rows("totals")[0])
    return {
        "title": f"{meta.get('repo', 'Repo')} Code Health",
        "meta": meta,
        "commits": commits,
        "authors": authors,
        "files": file_rows(rows("complexity"), churn, functions),
        "coupling": [[int(r[0]), int(r[1].rstrip("%")), r[2], r[3]] for r in rows("coupling")],
        "fns": [[f["ccn"], f["length"], f["name"], f["path"], f["line"]]
                for f in sorted(functions, key=lambda f: -f["ccn"])[:TOP_FUNCTIONS]],
    }


def function_row(r):
    return {"ccn": int(r[0]), "length": int(r[1]), "params": int(r[2]), "name": r[3],
            "path": r[4], "line": int(r[5]), "level": int(r[6])}


def file_rows(complexity, churn, functions):
    flagged, worst = {}, {}
    for f in functions:
        if f["level"] > 0:
            flagged[f["path"]] = flagged.get(f["path"], 0) + 1
        if f["path"] not in worst or f["ccn"] > worst[f["path"]]["ccn"]:
            worst[f["path"]] = f
    result = []
    for path, lines, weight, depth, grade in complexity:
        commits, authors = churn.get(path, (0, 0))
        w = worst.get(path)
        result.append([path, int(lines), int(weight), int(depth), grade[0], commits, authors,
                       flagged.get(path, 0),
                       [w["ccn"], w["length"], w["params"], w["name"], w["line"]] if w else None])
    return result


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
