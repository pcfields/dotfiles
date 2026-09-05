-- https://github.com/Samsung/netcoredbg
--
-- Debug configurations for .NET. Registered for both `cs` and `fsharp`, since
-- the two compile to the same runtime and debug identically.

local M = {}

local function adapter_command()
	local bin = vim.fn.stdpath("data") .. "/mason/bin/netcoredbg"

	if require("pcf.utils").is_windows_platform() then
		bin = bin .. ".cmd"
	end

	return bin
end

-- .NET debugging launches a built DLL rather than a source file, so the path
-- has to be discovered. Prefer a single obvious candidate under bin/Debug and
-- only ask when the guess is ambiguous.
local function find_target_dll()
	local cwd = vim.fn.getcwd()
	local candidates = vim.fs.find(function(name, path)
		return name:match("%.dll$") ~= nil and path:match("[/\\]bin[/\\]Debug[/\\]") ~= nil
	end, { path = cwd, type = "file", limit = math.huge })

	-- Project output shares the directory name with the project, which filters
	-- out the dependency DLLs copied alongside it.
	local project_name = vim.fn.fnamemodify(cwd, ":t")
	local likely = vim.tbl_filter(function(path)
		return vim.fn.fnamemodify(path, ":t:r") == project_name
	end, candidates)

	if #likely == 1 then
		return likely[1]
	end

	local default = likely[1] or candidates[1] or (cwd .. "/bin/Debug/")

	return vim.fn.input("Path to dll: ", default, "file")
end

function M.setup()
	local ok, dap = pcall(require, "dap")

	if not ok then
		return
	end

	dap.adapters.coreclr = {
		type = "executable",
		command = adapter_command(),
		args = { "--interpreter=vscode" },
	}

	local configurations = {
		{
			type = "coreclr",
			name = "Launch project",
			request = "launch",
			program = find_target_dll,
			cwd = "${workspaceFolder}",
			stopAtEntry = false,
		},
		{
			type = "coreclr",
			name = "Attach to process...",
			request = "attach",
			processId = require("dap.utils").pick_process,
			cwd = "${workspaceFolder}",
		},
	}

	dap.configurations.cs = configurations
	-- deepcopy, not assignment: sharing the table would let a later insert on
	-- one filetype silently mutate the other.
	dap.configurations.fsharp = vim.deepcopy(configurations)
end

return M
