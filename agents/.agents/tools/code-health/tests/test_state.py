from pathlib import Path, PureWindowsPath

from code_health.state import repo_key, state_dir


def test_override_wins():
    env = {"CODE_HEALTH_STATE_DIR": "/custom", "XDG_STATE_HOME": "/xdg", "LOCALAPPDATA": "C:\\Local"}

    assert state_dir(env=env, home=Path("/home/u")) == Path("/custom")


def test_uses_xdg_state_home_or_the_default():
    assert state_dir(env={"XDG_STATE_HOME": "/xdg"}, home=Path("/home/u")) == Path("/xdg/code-health")
    assert state_dir(env={}, home=Path("/home/u")) == Path("/home/u/.local/state/code-health")


def test_windows_uses_the_home_folder_not_app_data():
    local = {"LOCALAPPDATA": "C:\\Users\\u\\AppData\\Local"}

    path = state_dir(env=local, home=PureWindowsPath("C:\\Users\\u"))

    assert PureWindowsPath(path) == PureWindowsPath("C:\\Users\\u\\.local\\state\\code-health")


def test_repo_key_is_stable_and_differs_per_repo():
    assert repo_key("/work/a") == repo_key("/work/a")
    assert repo_key("/work/a") != repo_key("/work/b")
    assert len(repo_key("/work/a")) == 16


def test_repo_key_ignores_case_and_slashes_on_windows():
    assert repo_key("C:\\Work\\A", platform="win32") == repo_key("c:/work/a", platform="win32")
