-- [[ Basic Keymaps ]]
local pcf_utils = require("pcf.utils")
local utils_treesitter = require("pcf.utils.treesitter")
local utils_macros = require("pcf.utils.macros")

local map = pcf_utils.map
local copy_file_path_to_clipboard = pcf_utils.copy_file_path_to_clipboard
local copy_file_name_to_clipboard = pcf_utils.copy_file_name_to_clipboard
local close_buffer_and_keep_split = pcf_utils.close_buffer_and_keep_split
local execute_command_on_enclosing_node = utils_treesitter.execute_command_on_enclosing_node
local play_macro = utils_macros.play_macro
local record_macro = utils_macros.record_macro

-- How copy, delete and paste work in this config:
--   * y, d, c, x and p are left as Neovim's defaults. They use Neovim's own
--     internal register, never the system clipboard, because the 'clipboard'
--     option is deliberately left unset. Deleting text in Neovim therefore
--     cannot overwrite something copied in another app.
--   * The system clipboard is only read or written through the explicit
--     <leader>yc / <leader>dc / <leader>pc mappings below.
--   * '"+' is Neovim's name for the system clipboard register.
local clipboard_register = '"+'

--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Clear search with <esc>
map({ "i", "n", "v" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
map({ "n" }, "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>", { desc = "Redraw / clear hlsearch / diff update" })

-- Search word under cursor
map({ "n", "x" }, "gw", "*N", { desc = "Search word under cursor" })

map({ "n" }, "<leader>xn", "<cmd>Noice dismiss<cr>", { desc = "Dismiss all notifications" })

--------------------------------------------------------------------------------------------
-- Files  -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
map("i", "<leader><leader>", "<esc>", { desc = "Exit insert mode" })

map({ "n" }, "<leader>ss", "/", { desc = "Search", silent = false })

--------------------------------------------------------------------------------------------
-- Copy
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>cfn", copy_file_name_to_clipboard, { desc = "Copy filename to clipboard" })
map({ "n" }, "<leader>cfp", copy_file_path_to_clipboard, { desc = "Copy file path to clipboard" })

--------------------------------------------------------------------------------------------
-- Delete and paste
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>de", "d$", { desc = "Delete to end of line" })

-- After a delete, plain `p` pastes the deleted text (Neovim default).
-- Register 0 always holds the last *yank* and deletes never overwrite it, so
-- this pastes what you copied even if you deleted something since.
map({ "n", "v" }, "<leader>py", '"0p', { desc = "Paste last yank (ignores deletes)" })

--------------------------------------------------------------------------------------------
-- Clipboard copy, delete and paste
--------------------------------------------------------------------------------------------
-- Normal and visual mode need separate mappings: in normal mode the command is
-- doubled to act on the whole line (yy, dd), while in visual mode a single y/d
-- acts on the selection. A doubled command in visual mode would act on the
-- selection and then leave a second operator waiting for a motion.

-- Copy to the clipboard, e.g. to paste into another app
map({ "n" }, "<leader>yc", clipboard_register .. "yy", { desc = "Copy line to clipboard" })
map({ "v" }, "<leader>yc", clipboard_register .. "y", { desc = "Copy selection to clipboard" })

-- Paste from the clipboard, e.g. text copied in another app
map({ "n", "v" }, "<leader>pc", clipboard_register .. "p", { desc = "Paste from clipboard" })

-- Cut: delete the text and put it on the clipboard
map({ "n" }, "<leader>dc", clipboard_register .. "dd", { desc = "Cut line to clipboard" })
map({ "v" }, "<leader>dc", clipboard_register .. "d", { desc = "Cut selection to clipboard" })

--------------------------------------------------------------------------------------------
-- File explorer -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>ow", "<cmd>Neotree toggle reveal float<cr>", { desc = "Open Neo-tree floating window" })
map({ "n" }, "<leader>oe", "<cmd>Neotree toggle reveal current<cr>", { desc = "Open Neo-tree in current window" })
map({ "n" }, "<leader>og", "<cmd>Neotree git_status<cr>", { desc = "Open Neo-tree Git status" })

--------------------------------------------------------------------------------------------
-- Buffers ----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

map({ "n", "v", "s" }, "<leader>hs", "<cmd>w<cr><esc>", { desc = "Save buffer" })
map({ "n", "v", "s" }, "<leader>ha", "<cmd>wa<cr><esc>", { desc = "Save all buffers" })

map({ "n" }, "<leader>hn", "<cmd>enew<cr>", { desc = "New buffer(file)" })
map({ "n" }, "<leader>hq", close_buffer_and_keep_split, { desc = "Close buffer and keep split" })
map({ "n" }, "<leader>ho", [[:%bdelete|edit #|bdelete #<CR>]], { desc = "Close all buffers except current one" })
map({ "n" }, "<leader>hx", "<cmd>close<cr>", { desc = "Close current split" })
map({ "n" }, "<leader>hy", ":%y+<CR>", { desc = "Copy all text in buffer to clipboard" })
map({ "n" }, "<leader>hb", "gg<S-v>G", { desc = "Select all text in buffer" })

map({ "n" }, "<C-l>", "<cmd>e #<cr>", { desc = "Switch to last used buffer" })
map({ "n" }, "<C-j>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map({ "n" }, "<C-k>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })

--------------------------------------------------------------------------------------------
-- Windows ---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-- Move to window using the <ctrl> hjkl keys
map({ "n" }, "<leader>wh", "<C-w>h", { desc = "Go to left window" })
map({ "n" }, "<leader>wj", "<C-w>j", { desc = "Go to lower window" })
map({ "n" }, "<leader>wk", "<C-w>k", { desc = "Go to upper window" })
map({ "n" }, "<leader>wl", "<C-w>l", { desc = "Go to right window" })

-- Split windows
map({ "n" }, "<leader>wsj", "<C-w>s", { desc = "Split window below" })
map({ "n" }, "<leader>wsl", "<C-w>v", { desc = "Split window right" })
map({ "n" }, "<leader>wq", "<C-w>c", { desc = "Delete window" })
map({ "n" }, "<leader>wn", "<C-w>n", { desc = "Create new window" })

-- Resize windows 50/50
map({ "n" }, "<leader>ww", "<C-w>=", { desc = "Resize windows to be 50|50" })

--------------------------------------------------------------------------------------------
-- Resize ---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
map({ "n" }, "<C-Up>", "<cmd>resize +4<cr>", { desc = "Increase window height" })
map({ "n" }, "<C-Down>", "<cmd>resize -4<cr>", { desc = "Decrease window height" })
map({ "n" }, "<C-Left>", "<cmd>vertical resize +4<cr>", { desc = "Increase window width" })
map({ "n" }, "<C-Right>", "<cmd>vertical resize -4<cr>", { desc = "Decrease window width" })

--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>qa", "<cmd>qa<cr>", { desc = "Quit all and close Neovim" })
map({ "n" }, "<leader>qq", "<cmd>q<cr>", { desc = "Quit" })

--------------------------------------------------------------------------------------------
-- Line movement ---------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

map({ "n" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Move up one line and manage word wrap", expr = true })
map({ "n" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Move down one line and manage word wrap", expr = true })
map({ "n" }, "n", "nzz", { desc = "Go to next and center cursor in middle of screen" })
map({ "n" }, "N", "Nzz", { desc = "Go to previous and center cursor in middle of screen" })
map({ "n" }, "*", "*zz", { desc = "Search forward for the word under the cursor and center cursor in middle of screen" })
map({ "n" }, "#", "#zz", { desc = "Search backward and center cursor in middle of screen" })
map({ "n" }, "g*", "g*zz", { desc = "Search forward for the word under the cursor and center cursor in middle of screen" })
map({ "n" }, "g#", "g#zz", { desc = "Search backward and center cursor in middle of screen" })

--------------------------------------------------------------------------------------------
-- Horizontal line movement
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>jh", "^", { desc = "Go to beginning of line" })
map({ "n", "v" }, "<leader>jl", "$", { desc = "Go to end of line" })
map({ "n", "v" }, "<leader>jb", "%", { desc = "Jump to the next matching bracket" })

--------------------------------------------------------------------------------------------
-- Vertical line movement
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>ju", "gg", { desc = "Jump to top of buffer" })
map({ "n", "v" }, "<leader>jm", "<S-g>", { desc = "Jump to bottom of buffer" })

--------------------------------------------------------------------------------------------
-- Move line down
--------------------------------------------------------------------------------------------
map({ "n" }, "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })

--------------------------------------------------------------------------------------------
-- Move line up
--------------------------------------------------------------------------------------------
map({ "n" }, "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })
-- TODO: testing
--------------------------------------------------------------------------------------------
-- Terminal
--------------------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    local buf = 0

    map("t", "<A-i>", [[<C-\><C-n>]], { desc = "Exit terminal mode", buffer = buf })
    map("t", "<A-w>", [[<C-\><C-n><C-w>]], { desc = "Exit terminal mode and enter window command mode", buffer = buf })

    map("t", "<A-h>", [[<Cmd>wincmd h<CR>]], { desc = "Move to left window", buffer = buf })
    map("t", "<A-j>", [[<Cmd>wincmd j<CR>]], { desc = "Move to lower window", buffer = buf })
    map("t", "<A-k>", [[<Cmd>wincmd k<CR>]], { desc = "Move to upper window", buffer = buf })
    map("t", "<A-l>", [[<Cmd>wincmd l<CR>]], { desc = "Move to right window", buffer = buf })
  end,
})

--------------------------------------------------------------------------------------------
-- Open things -----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
map({ "n" }, "<C-p>", "<cmd>:Lazy<cr>", { desc = "Open Lazy Plugin Manager" })
map({ "n" }, "<leader>gv", "<cmd>::DiffviewOpen<cr>", { desc = "Open Git diff view" })
map({ "n" }, "<leader>gx", "<cmd>::DiffviewClose<cr>", { desc = "Close Git diff view" })
--------------------------------------------------------------------------------------------
-- Diagnostics (Errors)  --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- Go to next diagnostic
map({ "n" }, "<leader>jn", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Jump to next diagnostic message" })

-- Go to previous diagnostic
map({ "n" }, "<leader>jp", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Jump to previous diagnostic message" })

map({ "n" }, "<leader>ei", vim.diagnostic.open_float, { desc = "Open floating diagnostic info message" })

map("n", "<leader>es", function()
  local toggled_value = not vim.diagnostic.config().virtual_text

  vim.diagnostic.config({ virtual_text = toggled_value })
end, { desc = "Toggle diagnostic virtual_text ([s]how)" })

map({ "n" }, "<leader>et", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Trouble: Buffer diagnostics" })
map({ "n" }, "<leader>eT", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble: All diagnostics" })

--------------------------------------------------------------------------------------------
-- Folding ----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>ft", "za", { desc = "Toggle fold under cursor" })

--------------------------------------------------------------------------------------------
-- Yank keymaps
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>ye", "y$", { desc = "Yank till end of line" })

-- The inside/around mappings below (yank, delete, select, change) find the
-- nearest enclosing brackets or quotes with treesitter, so you don't have to
-- type which one: <leader>di on `f(a, b)` runs `di(`, inside "text" it runs
-- `di"`. They use the default register like plain y/d/c.
local brackets_or_strings_text = " (...) or [...] or {...} or strings"

map({ "n", "v" }, "<leader>yi", function()
  execute_command_on_enclosing_node("yi")
end, { desc = "Yank inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>ya", function()
  execute_command_on_enclosing_node("ya")
end, { desc = "Yank around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Delete Inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>di", function()
  execute_command_on_enclosing_node("di")
end, { desc = "Delete inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>da", function()
  execute_command_on_enclosing_node("da")
end, { desc = "Delete around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Select inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>vi", function()
  execute_command_on_enclosing_node("vi")
end, { desc = "Select inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>va", function()
  execute_command_on_enclosing_node("va")
end, { desc = "Select around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Change inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>ci", function()
  execute_command_on_enclosing_node("ci")
end, { desc = "Change inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>ca", function()
  execute_command_on_enclosing_node("ca")
end, { desc = "Change around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Macros  --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

map({ "n" }, "<leader>mp", play_macro, { desc = "Play a macro from a specified register" })
map({ "n" }, "<leader>mr", record_macro, { desc = "Record a macro in a specified register" })
