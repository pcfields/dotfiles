-- https://github.com/folke/snacks.nvim
--
--

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	config = function()
		local u = require("pcf.plugins.ui.snacks-utils")
		local map = require("pcf.utils").map
		local snacks = require("snacks")

		snacks.setup({
			animate = { enabled = true },
			bigfile = { enabled = true },
			dashboard = { enabled = true },
			dim = { enabled = true },
			indent = { enabled = true },
			lazygit = { enabled = true },
			input = { enabled = true },
			notify = { enabled = true },
			notifier = { enabled = true },
			quickfile = { enabled = true },
			statuscolumn = { enabled = true },
			terminal = { enabled = true },
			words = { enabled = true },
			picker = {},
			scope = { enabled = true },
		})

		-- Buffers
		map({ "n", "v" }, "<leader>hv", u.ViewOpenBuffers, { desc = "View Open Buffers" })

		-- Search
		map({ "n", "v" }, "<leader>se", u.SearchGrep, { desc = "Search everywhere using Grep" })
		map({ "n", "v" }, "<leader>sf", u.SearchFiles, { desc = "Search Files" })
		map({ "n", "v" }, "<leader>sg", u.SearchGitFiles, { desc = "Search Git Files" })
		map({ "n", "v" }, "<leader>sr", u.SearchRecentFiles, { desc = "Search Recent Files" })
		map({ "n", "v" }, "<leader>sw", u.SearchGrepWord, { desc = "Search selection or word" })
		map({ "n", "v" }, "<leader>sh", u.SearchHelpPages, { desc = "Search Help Pages" })

		-- Git
		map({ "n", "v" }, "<leader>gl", u.GitFileLog, { desc = "Git File Log" })
		map({ "n", "v" }, "<leader>gg", u.OpenLazyGit, { desc = "LazyGit" })
		map({ "n", "v" }, "<leader>gh", u.GitLogHistory, { desc = "Git Log History" })
		map({ "n", "v" }, "<leader>gs", u.GitStatus, { desc = "Git Status" })
		map({ "n", "v" }, "<leader>gdl", u.GitDiffList, { desc = "Git Diff list" })
		map({ "n", "v" }, "<leader>gb", u.ListGitBranches, { desc = "List Git Branches" })

		-- [LSP] Jump to
		map({ "n", "v" }, "<leader>jd", u.GotoDefinition, { desc = "Goto Definition" })
		map({ "n", "v" }, "<leader>ji", u.GotoImplementation, { desc = "Goto Implementation" })
		map({ "n", "v" }, "<leader>jt", u.GotoTypeDefinition, { desc = "Goto T[y]pe Definition" })
		map({ "n", "v" }, "<leader>jr", u.GotoReferences, { desc = "Goto References", nowait = true })

		-- Lists
		map({ "n", "v" }, "<leader>ef", u.SearchDiagnosticsBuffer, { desc = "Search Diagnostics" })
		map({ "n", "v" }, "<leader>ea", u.SearchAllDiagnostics, { desc = "Search All Diagnostics" })

		-- Open
		map({ "n", "v" }, "<leader>os", u.ListLSPSymbols, { desc = "Open LSP Symbols" })
		map({ "n", "v" }, "<leader>om", u.SearchMarks, { desc = "Open Marks" })
		map({ "n", "v" }, "<leader>oj", u.SearchJumps, { desc = "Open Jumps" })
		map({ "n", "v" }, "<leader>or", u.DisplayRegisters, { desc = "Open Registers" })
		map({ "n", "v" }, "<leader>oh", vim.lsp.buf.hover, { desc = "Hover Documentation" })
		map({ "n", "v" }, "<leader>ot", u.TodoComments, { desc = "Open Todo Comments" })
		map({ "n", "v" }, "<leader>on", u.Notifications, { desc = "Open Notification History" })

		map({ "n", "v" }, "<A-o>", u.ToggleTerminal, { desc = "Toggle Terminal" })

		-- NOTE: review Snacks Explorer to see if it can replace neo-tree
		map({ "n", "v" }, "<leader>fs", u.Explorer, { desc = "Open File Explorer [ Sidebar ]" })
	end,
}
