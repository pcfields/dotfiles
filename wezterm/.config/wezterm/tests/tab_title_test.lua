-- Tab titles, through the format-tab-title handler.
local fakes = require("tests.fakes")
local colors = fakes.rose_pine

local cases, test = require("tests.cases")()

test("a shell tab is named after its directory", function(t)
	local items = fakes.format_tab({ title = "~/dotfiles", process = "/usr/bin/fish", cwd = "/home/me/dotfiles" })
	t.eq(fakes.plain(items), " 1: dotfiles ")
end)

test("the tab number is iris and the active title is text colored", function(t)
	local items = fakes.format_tab({ title = "~/dotfiles", process = "/usr/bin/fish", cwd = "/home/me/dotfiles" })
	t.eq(fakes.color_of(items, " 1:"), colors.iris, "number")
	t.eq(fakes.color_of(items, " dotfiles "), colors.text, "title")
end)

test("an inactive title is muted, and subtle on hover", function(t)
	local fields = { title = "~/x", process = "fish", cwd = "/home/me/x", is_active = false }
	t.eq(fakes.color_of(fakes.format_tab(fields), " x "), colors.muted, "idle")
	fields.hover = true
	t.eq(fakes.color_of(fakes.format_tab(fields), " x "), colors.subtle, "hover")
end)

test("the number follows the tab index", function(t)
	local items = fakes.format_tab({ index = 2, title = "~/x", process = "fish", cwd = "/home/me/x" })
	t.eq(fakes.plain(items), " 3: x ")
end)

test("a title set on the tab wins", function(t)
	local items = fakes.format_tab({ tab_title = "notes", title = "nvim", process = "nvim", cwd = "/home/me/x" })
	t.eq(fakes.plain(items), " 1: notes ")
end)

test("a tool's own title drops the leading location", function(t)
	local items = fakes.format_tab({ title = "dotfiles - lazygit", process = "lazygit", cwd = "/home/me/dotfiles" })
	t.eq(fakes.plain(items), " 1: lazygit ")
end)

test("a tool launched through pwsh is named by its title", function(t)
	local items = fakes.format_tab({
		title = "lazygit",
		process = "C:\\Program Files\\PowerShell\\7\\pwsh.exe",
		cwd = "C:\\Users\\me\\repo",
	})
	t.eq(fakes.plain(items), " 1: lazygit ")
end)

test("fish's `<command> <cwd>` title names the running tool", function(t)
	local items = fakes.format_tab({ title = "nvim ~/dotfiles", process = "/usr/bin/nvim", cwd = "/home/me/dotfiles" })
	t.eq(fakes.plain(items), " 1: nvim ")
end)

test("a Windows console path title falls back to the directory", function(t)
	local items = fakes.format_tab({ title = "C:\\Windows\\system32\\cmd.exe", process = "cmd.exe", cwd = "C:\\Users\\me\\" })
	t.eq(fakes.plain(items), " 1: me ")
end)

test("a shell with no directory is named after the shell", function(t)
	local items = fakes.format_tab({ title = "pwsh", process = "pwsh.exe" })
	t.eq(fakes.plain(items), " 1: pwsh ")
end)

test("a title matching the directory name is treated as the default", function(t)
	local items = fakes.format_tab({ title = "Repo", process = "/usr/bin/htop", cwd = "/home/me/repo" })
	t.eq(fakes.plain(items), " 1: htop ")
end)

test("a split tab shows one pip per pane", function(t)
	local items = fakes.format_tab({ title = "~/x", process = "fish", cwd = "/x", panes = { {}, {}, {} } })
	t.eq(fakes.plain(items), " 1: x ▪▪▪ ")
	t.eq(fakes.color_of(items, "▪▪▪ "), colors.subtle, "pip color")
end)

test("pips stop at four and the rest collapse into +", function(t)
	local items = fakes.format_tab({ title = "~/x", process = "fish", cwd = "/x", panes = { {}, {}, {}, {}, {}, {} } })
	t.eq(fakes.plain(items), " 1: x ▪▪▪▪+ ")
end)

test("a zoomed tab shows ZOOM in love before the pips", function(t)
	local items = fakes.format_tab({ title = "~/x", process = "fish", cwd = "/x", panes = { { is_zoomed = true }, {} } })
	t.eq(fakes.plain(items), " 1: x ZOOM ▪▪ ")
	t.eq(fakes.color_of(items, "ZOOM "), colors.love, "zoom color")
end)

test("only the title is truncated, never the number or markers", function(t)
	local items = fakes.format_tab({
		title = "~/a-very-long-directory-name",
		process = "fish",
		cwd = "/a-very-long-directory-name",
		panes = { { is_zoomed = true }, {} },
		max_width = 12,
	})
	t.eq(fakes.plain(items), " 1: ZOOM ▪▪ ")
end)

return cases
