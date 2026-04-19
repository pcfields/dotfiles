-- https://github.com/folke/trouble.nvim

return { -- Diagnostics
	"folke/trouble.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("trouble").setup()
	end,
}
