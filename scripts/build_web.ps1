param(
  [switch]$Demo
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$envValues = @{}
if (-not $Demo) {
  $envValues = Read-IvraDotEnv
}

$dartDefines = if ($Demo) { @() } else { Get-IvraDartDefines -Values $envValues -RequireSupabase }
$flutterArgs = @("build", "web") + $dartDefines

Invoke-IvraFlutter -FlutterArgs $flutterArgs
