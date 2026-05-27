param(
  [switch]$BuildAndroid,
  [switch]$Demo
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$envValues = @{}
if (-not $Demo) {
  $envValues = Read-IvraDotEnv
}

$dartDefines = if ($Demo) { @() } else { Get-IvraDartDefines -Values $envValues }
$flutter = Get-IvraFlutterCommand

$steps = @(
  @("pub", "get"),
  @("analyze"),
  @("test"),
  (@("build", "web") + $dartDefines)
)

if ($BuildAndroid) {
  $steps += ,(@("build", "apk", "--debug") + $dartDefines)
}

foreach ($step in $steps) {
  Write-Host "Running: $flutter $($step -join ' ')"
  & $flutter @step
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Write-Host "Local verification completed."
