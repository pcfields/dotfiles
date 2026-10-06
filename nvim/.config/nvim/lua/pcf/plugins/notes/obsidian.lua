-- https://github.com/obsidian-nvim/obsidian.nvim
--
-- Knowledge-base workflow over a plain-markdown vault, read on GitHub from the
-- phone (the Obsidian app is not used). Links are standard markdown links with
-- relative paths so GitHub renders them; wikilinks would show as plain text.
-- Keymaps live in config/keymaps.lua under <leader>n; the `cmd`/`ft` triggers
-- below lazy-load the plugin on first use.
--
-- Override the vault location with $NOTES_VAULT (e.g. on Windows).

local VAULT_PATH = vim.env.NOTES_VAULT or "~/ws/personal/personal-notebook"

-- "My Article" -> "my-article" so filenames need no URL escaping in links.
-- Falls back to a timestamp when no title is given.
local function note_id(title)
  if title == nil or title == "" then
    return tostring(os.date("%Y%m%d%H%M%S"))
  end

  local id = title:lower():gsub("[^%w%s-]", ""):gsub("%s+", "-"):gsub("-+", "-"):gsub("^-", ""):gsub("-$", "")

  return id
end

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  cmd = "Obsidian",
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "personal", path = VAULT_PATH },
    },
    note_id_func = note_id,
    link = { style = "markdown", format = "relative" },
    picker = { name = "snacks.picker" },
    templates = {
      folder = "templates",
    },
    attachments = {
      folder = "attachments",
    },
    -- render-markdown.nvim owns in-buffer rendering
    ui = { enable = false },
    -- Articles, not daily notes: keep new notes at the vault root; organise with links and index notes.
    new_notes_location = "current_dir",
  },
}
