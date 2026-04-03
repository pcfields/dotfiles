-- https://github.com/mfussenegger/nvim-dap
-- https://github.com/jay-babu/mason-nvim-dap.nvim
-- https://github.com/rcarriga/nvim-dap-ui

return { -- Debugger
	"mfussenegger/nvim-dap",
	dependencies = { -- Creates a beautiful debugger UI
		"rcarriga/nvim-dap-ui", -- Installs the debug adapters for you
		"williamboman/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim", -- Add your own debuggers here
		"theHamsta/nvim-dap-virtual-text",
		"nvim-neotest/nvim-nio",
		"williamboman/mason.nvim",
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
				"js-debug-adapter", -- JavaScript/TypeScript debugger
			},
			automatic_installation = true,
			handlers = {}, -- Use default handlers
		})

		-- Setup nvim-dap-vscode-js to configure JS/TS debug adapters
		require("dap-vscode-js").setup({
			debugger_path = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter",
			adapters = { "pwa-node", "pwa-chrome", "pwa-msedge" },
		})

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

	-- React configurations (uses same adapter as JavaScript/TypeScript)
	dap.configurations.javascriptreact = dap.configurations.javascript
	dap.configurations.typescriptreact = dap.configurations.typescript

	-- Helper function to get port from package.json or prompt user
	local function get_dev_server_port()
		local package_json_path = vim.fn.getcwd() .. "/package.json"
		local default_port = "3000"

		-- Try to read port from package.json scripts
		if vim.fn.filereadable(package_json_path) == 1 then
			local ok, package_data = pcall(vim.fn.json_decode, vim.fn.readfile(package_json_path))
			if ok and package_data.scripts then
				-- Look for common dev script patterns with port
				for _, script in pairs(package_data.scripts) do
					local port = script:match("%-%-port[=%s]+(%d+)")
					if not port then
						port = script:match("PORT[=%s]+(%d+)")
					end
					if port then
						default_port = port
						break
					end
				end
			end
		end

		-- Prompt user with detected/default port
		local port = vim.fn.input("Dev server port: ", default_port)
		return port ~= "" and port or default_port
	end

	-- Add browser debugging for React with dynamic port
	table.insert(dap.configurations.javascriptreact, {
		type = "pwa-msedge",
		request = "launch",
		name = "Launch Edge for React",
		url = function()
			local port = get_dev_server_port()
			return "http://localhost:" .. port
		end,
		webRoot = "${workspaceFolder}",
		sourceMaps = true,
		runtimeExecutable = "/usr/bin/microsoft-edge",
	})

	table.insert(dap.configurations.typescriptreact, {
		type = "pwa-msedge",
		request = "launch",
		name = "Launch Edge for React",
		url = function()
			local port = get_dev_server_port()
			return "http://localhost:" .. port
		end,
		webRoot = "${workspaceFolder}",
		sourceMaps = true,
		runtimeExecutable = "/usr/bin/microsoft-edge",
	})

	-- Add static port options for Edge (default browser)
	local common_ports = { "3000", "5173" }
	for _, port in ipairs(common_ports) do
		table.insert(dap.configurations.javascriptreact, {
			type = "pwa-msedge",
			request = "launch",
			name = "Launch Edge (port " .. port .. ")",
			url = "http://localhost:" .. port,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			runtimeExecutable = "/usr/bin/microsoft-edge",
		})

		table.insert(dap.configurations.typescriptreact, {
			type = "pwa-msedge",
			request = "launch",
			name = "Launch Edge (port " .. port .. ")",
			url = "http://localhost:" .. port,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
			runtimeExecutable = "/usr/bin/microsoft-edge",
		})
	end

	-- Add Chrome as fallback option (after Edge options)
	table.insert(dap.configurations.javascriptreact, {
		type = "pwa-chrome",
		request = "launch",
		name = "Launch Chrome for React",
		url = function()
			local port = get_dev_server_port()
			return "http://localhost:" .. port
		end,
		webRoot = "${workspaceFolder}",
		sourceMaps = true,
	})

	table.insert(dap.configurations.typescriptreact, {
		type = "pwa-chrome",
		request = "launch",
		name = "Launch Chrome for React",
		url = function()
			local port = get_dev_server_port()
			return "http://localhost:" .. port
		end,
		webRoot = "${workspaceFolder}",
		sourceMaps = true,
	})

	for _, port in ipairs(common_ports) do
		table.insert(dap.configurations.javascriptreact, {
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (port " .. port .. ")",
			url = "http://localhost:" .. port,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		})

		table.insert(dap.configurations.typescriptreact, {
			type = "pwa-chrome",
			request = "launch",
			name = "Launch Chrome (port " .. port .. ")",
			url = "http://localhost:" .. port,
			webRoot = "${workspaceFolder}",
			sourceMaps = true,
		})
	end
		-- toggle to see last session result. Without this ,you can't see session output in case of unhandled exception.
		map("n", "<F7>", dapui.toggle, { desc = "[Debugger] Toggle last session result" })

		-- Basic debugging keymaps, feel free to change to your liking!
		map("n", "<F5>", dap.continue, { desc = "[Debugger] Continue" })
		map("n", "<F1>", dap.step_into, { desc = "[Debugger] Step into" })
		map("n", "<F2>", dap.step_over, { desc = "[Debugger] Step over" })
		map("n", "<F3>", dap.step_out, { desc = "[Debugger] Step out" })

		map("n", "<leader>db", dap.toggle_breakpoint, { desc = "[Debugger] Toggle breakpoint" })
		map("n", "<leader>dB", function()
			dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
		end, { desc = "[Debugger] Set breakpoint condition" })

		-- Setup dap listeners
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
