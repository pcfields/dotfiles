local wezterm = require("wezterm")

local platform = {
	is_windows = wezterm.target_triple:find("windows") ~= nil,
}

platform.shell = platform.is_windows and "pwsh.exe" or (os.getenv("SHELL") or "/usr/bin/fish")

platform.home_dir = wezterm.home_dir

platform.font_size = 12

return platform
