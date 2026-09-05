-- https://github.com/nvim-treesitter/nvim-treesitter
--
-- This tracks nvim-treesitter's `main` branch, which is a rewrite rather than an
-- evolution of `master`: setup() accepts only `install_dir`, and parser
-- installation, highlighting and indentation are each driven explicitly here.
--
-- The branch is pinned deliberately. Upstream renamed its default branch from
-- `master` to `main`, and an unpinned spec silently follows that rename -- at
-- which point a `master`-style config is accepted and then ignored, leaving no
-- parsers installed and no highlighting outside whatever another plugin happens
-- to start.
--
-- Requires the tree-sitter CLI (>= 0.26.1, not the npm build) and a C compiler
-- on PATH. Both are provisioned per platform:
--   Linux    nix/.config/nix/home.nix       -- tree-sitter, plus apt build-essential
--   Windows  packages/scoop-packages.txt    -- tree-sitter, plus a C toolchain
--   macOS    brew install tree-sitter, plus the Xcode command line tools

local PARSERS = {
  -- Web
  "css",
  "graphql",
  "html",
  "javascript",
  "json",
  "scss",
  "tsx",
  "typescript",
  -- Infrastructure and config
  "bash",
  "c_sharp",
  "dockerfile",
  "sql",
  "toml",
  "yaml",
  -- Languages
  "elixir",
  "elm",
  "erlang",
  "fsharp",
  "haskell",
  "heex",
  "lua",
  "python",
  "rust",
  "zig",
}

-- Treesitter indentation is still marked experimental upstream; where it is
-- worse than the built-in indentexpr, leave the built-in alone.
local INDENT_DISABLED = {
  python = true,
}

local TEXTOBJECTS = {
  { lhs = "af", query = "@function.outer", desc = "a function" },
  { lhs = "if", query = "@function.inner", desc = "inner function" },
  { lhs = "ac", query = "@class.outer", desc = "a class" },
  { lhs = "ic", query = "@class.inner", desc = "inner class" },
}

-- Attach treesitter to a buffer, if a parser for its filetype is installed.
local function start_treesitter(buf, filetype)
  if filetype == nil or filetype == "" then
    return
  end

  local lang = vim.treesitter.language.get_lang(filetype)

  if not lang then
    return
  end

  -- Fails when the parser is not installed yet, which is expected until
  -- :TSInstallConfigured completes.
  if not pcall(vim.treesitter.start, buf, lang) then
    return
  end

  if not INDENT_DISABLED[filetype] then
    vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

local function install_missing_parsers(nvim_treesitter)
  local installed = nvim_treesitter.get_installed()

  local missing = vim.tbl_filter(function(lang)
    return not vim.tbl_contains(installed, lang)
  end, PARSERS)

  if #missing == 0 then
    return
  end

  nvim_treesitter.install(missing):await(function()
    -- Buffers opened before the parser finished building never got a
    -- highlighter; attach one now rather than making the user restart.
    vim.schedule(function()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          start_treesitter(buf, vim.bo[buf].filetype)
        end
      end
    end)
  end)
end

local function setup_textobjects()
  local ok, textobjects = pcall(require, "nvim-treesitter-textobjects")

  if not ok then
    return
  end

  textobjects.setup({
    select = {
      lookahead = true,
    },
  })

  local map = require("pcf.utils").map

  for _, textobject in ipairs(TEXTOBJECTS) do
    map({ "x", "o" }, textobject.lhs, function()
      require("nvim-treesitter-textobjects.select").select_textobject(textobject.query, "textobjects")
    end, { desc = "Select " .. textobject.desc })
  end
end

return { -- Highlight, edit, and navigate code
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  -- Loaded eagerly so the FileType handler below is registered before any
  -- file buffer is created.
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local ok, nvim_treesitter = pcall(require, "nvim-treesitter")

    if not ok then
      return
    end

    nvim_treesitter.setup({})

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("pcf_treesitter", { clear = true }),
      callback = function(event)
        start_treesitter(event.buf, event.match)
      end,
    })

    vim.api.nvim_create_user_command("TSInstallConfigured", function()
      install_missing_parsers(nvim_treesitter)
    end, { desc = "Install missing configured Tree-sitter parsers" })

    setup_textobjects()

    require("nvim-ts-autotag").setup({})
  end,
}
