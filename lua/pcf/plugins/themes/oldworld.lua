--------------------------------------------------------------
-- THEME: OldWorld
-- URL: https://github.com/dgox16/oldworld.nvim
-- options >>  oldworld
--------------------------------------------------------------

local M = {}

M.colorscheme = "oldworld"

function M.spec(active)
	return {
		"dgox16/oldworld.nvim",
		lazy = not active,
		priority = active and 1000 or nil,
		config = function()
			require("oldworld").setup({
				variant = "default", -- (variants: default | oled | cooler)
			})

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
