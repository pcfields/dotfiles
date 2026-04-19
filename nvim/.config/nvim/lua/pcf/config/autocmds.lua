-----------------------------------------------------
-- Autocommands
-----------------------------------------------------

-- Highlight text on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
	callback = function()
		vim.hl.on_yank({ higroup = "Visual", timeout = 300 })
	end,
})
