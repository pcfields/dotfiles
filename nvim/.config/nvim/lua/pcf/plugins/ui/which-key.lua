-- https://github.com/folke/which-key.nvim
-- Useful plugin to show you pending keybinds.

-- Display keybinding information

return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	config = function()
		require("which-key").setup({})
	end,
}
