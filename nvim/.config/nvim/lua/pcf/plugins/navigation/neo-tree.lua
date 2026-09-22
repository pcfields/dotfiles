-- https://github.com/nvim-neo-tree/neo-tree.nvim

return { -- File explorer
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  config = function()
    local events = require("neo-tree.events")

    -- Tell the language servers about renamed/moved files so they update the
    -- imports that point at them (e.g. vtsls in TS/JS projects)
    local function on_move(data)
      require("snacks").rename.on_rename_file(data.source, data.destination)
    end

    require("neo-tree").setup({
      -- Navigate like mini.files: l goes in, h goes out, L opens and closes the
      -- tree. <cr> still opens, <bs> moves the root up, H toggles hidden files.
      window = {
        mappings = {
          ["l"] = "open", -- expand a folder / open a file (replaces focus_preview; P still toggles preview)
          ["h"] = "close_node", -- collapse the folder, or jump to and collapse the parent
          ["L"] = function(state)
            local node = state.tree:get_node()
            state.commands.open(state)
            if node.type == "file" then
              require("neo-tree.command").execute({ action = "close" })
            end
          end,
          ["g?"] = "show_help",
        },
      },
      event_handlers = {
        { event = events.FILE_MOVED, handler = on_move },
        { event = events.FILE_RENAMED, handler = on_move },
      },
      reveal = true,
      filesystem = {
        follow_current_file = {
          enabled = true, -- This will find and focus the file in the active buffer every time
          -- the current file is changed while the tree is open.
          leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
        },
      },
    })
  end,
}
