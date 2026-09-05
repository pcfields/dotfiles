-- Install package manager ----------------------------------
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	if vim.fn.executable("git") ~= 1 then
		error("Cannot bootstrap lazy.nvim: Git is not available on PATH", 0)
	end

	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})

	if vim.v.shell_error ~= 0 then
		error(string.format("Failed to bootstrap lazy.nvim (Git exit %d):\n%s", vim.v.shell_error, vim.trim(output)), 0)
	end
end

vim.opt.rtp:prepend(lazypath)

local status_ok, lazy = pcall(require, "lazy")
if not status_ok then
	error(string.format("Failed to load lazy.nvim from %s:\n%s", lazypath, lazy), 0)
end

return lazy
