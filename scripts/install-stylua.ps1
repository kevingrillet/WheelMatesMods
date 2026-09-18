[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$version = '2.5.2'
$expectedHash = 'e77d0ea1226b8b389b43f702240091249a96eea25857281f90ea24d0eb9eb969'
$destination = Join-Path (Split-Path -Parent $PSScriptRoot) 'tools\stylua'
New-Item -ItemType Directory -Force -Path $destination | Out-Null
$archive = Join-Path $destination 'stylua.zip'
Invoke-WebRequest "https://github.com/JohnnyMorganz/StyLua/releases/download/v$version/stylua-windows-x86_64.zip" -OutFile $archive
if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedHash) {
    throw 'StyLua archive checksum mismatch; archive was not extracted.'
}
Expand-Archive -LiteralPath $archive -DestinationPath $destination -Force
& (Join-Path $destination 'stylua.exe') --version
if ($LASTEXITCODE -ne 0) { throw 'StyLua installation check failed.' }
