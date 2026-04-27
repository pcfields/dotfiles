# Install Scoop, buckets, and all CLI tools needed for dotfiles on Windows

# Exit on error
echo "=== Scoop + Dotfiles Core Tools Setup ==="

# Check for Scoop
$scoopDir = "$env:USERPROFILE\scoop"
if (-not (Test-Path $scoopDir)) {
  Write-Host "Scoop not found. Installing..."
  iwr -useb get.scoop.sh | iex
} else {
  Write-Host "Scoop is already installed."
}

# Add buckets
$neededBuckets = @("extras", "nerd-fonts", "versions")
foreach ($bucket in $neededBuckets) {
  if (-not (scoop bucket list | Select-String $bucket)) {
    scoop bucket add $bucket
  }
}

# Install packages
$pkgList = Join-Path $PSScriptRoot "..\..\packages\scoop-packages.txt"
if (-not (Test-Path $pkgList)) {
  Write-Host "Error: $pkgList not found."
  exit 1
}

$pkgs = Get-Content $pkgList | Where-Object { $_ -match '^[^#\s]' }
foreach ($pkg in $pkgs) {
  Write-Host ("Installing: $pkg")
  scoop install $pkg
}

Write-Host "=== Scoop-based core CLI setup complete ==="