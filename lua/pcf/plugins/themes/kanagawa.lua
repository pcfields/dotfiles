--------------------------------------------------------------
-- THEME: Kanagawa
-- URL: https://github.com/rebelot/kanagawa.nvim
-- options >>  kanagawa | kanagawa-wave | kanagawa-dragon | kanagawa-lotus |
--------------------------------------------------------------

local M = {}

M.colorscheme = "kanagawa"

function M.spec(active)
	return {
		"rebelot/kanagawa.nvim",
		name = "kanagawa",
		lazy = not active,
		priority = active and 1000 or nil,
		config = function()
			require("kanagawa").setup({})

			if active then
				local status_ok, _ = pcall(vim.cmd, "colorscheme " .. M.colorscheme)

				if not status_ok then
					vim.notify("colorscheme " .. M.colorscheme .. " not found")

					return
				end
			end
		end,
	}
end

return M
