--https://github.com/folke/flash.nvim
--
return {
	"folke/flash.nvim",
	event = "VeryLazy",
	---@type Flash.Config
	opts = {
		char = {
			enabled = false,
		},
		modes = {
			search = { enabled = false },
			char = { jump_labels = true },
		},
	},
  -- stylua: ignore
  keys = {
    { "<leader>si", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash search" },
  },
}
