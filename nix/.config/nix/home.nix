{ config, lib, pkgs, ... }:

{
  # ── Identity ────────────────────────────────────────────────────────
  # Update these to match your system user
  home.username = "pcfields";
  home.homeDirectory = "/home/pcfields";

  # Do not change — tracks Home Manager release compatibility
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # Postman is unfree; keep the exception limited to this package.
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "postman"
    ];

  # ── Packages ────────────────────────────────────────────────────────
  home.packages = with pkgs; [

    # --- Programming languages & runtimes ---
    # Node.js, Python, Elixir, Zig are managed by mise (see ~/.config/mise/config.toml)
    # Rust is managed by rustup (see install/install-rustup.sh)

    # --- Editor ---
    neovim              # latest from nixpkgs-unstable (0.12.x)

    # --- LSP servers: web ---
    lua-language-server                 # lua_ls
    vscode-langservers-extracted        # jsonls, cssls, eslint, htmlls
    vtsls                               # vtsls -- replaces ts_ls; better on monorepos
    emmet-language-server               # emmet_language_server
    tailwindcss-language-server         # tailwindcss
    graphql-language-service-cli        # graphql
    marksman                            # marksman (markdown)
    biome                               # biome (LSP + formatter/linter for JS/TS/JSON)

    # --- LSP servers: infrastructure and config ---
    bash-language-server                # bashls (uses shellcheck below when present)
    yaml-language-server                # yamlls
    dockerfile-language-server-nodejs   # dockerls
    taplo                               # taplo (TOML LSP + formatter)

    # --- LSP servers: .NET ---
    # roslyn-ls ships bin/Microsoft.CodeAnalysis.LanguageServer, which is the
    # first name nvim-lspconfig's roslyn_ls config looks for. It resolves the
    # `dotnet` runtime from PATH, which mise provides.
    roslyn-ls                           # roslyn_ls (C#)
    csharpier                           # C# formatter

    # --- LSP servers: runtimes managed by mise ---
    basedpyright                        # basedpyright (Python types)
    ruff                                # ruff (Python lint + format, also an LSP)
    elixir-ls                           # elixirls
    erlang-language-platform            # elp (Erlang, lspconfig calls it `elp`)
    zls                                 # zls (Zig)

    # --- Formatters and linters ---
    prettierd                           # prettierd (fast Prettier daemon)
    stylua                              # stylua (Lua formatter)
    shfmt                               # shfmt (shell formatter)
    shellcheck                          # shell linter; bash-language-server uses it
    sqlfluff                            # SQL linter and formatter

    # --- Database clients ---
    sqlite                              # sqlite3
    postgresql                          # psql (client; the server is unused here)

    # --- Treesitter ---
    tree-sitter                         # tree-sitter CLI (>= 0.26.1); nvim-treesitter's
                                        # main branch shells out to it to build parsers

    # --- Terminal utilities ---
    ripgrep             # rg  — fast grep replacement
    fd                  # fast find replacement
    fzf                 # fuzzy finder
    bat                 # cat with syntax highlighting
    eza                 # modern ls replacement
    yazi                # fast file navigator
    delta               # better git diffs
    lazygit             # TUI for git
    gh                  # GitHub CLI

    # --- API development --
    postman
    insomnia
  ];

   # ── Environment variables ───────────────────────────────────────────
   # These are used when no shell config sets them
   home.sessionVariables = {
     EDITOR = "nvim";
     VISUAL = "nvim";
   };
}
