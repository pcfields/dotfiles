# PowerShell aliases and functions to be version controlled
# Add new aliases/functions below. These are PUBLIC and versioned.

# Aliases
Set-Alias vim nvim
Set-Alias ed nvim
Set-Alias lg lazygit
Set-Alias gt git
Set-Alias gph git
Set-Alias gct 'git commit'
Set-Alias gss 'git status'
Set-Alias gdf git
Set-Alias cat bat
Set-Alias c Clear-Host
Set-Alias pwdc Show-And-Copy-Current-Directory-Path
Set-Alias rmnode RemoveNodeModules

# Set EDITOR
$env:EDITOR = "nvim"

# Functions for extended aliases/commands
function glg { git log --oneline @args }
function ls  { eza --icons=auto @args }
function la  { eza -a --icons=auto @args }
function lt  { eza --tree --level=2 @args }
function l   { eza -l --icons=auto @args }
function lx  { eza -la --sort=size @args }
function lm  { eza -la --sort=modified @args }

# Aliases previously defined to avoid duplication
# ll (included in functions)
function ll { eza -la --icons=auto @args }

# Git command aliases implemented as functions for custom logic
function gpl { git pull @args }
function ggs { git status @args }
function ggc { git commit -am @args }

function Show-And-Copy-Current-Directory-Path {
    $currentDirectory = Get-Location
    Set-Clipboard -Value $currentDirectory
    Write-Host "Current directory '$currentDirectory' copied to clipboard!" -ForegroundColor Cyan
}

function RemoveNodeModules {
    param (
        [string]$Path = ".\node_modules"
    )
    if (Test-Path $Path) {
        Remove-Item -Recurse -Force $Path
        Write-Host "Removed: $Path"
    } else {
        Write-Host "Path does not exist: $Path"
    }
}

# Optional: Safer versions of file commands
function rm { Remove-Item -Confirm $args }
function cp { Copy-Item -Confirm $args }
function mv { Move-Item -Confirm $args }
