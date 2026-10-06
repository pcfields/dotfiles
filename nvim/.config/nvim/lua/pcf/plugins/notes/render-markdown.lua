-- https://github.com/MeanderingProgrammer/render-markdown.nvim
--
-- Renders headings, checkboxes, tables and callouts in the buffer. Needs the
-- bundled `markdown` and `markdown_inline` tree-sitter parsers.
--
-- Headings are plain: numbered icons, no bar, and one colour (the theme's
-- Title) for every level instead of one colour per level.

local LEVELS = 6

local function apply_heading_highlights()
  local title = vim.api.nvim_get_hl(0, { name = "Title", link = false })
  local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  local fg = title.fg or normal.fg

  vim.api.nvim_set_hl(0, "PcfMdHeading", { fg = fg })
  for level = 1, LEVELS do
    vim.api.nvim_set_hl(0, "@markup.heading." .. level .. ".markdown", { fg = fg, bold = level <= 2 })
  end
end

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
    heading = {
      signs = {},
      backgrounds = {},
      foregrounds = { "PcfMdHeading" },
    },
    bullet = {
      highlight = "Comment",
    },
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    apply_heading_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("PcfMarkdownHeadings", { clear = true }),
      callback = apply_heading_highlights,
    })
  end,
}
