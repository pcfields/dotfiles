return {
  "neovim/nvim-lspconfig",
  dependencies = {
    { "williamboman/mason.nvim", config = true },
    { "saghen/blink.cmp" },
  },
  config = function()
    local capabilities = require("blink.cmp").get_lsp_capabilities(
      vim.lsp.protocol.make_client_capabilities()
    )

    -- Server configurations using native Neovim 0.12 API
    local language_servers = {
      marksman = {},
      jsonls = {},
      cssls = {},
      ts_ls = {},
      eslint = {},
      emmet_ls = {},
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
