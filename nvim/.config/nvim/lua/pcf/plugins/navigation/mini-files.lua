-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-files.md
-- Navigate and manipulate file system

return {
	"echasnovski/mini.files",
	version = "*",
	config = function()
		local map = require("pcf.utils").map

		require("mini.files").setup({})

		map("n", "<leader>fd", function()
			require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
		end, { desc = "Open mini.files (Directory of Current File)" })
	end,
}
