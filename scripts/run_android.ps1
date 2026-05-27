param(
  [switch]$Demo,
  [switch]$Release,
  [string]$Device
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$envValues = @{}
if (-not $Demo) {
  $envValues = Read-IvraDotEnv
}

$dartDefines = if ($Demo) { @() } else { Get-IvraDartDefines -Values $envValues }

$buildMode = if ($Release) { @("--release") } else { @() }
$deviceArg = if ($Device) { @("-d", $Device) } else { @() }

$flutterArgs = @("run") + $buildMode + $deviceArg + $dartDefines

Invoke-IvraFlutter -FlutterArgs $flutterArgs
