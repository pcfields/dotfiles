<#
.SYNOPSIS
    Links each shared agent skill into ~/.claude/skills.

.DESCRIPTION
    Windows twin of install/install-agent-links.sh. Run it after adding,
    renaming or removing a skill in agents\.agents\skills. Uses directory
    junctions, which need no elevation, so a normal prompt is enough.

    Links per skill, not the whole folder, because Claude Code keeps its own
    entries (synced, .trash) in ~/.claude/skills. Removes links into the shared
    skills folder whose skill no longer exists; leaves everything else alone.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File install\windows\link-agent-skills.ps1
#>
param(
    # setup-windows-symlinks.ps1 passes the real user's profile when elevated.
    [string]$UserProfile = $HOME
)

$ErrorActionPreference = "Stop"

function Test-IsLink($item) {
    [bool]($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint)
}

# Windows PowerShell 5.1 returns Target as an array; PowerShell 7 as a string.
function Get-LinkTarget($item) {
    @($item.Target)[0]
}

function Test-SamePath($a, $b) {
    $a -and $b -and ($a.TrimEnd('\') -ieq $b.TrimEnd('\'))
}

$DotfilesRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$sharedSkills = Join-Path $DotfilesRoot "agents\.agents\skills"
$claudeSkills = Join-Path $UserProfile ".claude\skills"

if (-not (Test-Path $sharedSkills)) {
    throw "Missing $sharedSkills"
}

# A directory link here (from an older setup script) would send the links below
# into the repo. Get-Item, not Test-Path, so a dangling one is still found.
$existing = Get-Item $claudeSkills -Force -ErrorAction SilentlyContinue
if ($existing -and (Test-IsLink $existing)) {
    Write-Host "Removing old directory link: $claudeSkills" -ForegroundColor Cyan
    $existing.Delete()
}
New-Item -ItemType Directory -Path $claudeSkills -Force | Out-Null

$skills = Get-ChildItem $sharedSkills -Directory
foreach ($skill in $skills) {
    $dest = Join-Path $claudeSkills $skill.Name
    $item = Get-Item $dest -Force -ErrorAction SilentlyContinue

    if ($item -and -not (Test-IsLink $item)) {
        Write-Warning "Skipping $dest (exists and is not a link)"
        continue
    }
    if ($item -and (Test-SamePath (Get-LinkTarget $item) $skill.FullName)) {
        continue
    }
    if ($item) { $item.Delete() }

    New-Item -ItemType Junction -Path $dest -Target $skill.FullName | Out-Null
    Write-Host "Linked: $dest -> $($skill.FullName)" -ForegroundColor Green
}

foreach ($item in Get-ChildItem $claudeSkills -Force | Where-Object { Test-IsLink $_ }) {
    $target = Get-LinkTarget $item
    $intoShared = $target -and (Test-SamePath (Split-Path -Parent $target) $sharedSkills)
    if ($intoShared -and -not (Test-Path $target)) {
        $item.Delete()
        Write-Host "Removed dangling link: $($item.FullName)" -ForegroundColor Cyan
    }
}

Write-Host "Linked $($skills.Count) skills into $claudeSkills. Run /reload-skills or start a new Claude Code session to pick them up." -ForegroundColor Green
