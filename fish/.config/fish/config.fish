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

alias gt='git'
alias gss='git status'
alias gct='git commit'
alias gph='git push'
alias gpl='git pull'
alias gdf='git diff'
alias glg='git log --oneline'

alias lg='lazygit'

alias ll='eza -la --icons=auto'
alias ls='eza --icons=auto'
alias la='eza -a --icons=auto'
alias lt='eza --tree --level=2'
alias l='eza -l --icons=auto'
alias lx='eza -la --sort=size'
alias lm='eza -la --sort=modified'

function sync
    cd ~/dotfiles && ./install.sh stow
end

function update-packages
    sudo apt update && sudo apt upgrade
end

function update-home
    cd ~/.config/nix && nix flake update && home-manager switch --flake .
end

function nix-check
    cd ~/.config/nix && nix flake update --dry-run
end

alias cat='bat'
alias c='clear'
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

source /home/pcfields/.nix-profile/etc/profile.d/nix.fish
set -xa PATH /home/pcfields/.nix-profile/bin $PATH
