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

  # ── Git ─────────────────────────────────────────────────────────────
  # Git config is in Nix for delta integration and defaults
  programs.git = {
    enable = true;
    delta.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      core.editor = "nvim";
    };
  };

  # ── fzf ─────────────────────────────────────────────────────────────
  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [ "--height=40%" "--layout=reverse" "--border" ];
  };

  # ── bat ─────────────────────────────────────────────────────────────
  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  # ── Environment variables ───────────────────────────────────────────
  # These are used when no shell config sets them
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
