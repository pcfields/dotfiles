# PATH - add local bin for opencode, oh-my-posh, etc.
if not contains "$HOME/.local/bin" $PATH
    set -gx PATH "$HOME/.local/bin" $PATH
end
if not contains "$HOME/.opencode/bin" $PATH
    set -gx PATH "$HOME/.opencode/bin" $PATH
end

# Set SHELL for other terminals that respect it (cosmic-term, gnome-terminal, etc.)
set -gx SHELL (which fish)

if status is-interactive
    set -g fish_greeting
end

if test -f ~/.config/opencode/opencode.fish
    source ~/.config/opencode/opencode.fish
end

if command -q mise
    mise activate fish | source
end

if command -q zoxide
    zoxide init fish | source
end

if command -q fzf
    fzf --fish | source
end

if command -q oh-my-posh
    oh-my-posh init fish --config ~/.config/ohmyposh/base.json | source
end

alias vim='nvim'
alias ed='nvim'
alias g='git'
alias lg='lazygit'
alias ll='eza -la --icons=auto'
alias ls='eza --icons=auto'
alias cat='bat'
alias c='clear'
source /home/pcfields/.nix-profile/etc/profile.d/nix.fish
set -xa PATH /home/pcfields/.nix-profile/bin $PATH
