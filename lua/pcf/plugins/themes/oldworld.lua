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
			local colors = require("pcf.utils.colors")

			require("oldworld").setup({
				variant = "default", -- (variants: default | oled | cooler)
				highlight_overrides = {
					["@keyword"] = { fg = colors.ice_blue },
					Constant = { fg = colors.steel_blue },
					Function = { fg = colors.fern },
					["@lsp.typemod.function.readonly"] = { fg = colors.fern },
					String = { fg = colors.peach },
					["@markup.link.label"] = { fg = colors.default_fg },
					["@lsp.type.parameter"] = { italic = true },
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
