# PowerShell aliases and functions to be version controlled
# Add new aliases/functions below. These are PUBLIC and versioned.

# Aliases
Set-Alias ll "ls -Force"
Set-Alias vim "nvim"
Set-Alias ed "nvim"
Set-Alias lg lazygit
Set-Alias pwdc Show-And-Copy-Current-Directory-Path
Set-Alias rmnode RemoveNodeModules

# Git command aliases (all real work done by functions below)
Set-Alias ggs GitStatus
Set-Alias ggp GitPull
Set-Alias ggc GitCommit
Set-Alias ggd GitSwitchDevelop
Set-Alias ggl GitSwitchLast
Set-Alias ggm GitSwitchMaster

# Set EDITOR
$env:EDITOR = "nvim"

# Generic Functions
function ll { Get-ChildItem -Force | Format-Table Mode, LastWriteTime, Length, Name }

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

function GitSwitchDevelop {
    Write-Host "Switching to the 'develop' branch..." -ForegroundColor Cyan
    & git switch develop
}
function GitSwitchMaster {
    Write-Host "Switching to the 'master' branch..." -ForegroundColor Cyan
    & git switch master
}
function GitSwitchLast {
    Write-Host "Switching to the 'last' branch..." -ForegroundColor Cyan
    & git switch -
}
function GitStatus {
    Write-Host "Checking the status of the current branch..." -ForegroundColor Cyan
    & git status $args
}
function GitCommit { & git commit -am $args }
function GitPull {
    Write-Host "Pulling the latest changes from the remote repository..." -ForegroundColor Cyan
    & git pull
}
