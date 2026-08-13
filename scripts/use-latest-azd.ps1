[CmdletBinding()]
param(
    [version] $MinimumVersion = [version] "1.27.1"
)

$ErrorActionPreference = "Stop"
$installations = @(
    Get-Command azd -CommandType Application -All -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Source -Unique |
        ForEach-Object {
            $output = & $_ version 2>&1 | Select-Object -First 1 | Out-String
            if ($output -match "(\d+\.\d+\.\d+)") {
                [pscustomobject] @{
                    Path = $_
                    Version = [version] $Matches[1]
                }
            }
        }
)

if (-not $installations) {
    throw "azd is not installed or is not on PATH."
}

$selected = $installations |
    Sort-Object Version -Descending |
    Select-Object -First 1
if ($selected.Version -lt $MinimumVersion) {
    throw "The newest azd installation is $($selected.Version); version $MinimumVersion or later is required."
}

$selectedDirectory = Split-Path $selected.Path -Parent
$pathEntries = @(
    $selectedDirectory
    $env:PATH -split ";" |
        Where-Object {
            $_ -and $_.TrimEnd("\") -ne $selectedDirectory.TrimEnd("\")
        }
)
$env:PATH = $pathEntries -join ";"

$resolved = Get-Command azd -CommandType Application -ErrorAction Stop |
    Select-Object -First 1
Write-Host "[ok] Using azd $($selected.Version) from $($resolved.Source)"
