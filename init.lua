-----------------------------------------------------
-- Load configuration
-----------------------------------------------------
require("pcf.config.options")
require("pcf.config.keymaps")
require("pcf.config.diagnostics")

-----------------------------------------------------
-- Install plugin manager
-----------------------------------------------------
local plugin_manager = require("pcf.config.plugin-manager")

-----------------------------------------------------
-- Load plugins
-----------------------------------------------------

-- Helper function to reduce duplication
local function plugin(path)
	return require("pcf.plugins." .. path)
end

plugin_manager.setup({
	plugin("themes"), -- see lua/pcf/plugins/themes/init.lua

	plugin("ai.copilot"),
	plugin("ai.copilot-chat"),

	plugin("completion.blink"),

	plugin("debugging.dap"),

	plugin("editor.autopairs"),
	plugin("editor.code-indentation"),
	plugin("editor.comment"),
	plugin("editor.flash"),
	plugin("editor.local-highlight"),
	plugin("editor.nvim-surround"),
	plugin("editor.refactoring"),
	plugin("editor.todo-comments"),
	plugin("editor.treesitter"),
	plugin("editor.trouble"),
	plugin("editor.ufo"),

	plugin("git.diffview"),
	plugin("git.gitsigns"),

	plugin("lsp.format"),
	plugin("lsp.lint"),
	plugin("lsp.lsp-config"),

	plugin("navigation.mini-files"),
	plugin("navigation.neo-tree"),

	plugin("testing.neo-test"),

	plugin("ui.lualine"),
	plugin("ui.noice"),
	plugin("ui.snacks"),
	plugin("ui.which-key"),

	plugin("utils.lazydev"),
}, {})
