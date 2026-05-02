{ config, pkgs, ... }:

{
  # ── Identity ────────────────────────────────────────────────────────
  # Update these to match your system user
  home.username = "pcfields";
  home.homeDirectory = "/home/pcfields";

  # Do not change — tracks Home Manager release compatibility
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  # ── Packages ────────────────────────────────────────────────────────
  home.packages = with pkgs; [

    # --- Programming languages & runtimes ---
    # Node.js, Python, Elixir, Zig are managed by mise (see ~/.config/mise/config.toml)
    # Rust is managed by rustup (see install/install-rustup.sh)

    # --- Editor ---
    neovim              # latest from nixpkgs-unstable (0.12.x)

    # --- LSP servers ---
    lua-language-server                 # lua_ls
    vscode-langservers-extracted        # jsonls, cssls, eslint, htmlls
    typescript-language-server          # ts_ls
    emmet-language-server               # emmet_language_server
    marksman                            # marksman (markdown)
    biome                               # biome (LSP + formatter/linter for JS/TS/JSON)

    # --- Formatters ---
    prettierd                           # prettierd (fast Prettier daemon)
    stylua                              # stylua (Lua formatter)

    # --- Treesitter ---
    tree-sitter                         # required by nvim-treesitter to compile parsers

    # --- Terminal utilities ---
    ripgrep             # rg  — fast grep replacement
    fd                  # fast find replacement
    fzf                 # fuzzy finder
    bat                 # cat with syntax highlighting
    eza                 # modern ls replacement
    yazi                # fast file navigator
    delta               # better git diffs
    lazygit             # TUI for git
  ];

   # ── Environment variables ───────────────────────────────────────────
   # These are used when no shell config sets them
   home.sessionVariables = {
     EDITOR = "nvim";
     VISUAL = "nvim";
   };
}
