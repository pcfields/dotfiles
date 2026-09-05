-- https://github.com/mfussenegger/nvim-dap
-- https://github.com/rcarriga/nvim-dap-ui

return { -- Debugger
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		-- config = true runs mason.setup(), which initialises the package
		-- registry. Without it ensure_adapters below can only see packages that
		-- are already installed.
		{ "williamboman/mason.nvim", config = true },
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local map = require("pcf.utils").map

		dapui.setup()
		require("nvim-dap-virtual-text").setup({})

		-- mason-nvim-dap's ensure_installed silently does nothing against
		-- mason.nvim v2, so drive the registry directly instead.
		local function ensure_adapters(names)
			local ok, registry = pcall(require, "mason-registry")

			if not ok then
				return
			end

			registry.refresh(function()
				for _, name in ipairs(names) do
					-- not `package`: that name shadows Lua's standard library table
					local found, pkg = pcall(registry.get_package, name)

					if not found then
						-- Silently skipping here once hid a genuine misconfiguration
						-- for a whole stage, so say so loudly instead.
						vim.notify("DAP adapter not found in the Mason registry: " .. name, vim.log.levels.WARN)
					elseif not pkg:is_installed() then
						vim.notify("Installing DAP adapter: " .. name, vim.log.levels.INFO)
						pkg:install()
					end
				end
			end)
		end

		-- codelldb is picked up automatically by rustaceanvim
		ensure_adapters({ "js-debug-adapter", "codelldb", "netcoredbg" })

		require("pcf.dap.javascript").setup()
		require("pcf.dap.dotnet").setup()

		-- Keymaps
		map("n", "<F7>", dapui.toggle, { desc = "[Debugger] Toggle last session result" })
		map("n", "<F5>", dap.continue, { desc = "[Debugger] Continue" })
		map("n", "<F1>", dap.step_into, { desc = "[Debugger] Step into" })
		map("n", "<F2>", dap.step_over, { desc = "[Debugger] Step over" })
		map("n", "<F3>", dap.step_out, { desc = "[Debugger] Step out" })
		map("n", "<leader>db", dap.toggle_breakpoint, { desc = "[Debugger] Toggle breakpoint" })
		map("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "[Debugger] Set breakpoint condition" })

		-- Auto open/close dap-ui
		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end
	end,
}
