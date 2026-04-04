-- https://github.com/mfussenegger/nvim-lint
--
return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		local linters = {
			js = { "biomejs", "eslint_d" },
		}

		lint.linters_by_ft = {
			javascript = linters.js,
			javascriptreact = linters.js,
			typescript = linters.js,
			typescriptreact = linters.js,
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
