[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$SavePath = (Join-Path $PSScriptRoot '..\save\SaveGames\Save_1_Data.sav'),
    [ValidatePattern('^Player\.Id\.\d+$')]
    [string]$PlayerId = 'Player.Id.1',
    [ValidateRange(0, [int]::MaxValue)]
    [int]$ObjectsBroken = 49
)

$ErrorActionPreference = 'Stop'

function Find-ByteSequence {
    param([byte[]]$Bytes, [byte[]]$Needle, [int]$StartAt = 0, [int]$EndAt = $Bytes.Length)

    $matches = [System.Collections.Generic.List[int]]::new()
    $lastStart = [Math]::Min($EndAt, $Bytes.Length) - $Needle.Length
    for ($offset = $StartAt; $offset -le $lastStart; $offset++) {
        $isMatch = $true
        for ($index = 0; $index -lt $Needle.Length; $index++) {
            if ($Bytes[$offset + $index] -ne $Needle[$index]) { $isMatch = $false; break }
        }
        if ($isMatch) { $matches.Add($offset) }
    }
    return $matches
}

function Read-NullTerminatedAscii {
    param([byte[]]$Bytes, [int]$Offset)

    $end = $Offset
    while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) { $end++ }
    return [System.Text.Encoding]::ASCII.GetString($Bytes, $Offset, $end - $Offset)
}

$developmentSaveDirectory = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\save\SaveGames')).TrimEnd('\')
$resolvedSavePath = [System.IO.Path]::GetFullPath(
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SavePath)
)

if (-not $resolvedSavePath.StartsWith("$developmentSaveDirectory\", [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to edit a save outside the development copy directory: $developmentSaveDirectory"
}
if (-not (Test-Path -LiteralPath $resolvedSavePath -PathType Leaf)) {
    throw "Development save not found: $resolvedSavePath"
}

$bytes = [System.IO.File]::ReadAllBytes($resolvedSavePath)
$ascii = [System.Text.Encoding]::ASCII
$playerMarkers = Find-ByteSequence -Bytes $bytes -Needle $ascii.GetBytes('Player.Id.')
$personalActivityMaps = Find-ByteSequence -Bytes $bytes -Needle $ascii.GetBytes('PersonalTrackedActivityCounts')
$activityTag = $ascii.GetBytes('Achievement.Activity.Destructibles')
$counterOffset = $null

foreach ($mapOffset in $personalActivityMaps) {
    $owningMarker = $playerMarkers | Where-Object { $_ -lt $mapOffset } | Select-Object -Last 1
    if ($null -eq $owningMarker -or (Read-NullTerminatedAscii -Bytes $bytes -Offset $owningMarker) -ne $PlayerId) {
        continue
    }

    $activityOffset = Find-ByteSequence -Bytes $bytes -Needle $activityTag -StartAt $mapOffset -EndAt ([Math]::Min($bytes.Length, $mapOffset + 1024)) |
        Select-Object -First 1
    if ($null -eq $activityOffset) { continue }

    # GameplayTag serialization: tag NUL, FName length 5, "None" NUL, Int32 counter.
    $afterTag = $activityOffset + $activityTag.Length + 1
    if ($afterTag + 9 -le $bytes.Length -and
        [BitConverter]::ToInt32($bytes, $afterTag) -eq 5 -and
        $ascii.GetString($bytes, $afterTag + 4, 5) -eq "None$([char]0)") {
        $counterOffset = $afterTag + 9
        break
    }
}

if ($null -eq $counterOffset) {
    throw "No personal destructibles counter was found for $PlayerId. The save was not changed."
}

$previousCount = [BitConverter]::ToInt32($bytes, $counterOffset)
$backupPath = '{0}.before-hf-break-edit-{1:yyyyMMdd-HHmmss}.bak' -f $resolvedSavePath, (Get-Date)

if ($PSCmdlet.ShouldProcess($resolvedSavePath, "Set $PlayerId destructibles counter from $previousCount to $ObjectsBroken")) {
    if (Test-Path -LiteralPath $backupPath) {
        throw "Refusing to overwrite an existing backup: $backupPath"
    }
    Copy-Item -LiteralPath $resolvedSavePath -Destination $backupPath
    [Array]::Copy([BitConverter]::GetBytes($ObjectsBroken), 0, $bytes, $counterOffset, 4)
    [System.IO.File]::WriteAllBytes($resolvedSavePath, $bytes)

    $verifiedBytes = [System.IO.File]::ReadAllBytes($resolvedSavePath)
    if ([BitConverter]::ToInt32($verifiedBytes, $counterOffset) -ne $ObjectsBroken) {
        throw "Verification failed. Restore the development backup: $backupPath"
    }
}

[pscustomobject]@{
    SavePath       = $resolvedSavePath
    PlayerId       = $PlayerId
    PreviousCount  = $previousCount
    NewCount       = $ObjectsBroken
    Backup         = if ($WhatIfPreference) { 'Not created (WhatIf)' } else { $backupPath }
    Verified       = if ($WhatIfPreference) { 'Not written (WhatIf)' } else { 'Counter value verified' }
} | Format-List
