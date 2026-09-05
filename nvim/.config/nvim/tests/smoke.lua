local source = debug.getinfo(1, "S").source

if source:sub(1, 1) ~= "@" then
	error("Cannot resolve the smoke test path", 0)
end

local test_file = source:sub(2)
local config_root = vim.fs.dirname(vim.fs.dirname(test_file))
local init_file = vim.fs.joinpath(config_root, "init.lua")
local conform_callback_test = vim.fs.joinpath(config_root, "tests", "conform-callback.lua")

local lua_files = vim.fs.find(function(name)
	return vim.endswith(name, ".lua")
end, {
	path = config_root,
	type = "file",
	limit = math.huge,
})

table.sort(lua_files)

if #lua_files == 0 then
	error("No Lua configuration files found under " .. config_root, 0)
end

for _, file in ipairs(lua_files) do
	local chunk, load_error = loadfile(file)

	if not chunk then
		error(string.format("Lua syntax error in %s:\n%s", file, load_error), 0)
	end
end

local stylua = vim.fn.exepath("stylua")

if stylua == "" then
	error("StyLua is not available on PATH", 0)
end

local formatting = vim.system({ stylua, "--check", config_root }, { text = true }):wait()

if formatting.code ~= 0 then
	error(string.format("StyLua check failed:\n%s%s", formatting.stdout or "", formatting.stderr or ""), 0)
end

local runtime_command = string.format("lua vim.opt.runtimepath:prepend(%q)", config_root)
local startup = vim.system({
	vim.v.progpath,
	"--headless",
	"-i",
	"NONE",
	"--cmd",
	runtime_command,
	"-u",
	init_file,
	"-c",
	"lua assert(vim.fn.exists(':TSInstallConfigured') == 2, 'TSInstallConfigured command is missing')",
	"-c",
	"lua assert(vim.fn.exists(':DapInstallAdapters') == 2, 'DapInstallAdapters command is missing')",
	"-c",
	"qa!",
}, { text = true }):wait()

if startup.code ~= 0 then
	error(string.format("Headless startup failed (exit %d):\n%s%s", startup.code, startup.stdout or "", startup.stderr or ""), 0)
end

local conform_callback = vim.system({
	vim.v.progpath,
	"--headless",
	"-i",
	"NONE",
	"--cmd",
	runtime_command,
	"-u",
	init_file,
	"-l",
	conform_callback_test,
}, { text = true }):wait()

if conform_callback.code ~= 0 then
	error(
		string.format("Conform callback test failed (exit %d):\n%s%s", conform_callback.code, conform_callback.stdout or "", conform_callback.stderr or ""),
		0
	)
end

print(string.format("Neovim smoke test passed: %d Lua files parsed", #lua_files))
vim.cmd("qa!")
