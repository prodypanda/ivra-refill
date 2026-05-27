param(
  [switch]$Demo,
  [switch]$SkipReadiness,
  [switch]$IncludeAppBundle,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$repoRoot = Split-Path $PSScriptRoot -Parent
$flutter = Get-IvraFlutterCommand

$envValues = @{}
if (-not $Demo) {
  $envValues = Read-IvraDotEnv
}

$dartDefines = if ($Demo) { @() } else { Get-IvraDartDefines -Values $envValues -RequireSupabase }

function Invoke-ReleaseStep {
  param(
    [string]$Description,
    [string[]]$CommandArgs
  )

  Write-Host ""
  Write-Host $Description
  Write-Host "Running: $flutter $($CommandArgs -join ' ')"

  if ($DryRun) {
    return
  }

  & $flutter @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Write-Host "Ivra release package"

if ($Demo) {
  Write-Host "Mode: demo"
} else {
  Write-Host "Mode: production"
}

if ($DryRun) {
  Write-Host "Dry run: commands will be printed but not executed."
}

if (-not $Demo -and -not $SkipReadiness) {
  $readinessScript = Join-Path $PSScriptRoot "check_release_readiness.ps1"
  Write-Host ""
  Write-Host "Running release-readiness gate."

  if (-not $DryRun) {
    & $readinessScript
    if (-not $?) {
      exit 1
    }
  } else {
    Write-Host "Would run: $readinessScript"
  }
} elseif ($Demo) {
  Write-Host "Skipping release-readiness gate for demo packaging."
} elseif ($SkipReadiness) {
  Write-Host "Skipping release-readiness gate because -SkipReadiness was provided."
}

Invoke-ReleaseStep -Description "Resolving Flutter packages" -CommandArgs @("pub", "get")
Invoke-ReleaseStep -Description "Building web release" -CommandArgs (@("build", "web") + $dartDefines)
Invoke-ReleaseStep -Description "Building Android release APK" -CommandArgs (@("build", "apk", "--release") + $dartDefines)

if ($IncludeAppBundle) {
  Invoke-ReleaseStep -Description "Building Android release app bundle" -CommandArgs (@("build", "appbundle", "--release") + $dartDefines)
}

$manifestMode = if ($Demo) { "demo" } else { "production" }
$manifestScript = Join-Path $PSScriptRoot "create_release_manifest.ps1"
Write-Host ""
Write-Host "Creating release manifest"

if ($DryRun) {
  Write-Host "Would run: $manifestScript -Mode $manifestMode -IncludeAppBundle:$IncludeAppBundle"
} else {
  & $manifestScript -Mode $manifestMode -IncludeAppBundle:$IncludeAppBundle
  if (-not $?) {
    exit 1
  }
}

Write-Host ""
Write-Host "Release package step complete."
Write-Host "Web output: $([System.IO.Path]::GetFullPath((Join-Path $repoRoot 'build\web')))"
Write-Host "APK output: $([System.IO.Path]::GetFullPath((Join-Path $repoRoot 'build\app\outputs\flutter-apk\app-release.apk')))"
Write-Host "Manifest: $([System.IO.Path]::GetFullPath((Join-Path $repoRoot '.generated\release\release-manifest.json')))"

if ($IncludeAppBundle) {
  Write-Host "AAB output: $([System.IO.Path]::GetFullPath((Join-Path $repoRoot 'build\app\outputs\bundle\release\app-release.aab')))"
}
