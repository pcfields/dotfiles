-- https://github.com/nvim-treesitter/nvim-treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter-textobjects

return { -- Treesitter: parser management, highlighting, textobjects
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	build = ":TSUpdate",
	dependencies = {
		"nvim-treesitter/nvim-treesitter-textobjects",
		"windwp/nvim-ts-autotag",
	},
	config = function()
		local map = require("pcf.utils").map

		-- Parser management
		require("nvim-treesitter").setup({})

		-- Install parsers (no-op if already installed)
		require("nvim-treesitter").install({
			"html",
			"javascript",
			"json",
			"lua",
			"tsx",
			"typescript",
			"elm",
			"haskell",
			"rust",
		})

		-- Enable treesitter highlighting per filetype (replaces highlight.enable)
		local ts_filetypes = {
			"html",
			"javascript",
			"javascriptreact",
			"json",
			"lua",
			"typescript",
			"typescriptreact",
			"elm",
			"haskell",
			"rust",
			"css",
			"markdown",
			"yaml",
			"toml",
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = ts_filetypes,
			callback = function()
				vim.treesitter.start()
			end,
		})

		-- Textobjects (standalone API)
		require("nvim-treesitter-textobjects").setup({
			select = {
				lookahead = true,
			},
		})

		local select_textobject = require("nvim-treesitter-textobjects.select").select_textobject

		map({ "x", "o" }, "af", function()
			select_textobject("@function.outer", "textobjects")
		end, { desc = "Select outer function" })

		map({ "x", "o" }, "if", function()
			select_textobject("@function.inner", "textobjects")
		end, { desc = "Select inner function" })

		map({ "x", "o" }, "ac", function()
			select_textobject("@class.outer", "textobjects")
		end, { desc = "Select outer class" })

		map({ "x", "o" }, "ic", function()
			select_textobject("@class.inner", "textobjects")
		end, { desc = "Select inner class" })

		-- Setup rename open & closing html tag
		require("nvim-ts-autotag").setup({})
	end,
}
