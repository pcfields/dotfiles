return {
  "neovim/nvim-lspconfig",
  dependencies = {
    -- Catalogue of JSON/YAML schemas, so package.json, tsconfig.json,
    -- GitHub Actions workflows and docker-compose files are validated as you
    -- type rather than when CI rejects them.
    "b0o/SchemaStore.nvim",
  },
  config = function()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    -- Merge blink.cmp capabilities if available
    local blink_ok, blink = pcall(require, "blink.cmp")
    if blink_ok then
      capabilities = blink.get_lsp_capabilities(capabilities)
    end

    local schemastore_ok, schemastore = pcall(require, "schemastore")

    -- Server configurations using native Neovim 0.12 API.
    -- Every binary here comes from nix/.config/nix/home.nix on Linux, and from
    -- scoop or npm on Windows -- see packages/npm-global-packages.txt.
    local language_servers = {
      -- Web
      cssls = {},
      emmet_language_server = {},
      html = {},
      biome = {},
      eslint = {},
      graphql = {},

      tailwindcss = {
        -- lspconfig falls back to `.git` as a root marker (for Tailwind v4,
        -- where tailwind.config.* is optional). That starts a ~170 MB server in
        -- every repository, Tailwind or not. Real projects still announce
        -- themselves through package.json or a config file, so require one of
        -- those and drop the `.git` fallback.
        root_dir = function(bufnr, on_dir)
          local util = require("lspconfig.util")
          local fname = vim.api.nvim_buf_get_name(bufnr)

          local markers = {
            "tailwind.config.js",
            "tailwind.config.cjs",
            "tailwind.config.mjs",
            "tailwind.config.ts",
            "postcss.config.js",
            "postcss.config.cjs",
            "postcss.config.mjs",
            "postcss.config.ts",
          }

          -- package.json listing tailwindcss covers v3 and v4 alike
          markers = util.insert_package_json(markers, "tailwindcss", fname)
          -- Phoenix and Rails projects declare it in their lockfiles
          markers = util.root_markers_with_field(markers, { "mix.lock", "Gemfile.lock" }, "tailwind", fname)

          local found = vim.fs.find(markers, { path = fname, upward = true })[1]

          if found then
            on_dir(vim.fs.dirname(found))
          end
        end,
      },
      -- vtsls replaces ts_ls: better behaviour on monorepos and project
      -- references. Do not enable both, or every buffer gets two clients.
      vtsls = {},

      -- Infrastructure and config
      bashls = {},
      dockerls = {},
      taplo = {},

      -- .NET
      -- nvim-lspconfig's defaults already cover solution/project loading,
      -- inlay hints, code lens and decompiled-source navigation, so there is
      -- nothing to add here. Razor is the one gap; it needs seblyng/roslyn.nvim.
      roslyn_ls = {},
      -- lspconfig's defaults are FsAutoComplete's own recommended settings
      -- (linter, stub generation, unused-open analysis, code lens), so there
      -- is nothing worth overriding here.
      fsautocomplete = {},

      -- Runtimes managed by mise
      basedpyright = {},
      ruff = {},
      elixirls = {},
      elp = {},
      zls = {},

      -- Docs
      marksman = {},

      jsonls = {
        settings = {
          json = {
            schemas = schemastore_ok and schemastore.json.schemas() or nil,
            validate = { enable = true },
          },
        },
      },

      yamlls = {
        settings = {
          yaml = {
            -- SchemaStore supplies the catalogue; disabling the built-in
            -- store avoids the two fighting over the same files.
            schemaStore = { enable = false, url = "" },
            schemas = schemastore_ok and schemastore.yaml.schemas() or nil,
            validate = true,
          },
        },
      },

      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      },
    }

    -- Configure and enable each server using native API
    for server, config in pairs(language_servers) do
      vim.lsp.config(server, vim.tbl_extend("force", {
        capabilities = capabilities,
      }, config))
    end

    vim.lsp.enable(vim.tbl_keys(language_servers))
  end,
}
