#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates symbolic links from the dotfiles repo to Windows config locations.

.DESCRIPTION
    Run this script once after cloning the dotfiles repo on a Windows machine.
    Must be run as Administrator (symlinks require elevated privileges).

.EXAMPLE
    # From an elevated PowerShell prompt:
    .\scripts\setup-windows.ps1
#>

$ErrorActionPreference = "Stop"

$DotfilesRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

# Define symlink mappings: [target in dotfiles] -> [link location on Windows]
$Links = @(
    @{
        Source = Join-Path $DotfilesRoot "wezterm\.wezterm.lua"
        Target = Join-Path $HOME ".wezterm.lua"
    },
    @{
        Source = Join-Path $DotfilesRoot "nvim\.config\nvim"
        Target = Join-Path $env:LOCALAPPDATA "nvim"
    },
    @{
        Source = Join-Path $DotfilesRoot "ohmyposh\.config\ohmyposh"
        Target = Join-Path $HOME ".config\ohmyposh"
    }
)

foreach ($Link in $Links) {
    $source = $Link.Source
    $target = $Link.Target

    # Verify source exists
    if (-not (Test-Path $source)) {
        Write-Warning "Source not found, skipping: $source"
        continue
    }

    # If target already exists
    if (Test-Path $target) {
        $item = Get-Item $target -Force
        if ($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "Symlink already exists: $target -> $source" -ForegroundColor Yellow
            continue
        }

        # Back up existing config
        $backup = "$target.backup"
        Write-Host "Backing up existing config: $target -> $backup" -ForegroundColor Cyan
        Move-Item -Path $target -Destination $backup -Force
    }

    # Ensure parent directory exists
    $parentDir = Split-Path -Parent $target
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Create symlink (works for both files and directories)
    New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null

    Write-Host "Linked: $target -> $source" -ForegroundColor Green
}

Write-Host "`nSetup complete." -ForegroundColor Green
