param(
  [switch]$Demo,
  [switch]$IncludeAppBundle,
  [switch]$BuildAndroidDebug,
  [switch]$SkipVerify,
  [switch]$SkipPackage,
  [switch]$SkipArchive,
  [switch]$SkipEvidence,
  [string]$ReleaseName,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$mode = if ($Demo) { "demo" } else { "production" }

function Invoke-Step {
  param(
    [string]$Description,
    [string]$ScriptPath,
    [hashtable]$Parameters = @{}
  )

  $argumentText = ($Parameters.GetEnumerator() | ForEach-Object {
      if ($_.Value -is [switch] -or $_.Value -is [bool]) {
        if ($_.Value) { "-$($_.Key)" } else { $null }
      } elseif ($null -ne $_.Value) {
        "-$($_.Key) $($_.Value)"
      }
    }) -join " "

  Write-Host ""
  Write-Host $Description
  Write-Host "Running: $ScriptPath $argumentText"

  if ($DryRun) {
    return
  }

  & $ScriptPath @Parameters
  if (-not $?) {
    exit 1
  }
}

Write-Host "Ivra go-live preparation"
Write-Host "Mode: $mode"
if ($DryRun) {
  Write-Host "Dry run: commands will be printed but not executed."
}

if (-not $SkipVerify) {
  $verifyParameters = @{
    Demo = [bool]$Demo
    BuildAndroid = [bool]$BuildAndroidDebug
  }
  Invoke-Step `
    -Description "Running local verification" `
    -ScriptPath (Join-Path $PSScriptRoot "verify_local.ps1") `
    -Parameters $verifyParameters
}

if (-not $SkipPackage) {
  $packageParameters = @{
    Demo = [bool]$Demo
    IncludeAppBundle = [bool]$IncludeAppBundle
  }
  Invoke-Step `
    -Description "Building release package" `
    -ScriptPath (Join-Path $PSScriptRoot "package_release.ps1") `
    -Parameters $packageParameters
}

if (-not $SkipArchive) {
  $archiveParameters = @{
    Mode = $mode
    IncludeAppBundle = [bool]$IncludeAppBundle
  }
  if (-not [string]::IsNullOrWhiteSpace($ReleaseName)) {
    $archiveParameters.ReleaseName = $ReleaseName
    $archiveParameters.Force = $true
  }

  Invoke-Step `
    -Description "Archiving release artifacts" `
    -ScriptPath (Join-Path $PSScriptRoot "archive_release_artifacts.ps1") `
    -Parameters $archiveParameters

  $verifyArchiveParameters = @{}
  if (-not [string]::IsNullOrWhiteSpace($ReleaseName)) {
    $verifyArchiveParameters.ReleaseName = $ReleaseName
  }

  Invoke-Step `
    -Description "Verifying release archive checksums" `
    -ScriptPath (Join-Path $PSScriptRoot "verify_release_archive.ps1") `
    -Parameters $verifyArchiveParameters
}

if (-not $SkipEvidence) {
  $evidenceParameters = @{
    Mode = $mode
  }
  if (-not [string]::IsNullOrWhiteSpace($ReleaseName)) {
    $evidenceParameters.ReleaseName = $ReleaseName
  }

  Invoke-Step `
    -Description "Creating go-live evidence report" `
    -ScriptPath (Join-Path $PSScriptRoot "create_go_live_evidence.ps1") `
    -Parameters $evidenceParameters
}

Write-Host ""
Write-Host "Go-live preparation completed."
Write-Host "Workspace: $repoRoot"
