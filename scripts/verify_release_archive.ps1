param(
  [string]$ReleaseName,
  [string]$ReleasePath
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$releaseRoot = Join-Path $repoRoot ".generated\release\releases"

if ([string]::IsNullOrWhiteSpace($ReleasePath)) {
  if ([string]::IsNullOrWhiteSpace($ReleaseName)) {
    $latestRelease = Get-ChildItem -LiteralPath $releaseRoot -Directory -ErrorAction SilentlyContinue |
      Sort-Object LastWriteTime -Descending |
      Select-Object -First 1

    if ($null -eq $latestRelease) {
      throw "No release archive folders found under $releaseRoot."
    }

    $ReleasePath = $latestRelease.FullName
  } else {
    $ReleasePath = Join-Path $releaseRoot $ReleaseName
  }
}

$ReleasePath = [System.IO.Path]::GetFullPath($ReleasePath)
if (-not (Test-Path -LiteralPath $ReleasePath -PathType Container)) {
  throw "Release archive folder does not exist: $ReleasePath"
}

$checksumsPath = Join-Path $ReleasePath "checksums.sha256"
if (-not (Test-Path -LiteralPath $checksumsPath -PathType Leaf)) {
  throw "Missing checksum file: $checksumsPath"
}

$failures = New-Object System.Collections.Generic.List[string]
$verified = 0

foreach ($rawLine in Get-Content -LiteralPath $checksumsPath) {
  $line = $rawLine.Trim()
  if ($line.Length -eq 0) {
    continue
  }

  $parts = $line -split "\s+", 2
  if ($parts.Count -ne 2) {
    $failures.Add("Invalid checksum line: $line") | Out-Null
    continue
  }

  $expectedHash = $parts[0].ToLowerInvariant()
  $relativePath = $parts[1].Trim()
  $artifactPath = Join-Path $ReleasePath $relativePath

  if (-not (Test-Path -LiteralPath $artifactPath -PathType Leaf)) {
    $failures.Add("Missing artifact: $relativePath") | Out-Null
    continue
  }

  $actualHash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($actualHash -ne $expectedHash) {
    $failures.Add("Checksum mismatch for ${relativePath}: expected $expectedHash, got $actualHash") | Out-Null
    continue
  }

  $verified += 1
}

if ($failures.Count -gt 0) {
  Write-Host "Release archive verification failed:"
  foreach ($failure in $failures) {
    Write-Host " - $failure"
  }
  exit 1
}

Write-Host "Release archive verified."
Write-Host "Folder: $ReleasePath"
Write-Host "Artifacts verified: $verified"
