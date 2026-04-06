--------------------------------------------------------------
-- THEME: Rose Pine
-- URL: https://github.com/rose-pine/neovim
-- options >>  rose-pine | rose-pine-main | rose-pine-moon | rose-pine-dawn |
--------------------------------------------------------------

return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		require("rose-pine").setup({})

		local colorscheme = "rose-pine"
		local status_ok, _ = pcall(vim.cmd, "colorscheme " .. colorscheme)

		if not status_ok then
			vim.notify("colorscheme " .. colorscheme .. " not found")

			return
		end
	end,
}
