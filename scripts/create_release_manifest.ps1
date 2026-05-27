param(
  [ValidateSet("demo", "production")]
  [string]$Mode = "production",
  [switch]$IncludeAppBundle,
  [string]$OutputPath,
  [switch]$AllowMissing,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $repoRoot ".generated\release\release-manifest.json"
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

function New-StringSha256 {
  param([string]$Value)

  $sha256 = [System.Security.Cryptography.SHA256]::Create()
  try {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($Value)
    $hashBytes = $sha256.ComputeHash($bytes)
    return ([System.BitConverter]::ToString($hashBytes)).Replace("-", "").ToLowerInvariant()
  } finally {
    $sha256.Dispose()
  }
}

function New-FileArtifact {
  param(
    [string]$Name,
    [string]$Path
  )

  $absolutePath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
    return [pscustomobject]@{
      name = $Name
      type = "file"
      path = [System.IO.Path]::GetRelativePath($repoRoot, $absolutePath)
      exists = $false
    }
  }

  $file = Get-Item -LiteralPath $absolutePath
  $hash = Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256

  return [pscustomobject]@{
    name = $Name
    type = "file"
    path = [System.IO.Path]::GetRelativePath($repoRoot, $absolutePath)
    exists = $true
    bytes = $file.Length
    sha256 = $hash.Hash.ToLowerInvariant()
    lastWriteTimeUtc = $file.LastWriteTimeUtc.ToString("o")
  }
}

function New-DirectoryArtifact {
  param(
    [string]$Name,
    [string]$Path
  )

  $absolutePath = [System.IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $absolutePath -PathType Container)) {
    return [pscustomobject]@{
      name = $Name
      type = "directory"
      path = [System.IO.Path]::GetRelativePath($repoRoot, $absolutePath)
      exists = $false
    }
  }

  $files = Get-ChildItem -LiteralPath $absolutePath -Recurse -File |
    Sort-Object FullName

  $totalBytes = 0
  $hashLines = New-Object System.Collections.Generic.List[string]

  foreach ($file in $files) {
    $totalBytes += $file.Length
    $relativePath = [System.IO.Path]::GetRelativePath($absolutePath, $file.FullName)
    $fileHash = Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
    $hashLines.Add("$relativePath $($fileHash.Hash.ToLowerInvariant())") | Out-Null
  }

  $directoryHash = New-StringSha256 -Value ($hashLines -join "`n")

  return [pscustomobject]@{
    name = $Name
    type = "directory"
    path = [System.IO.Path]::GetRelativePath($repoRoot, $absolutePath)
    exists = $true
    fileCount = $files.Count
    bytes = $totalBytes
    sha256 = $directoryHash
  }
}

$artifacts = New-Object System.Collections.Generic.List[object]
$artifacts.Add((New-DirectoryArtifact -Name "web" -Path (Join-Path $repoRoot "build\web"))) | Out-Null
$artifacts.Add((New-FileArtifact -Name "android-apk" -Path (Join-Path $repoRoot "build\app\outputs\flutter-apk\app-release.apk"))) | Out-Null

if ($IncludeAppBundle) {
  $artifacts.Add((New-FileArtifact -Name "android-aab" -Path (Join-Path $repoRoot "build\app\outputs\bundle\release\app-release.aab"))) | Out-Null
}

$missingArtifacts = @($artifacts.ToArray() | Where-Object { -not $_.exists })
if ($missingArtifacts.Count -gt 0 -and -not $AllowMissing) {
  $names = ($missingArtifacts | ForEach-Object { $_.name }) -join ", "
  throw "Missing release artifacts: $names. Build first or rerun with -AllowMissing."
}

$manifest = [pscustomobject]@{
  app = "Ivra Refill"
  packageId = "com.ivra.refill"
  version = Get-PubspecVersion
  mode = $Mode
  generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
  artifacts = $artifacts.ToArray()
}

Write-Host "Ivra release manifest"
Write-Host "Mode: $Mode"
Write-Host "Target: $OutputPath"

if ($DryRun) {
  $manifest | ConvertTo-Json -Depth 6
  Write-Host "Dry run complete. No file was written."
  exit 0
}

$outputDirectory = Split-Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

Write-Host "Created $OutputPath."
