return { -- Run tests
	"nvim-neotest/neotest",
	event = "VeryLazy",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"marilari88/neotest-vitest",
		"nvim-neotest/neotest-jest",
	},
	config = function()
		local map = require("pcf.utils").map
		local neo_test = require("neotest")
		neo_test.setup({
			adapters = {
				require("neotest-vitest"),
			},
			status = {
				enabled = true,
				signs = true,
				virtual_text = true,
			},
		})

		map("n", "<leader>tp", "<cmd>lua require'neotest'.output_panel.toggle()<cr>", { desc = "Toggle test Output Panel" })
		map("n", "<leader>tl", "<cmd>lua require'neotest'.summary.toggle()<cr>", { desc = "Toggle test summary/list" })
		map("n", "<leader>tt", "<cmd>lua require'neotest'.run.run()<cr>", { desc = "Run nearest test " })
		map("n", "<leader>tw", "<cmd>lua require'neotest'.watch.toggle(vim.fn.expand('%'))<cr>", { desc = "Watch file" })
		map("n", "<leader>tf", "<cmd>lua require'neotest'.run.run(vim.fn.expand('%'))<cr>", { desc = "Test current file" })
		map("n", "<leader>td", "<cmd>lua require'neotest'.run.run({strategy = 'dap'})<cr>", { desc = "Debug Test" })
		map("n", "<leader>ts", "<cmd>lua require'neotest'.run.stop()<cr>", { desc = "Test Stop" })
		map("n", "<leader>ta", "<cmd>lua require'neotest'.run.attach()<cr>", { desc = "Attach Test" })
	end,
}
