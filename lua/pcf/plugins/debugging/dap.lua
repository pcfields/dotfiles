-- https://github.com/mfussenegger/nvim-dap
-- https://github.com/jay-babu/mason-nvim-dap.nvim
-- https://github.com/rcarriga/nvim-dap-ui

return { -- Debugger
	"mfussenegger/nvim-dap",
	dependencies = {
		"rcarriga/nvim-dap-ui",
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
		"mxsdev/nvim-dap-vscode-js",
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local map = require("pcf.utils").map

		require("dapui").setup()
		require("nvim-dap-virtual-text").setup({})

		-- Setup mason-nvim-dap to auto-install debug adapters
		require("mason-nvim-dap").setup({
			ensure_installed = {
				"js-debug-adapter",
			},
			automatic_installation = true,
			handlers = {},
		})

		-- Setup nvim-dap-vscode-js to configure JS/TS debug adapters
		require("dap-vscode-js").setup({
			debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
			adapters = { "pwa-node", "pwa-chrome", "pwa-msedge" },
		})

		-- Helper function to get port from package.json or prompt user
		local function get_dev_server_port()
			local package_json_path = vim.fn.getcwd() .. "/package.json"
			local default_port = "3000"

			if vim.fn.filereadable(package_json_path) == 1 then
				local ok, package_data = pcall(vim.fn.json_decode, vim.fn.readfile(package_json_path))
				if ok and package_data.scripts then
					for _, script in pairs(package_data.scripts) do
						local port = script:match("%-%-port[=%s]+(%d+)") or script:match("PORT[=%s]+(%d+)")
						if port then
							default_port = port
							break
						end
					end
				end
			end

			local port = vim.fn.input("Dev server port: ", default_port)
			return port ~= "" and port or default_port
		end

		-- Helper to add a browser config to both JSX and TSX filetypes
		local function add_browser_config(config)
			table.insert(dap.configurations.javascriptreact, config)
			table.insert(dap.configurations.typescriptreact, config)
		end

		-- Node configurations
		dap.configurations.javascript = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
			},
		}

		dap.configurations.typescript = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch file",
				program = "${file}",
				cwd = "${workspaceFolder}",
				sourceMaps = true,
				protocol = "inspector",
				console = "integratedTerminal",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach",
				processId = require("dap.utils").pick_process,
				cwd = "${workspaceFolder}",
				sourceMaps = true,
			},
		}

		-- React configurations inherit Node configs as base
		dap.configurations.javascriptreact = dap.configurations.javascript
		dap.configurations.typescriptreact = dap.configurations.typescript

		-- Browser configs: Edge (dynamic port), Edge (static ports), Chrome (dynamic), Chrome (static)
		local browsers = {
			{ type = "pwa-msedge", label = "Edge", runtimeExecutable = "/usr/bin/microsoft-edge" },
			{ type = "pwa-chrome", label = "Chrome" },
		}

		for _, browser in ipairs(browsers) do
			-- Dynamic port (prompts user)
			add_browser_config({
				type = browser.type,
				request = "launch",
				name = "Launch " .. browser.label .. " for React",
				url = function()
					return "http://localhost:" .. get_dev_server_port()
				end,
				webRoot = "${workspaceFolder}",
				sourceMaps = true,
				runtimeExecutable = browser.runtimeExecutable,
			})

			-- Static port shortcuts
			for _, port in ipairs({ "3000", "5173" }) do
				add_browser_config({
					type = browser.type,
					request = "launch",
					name = "Launch " .. browser.label .. " (port " .. port .. ")",
					url = "http://localhost:" .. port,
					webRoot = "${workspaceFolder}",
					sourceMaps = true,
					runtimeExecutable = browser.runtimeExecutable,
				})
			end
		end

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
