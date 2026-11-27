local wezterm = require("wezterm")

-- Modules load from beside this file, so a --config-file run or a worktree
-- uses its own copy rather than the installed one.
package.path = wezterm.config_dir .. "/?.lua;" .. package.path

local platform = require("pcf.platform")

local config = wezterm.config_builder()

local function apply(settings)
	for key, value in pairs(settings) do
		config[key] = value
	end
end

-- Shell and Working Directory
config.default_cwd = platform.home_dir
config.default_prog = { platform.shell }

-- Performance Settings
config.max_fps = 120
config.animation_fps = 120
config.front_end = "OpenGL" -- WebGpu flickers on Linux

-- Scrollback
config.scrollback_lines = 50000

-- Window behavior
config.window_close_confirmation = "AlwaysPrompt"
config.audible_bell = "Disabled"

apply(require("pcf.appearance"))
apply(require("pcf.keys"))

require("pcf.workspace_history").register()
require("pcf.tab_title").register()
require("pcf.status_bar").register()

return config
