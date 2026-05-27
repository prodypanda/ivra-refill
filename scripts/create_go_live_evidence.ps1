param(
  [ValidateSet("demo", "production")]
  [string]$Mode = "production",
  [string]$ReleaseName,
  [string]$ReleasePath,
  [string]$OutputPath,
  [switch]$SkipReadiness
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$repoRoot = Split-Path $PSScriptRoot -Parent
$releaseRoot = Join-Path $repoRoot ".generated\release\releases"

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $repoRoot ".generated\release\go-live-evidence.md"
}

function Get-PubspecVersion {
  $pubspecPath = Join-Path $repoRoot "pubspec.yaml"
  if (-not (Test-Path -LiteralPath $pubspecPath -PathType Leaf)) {
    return "unknown"
  }

  $versionLine = Get-Content -LiteralPath $pubspecPath |
    Where-Object { $_ -match "^version:\s*(.+)$" } |
    Select-Object -First 1

  if ($null -eq $versionLine) {
    return "unknown"
  }

  return ($versionLine -replace "^version:\s*", "").Trim()
}

function Resolve-ReleasePath {
  if (-not [string]::IsNullOrWhiteSpace($ReleasePath)) {
    return [System.IO.Path]::GetFullPath($ReleasePath)
  }

  if (-not [string]::IsNullOrWhiteSpace($ReleaseName)) {
    return [System.IO.Path]::GetFullPath((Join-Path $releaseRoot $ReleaseName))
  }

  $latestRelease = Get-ChildItem -LiteralPath $releaseRoot -Directory -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

  if ($null -eq $latestRelease) {
    return $null
  }

  return $latestRelease.FullName
}

function Read-KeyValueFile {
  param([string]$Path)

  $values = @{}
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    return $values
  }

  foreach ($rawLine in Get-Content -LiteralPath $Path) {
    $line = $rawLine.Trim()
    if ($line.Length -eq 0 -or $line.StartsWith("#")) {
      continue
    }

    $separatorIndex = $line.IndexOf("=")
    if ($separatorIndex -le 0) {
      continue
    }

    $values[$line.Substring(0, $separatorIndex).Trim()] =
      $line.Substring($separatorIndex + 1).Trim()
  }

  return $values
}

function Convert-Status {
  param([bool]$Value)

  if ($Value) {
    return "OK"
  }

  return "Missing"
}

$resolvedReleasePath = Resolve-ReleasePath
$manifestPath = Join-Path $repoRoot ".generated\release\release-manifest.json"
$releaseManifestPath = if ($null -ne $resolvedReleasePath) {
  Join-Path $resolvedReleasePath "release-manifest.json"
} else {
  $null
}

if ($null -ne $releaseManifestPath -and (Test-Path -LiteralPath $releaseManifestPath -PathType Leaf)) {
  $manifestPath = $releaseManifestPath
}

$manifest = $null
if (Test-Path -LiteralPath $manifestPath -PathType Leaf) {
  $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
}

$envPath = Join-Path $repoRoot ".env"
$envValues = Read-IvraDotEnv -Path $envPath
$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"
$keyProperties = Read-KeyValueFile -Path $keyPropertiesPath
$checklistPath = Join-Path $repoRoot "docs\02-todo-checklist.md"

$supabaseUrlHost = "not configured"
if ($envValues.ContainsKey("SUPABASE_URL")) {
  $parsedUrl = $null
  if ([System.Uri]::TryCreate([string]$envValues["SUPABASE_URL"], [System.UriKind]::Absolute, [ref]$parsedUrl)) {
    $supabaseUrlHost = $parsedUrl.Host
  }
}

$projectRef = if ($envValues.ContainsKey("SUPABASE_PROJECT_REF")) {
  [string]$envValues["SUPABASE_PROJECT_REF"]
} else {
  "not configured"
}

$keystoreConfigured =
  $keyProperties.ContainsKey("storeFile") -and
  $keyProperties.ContainsKey("storePassword") -and
  $keyProperties.ContainsKey("keyAlias") -and
  $keyProperties.ContainsKey("keyPassword")

$uncheckedItems = @()
if (Test-Path -LiteralPath $checklistPath -PathType Leaf) {
  $uncheckedItems = Get-Content -LiteralPath $checklistPath |
    Where-Object { $_ -match "^\s*-\s+\[ \]\s+(.+)$" } |
    ForEach-Object { ($_ -replace "^\s*-\s+\[ \]\s+", "").Trim() }
}

$archiveVerificationStatus = "Not run"
$archiveVerificationOutput = @()
if ($null -ne $resolvedReleasePath -and (Test-Path -LiteralPath $resolvedReleasePath -PathType Container)) {
  $verifyScript = Join-Path $PSScriptRoot "verify_release_archive.ps1"
  $archiveVerificationOutput = & $verifyScript -ReleasePath $resolvedReleasePath 2>&1 |
    ForEach-Object { $_.ToString() }
  $archiveVerificationStatus = if ($LASTEXITCODE -eq 0 -or $?) { "Passed" } else { "Failed" }
}

