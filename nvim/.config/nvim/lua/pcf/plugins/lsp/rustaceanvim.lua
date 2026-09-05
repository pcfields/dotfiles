-- https://github.com/mrcjkb/rustaceanvim
--
-- rust-analyzer speaks a number of LSP extensions that a plain client cannot
-- use: expanding macros, viewing HIR/MIR, discovering runnables, and reading
-- Cargo metadata. rustaceanvim wires those up, provides a neotest adapter for
-- `cargo test`, and configures nvim-dap against codelldb.
--
-- It attaches rust_analyzer itself, so `rust_analyzer` must NOT also appear in
-- the language_servers table in lsp-config.lua -- two clients on one buffer
-- means every diagnostic appears twice.
--
-- rust-analyzer comes from `rustup component add`, not Nix, so it stays
-- version-locked to the toolchain compiling the code (see install/install-rustup.sh).

return {
  "mrcjkb/rustaceanvim",
  version = "^6",
  -- The plugin registers its own filetype handling; lazy-loading it on `ft`
  -- is what upstream explicitly warns against.
  lazy = false,
  init = function()
    -- Must be set before the plugin loads, hence `init` rather than `config`.
    vim.g.rustaceanvim = {
      tools = {
        float_win_config = { border = "rounded" },
      },
      server = {
        ---@param client vim.lsp.Client
        ---@param bufnr integer
        on_attach = function(client, bufnr)
          local map = require("pcf.utils").map

          map("n", "<leader>ra", function()
            vim.cmd.RustLsp("codeAction")
          end, { desc = "[Rust] Code action", buffer = bufnr })

          map("n", "<leader>rr", function()
            vim.cmd.RustLsp("runnables")
          end, { desc = "[Rust] Runnables", buffer = bufnr })

          map("n", "<leader>rd", function()
            vim.cmd.RustLsp("debuggables")
          end, { desc = "[Rust] Debuggables", buffer = bufnr })

          map("n", "<leader>rm", function()
            vim.cmd.RustLsp("expandMacro")
          end, { desc = "[Rust] Expand macro", buffer = bufnr })

          map("n", "<leader>rc", function()
            vim.cmd.RustLsp("openCargo")
          end, { desc = "[Rust] Open Cargo.toml", buffer = bufnr })

          map("n", "<leader>re", function()
            vim.cmd.RustLsp("explainError")
          end, { desc = "[Rust] Explain error", buffer = bufnr })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              buildScripts = { enable = true },
            },
            -- Surface the same lints `cargo clippy` would, rather
            -- than the narrower default `cargo check`.
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            procMacro = { enable = true },
            inlayHints = {
              bindingModeHints = { enable = true },
              closureReturnTypeHints = { enable = "with_block" },
              lifetimeElisionHints = { enable = "skip_trivial" },
            },
          },
        },
      },
    }
  end,
}
