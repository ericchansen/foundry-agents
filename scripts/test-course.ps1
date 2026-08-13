[CmdletBinding()]
param(
    [string] $PipIndexUrl
)

$ErrorActionPreference = "Stop"

python -m unittest discover -s tests -v
if ($LASTEXITCODE -ne 0) {
    throw "Course unit tests failed."
}

python -m compileall -q src examples tests
if ($LASTEXITCODE -ne 0) {
    throw "Python compilation failed."
}

$parseFailed = $false
Get-ChildItem .\scripts\*.ps1 | ForEach-Object {
    $tokens = $null
    $errors = $null
    [System.Management.Automation.Language.Parser]::ParseFile(
        $_.FullName,
        [ref] $tokens,
        [ref] $errors
    ) | Out-Null

    if ($errors.Count) {
        $parseFailed = $true
        $errors | ForEach-Object {
            Write-Error "$($_.Extent.File):$($_.Extent.StartLineNumber): $($_.Message)"
        }
    }
}
if ($parseFailed) {
    throw "PowerShell parsing failed."
}

az bicep build --file .\infra\main.bicep --stdout | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "Bicep compilation failed."
}

$commonArguments = @{}
if ($PipIndexUrl) {
    $commonArguments.PipIndexUrl = $PipIndexUrl
}

& .\scripts\test-image.ps1 `
    -ImageName "foundry-course-echo:local" `
    -ProjectPath ".\examples\01-echo-agent" `
    -Port 18088 `
    -RequestText "protocol-first" `
    -ExpectedText "Echo: protocol-first" `
    @commonArguments

& .\scripts\test-image.ps1 `
    -ImageName "custom-image-hosted-agent-lab:local" `
    -ProjectPath ".\src\agent" `
    -Port 18089 `
    @commonArguments

& .\scripts\test-image.ps1 `
    -ImageName "foundry-course-model:local" `
    -ProjectPath ".\examples\02-model-agent" `
    -BuildOnly `
    @commonArguments

Write-Host "Course infrastructure, examples, and capstone image verified." -ForegroundColor Green
