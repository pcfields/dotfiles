-----------------------------------------------------
-- Autocommands
-----------------------------------------------------

-- Highlight text on yank
local yank_group = vim.api.nvim_create_augroup("yank_highlight", { clear = true })

local function set_yank_highlight()
  vim.api.nvim_set_hl(0, "YankFlash", { bg = "#ff9e3b", fg = "#000000", bold = true })
end

set_yank_highlight()

-- Colorschemes clear custom groups, so re-apply on change
vim.api.nvim_create_autocmd("ColorScheme", {
  group = yank_group,
  callback = set_yank_highlight,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = yank_group,
  callback = function()
    vim.hl.on_yank({ higroup = "YankFlash", timeout = 600 })
  end,
})
