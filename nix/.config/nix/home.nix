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
    rustup              # manages Rust toolchains (stable/nightly) — kept here because
                        # rustup is the industry standard and mise just wraps it anyway

    # --- Editor ---
    neovim              # latest from nixpkgs-unstable (0.12.x)

    # --- Terminal utilities ---
    ripgrep             # rg  — fast grep replacement
    fd                  # fast find replacement
    fzf                 # fuzzy finder
    bat                 # cat with syntax highlighting
    eza                 # modern ls replacement
    zoxide              # smarter cd
    jq                  # JSON processor
    yq                  # YAML/TOML/XML processor
    delta               # better git diffs
    tldr                # simplified man pages
    du-dust             # disk usage (dust)
    duf                 # disk free (modern df)
    procs               # modern ps replacement
    sd                  # sed alternative
    choose              # cut/awk alternative
    hyperfine           # benchmarking tool
    tokei               # count lines of code
    lazygit             # TUI for git
    tree                # directory tree view
    unzip
    xclip               # clipboard support
    httpie              # user-friendly HTTP client (http/https commands)
    shellcheck          # linter for bash/sh scripts

    # --- System & networking ---
    htop
    btop                # prettier htop alternative
    nmap
    lsof
    nethogs             # per-process bandwidth
    bandwhich           # bandwidth by process/connection
    mtr                 # traceroute + ping

    # --- Shell extras ---
    any-nix-shell       # proper nix-shell support for fish
  ];

  # ── Git ─────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    # Uncomment and set your identity:
    # userName = "Your Name";
    # userEmail = "you@example.com";
    delta.enable = true;           # use delta for diffs
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
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

  # ── direnv (auto-load .envrc / flake devshells) ─────────────────────
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;      # cached nix develop integration
  };

  # ── Environment variables ───────────────────────────────────────────
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
}
