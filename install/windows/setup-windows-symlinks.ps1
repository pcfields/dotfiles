#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates symbolic links from the dotfiles repo to Windows config locations.

.DESCRIPTION
    Run this script once after cloning the dotfiles repo on a Windows machine.
    Must be run as Administrator (symlinks require elevated privileges).
    Automatically detects the real user profile even when run as a different admin account.

.EXAMPLE
    # From an elevated PowerShell prompt:
    .\scripts\setup-windows.ps1
#>

$ErrorActionPreference = "Stop"

$DotfilesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

# Detect the real (non-elevated) user by finding the owner of explorer.exe.
# When "Run as Administrator" is used from a normal user session, explorer.exe
# is still owned by the original user, so $HOME/$env:LOCALAPPDATA (which resolve
# to the admin account) are replaced with the real user's profile paths.
$realUserProfile = $null
$explorerProc = Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" |
    Select-Object -First 1
if ($explorerProc) {
    $ownerInfo = Invoke-CimMethod -InputObject $explorerProc -MethodName GetOwner
    $owner = [PSCustomObject]@{ ReturnValue = $ownerInfo.ReturnValue; User = $ownerInfo.User }
    if ($owner.ReturnValue -eq 0 -and $owner.User) {
        $candidate = "C:\Users\$($owner.User)"
        if (Test-Path $candidate) {
            $realUserProfile = $candidate
            Write-Host "Detected real user profile: $realUserProfile" -ForegroundColor Cyan
        }
    }
}
if (-not $realUserProfile) {
    $realUserProfile = $HOME
    Write-Host "Could not detect real user via explorer.exe; using `$HOME: $realUserProfile" -ForegroundColor Yellow
}
$realLocalAppData = Join-Path $realUserProfile "AppData\Local"
# Derive the real user's PowerShell profile path (CurrentUserAllHosts equivalent)
$realPSProfile = Join-Path $realUserProfile `
    "Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# Define symlink mappings: [target in dotfiles] -> [link location on Windows]
$Links = @(
    @{
        Source = Join-Path $DotfilesRoot "wezterm\.wezterm.lua"
        Target = Join-Path $realUserProfile ".wezterm.lua"
    },
    @{
        Source = Join-Path $DotfilesRoot "nvim\.config\nvim"
        Target = Join-Path $realLocalAppData "nvim"
    },
    @{
        Source = Join-Path $DotfilesRoot "ohmyposh\.config\ohmyposh"
        Target = Join-Path $realUserProfile ".config\ohmyposh"
    },
    @{
        Source = Join-Path $DotfilesRoot "opencode\.config\opencode"
        Target = Join-Path $realUserProfile ".config\opencode"
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

Write-Host "`nSymlinking PowerShell profile..." -ForegroundColor Green

# Powershell profile handling
$dotfilesProfile = Join-Path $DotfilesRoot "powershell\profile.ps1"
$powershellProfile = $realPSProfile
if (!(Test-Path $dotfilesProfile)) {
    Write-Warning "dotfiles PowerShell profile not found ($dotfilesProfile), skipping PowerShell profile setup."
} else {
    # Backup current $PROFILE if it exists and is not already a symlink to dotfiles
    if (Test-Path $powershellProfile) {
        $item = Get-Item $powershellProfile -Force
        $alreadySymlink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint
        $targetPointsToDotfiles = $alreadySymlink -and (Get-Item $powershellProfile).Target -eq $dotfilesProfile
        if (-not $targetPointsToDotfiles) {
            $backup = "$powershellProfile.bak"
            Write-Host "Backing up your existing PowerShell profile: $powershellProfile -> $backup" -ForegroundColor Yellow
            Move-Item -Path $powershellProfile -Destination $backup -Force
        }
    }
    # Ensure parent directory for profile exists
    $parentDir = Split-Path -Parent $powershellProfile
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }
    # Create symlink from dotfiles profile to $PROFILE
    if (Test-Path $powershellProfile) { Remove-Item $powershellProfile -Force }
    New-Item -ItemType SymbolicLink -Path $powershellProfile -Target $dotfilesProfile | Out-Null
    Write-Host "Symlinked PowerShell profile: $powershellProfile -> $dotfilesProfile" -ForegroundColor Green
}

Write-Host "`nSetup complete." -ForegroundColor Green
