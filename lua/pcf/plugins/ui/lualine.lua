-- https://github.com/nvim-lualine/lualine.nvim
-- See `:help lualine.txt`

return { -- Neovim statusline plugin
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local macro_recording_text = require("pcf.utils.macros").macro_recording_text
		local get_winbar_filename = require("pcf.utils.buffers").get_winbar_filename

		require("lualine").setup({
			options = {
				icons_enabled = true,
				theme = "palenight", -- auto | palenight | ayu_dark | ayu_mirage | codedark
				component_separators = "",
				section_separators = "",
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				always_show_tabline = true,
				globalstatus = true,
				refresh = {
					statusline = 100,
					tabline = 100,
					winbar = 100,
				},
			},
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "diagnostics", "filename", "filesize" },
				lualine_c = { "branch", "diff", macro_recording_text },
				lualine_x = { "encoding", "fileformat", "filetype" },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			winbar = {
				lualine_c = { get_winbar_filename },
			},
			inactive_winbar = {
				lualine_b = { get_winbar_filename },
			},
			extensions = {},
		})
	end,
}
