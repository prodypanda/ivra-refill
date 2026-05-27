param(
  [ValidateSet("demo", "production")]
  [string]$Mode = "production",
  [switch]$IncludeAppBundle,
  [string]$ReleaseName,
  [switch]$Force,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent

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

function Get-SafeName {
  param([string]$Value)

  return ($Value -replace "[^A-Za-z0-9._-]", "-")
}

function Add-ChecksumLine {
  param(
    [System.Collections.Generic.List[string]]$Lines,
    [string]$Path,
    [string]$BasePath
  )

  $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
  $relativePath = [System.IO.Path]::GetRelativePath($BasePath, $Path).Replace("\", "/")
  $Lines.Add("$($hash.Hash.ToLowerInvariant())  $relativePath") | Out-Null
}

$version = Get-PubspecVersion
$safeVersion = Get-SafeName -Value $version
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmss")

if ([string]::IsNullOrWhiteSpace($ReleaseName)) {
  $ReleaseName = "ivra-refill-$safeVersion-$Mode-$timestamp"
}

$releaseRoot = Join-Path $repoRoot ".generated\release\releases"
$releaseDir = Join-Path $releaseRoot $ReleaseName
$releaseRootFull = [System.IO.Path]::GetFullPath($releaseRoot)
$releaseDirFull = [System.IO.Path]::GetFullPath($releaseDir)
$webBuildDir = Join-Path $repoRoot "build\web"
$apkPath = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"
$aabPath = Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"
$manifestPath = Join-Path $repoRoot ".generated\release\release-manifest.json"
$manifestScript = Join-Path $PSScriptRoot "create_release_manifest.ps1"

if (-not $DryRun) {
  if (-not (Test-Path -LiteralPath $webBuildDir -PathType Container)) {
    throw "Missing web build directory: $webBuildDir"
  }

  if (-not (Test-Path -LiteralPath $apkPath -PathType Leaf)) {
    throw "Missing release APK: $apkPath"
  }

  if ($IncludeAppBundle -and -not (Test-Path -LiteralPath $aabPath -PathType Leaf)) {
    throw "Missing release app bundle: $aabPath"
  }
}

if ((Test-Path -LiteralPath $releaseDir) -and -not $Force) {
  throw "$releaseDir already exists. Use -Force to replace it."
}

Write-Host "Ivra release archive"
Write-Host "Mode: $Mode"
Write-Host "Release: $ReleaseName"
Write-Host "Target: $releaseDir"

if ($DryRun) {
  Write-Host "Would refresh manifest: $manifestPath"
  Write-Host "Would zip web build from: $webBuildDir"
  Write-Host "Would copy APK: $apkPath"
  if ($IncludeAppBundle) {
    Write-Host "Would copy AAB: $aabPath"
  }
  Write-Host "Would write checksums.sha256"
  Write-Host "Dry run complete. No files were written."
  exit 0
}

& $manifestScript -Mode $Mode -IncludeAppBundle:$IncludeAppBundle
if (-not $?) {
  exit 1
}

if (Test-Path -LiteralPath $releaseDir) {
  $releaseRootWithSeparator = $releaseRootFull.TrimEnd([System.IO.Path]::DirectorySeparatorChar) +
    [System.IO.Path]::DirectorySeparatorChar
  if (-not $releaseDirFull.StartsWith($releaseRootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to delete a release directory outside $releaseRootFull."
  }

  Remove-Item -LiteralPath $releaseDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

$webZipName = "ivra-refill-web-$safeVersion-$Mode.zip"
$apkName = "ivra-refill-$safeVersion-$Mode.apk"
$aabName = "ivra-refill-$safeVersion-$Mode.aab"

$webZipPath = Join-Path $releaseDir $webZipName
$releaseApkPath = Join-Path $releaseDir $apkName
$releaseManifestPath = Join-Path $releaseDir "release-manifest.json"
$checksumsPath = Join-Path $releaseDir "checksums.sha256"

Compress-Archive -Path (Join-Path $webBuildDir "*") -DestinationPath $webZipPath -Force
Copy-Item -LiteralPath $apkPath -Destination $releaseApkPath -Force
Copy-Item -LiteralPath $manifestPath -Destination $releaseManifestPath -Force

if ($IncludeAppBundle) {
  $releaseAabPath = Join-Path $releaseDir $aabName
  Copy-Item -LiteralPath $aabPath -Destination $releaseAabPath -Force
}

$checksumLines = New-Object System.Collections.Generic.List[string]
Get-ChildItem -LiteralPath $releaseDir -File |
  Where-Object { $_.Name -ne "checksums.sha256" } |
  Sort-Object Name |
  ForEach-Object {
    Add-ChecksumLine -Lines $checksumLines -Path $_.FullName -BasePath $releaseDir
  }

$checksumLines | Set-Content -LiteralPath $checksumsPath -Encoding UTF8

Write-Host ""
Write-Host "Release archive created."
Write-Host "Folder: $releaseDir"
Write-Host "Web zip: $webZipPath"
Write-Host "APK: $releaseApkPath"
if ($IncludeAppBundle) {
  Write-Host "AAB: $releaseAabPath"
}
Write-Host "Manifest: $releaseManifestPath"
Write-Host "Checksums: $checksumsPath"
