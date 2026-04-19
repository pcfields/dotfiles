-- https://github.com/nvim-treesitter/nvim-treesitter
-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`

return { -- Highlight, edit, and navigate code
	"nvim-treesitter/nvim-treesitter",
	event = "BufRead",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"mfussenegger/nvim-ts-hint-textobject",
		"windwp/nvim-ts-autotag",
	},
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			-- Add languages to be installed here that you want installed for treesitter
			ensure_installed = {
				"html",
				"javascript",
				"json",
				"lua",
				"tsx",
				"typescript",
				"elm",
				"haskell",
				"rust",
			},

			-- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
			auto_install = false,
			highlight = {
				enable = true,
			},
		indent = {
			enable = true,
			disable = { "python" },
		},
		-- NOTE: incremental_selection replaced by native v_an/v_in in Neovim 0.12+
		-- Use `an` to expand selection outward and `in` to shrink inward in visual mode
		-- Enable syntax aware text objects
			textobjects = {
				select = {
					enable = true,
					lookahead = true,
					keymaps = {
						["af"] = "@function.outer",
						["if"] = "@function.inner",
						["ac"] = "@class.outer",
						["ic"] = "@class.inner",
					},
				},
			},
		})

		-- Setup rename open & closing html tag
		require("nvim-ts-autotag").setup({})
	end,
}
