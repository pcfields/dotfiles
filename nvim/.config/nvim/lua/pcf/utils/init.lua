local M = {}

function M.map(mode, lhs, rhs, opts)
  -- Initialize opts if it's not provided
  if opts == nil then
    opts = {}
  end

  -- Set default values for opts
  if opts.silent == nil then
    opts.silent = true
  end

  if opts.noremap == nil then
    opts.noremap = true
  end

  -- Create the mapping
  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.copy_file_path_to_clipboard()
  local filepath = vim.fn.expand("%:p")

  vim.fn.setreg("+", filepath)
end

function M.copy_file_name_to_clipboard()
  local filename = vim.fn.expand("%:t")

  vim.fn.setreg("+", filename)
end

-- Snacks.bufdelete keeps the window open (showing another buffer) and asks
-- whether to save when the buffer has unsaved changes.
function M.close_buffer_and_keep_split()
  require("snacks").bufdelete()
end

function M.is_windows_platform()
  return vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 -- return wezterm.target_triple == windows_platform
end

return M
