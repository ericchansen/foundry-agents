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

$previousEnvironmentName = $env:AZURE_ENV_NAME
$previousLocation = $env:AZURE_LOCATION
$previousDeployments = $env:AI_PROJECT_DEPLOYMENTS
try {
    $env:AZURE_ENV_NAME = "course-validation"
    $env:AZURE_LOCATION = "eastus2"
    $env:AI_PROJECT_DEPLOYMENTS = '[{"name":"gpt-5.4-mini","model":{"format":"OpenAI","name":"gpt-5.4-mini","version":"2026-03-17"},"sku":{"name":"GlobalStandard","capacity":10}}]'
    $buildParametersOutput = az bicep build-params --file .\infra\main.bicepparam --stdout
    if ($LASTEXITCODE -ne 0) {
        throw "Bicep parameter compilation failed."
    }
    $buildParameters = $buildParametersOutput | ConvertFrom-Json
    $parameters = $buildParameters.parametersJson | ConvertFrom-Json
    if ($parameters.parameters.aiProjectDeploymentsJson.value -ne $env:AI_PROJECT_DEPLOYMENTS) {
        throw "Bicep parameter serialization changed the model deployment JSON."
    }
}
finally {
    $env:AZURE_ENV_NAME = $previousEnvironmentName
    $env:AZURE_LOCATION = $previousLocation
    $env:AI_PROJECT_DEPLOYMENTS = $previousDeployments
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
