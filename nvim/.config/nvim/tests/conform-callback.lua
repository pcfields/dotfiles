local buffer = vim.api.nvim_create_buf(true, true)
vim.api.nvim_set_current_buf(buffer)
vim.bo[buffer].filetype = "lua"
vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "local value={1,2}" })
vim.api.nvim_exec_autocmds("BufNewFile", { buffer = buffer })

local notifications = {}
local original_notify = vim.notify

vim.notify = function(message)
  table.insert(notifications, message)
end

local keys = vim.api.nvim_replace_termcodes("<leader>hf", true, false, true)
vim.api.nvim_feedkeys(keys, "xt", false)
vim.notify = original_notify

assert(vim.tbl_contains(notifications, "Formatted"), "Manual formatting must notify after editing the buffer")

vim.api.nvim_buf_delete(buffer, { force = true })
