[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $RepoRoot 'mods\mods.txt'

if (-not (Test-Path -LiteralPath $Manifest)) { throw "Missing manifest: $Manifest" }
$failures = @()
Get-Content -LiteralPath $Manifest | ForEach-Object {
    if ($_ -match '^\s*([A-Za-z0-9]+)\s*:\s*[01]\s*(?:;.*)?$') {
        $module = $Matches[1]
        $main = Join-Path $RepoRoot "mods\$module\Scripts\main.lua"
        if (-not (Test-Path -LiteralPath $main)) { $failures += "Manifest module '$module' has no Scripts/main.lua." }
    } elseif ($_ -notmatch '^\s*(;.*)?$') { $failures += "Invalid manifest line: $_" }
}

$stylua = Join-Path $RepoRoot 'tools\stylua\stylua.exe'
if (-not (Test-Path -LiteralPath $stylua)) {
    $command = Get-Command stylua -ErrorAction SilentlyContinue
    $stylua = if ($command) { $command.Source } else { $null }
}
if ($stylua) {
    & $stylua --check (Join-Path $RepoRoot 'mods') (Join-Path $RepoRoot 'tests')
    if ($LASTEXITCODE -ne 0) { $failures += 'StyLua reported Lua syntax or formatting issues.' }
} else {
    $failures += 'StyLua is missing. Run scripts/install-stylua.ps1 or install stylua on PATH.'
}

$python = Join-Path $RepoRoot 'tools\test-python-env\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) { $python = 'python' }
& $python (Join-Path $RepoRoot 'tests\run.py')
if ($LASTEXITCODE -ne 0) { $failures += 'Lua regression tests failed. See tests/README.md for the test runtime setup.' }

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host 'Validation passed.' -ForegroundColor Green
