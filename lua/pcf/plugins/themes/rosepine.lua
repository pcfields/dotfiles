--------------------------------------------------------------
-- THEME: Rose Pine
-- URL: https://github.com/rose-pine/neovim
-- options >>  rose-pine | rose-pine-main | rose-pine-moon | rose-pine-dawn |
--------------------------------------------------------------

local M = {}

M.colorscheme = "rose-pine"

function M.spec(active)
	return {
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = not active,
		priority = active and 1000 or nil,
		config = function()
			require("rose-pine").setup({})

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
