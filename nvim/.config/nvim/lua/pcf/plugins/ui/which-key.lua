-- https://github.com/folke/which-key.nvim
-- Useful plugin to show you pending keybinds.

-- Display keybinding information

return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  config = function()
    local which_key_ok, which_key = pcall(require, "which-key")

    if not which_key_ok then
      return
    end

    which_key.setup({})
    which_key.add({
      { "<leader>b", group = "Breakpoints" },
      { "<leader>c", group = "Change / comments" },
      { "<leader>cf", group = "Copy file" },
      { "<leader>d", group = "Delete" },
      { "<leader>e", group = "Diagnostics" },
      { "<leader>f", group = "Folds" },
      { "<leader>g", group = "Git" },
      { "<leader>gd", group = "Git diff" },
      { "<leader>h", group = "Buffers / files" },
      { "<leader>j", group = "Jump" },
      { "<leader>m", group = "Macros" },
      { "<leader>o", group = "Open" },
      { "<leader>p", group = "Paste" },
      { "<leader>q", group = "Quit" },
      { "<leader>r", group = "Refactor / Rust" },
      { "<leader>s", group = "Search" },
      { "<leader>t", group = "Tests" },
      { "<leader>u", group = "UI" },
      { "<leader>v", group = "Select" },
      { "<leader>w", group = "Windows" },
      { "<leader>ws", group = "Split" },
      { "<leader>x", group = "Dismiss" },
      { "<leader>y", group = "Yank" },
    })
  end,
}
