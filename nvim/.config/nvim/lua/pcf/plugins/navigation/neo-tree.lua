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
