-- https://github.com/ThePrimeagen/refactoring.nvim
--
local map = require("pcf.utils").map

return {
	"ThePrimeagen/refactoring.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	config = function()
		local refactoring = require("refactoring")

		refactoring.setup({})

		-- Remaps for the refactoring operations
		map({ "n", "x" }, "<leader>rr", function()
			refactoring.select_refactor()
		end, { desc = "Refactoring menu" })

		map("n", "<leader>re", function()
			refactoring.refactor("Extract Function")
		end, { desc = "Extract function" })

		map("n", "<leader>rf", function()
			refactoring.refactor("Extract Function To File")
		end, { desc = "Extract function to file" })

		map("n", "<leader>rv", function()
			refactoring.refactor("Extract Variable")
		end, { desc = "Extract variable" })

		map("n", "<leader>ri", function()
			refactoring.refactor("Inline Variable")
		end, { desc = "Inline variable" })
	end,
}
