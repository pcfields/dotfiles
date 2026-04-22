# PowerShell profile - managed by dotfiles setup script
# This file should be symlinked/copied to $PROFILE (Microsoft.PowerShell_profile.ps1)

# Oh My Posh initialization (correct config path for theme)
oh-my-posh init pwsh --config "$HOME\.config\ohmyposh\omp-pcfields.json" | Invoke-Expression

# Import custom aliases/functions from dotfiles
. "$HOME\dotfiles\powershell\aliases.ps1"

# Optionally load a local, untracked file for private/work stuff
$private = "$HOME\dotfiles\powershell\local-private.ps1"
if (Test-Path $private) { . $private }
