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
		require("nvim-treesitter").setup({
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
			auto_install = false,
			highlight = {
				enable = true,
			},
			indent = {
				enable = true,
				disable = { "python" },
			},
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

		require("nvim-ts-autotag").setup({})
	end,
}
