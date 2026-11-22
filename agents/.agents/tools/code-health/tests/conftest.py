import pytest
from gitrepo import git


@pytest.fixture
def repo(tmp_path, monkeypatch):
    root = tmp_path / "repo"
    root.mkdir()
    git(root, "init", "-q", "-b", "main")
    monkeypatch.chdir(root)
    return root


@pytest.fixture
def state(tmp_path, monkeypatch):
    folder = tmp_path / "state"
    monkeypatch.setenv("CODE_HEALTH_STATE_DIR", str(folder))
    return folder
