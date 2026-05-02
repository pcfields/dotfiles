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
			javascript = { "biome", "prettierd", stop_after_first = true },
			typescript = { "biome", "prettierd", stop_after_first = true },
			javascriptreact = { "biome", "prettierd", stop_after_first = true },
			typescriptreact = { "biome", "prettierd", stop_after_first = true },
			css = { "prettierd" },
			json = { "biome", "prettierd", stop_after_first = true },
			yaml = { "prettierd" },
			html = { "prettierd" },
			markdown = { "prettierd" },
			graphql = { "prettierd" },
			liquid = { "prettierd" },
			lua = { "stylua" },
		},
			format_on_save = save_settings,
		})

		require("pcf.utils").map({ "n", "v" }, "<leader>hf", function()
			conform.format(save_settings)
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
