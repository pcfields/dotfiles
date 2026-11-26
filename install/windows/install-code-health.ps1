# Install the code-health binary into ~\.local\bin from a release of the
# private code-health repo, at the version in packages\code-health-version.txt.
# Needs gh signed in and CODE_HEALTH_REPO set to <owner>/<name>. This is the
# Windows counterpart of install/install-code-health.sh.

Write-Host "=== code-health setup ==="

# gh comes from scoop (packages/scoop-packages.txt)
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host "Error: gh not found on PATH."
  Write-Host "Install it first:  scoop install gh, then gh auth login"
  exit 1
}
if (-not $env:CODE_HEALTH_REPO) {
  Write-Host "Error: CODE_HEALTH_REPO is not set: see docs\secrets.md"
  exit 1
}

$versionFile = Join-Path $PSScriptRoot "..\..\packages\code-health-version.txt"
$version = Get-Content $versionFile |
  ForEach-Object { ($_ -replace '#.*$', '').Trim() } |
  Where-Object { $_ } |
  Select-Object -First 1
$binDir = Join-Path $HOME ".local\bin"
$bin = Join-Path $binDir "code-health.exe"

# The Python tool was a uv tool; its shim would shadow the binary on PATH.
if ((Get-Command uv -ErrorAction SilentlyContinue) -and (uv tool list 2>$null | Select-String '^code-health ')) {
  Write-Host "Removing the uv-installed Python code-health"
  uv tool uninstall code-health
}

$installed = if (Test-Path $bin) { & $bin --version } else { "" }
if ($installed -eq "code-health $($version.TrimStart('v'))") {
  Write-Host "code-health $version is already installed at $bin"
} else {
  Write-Host "Downloading code-health $version"
  $tmp = Join-Path ([IO.Path]::GetTempPath()) "code-health-$version"
  gh release download $version --repo $env:CODE_HEALTH_REPO --pattern code-health.exe --dir $tmp --clobber
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  New-Item -ItemType Directory -Force -Path $binDir | Out-Null
  Copy-Item (Join-Path $tmp "code-health.exe") $bin -Force
  Remove-Item $tmp -Recurse -Force
}

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (($userPath -split ';') -notcontains $binDir) {
  [Environment]::SetEnvironmentVariable("Path", "$userPath;$binDir", "User")
  Write-Host "Added $binDir to your user PATH. Open a new terminal, and quit Claude Desktop from its tray icon, to pick it up."
}

Write-Host "=== $(& $bin --version) installed at $bin ==="
