-- https://github.com/folke/todo-comments.nvim
--
return { -- Add colors to TODO comment
	"folke/todo-comments.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	opts = {},
}
