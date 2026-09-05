-- https://github.com/stevearc/conform.nvim

return { -- Code formatting
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		local save_settings = {
			lsp_format = "fallback",
			async = false,
			timeout_ms = 10000,
		}

		-- On Windows, a global npm install writes both a bare shell script and a
		-- .cmd wrapper. Neovim can spawn the .cmd but not the bare shim, so prefer
		-- it when present. This is a property of npm itself, not of whichever tool
		-- manages Node -- it applied under Volta and still applies under mise.
		-- See packages/npm-global-packages.txt.
		local prettier_cmd = "prettier"
		if vim.fn.has("win32") == 1 then
			local cmd_path = vim.fn.exepath("prettier.cmd")
			if cmd_path ~= "" then
				prettier_cmd = "prettier.cmd"
			end
		end

		conform.setup({
			notify_on_error = true,
			formatters_by_ft = {
				javascript = { "biome", "prettier", stop_after_first = true },
				typescript = { "biome", "prettier", stop_after_first = true },
				javascriptreact = { "biome", "prettier", stop_after_first = true },
				typescriptreact = { "biome", "prettier", stop_after_first = true },
				css = { "prettier" },
				json = { "biome", "prettier", stop_after_first = true },
				yaml = { "prettier" },
				html = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
			},
			formatters = {
				prettier = { command = prettier_cmd },
			},
			format_on_save = save_settings,
		})

		require("pcf.utils").map({ "n", "v" }, "<leader>hf", function()
			conform.format(vim.tbl_extend("force", save_settings, {
				callback = function(err, did_edit)
					if err then
						vim.notify("Format error: " .. err, vim.log.levels.ERROR)
					elseif did_edit then
						vim.notify("Formatted", vim.log.levels.INFO)
					end
				end,
			}))
		end, { desc = "Format file or range (in visual mode)" })

		require("pcf.utils").map({ "n" }, "<leader>hi", function()
			local formatters = conform.list_formatters()
			if #formatters == 0 then
				vim.notify("No formatters configured for this file type", vim.log.levels.WARN)
				return
			end
			local lines = {}
			for _, f in ipairs(formatters) do
				local status = f.available and "✓" or "✗"
				local info = status .. " " .. f.name
				if f.available_msg then
					info = info .. " (" .. f.available_msg .. ")"
				end
				table.insert(lines, info)
			end
			vim.notify("Formatters:\n" .. table.concat(lines, "\n"), vim.log.levels.INFO)
		end, { desc = "Show formatters for current buffer" })
	end,
}
