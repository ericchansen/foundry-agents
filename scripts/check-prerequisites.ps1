[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$failures = [System.Collections.Generic.List[string]]::new()

function Test-Command {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        $failures.Add("$Name is not installed or is not on PATH.")
        return $false
    }

    return $true
}

function Test-MinimumVersion {
    param(
        [Parameter(Mandatory)]
        [string] $Name,

        [Parameter(Mandatory)]
        [string] $Output,

        [Parameter(Mandatory)]
        [version] $Minimum
    )

    if ($Output -notmatch "(\d+\.\d+\.\d+)") {
        $failures.Add("Could not determine the $Name version from: $Output")
        return
    }

    $actual = [version] $Matches[1]
    if ($actual -lt $Minimum) {
        $failures.Add("$Name $actual is installed; version $Minimum or later is required.")
        return
    }

    Write-Host "[ok] $Name $actual"
}

if (Test-Command "python") {
    Test-MinimumVersion "Python" (& python --version 2>&1 | Out-String) ([version] "3.13.0")
}

if (Test-Command "azd") {
    Test-MinimumVersion "azd" (& azd version 2>&1 | Select-Object -First 1 | Out-String) ([version] "1.27.1")

    $installedExtensions = & azd ext list --installed 2>&1 | Out-String
    foreach ($extension in @("microsoft.foundry", "azure.ai.agents", "azure.ai.projects")) {
        if ($installedExtensions -notmatch [regex]::Escape($extension)) {
            $failures.Add("azd extension '$extension' is not installed.")
        }
        else {
            Write-Host "[ok] azd extension $extension"
        }
    }
}

if (Test-Command "az") {
    Write-Host "[ok] Azure CLI"
}

if (Test-Command "docker") {
    try {
        $serverVersion = & docker version --format "{{.Server.Version}}" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($serverVersion | Out-String)
        }

        Write-Host "[ok] Docker engine $serverVersion"
    }
    catch {
        $failures.Add("Docker is installed, but the Docker engine is not available.")
    }
}

if ($failures.Count -gt 0) {
    Write-Host ""
    Write-Host "Prerequisite check failed:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "All hosted-agent prerequisites are ready." -ForegroundColor Green
