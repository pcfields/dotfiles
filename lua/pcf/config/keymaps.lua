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

-- NOTE: I am using 'z' register for yanking and pasting
local yank_register = '"z'
local clipboard_register = '"+'
local delete_register = '"x'

--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
map({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Clear search with <esc>
map({ "i", "n", "v" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Clear search, diff update and redraw
map({ "n" }, "<leader>ur", "<Cmd>nohlsearch<Bar>diffupdate<Bar>normal! <C-L><CR>",
	{ desc = "Redraw / clear hlsearch / diff update" })

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
-- Overwrite default yank and paste to use z register
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "y", yank_register .. "y", { desc = "Yank to [" .. yank_register .. "] register" })
map({ "n", "v" }, "p", yank_register .. "p", { desc = "Paste from [" .. yank_register .. "] register" })
map({ "n", "v" }, "d", delete_register .. "d", { desc = "Delete and copy to [" .. delete_register .. "] register" })

--------------------------------------------------------------------------------------------
-- Copy, delete and paste
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>dy", yank_register .. "dd", { desc = "Delete and copy to [" .. yank_register .. "] register" })
map({ "n", "v" }, "<leader>de", delete_register .. "d$", { desc = "Delete to end of line" })
map({ "n", "v" }, "<leader>pd", delete_register .. "p", { desc = "Paste from [" .. delete_register .. "] register" })

--------------------------------------------------------------------------------------------
-- Clipboard copy, delete and paste
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>yc", clipboard_register .. "yy", { desc = "Copy to clipboard" })
map({ "n", "v" }, "<leader>pc", clipboard_register .. "p", { desc = "Paste from clipboard" })
map({ "n", "v" }, "<leader>dc", clipboard_register .. "dd", { desc = "Delete and copy to clipboard" })

--------------------------------------------------------------------------------------------
-- File explorer -----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
map({ "n" }, "<leader>fw", "<cmd>Neotree toggle reveal float<cr>", { desc = "Open File explorer [ floating window ] " })
map({ "n" }, "<leader>ft", "<cmd>Neotree toggle reveal current<cr>", { desc = "Open File explorer  [ tab ]" })
map({ "n" }, "<leader>fg", "<cmd>Neotree git_status<cr>", { desc = "Open File explorer [ git status ] " })

--------------------------------------------------------------------------------------------
-- Buffers ----------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

map({ "n", "v", "s" }, "<leader>hs", "<cmd>w<cr><esc>", { desc = "Save buffer" })
map({ "n", "v", "s" }, "<leader>ha", "<cmd>wa<cr><esc>", { desc = "Save all buffers" })

map({ "n" }, "<leader>hn", "<cmd>enew<cr>", { desc = "New buffer(file)" })
map({ "n" }, "<leader>hq", close_buffer_and_keep_split, { desc = "Close buffer and keep split" })
map({ "n" }, "<leader>ho", [[:%bdelete|edit #|bdelete #<CR>]], { desc = "Close all buffers except current one" })
map({ "n" }, "<leader>hx", "<cmd>:close<cr>", { desc = "Close split window" })

map({ "n" }, "<leader>hy", ":%y+<CR>", { desc = "Copy all text in buffer to clipboard" })
map({ "n" }, "<C-a>", "gg<S-v>G", { desc = "Select all text in buffer" })

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
map({ "n" }, "<leader>qw", "<cmd>qa<cr>", { desc = "Quit all, Close Neovim" })
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
map({ "n" }, "g*", "g*zz",
	{ desc = "Search forward for the word under the cursor and center cursor in middle of screen" })
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
		map("t", "<A-w>", [[<C-\><C-n><C-w>]],
			{ desc = "Exit terminal mode and enter window command mode", buffer = buf })

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
map({ "n" }, "<leader>oc", "<cmd>CopilotChatToggle<cr>", { desc = "Toggle CopilotChat window" })

--------------------------------------------------------------------------------------------
-- Diagnostics (Errors)  --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
-- Go to next diagnostic
map({ "n" }, "<leader>ej", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })

-- Go to previous diagnostic
map({ "n" }, "<leader>ek", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })

map({ "n" }, "<leader>ei", vim.diagnostic.open_float, { desc = "Open floating diagnostic info message" })

map("n", "<leader>es", function()
	local toggled_value = not vim.diagnostic.config().virtual_text

	vim.diagnostic.config({ virtual_text = toggled_value })
end, { desc = "Toggle diagnostic virtual_text ([s]how)" })

map({ "n" }, "<leader>oef", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Trouble: File/buffer issues" })
map({ "n" }, "<leader>oea", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Trouble: All open File/buffer issues" })

--------------------------------------------------------------------------------------------
-- Refactor  --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--
map({ "n" }, "<leader>rn", vim.lsp.buf.rename, { desc = "Refactor: Rename variable" })

--------------------------------------------------------------------------------------------
-- Code actions --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
---
map({ "n" }, "<leader>ka", vim.lsp.buf.code_action, { desc = "Code action" })
map({ "n" }, "<leader>kf", "za", { desc = "Toggle fold under cursor" })

--------------------------------------------------------------------------------------------
-- Yank keymaps
--------------------------------------------------------------------------------------------
--
map({ "n", "v" }, "<leader>ye", yank_register .. "y$", { desc = "Yank till end of line" })

local brackets_or_strings_text = " (...) or [...] or {...} or strings"

map({ "n", "v" }, "<leader>yi", function()
	local command_yank_inside_to_register_z = yank_register .. "yi"

	execute_command_on_enclosing_node(command_yank_inside_to_register_z)
end, { desc = "Yank inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>ya", function()
	local command_yank_around_to_register_z = yank_register .. "ya"

	execute_command_on_enclosing_node(command_yank_around_to_register_z)
end, { desc = "Yank around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Delete Inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>di", function()
	local command_delete_inside_save_to_delete_register = delete_register .. "di"

	execute_command_on_enclosing_node(command_delete_inside_save_to_delete_register)
end, { desc = "Delete inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>da", function()
	local command_delete_around_save_to_delete_register = delete_register .. "da"

	execute_command_on_enclosing_node(command_delete_around_save_to_delete_register)
end, { desc = "Delete around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Select inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>vi", function()
	local command_select_inside = "vi"

	execute_command_on_enclosing_node(command_select_inside)
end, { desc = "Select inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>va", function()
	local command_select_around = "va"

	execute_command_on_enclosing_node(command_select_around)
end, { desc = "Select around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Change inside and around keymaps
--------------------------------------------------------------------------------------------
map({ "n", "v" }, "<leader>ci", function()
	local command_change_inside_save_to_delete_register = delete_register .. "ci"

	execute_command_on_enclosing_node(command_change_inside_save_to_delete_register)
end, { desc = "Change inside " .. brackets_or_strings_text })

map({ "n", "v" }, "<leader>ca", function()
	local command_change_around_save_to_delete_register = delete_register .. "ca"

	execute_command_on_enclosing_node(command_change_around_save_to_delete_register)
end, { desc = "Change around " .. brackets_or_strings_text })

--------------------------------------------------------------------------------------------
-- Macros  --------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

map({ "n" }, "<leader>pm", play_macro, { desc = "Play a macro from a specified register" })
map({ "n" }, "<leader>rm", record_macro, { desc = "Record a macro in a specified register" })
