local Snacks = require("snacks")

local M = {}

local function enter_normal_mode()
	vim.api.nvim_input("<Esc>")
end

M.ViewOpenBuffers = function()
	Snacks.picker.buffers()
	enter_normal_mode()
end

M.SearchGrep = function()
	Snacks.picker.grep()
end

M.SearchFiles = function()
	Snacks.picker.files()
end

M.SearchGitFiles = function()
	Snacks.picker.git_files()
end

M.SearchRecentFiles = function()
	Snacks.picker.recent()
end

M.SearchGrepWord = function()
	Snacks.picker.grep_word()
end

M.GitFileLog = function()
	Snacks.picker.git_log_file()
end

M.OpenLazyGit = function()
	Snacks.lazygit()
end

M.GitLogHistory = function()
	Snacks.picker.git_log()
end

M.GitStatus = function()
	Snacks.picker.git_status()
end

M.GitDiffList = function()
	Snacks.picker.git_diff()
end

M.ListGitBranches = function()
	Snacks.picker.git_branches()
end

M.SearchHelpPages = function()
	Snacks.picker.help()
end

M.GotoDefinition = function()
	Snacks.picker.lsp_definitions()
end

M.GotoImplementation = function()
	Snacks.picker.lsp_implementations()
end

M.SearchDiagnosticsBuffer = function()
	Snacks.picker.diagnostics_buffer({
		layout = "vertical",
	})
end

M.SearchAllDiagnostics = function()
	Snacks.picker.diagnostics({
		layout = "vertical",
	})
end

M.GotoReferences = function()
	Snacks.picker.lsp_references()
end

M.ListLSPSymbols = function()
	Snacks.picker.lsp_symbols()
end

M.GotoTypeDefinition = function()
	Snacks.picker.lsp_type_definitions()
end

M.SearchMarks = function()
	Snacks.picker.marks()
end

M.SearchJumps = function()
	Snacks.picker.jumps()
end

M.DisplayRegisters = function()
	Snacks.picker.registers()
end

M.Explorer = function()
	Snacks.explorer()
end

M.ToggleTerminal = function()
	Snacks.terminal.toggle()
end

M.TodoComments = function()
	Snacks.picker.todo_comments()
end

M.Notifications = function()
	Snacks.picker.notifications()
end

return M
