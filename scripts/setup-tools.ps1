[CmdletBinding()]
param(
    [string]$GameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\WheelMates',
    [switch]$InstallUE4SS,
    [ValidateSet('dwmapi.dll', 'version.dll', 'winmm.dll')]
    [string]$ProxyDll = 'dwmapi.dll'
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$ToolsRoot = Join-Path $RepoRoot 'tools'
$GameBinary = Join-Path $GameRoot 'CarGame\Binaries\Win64'
$GameExe = Join-Path $GameBinary 'LyraGameSteam-Win64-Shipping.exe'
$UE4SSSource = Join-Path $ToolsRoot 'UE4SS_v3.0.1-1136-g35d1795d'
$UE4SSRuntime = Join-Path $UE4SSSource 'ue4ss'
$ModsSource = Join-Path $RepoRoot 'mods'

Write-Host 'WheelMates Lua mod environment' -ForegroundColor Green
if (-not (Test-Path -LiteralPath $GameExe)) { throw "WheelMates executable not found: $GameExe" }
Write-Host "Game: $GameRoot"
Write-Host ('UE4SS bundle: ' + $(if (Test-Path -LiteralPath $UE4SSRuntime) { 'available' } else { 'missing' }))
Write-Host 'Lua development needs UE4SS only. CMake, Ninja, xmake, and MSVC are not required unless a future C++ mod is introduced.'
Write-Host 'Optional reverse-engineering tools (FModel, RePak, retoc) are intentionally not installed by this script.'

if (-not $InstallUE4SS) { return }
if (-not (Test-Path -LiteralPath $UE4SSRuntime)) { throw "UE4SS bundle missing: $UE4SSRuntime. Restore the pinned bundle under tools before installing." }

$saveRoot = Join-Path $env:LOCALAPPDATA 'CarGame\Saved'
if (Test-Path -LiteralPath $saveRoot) { Write-Warning "Saves detected at $saveRoot. Back them up before proceeding." }
$destinationRuntime = Join-Path $GameBinary 'ue4ss'
$destinationProxy = Join-Path $GameBinary $ProxyDll
if (Test-Path -LiteralPath $destinationProxy) { throw "Refusing to replace $destinationProxy. Verify its origin and explicitly restore/remove it if appropriate." }

Copy-Item -LiteralPath (Join-Path $UE4SSSource 'dwmapi.dll') -Destination $destinationProxy
New-Item -ItemType Directory -Force -Path $destinationRuntime | Out-Null
Get-ChildItem -LiteralPath $UE4SSRuntime -Force | Copy-Item -Destination $destinationRuntime -Recurse -Force

$settings = Join-Path $destinationRuntime 'UE4SS-settings.ini'
$modsPath = $ModsSource.Replace('\', '/')
$settingsContent = [System.IO.File]::ReadAllText($settings)
$settingsContent = [regex]::Replace($settingsContent, '(?ms)\r?\n\[ExperimentalFeatures\]\s*\z', '')
$overrideValues = "+ModsFolderPaths = $modsPath`r`nControllingModsTxt = $modsPath/mods.txt"
$settingsContent = ([regex]::new('(?m)^ControllingModsTxt\s*=.*$')).Replace($settingsContent, $overrideValues, 1)
$settingsContent = [regex]::Replace($settingsContent, '(?m)^EnableHotReloadSystem\s*=.*$', 'EnableHotReloadSystem = 1')
$settingsContent = [regex]::Replace($settingsContent, '(?m)^EnableAutoReloadingLuaMods\s*=.*$', 'EnableAutoReloadingLuaMods = 1')
$settingsContent = [regex]::Replace($settingsContent, '(?m)^ConsoleEnabled\s*=.*$', 'ConsoleEnabled = 1')
[System.IO.File]::WriteAllText($settings, $settingsContent)
Write-Host 'UE4SS installed. Launch the game once, then inspect ue4ss\UE4SS.log.' -ForegroundColor Green
