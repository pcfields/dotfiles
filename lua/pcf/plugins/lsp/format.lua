-- https://github.com/stevearc/conform.nvim

return { -- Code formatting
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		local save_settings = {
			lsp_format = "fallback",
			async = false,
			timeout_ms = 10000,
		}

		conform.setup({
			formatters_by_ft = {
				javascript = { "biome", "prettier" },
				typescript = { "biome", "prettier" },
				javascriptreact = { "biome", "prettier" },
				typescriptreact = { "biome", "prettier" },
				css = { "prettier" },
				json = { "biome" },
				yaml = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
			},
			format_on_save = save_settings,
		})

		vim.keymap.set({ "n", "v" }, "<leader>hf", function()
			conform.format(save_settings)
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
