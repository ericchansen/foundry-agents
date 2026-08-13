[CmdletBinding()]
param(
    [string] $ImageName = "custom-image-hosted-agent-lab:local",
    [ValidateRange(1, 65535)]
    [int] $Port = 8088,
    [string] $PipIndexUrl
)

$ErrorActionPreference = "Stop"
$containerId = $null

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

    $buildArguments = @(
        "build",
        "--platform", "linux/amd64",
        "--tag", $ImageName
    )
    if ($PipIndexUrl) {
        $buildArguments += @("--build-arg", "PIP_INDEX_URL=$PipIndexUrl")
    }
    $buildArguments += ".\src\agent"

    & docker @buildArguments
    if ($LASTEXITCODE -ne 0) {
        throw "Docker build failed."
    }

    $containerId = (& docker run --detach `
        --publish "${Port}:8088" `
        --env "LOCAL_ECHO_MODE=true" `
        $ImageName).Trim()

    if ($LASTEXITCODE -ne 0 -or -not $containerId) {
        throw "Docker failed to start the test container."
    }

    $ready = $false
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        try {
            $probe = Invoke-WebRequest `
                -Uri "http://127.0.0.1:$Port/readiness" `
                -TimeoutSec 2 `
                -UseBasicParsing
            if ($probe.StatusCode -eq 200) {
                $ready = $true
                break
            }
        }
        catch {
            Start-Sleep -Seconds 1
        }
    }

    if (-not $ready) {
        & docker logs $containerId
        throw "The container did not become ready on port $Port."
    }

    $request = @{
        input = "Explain the hosted-agent container boundary."
        stream = $false
    } | ConvertTo-Json

    $response = Invoke-RestMethod `
        -Uri "http://127.0.0.1:$Port/responses" `
        -Method Post `
        -ContentType "application/json" `
        -Body $request

    $serialized = $response | ConvertTo-Json -Depth 20
    if ($serialized -notmatch "Echo: Explain the hosted-agent container boundary\.") {
        throw "The Responses endpoint returned an unexpected payload: $serialized"
    }

    Write-Host "Image contract verified: linux/amd64 build, readiness, and Responses API." -ForegroundColor Green
}
finally {
    if ($containerId) {
        & docker rm --force $containerId | Out-Null
    }
}
