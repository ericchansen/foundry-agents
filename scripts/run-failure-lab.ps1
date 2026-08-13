[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet(
        "wrong-architecture",
        "wrong-port",
        "missing-readiness",
        "missing-configuration"
    )]
    [string] $Scenario,

    [string] $PipIndexUrl
)

$ErrorActionPreference = "Stop"
$token = ([guid]::NewGuid().ToString("N")).Substring(0, 8)
$imageName = "foundry-course-failure-$Scenario-$token`:local"
$containerName = "foundry-course-failure-$Scenario-$token"
$containerStarted = $false

function Invoke-DockerBuild {
    param(
        [string] $Platform,
        [string] $Context
    )

    $arguments = @(
        "build",
        "--platform", $Platform,
        "--tag", $imageName
    )
    if ($PipIndexUrl) {
        $arguments += @("--build-arg", "PIP_INDEX_URL=$PipIndexUrl")
    }
    $arguments += $Context

    & docker @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed for scenario '$Scenario'."
    }
}

function Get-DockerLogs {
    param(
        [Parameter(Mandatory)]
        [string] $Name
    )

    $stdoutPath = Join-Path $env:TEMP "foundry-course-$token-stdout.log"
    $stderrPath = Join-Path $env:TEMP "foundry-course-$token-stderr.log"
    try {
        $process = Start-Process `
            -FilePath "docker" `
            -ArgumentList @("logs", $Name) `
            -NoNewWindow `
            -Wait `
            -PassThru `
            -RedirectStandardOutput $stdoutPath `
            -RedirectStandardError $stderrPath
        if ($process.ExitCode -ne 0) {
            throw "Docker logs failed for container '$Name'."
        }

        $stdout = Get-Content $stdoutPath -Raw -ErrorAction SilentlyContinue
        $stderr = Get-Content $stderrPath -Raw -ErrorAction SilentlyContinue
        return "$stdout$stderr"
    }
    finally {
        Remove-Item $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue
    }
}

try {
    if (-not $PipIndexUrl -and (Get-Command python -ErrorAction SilentlyContinue)) {
        foreach ($scope in @("--global", "--user", "--site")) {
            $configuredIndex = & python -m pip config $scope get global.index-url 2>$null
            if ($LASTEXITCODE -eq 0) {
                $PipIndexUrl = ($configuredIndex | Select-Object -First 1).Trim()
                break
            }
        }
    }

    if ($PipIndexUrl) {
        $indexUri = [uri] $PipIndexUrl
        if (-not $indexUri.IsAbsoluteUri -or $indexUri.Scheme -ne "https") {
            throw "PipIndexUrl must be an absolute HTTPS URL."
        }
        if ($indexUri.UserInfo) {
            throw "PipIndexUrl must not contain embedded credentials."
        }
    }

    switch ($Scenario) {
        "wrong-architecture" {
            Invoke-DockerBuild `
                -Platform "linux/arm64" `
                -Context ".\failures\wrong-architecture"
            $metadata = & docker image inspect $imageName |
                ConvertFrom-Json |
                Select-Object -First 1
            if ($metadata.Os -ne "linux" -or $metadata.Architecture -ne "arm64") {
                throw "Expected linux/arm64 evidence, found $($metadata.Os)/$($metadata.Architecture)."
            }
            Write-Host "Expected evidence: OS=linux Architecture=arm64"
        }
        "wrong-port" {
            Invoke-DockerBuild `
                -Platform "linux/amd64" `
                -Context ".\failures\wrong-port"
            & docker run `
                --detach `
                --name $containerName `
                --publish "127.0.0.1::8088" `
                $imageName | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Docker failed to start the wrong-port fixture."
            }
            $containerStarted = $true
            Start-Sleep -Seconds 2

            $published = (& docker port $containerName "8088/tcp").Trim()
            $hostPort = [int] ($published -replace "^.*:", "")
            try {
                Invoke-WebRequest `
                    -Uri "http://127.0.0.1:$hostPort/readiness" `
                    -TimeoutSec 2 `
                    -UseBasicParsing | Out-Null
                throw "The readiness probe unexpectedly succeeded."
            }
            catch {
                if ($_.Exception.Message -eq "The readiness probe unexpectedly succeeded.") {
                    throw
                }
            }
            Write-Host "Expected evidence: the process listens on 9090 while Foundry probes 8088."
            Write-Host (Get-DockerLogs -Name $containerName)
        }
        "missing-readiness" {
            Invoke-DockerBuild `
                -Platform "linux/amd64" `
                -Context ".\failures\missing-readiness"
            & docker run `
                --detach `
                --name $containerName `
                --publish "127.0.0.1::8088" `
                $imageName | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Docker failed to start the missing-readiness fixture."
            }
            $containerStarted = $true
            Start-Sleep -Seconds 2

            $published = (& docker port $containerName "8088/tcp").Trim()
            $hostPort = [int] ($published -replace "^.*:", "")
            try {
                Invoke-WebRequest `
                    -Uri "http://127.0.0.1:$hostPort/readiness" `
                    -TimeoutSec 2 `
                    -UseBasicParsing | Out-Null
                throw "The readiness endpoint unexpectedly succeeded."
            }
            catch {
                $statusCode = [int] $_.Exception.Response.StatusCode
                if ($statusCode -ne 404) {
                    throw "Expected HTTP 404, found $statusCode."
                }
            }
            Write-Host "Expected evidence: the process listens on 8088 but /readiness returns 404."
        }
        "missing-configuration" {
            Invoke-DockerBuild `
                -Platform "linux/amd64" `
                -Context ".\src\agent"
            & docker run `
                --detach `
                --name $containerName `
                $imageName | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw "Docker failed to start the missing-configuration fixture."
            }
            $containerStarted = $true
            Start-Sleep -Seconds 2

            $logs = Get-DockerLogs -Name $containerName
            if ($logs -notmatch "Missing required environment variable") {
                throw "The expected configuration error was not present in container logs."
            }
            Write-Host "Expected evidence from container stderr:"
            Write-Host $logs.Trim()
        }
    }

    Write-Host "Failure fixture '$Scenario' produced the expected evidence." -ForegroundColor Green
}
finally {
    if ($containerStarted) {
        & docker rm --force $containerName *> $null
    }
    & docker image inspect $imageName *> $null
    if ($LASTEXITCODE -eq 0) {
        & docker image rm --force $imageName *> $null
    }
}
