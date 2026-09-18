[CmdletBinding()]
param(
    [string]$SavePath = (Join-Path $PSScriptRoot '..\save\SaveGames\Save_1_Data.sav'),
    [ValidateRange(1, [int]::MaxValue)]
    [int]$Target = 50
)

$ErrorActionPreference = 'Stop'

function Find-ByteSequence {
    param(
        [byte[]]$Bytes,
        [byte[]]$Needle,
        [int]$StartAt = 0,
        [int]$EndAt = $Bytes.Length
    )

    $matches = [System.Collections.Generic.List[int]]::new()
    $lastStart = [Math]::Min($EndAt, $Bytes.Length) - $Needle.Length

    for ($offset = $StartAt; $offset -le $lastStart; $offset++) {
        $isMatch = $true
        for ($index = 0; $index -lt $Needle.Length; $index++) {
            if ($Bytes[$offset + $index] -ne $Needle[$index]) {
                $isMatch = $false
                break
            }
        }

        if ($isMatch) {
            $matches.Add($offset)
        }
    }

    return $matches
}

function Read-NullTerminatedAscii {
    param(
        [byte[]]$Bytes,
        [int]$Offset
    )

    $end = $Offset
    while ($end -lt $Bytes.Length -and $Bytes[$end] -ne 0) {
        $end++
    }

    return [System.Text.Encoding]::ASCII.GetString($Bytes, $Offset, $end - $Offset)
}

$resolvedSavePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($SavePath)
if (-not (Test-Path -LiteralPath $resolvedSavePath -PathType Leaf)) {
    throw "Sauvegarde introuvable : $resolvedSavePath"
}

$bytes = [System.IO.File]::ReadAllBytes($resolvedSavePath)
$ascii = [System.Text.Encoding]::ASCII
$playerPrefix = $ascii.GetBytes('Player.Id.')
$activityTag = $ascii.GetBytes('Achievement.Activity.Destructibles')

$playerMarkers = Find-ByteSequence -Bytes $bytes -Needle $playerPrefix
$personalActivityMaps = Find-ByteSequence -Bytes $bytes -Needle $ascii.GetBytes('PersonalTrackedActivityCounts')
$playerIds = [System.Collections.Generic.List[string]]::new()
foreach ($marker in $playerMarkers) {
    $playerId = Read-NullTerminatedAscii -Bytes $bytes -Offset $marker
    if ($playerId -match '^Player\.Id\.\d+$' -and -not $playerIds.Contains($playerId)) {
        $playerIds.Add($playerId)
    }
}

if ($playerIds.Count -eq 0) {
    throw 'No Player.Id was found in the save file.'
}

$progressByPlayer = @{}
foreach ($mapOffset in $personalActivityMaps) {
    # The activity map is a small serialized property. Limit the search to that
    # property so mirrored/shared activity counts cannot overwrite personal progress.
    $activityOffset = (Find-ByteSequence -Bytes $bytes -Needle $activityTag -StartAt $mapOffset -EndAt ([Math]::Min($bytes.Length, $mapOffset + 1024)) |
        Select-Object -First 1)
    if ($null -eq $activityOffset) {
        continue
    }

    # The GameplayTag ends with a NUL byte, followed by FName("None") and its Int32 map value.
    $afterTag = $activityOffset + $activityTag.Length + 1
    if ($afterTag + 9 -gt $bytes.Length -or [BitConverter]::ToInt32($bytes, $afterTag) -ne 5) {
        continue
    }

    $terminator = $ascii.GetString($bytes, $afterTag + 4, 5)
    if ($terminator -ne "None$([char]0)") {
        continue
    }

    $counter = [BitConverter]::ToInt32($bytes, $afterTag + 9)
    $owningMarker = $playerMarkers | Where-Object { $_ -lt $mapOffset } | Select-Object -Last 1
    if ($null -eq $owningMarker) {
        continue
    }

    $playerId = Read-NullTerminatedAscii -Bytes $bytes -Offset $owningMarker
    if ($playerId -match '^Player\.Id\.\d+$') {
        $progressByPlayer[$playerId] = $counter
    }
}

$playerIds |
    Sort-Object { [int]($_ -replace '^Player\.Id\.', '') } |
    ForEach-Object {
        $count = if ($progressByPlayer.ContainsKey($_)) { $progressByPlayer[$_] } else { 0 }
        [pscustomobject]@{
            PlayerId       = $_
            ObjectsBroken  = $count
            Target         = $Target
            Remaining      = [Math]::Max(0, $Target - $count)
            Status         = if ($count -ge $Target) { 'Complete' } else { 'In progress' }
        }
    } |
    Format-Table -AutoSize
