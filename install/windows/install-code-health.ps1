# Install the code-health CLI (agents\.agents\tools\code-health) with uv, as an
# editable tool, and download its tree-sitter grammars so a first run works
# offline. This is the Windows counterpart of install/install-code-health.sh.
# Re-run after the tool's dependencies change.

Write-Host "=== code-health setup ==="

# uv comes from scoop (packages/scoop-packages.txt)
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Write-Host "Error: uv not found on PATH."
  Write-Host "Install it first:  scoop install uv"
  exit 1
}

# Claude Desktop (an MSIX app) redirects AppData writes from its terminals into
# a private copy, where uv's Python junctions don't resolve (astral-sh/uv#19622).
$uvHome = Join-Path $env:USERPROFILE ".local\share\uv"
$uvDirs = @{
  UV_PYTHON_INSTALL_DIR = Join-Path $uvHome "python"
  UV_TOOL_DIR           = Join-Path $uvHome "tools"
}
foreach ($name in $uvDirs.Keys) {
  $current = [Environment]::GetEnvironmentVariable($name, "User")
  if (-not $current) {
    $current = $uvDirs[$name]
    [Environment]::SetEnvironmentVariable($name, $current, "User")
    Write-Host "Set $name=$current for your user"
  }
  Set-Item "Env:$name" $current
}

$toolDir = Resolve-Path (Join-Path $PSScriptRoot "..\..\agents\.agents\tools\code-health")
Write-Host "Installing code-health from $toolDir"
uv tool install --editable --force "$toolDir"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# Puts uv's tool folder (%USERPROFILE%\.local\bin) on the user PATH.
uv tool update-shell
$env:Path = "$env:USERPROFILE\.local\bin;$env:Path"

if (-not (Get-Command code-health -ErrorAction SilentlyContinue)) {
  Write-Host "Error: code-health not found after install. Open a new terminal and try again."
  exit 1
}

Write-Host "Downloading tree-sitter grammars"
code-health grammars
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== code-health installed at $((Get-Command code-health).Source) ==="
