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

if (Get-Command stylua -ErrorAction SilentlyContinue) {
    & stylua --check (Join-Path $RepoRoot 'mods')
    if ($LASTEXITCODE -ne 0) { $failures += 'StyLua reported Lua syntax or formatting issues.' }
} else {
    Write-Warning 'StyLua is not installed; only structural checks ran. Install the recommended VS Code extension for formatting and syntax validation.'
}

if ($failures.Count -gt 0) { throw ($failures -join [Environment]::NewLine) }
Write-Host 'Validation passed.' -ForegroundColor Green
