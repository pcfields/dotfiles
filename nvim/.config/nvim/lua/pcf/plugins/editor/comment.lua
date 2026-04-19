-- Use native Neovim 0.10+ commenting (gc/gcc) with JSX/TSX context awareness
-- via ts_context_commentstring, replacing Comment.nvim

return {
	"JoosepAlviste/nvim-ts-context-commentstring",
	lazy = false,
	config = function()
		---@diagnostic disable-next-line: inject-field
		vim.g.skip_ts_context_commentstring_module = true

		require("ts_context_commentstring").setup({
			enable_autocmd = false,
		})

		-- Override native commentstring resolution with treesitter-aware version
		local get_option = vim.filetype.get_option
		---@diagnostic disable-next-line: duplicate-set-field
		vim.filetype.get_option = function(filetype, option)
			return option == "commentstring"
				and require("ts_context_commentstring.internal").calculate_commentstring()
				or get_option(filetype, option)
		end

		-- Custom keymaps to match previous <leader>lk / <leader>bk mappings
		local map = require("pcf.utils").map

		map({ "n" }, "<leader>lk", "gcc", { desc = "Toggle line comment", remap = true })
		map({ "v" }, "<leader>lk", "gc", { desc = "Toggle line comment", remap = true })
		map({ "n" }, "<leader>bk", "gbc", { desc = "Toggle block comment", remap = true })
		map({ "v" }, "<leader>bk", "gb", { desc = "Toggle block comment", remap = true })
	end,
}
