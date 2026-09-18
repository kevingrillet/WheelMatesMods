[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SourceDirectory = (Join-Path $env:LOCALAPPDATA 'CarGame\Saved\SaveGames'),
    [string]$DestinationDirectory = (Join-Path $PSScriptRoot '..\save\SaveGames')
)

$ErrorActionPreference = 'Stop'

$sourcePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SourceDirectory)
$destinationPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DestinationDirectory)

if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw "Local game save directory not found: $sourcePath"
}

if ([System.StringComparer]::OrdinalIgnoreCase.Equals($sourcePath.TrimEnd('\'), $destinationPath.TrimEnd('\'))) {
    throw 'The source and destination directories must be different.'
}

if (-not (Test-Path -LiteralPath $destinationPath -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($destinationPath, 'Create development save directory')) {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }
}

$saveFiles = Get-ChildItem -LiteralPath $sourcePath -File -Filter '*.sav'
if ($saveFiles.Count -eq 0) {
    throw "No .sav files were found in: $sourcePath"
}

$results = foreach ($saveFile in $saveFiles) {
    $destinationFile = Join-Path $destinationPath $saveFile.Name

    # Copy-Item only reads $sourcePath. It never writes to or deletes from the live save directory.
    if ($PSCmdlet.ShouldProcess($destinationFile, "Import $($saveFile.Name) from the local game save")) {
        Copy-Item -LiteralPath $saveFile.FullName -Destination $destinationFile -Force
        $sourceHash = (Get-FileHash -LiteralPath $saveFile.FullName -Algorithm SHA256).Hash
        $destinationHash = (Get-FileHash -LiteralPath $destinationFile -Algorithm SHA256).Hash

        if ($sourceHash -ne $destinationHash) {
            throw "Verification failed after copying: $($saveFile.Name)"
        }
    }

    [pscustomobject]@{
        File        = $saveFile.Name
        Source      = $saveFile.FullName
        Destination = $destinationFile
        Bytes       = $saveFile.Length
        Verified    = if ($WhatIfPreference) { 'Not copied (WhatIf)' } else { 'SHA256 match' }
    }
}

$results | Format-Table -AutoSize
