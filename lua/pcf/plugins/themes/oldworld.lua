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
			local steel_blue = "#6b8cba"
			local ice_blue = "#85b5ba"
			local fern = "#6b9f6b"
			local peach = "#d4a08a"
			local default_fg = "#c9c7cd"

			local olive = "#a8b070"
			local teal = "#7da8a0"
			local warm_bg = "#1c1e1c"
			local sandy = "#c4a882"
			local blush = "#c9a0a0"
			local rose = "#c4929b"
			local mauve = "#b89cad"

			require("oldworld").setup({
				variant = "default", -- (variants: default | oled | cooler)
				highlight_overrides = {
					["@keyword"] = { fg = ice_blue },
					Constant = { fg = steel_blue },
					Function = { fg = fern },
					["@lsp.typemod.function.readonly"] = { fg = fern },
					String = { fg = peach },
					["@markup.link.label"] = { fg = default_fg },
				},
			})

			-- Override harsh palette colors before colorscheme loads
			local palette = require("oldworld.palette")

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
