-- https://github.com/MeanderingProgrammer/render-markdown.nvim
--
-- Renders headings, checkboxes, tables and callouts in the buffer. Needs the
-- bundled `markdown` and `markdown_inline` tree-sitter parsers.

return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    file_types = { "markdown" },
  },
}
