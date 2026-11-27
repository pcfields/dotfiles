-- The left and right status, through the update-status handlers.
local wezterm = require("wezterm")
local fakes = require("tests.fakes")
local colors = fakes.rose_pine

local cases, test = require("tests.cases")()

local function right(state)
	return fakes.strip(fakes.update_status(state).right)
end

test("the left status is the workspace badge", function(t)
	local window = fakes.update_status({ workspace = "dotfiles" })
	t.eq(fakes.strip(window.left), " " .. wezterm.nerdfonts.cod_layers .. " dotfiles    󰗘 ")
	t.eq(fakes.has_background(window.left, colors.iris), true, "iris badge")
end)

test("the badge turns gold while the leader is active", function(t)
	local window = fakes.update_status({ workspace = "dotfiles", leader = true })
	t.eq(fakes.has_background(window.left, colors.gold), true, "gold badge")
end)

test("the right status is empty when idle", function(t)
	t.eq(right({ workspace = "dotfiles" }), "")
end)

test("the right status shows LEADER", function(t)
	t.eq(right({ workspace = "dotfiles", leader = true }), "  LEADER ")
end)

test("the right status names known key tables and upper-cases others", function(t)
	t.eq(right({ workspace = "w", key_table = "split_panes" }), "  SPLIT ")
	t.eq(right({ workspace = "w", key_table = "copy_mode" }), "  COPY ")
	t.eq(right({ workspace = "w", key_table = "my_table" }), "  MY_TABLE ")
end)

test("the right status shows zoom and the pane count", function(t)
	t.eq(right({ workspace = "w", panes = { { is_zoomed = true }, {}, {} } }), "  ZOOM 3 panes ")
end)

test("with two workspaces only the next one is shown", function(t)
	t.eq(right({ workspace = "a", workspace_names = { "a", "b" } }), "  󰇙 b 󰅂 (2) ")
end)

test("with three workspaces the neighbours wrap around", function(t)
	t.eq(right({ workspace = "a", workspace_names = { "a", "b", "c" } }), "  󰅁 c 󰇙 b 󰅂 (3) ")
end)

test("long workspace names keep their last 20 columns", function(t)
	local long = "edocs.site.platform.landingpage"
	t.eq(right({ workspace = "a", workspace_names = { "a", long } }), "  󰇙 …latform.landingpage 󰅂 (2) ")
end)

test("sections sit in separate boxes, left to right", function(t)
	local state = { workspace = "a", leader = true, panes = { {}, {} }, workspace_names = { "a", "b" } }
	t.eq(right(state), "  LEADER   2 panes   󰇙 b 󰅂 (2) ")
end)

test("rendering the status bar logs no errors", function(t, loaded)
	t.eq(#loaded.errors, 0, "errors: " .. table.concat(loaded.errors, "; "))
end)

return cases
