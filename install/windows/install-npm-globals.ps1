# Install Node-based developer tooling that has no scoop manifest.
#
# These ship as npm packages rather than standalone binaries, so scoop cannot
# provide them. On Linux the equivalent tools come from Nix; this script is the
# Windows counterpart. See packages/npm-global-packages.txt.

Write-Host "=== Global npm tooling setup ==="

# Node comes from mise (installed by install-scoop.ps1)
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  Write-Host "Error: npm not found on PATH."
  Write-Host "Install Node first:  mise use --global node@22"
  exit 1
}

$pkgList = Join-Path $PSScriptRoot "..\..\packages\npm-global-packages.txt"
if (-not (Test-Path $pkgList)) {
  Write-Host "Error: $pkgList not found."
  exit 1
}

# Same parsing rules as install-scoop.ps1 and lib/common.sh
$pkgs = Get-Content $pkgList |
  ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
  Where-Object { $_ -ne '' }

foreach ($pkg in $pkgs) {
  Write-Host ("Installing: $pkg")
  npm install -g $pkg
}

Write-Host ""
Write-Host "=== Global npm tooling complete ==="
Write-Host "Verify a server resolves, e.g.:  where.exe vtsls"
Write-Host "If Neovim reports a server failing to start, see docs/install-windows.md"
