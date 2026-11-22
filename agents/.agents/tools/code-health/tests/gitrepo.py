import subprocess

CLEAN = "export function f(a) {\n  return a;\n}\n"


def nested(depth: int, name: str = "f") -> str:
    opening = "".join(f"{'  ' * (i + 1)}if (a{i}) {{\n" for i in range(depth))
    closing = "".join(f"{'  ' * (i + 1)}}}\n" for i in reversed(range(depth)))
    return f"export function {name}(a) {{\n{opening}{'  ' * (depth + 1)}return 1;\n{closing}  return 0;\n}}\n"


def git(root, *args):
    subprocess.run(
        ["git", "-c", "user.name=Test", "-c", "user.email=test@example.com", "-c", "commit.gpgsign=false", *args],
        cwd=root,
        check=True,
        capture_output=True,
    )


def write(root, path, text):
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


def commit(root, files: dict[str, str]):
    for path, text in files.items():
        write(root, path, text)
    git(root, "add", "-A")
    git(root, "commit", "-q", "-m", "change")
