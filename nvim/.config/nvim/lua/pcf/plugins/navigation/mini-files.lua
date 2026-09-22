-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-files.md
-- Navigate and manipulate file system

return {
  "echasnovski/mini.files",
  version = "*",
  config = function()
    local map = require("pcf.utils").map

    require("mini.files").setup({})

    -- Tell the language servers about renamed/moved files so they update the
    -- imports that point at them (e.g. vtsls in TS/JS projects)
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("pcf_mini_files_rename", { clear = true }),
      pattern = { "MiniFilesActionRename", "MiniFilesActionMove" },
      callback = function(event)
        require("snacks").rename.on_rename_file(event.data.from, event.data.to)
      end,
    })

    map("n", "<leader>of", function()
      require("mini.files").open(vim.api.nvim_buf_get_name(0), true)
    end, { desc = "Open Mini Files" })
  end,
}