$readinessStatus = "Skipped"
$readinessOutput = @()
if (-not $SkipReadiness) {
  $readinessScript = Join-Path $PSScriptRoot "check_release_readiness.ps1"
  $powershellPath = (Get-Process -Id $PID).Path
  $readinessOutput = & $powershellPath -NoProfile -ExecutionPolicy Bypass -File $readinessScript 2>&1 |
    ForEach-Object { $_.ToString() }
  $readinessStatus = if ($LASTEXITCODE -eq 0) { "Passed" } else { "Failed" }
}

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Ivra Go-Live Evidence") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Generated UTC: $((Get-Date).ToUniversalTime().ToString("o"))") | Out-Null
$lines.Add("- Workspace: $repoRoot") | Out-Null
$lines.Add("- Mode: $Mode") | Out-Null
$lines.Add("- App version: $(Get-PubspecVersion)") | Out-Null
$lines.Add("- Package ID: com.ivra.refill") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Environment Status") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Production .env: $(Convert-Status -Value (Test-Path -LiteralPath $envPath -PathType Leaf))") | Out-Null
$lines.Add("- Supabase project host: $supabaseUrlHost") | Out-Null
$lines.Add("- Supabase project ref: $projectRef") | Out-Null
$lines.Add("- Android signing file: $(Convert-Status -Value (Test-Path -LiteralPath $keyPropertiesPath -PathType Leaf))") | Out-Null
$lines.Add("- Android signing values: $(Convert-Status -Value $keystoreConfigured)") | Out-Null
$lines.Add("") | Out-Null

$lines.Add("## Release Archive") | Out-Null
$lines.Add("") | Out-Null
if ($null -eq $resolvedReleasePath) {
  $lines.Add("- Archive folder: not found") | Out-Null
} else {
  $lines.Add("- Archive folder: $resolvedReleasePath") | Out-Null
  $lines.Add("- Archive verification: $archiveVerificationStatus") | Out-Null
}
$lines.Add("- Manifest: $manifestPath") | Out-Null
$lines.Add("") | Out-Null

if ($null -ne $manifest) {
  $lines.Add("| Artifact | Type | Exists | Bytes | SHA-256 |") | Out-Null
  $lines.Add("| --- | --- | --- | ---: | --- |") | Out-Null
  foreach ($artifact in $manifest.artifacts) {
    $bytes = if ($null -ne $artifact.bytes) { $artifact.bytes } else { "" }
    $hash = if ($null -ne $artifact.sha256) { $artifact.sha256 } else { "" }
    $lines.Add("| $($artifact.name) | $($artifact.type) | $($artifact.exists) | $bytes | $hash |") | Out-Null
  }
  $lines.Add("") | Out-Null
}

$checksumsPath = if ($null -ne $resolvedReleasePath) {
  Join-Path $resolvedReleasePath "checksums.sha256"
} else {
  $null
}
if ($null -ne $checksumsPath -and (Test-Path -LiteralPath $checksumsPath -PathType Leaf)) {
  $lines.Add("## Checksums") | Out-Null
  $lines.Add("") | Out-Null
  $lines.Add('````text') | Out-Null
  foreach ($line in Get-Content -LiteralPath $checksumsPath) {
    $lines.Add($line) | Out-Null
  }
  $lines.Add('````') | Out-Null
  $lines.Add("") | Out-Null
}

$lines.Add("## Release Readiness") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Status: $readinessStatus") | Out-Null
if ($readinessOutput.Count -gt 0) {
  $lines.Add("") | Out-Null
  $lines.Add('````text') | Out-Null
  foreach ($line in $readinessOutput) {
    $lines.Add($line) | Out-Null
  }
  $lines.Add('````') | Out-Null
}
$lines.Add("") | Out-Null

$lines.Add("## Open Checklist Items") | Out-Null
$lines.Add("") | Out-Null
if ($uncheckedItems.Count -eq 0) {
  $lines.Add("- None") | Out-Null
} else {
  foreach ($item in $uncheckedItems) {
    $lines.Add("- $item") | Out-Null
  }
}
$lines.Add("") | Out-Null

$lines.Add("## Next Required Actions") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Create production .env with .\scripts\setup_supabase_env.ps1.") | Out-Null
$lines.Add("- Create Android release signing with .\scripts\setup_android_signing.ps1.") | Out-Null
$lines.Add("- Apply the Supabase migration and create real role accounts.") | Out-Null
$lines.Add("- Run RLS verification with real app_admin, app_manager, hotel_manager, and hotel_staff accounts.") | Out-Null
$lines.Add("- Rerun .\scripts\prepare_go_live.ps1 -IncludeAppBundle in production mode.") | Out-Null

$outputDirectory = Split-Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$lines | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "Go-live evidence written."
Write-Host "Path: $OutputPath"
