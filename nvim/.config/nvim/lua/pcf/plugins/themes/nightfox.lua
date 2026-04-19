--------------------------------------------------------------
-- THEME: NightFox
-- URL: https://github.com/EdenEast/nightfox.nvim
-- options >>  nightfox | carbonfox | duskfox | terafox || Light>> dawnfox | dayfox |
--------------------------------------------------------------

local M = {}

M.colorscheme = "carbonfox"

function M.spec(active)
	return {
		"EdenEast/nightfox.nvim",
		lazy = not active,
		priority = active and 1000 or nil,
		config = function()
			require("nightfox").setup({})

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
