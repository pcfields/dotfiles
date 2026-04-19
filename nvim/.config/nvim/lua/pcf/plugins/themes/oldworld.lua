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
			local variable_color = colors.storm

			require("oldworld").setup({
				variant = "default", -- (variants: default | oled | cooler)
				highlight_overrides = {
					Constant = { fg = colors.storm },
					Function = { fg = colors.sky }, -- for function declarations. not function calls
					String = { fg = colors.sage },
					Type = { fg = colors.orange },
					["@keyword"] = { fg = colors.amber },

					["@comment"] = { fg = colors.warm_gray },

					["@variable"] = { fg = variable_color },
					["@variable.builtin"] = { fg = variable_color, italic = true },
					["@variable.parameter"] = { fg = variable_color },
					["@variable.parameter.builtin"] = { fg = variable_color },
					["@variable.member"] = { fg = variable_color },

					["@property"] = { fg = colors.silver },
					["@property.builtin"] = { fg = colors.silver, italic = true },

					["@operator"] = { fg = colors.sandy }, -- for any operator e.g. `+`, `-`, `*`, `/`, `=`, etc.
					["@punctuation"] = { fg = colors.ash },
					["@punctuation.bracket"] = { fg = colors.ash },
					["@punctuation.delimiter"] = { fg = colors.ash },

					["@string.escape"] = { fg = colors.rose },

					["@type"] = { fg = colors.orange },     -- types, enums, interfaces, etc.
					["@lsp.type.type"] = { fg = colors.orange }, -- for type declarations e.g. type alias name.
					["@lsp.type.variable"] = { fg = colors.silver },
					["@lsp.type.keyword"] = { fg = colors.amber },
					["@lsp.type.parameter"] = { fg = colors.storm, italic = true },

					["@lsp.typemod.function.readonly"] = { fg = colors.sky }, -- functions called and/or declared with const. Not function declaration
					["@lsp.typemod.variable.declaration"] = { fg = colors.mauve }, -- for variable declarations e.g. const, let, var
					["@lsp.typemod.property"] = { fg = colors.silver },

					["@markup.link.label"] = { fg = colors.silver },

					["@tag"] = { fg = colors.terracotta },
					["@tag.builtin"] = { fg = colors.dusty_sage },
					["@tag.attribute"] = { fg = colors.soft_clay },
					["@tag.delimiter"] = { fg = colors.muted_stone },
				},
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
