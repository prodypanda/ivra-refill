$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$repoRoot = Split-Path $PSScriptRoot -Parent
$failures = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Failure {
  param([string]$Message)
  $failures.Add($Message) | Out-Null
}

function Add-Warning {
  param([string]$Message)
  $warnings.Add($Message) | Out-Null
}

function Test-RequiredFile {
  param([string]$RelativePath)

  $path = Join-Path $repoRoot $RelativePath
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    Add-Failure "Missing required file: $RelativePath"
  }
}

function Read-KeyValueFile {
  param([string]$Path)

  $values = @{}
  if (-not (Test-Path -LiteralPath $Path)) {
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

    $key = $line.Substring(0, $separatorIndex).Trim()
    $value = $line.Substring($separatorIndex + 1).Trim()
    $values[$key] = $value
  }

  return $values
}

function Test-RealValue {
  param(
    [hashtable]$Values,
    [string]$Key
  )

  if (-not $Values.ContainsKey($Key)) {
    return $false
  }

  $value = [string]$Values[$Key]
  return -not [string]::IsNullOrWhiteSpace($value) -and
    $value -notlike "YOUR_*" -and
    $value -notlike "*YOUR_PROJECT*"
}

Write-Host "Checking Ivra release readiness..."

$requiredFiles = @(
  ".env.example",
  "CHANGELOG.md",
  "CONTRIBUTING.md",
  "README.md",
  "SECURITY.md",
  ".github\workflows\flutter-ci.yml",
  "android\key.properties.example",
  "docs\04-supabase-deployment-runbook.md",
  "docs\05-release-checklist.md",
  "docs\06-pilot-onboarding-checklist.md",
  "docs\07-data-and-privacy-notes.md",
  "docs\08-go-live-record.md",
  "supabase\migrations\0001_initial_schema.sql",
  "supabase\bootstrap_first_admin.sql",
  "supabase\seed_rls_demo_data.sql",
  "supabase\rls_verification.sql",
  "scripts\verify_local.ps1",
  "scripts\setup_supabase_env.ps1",
  "scripts\deploy_supabase.ps1",
  "scripts\render_supabase_sql.ps1",
  "scripts\verify_supabase_rls.ps1",
  "scripts\build_web.ps1",
  "scripts\build_android_debug.ps1",
  "scripts\build_android_release.ps1",
  "scripts\build_android_bundle.ps1",
  "scripts\package_release.ps1",
  "scripts\create_release_manifest.ps1",
  "scripts\archive_release_artifacts.ps1",
  "scripts\verify_release_archive.ps1",
  "scripts\prepare_go_live.ps1",
  "scripts\create_go_live_evidence.ps1",
  "scripts\setup_android_signing.ps1",
  "android\app\src\main\res\mipmap-anydpi-v26\ic_launcher.xml",
  "android\app\src\main\res\values-v31\styles.xml",
  "web\manifest.json"
)

foreach ($file in $requiredFiles) {
  Test-RequiredFile $file
}

$envPath = Join-Path $repoRoot ".env"
$envValues = Read-IvraDotEnv -Path $envPath
if (-not (Test-Path -LiteralPath $envPath -PathType Leaf)) {
  Add-Failure "Missing .env with production SUPABASE_URL, SUPABASE_ANON_KEY, and SUPABASE_PROJECT_REF."
} else {
  if (-not (Test-RealValue -Values $envValues -Key "SUPABASE_URL")) {
    Add-Failure ".env SUPABASE_URL is missing or still a placeholder."
  }
  if (-not (Test-RealValue -Values $envValues -Key "SUPABASE_ANON_KEY")) {
    Add-Failure ".env SUPABASE_ANON_KEY is missing or still a placeholder."
  }
  if (-not (Test-RealValue -Values $envValues -Key "SUPABASE_PROJECT_REF")) {
    Add-Failure ".env SUPABASE_PROJECT_REF is missing or still a placeholder."
  }
}

$keyPropertiesPath = Join-Path $repoRoot "android\key.properties"
$keyProperties = Read-KeyValueFile -Path $keyPropertiesPath
if (-not (Test-Path -LiteralPath $keyPropertiesPath -PathType Leaf)) {
  Add-Failure "Missing android/key.properties for release signing."
} else {
  foreach ($key in @("storeFile", "storePassword", "keyAlias", "keyPassword")) {
    if (-not (Test-RealValue -Values $keyProperties -Key $key)) {
      Add-Failure "android/key.properties $key is missing or still a placeholder."
    }
  }

  if ($keyProperties.ContainsKey("storeFile")) {
    $storeFile = [string]$keyProperties["storeFile"]
    if (-not [System.IO.Path]::IsPathRooted($storeFile)) {
      $storeFile = Join-Path (Join-Path $repoRoot "android") $storeFile
    }

    if (-not (Test-Path -LiteralPath $storeFile -PathType Leaf)) {
      Add-Failure "Android release keystore file does not exist: $storeFile"
    }
  }
}

$checklistPath = Join-Path $repoRoot "docs\02-todo-checklist.md"
if (Test-Path -LiteralPath $checklistPath) {
  $checklist = Get-Content -LiteralPath $checklistPath -Raw
  foreach ($item in @(
    "Apply migration to Supabase project",
    "Create real users and assign profiles/roles",
    "Verify Supabase RLS with app_admin, app_manager, hotel_manager, and hotel_staff accounts"
  )) {
    if ($checklist -match "\- \[ \] $([regex]::Escape($item))") {
      Add-Failure "Release checklist still has an incomplete Supabase gate: $item"
    }
  }
}

$pubspecPath = Join-Path $repoRoot "pubspec.yaml"
if (Test-Path -LiteralPath $pubspecPath) {
  $pubspec = Get-Content -LiteralPath $pubspecPath -Raw
  if ($pubspec -notmatch "version:\s+\d+\.\d+\.\d+\+\d+") {
    Add-Warning "pubspec.yaml version does not look like semantic Flutter versioning."
  }
}

$textExtensions = @(
  ".dart",
  ".html",
  ".json",
  ".kts",
  ".md",
  ".ps1",
  ".sql",
  ".xml",
  ".yaml",
  ".yml"
)

$forbiddenPatterns = @(
  "com\.example",
  "Flutter Demo",
  "TODO",
  "FIXME",
  "pwa-strategy=none"
)

$excludedDirectories = @(
  "\.dart_tool\",
  "\.git\",
  "\.gradle\",
  "\.generated\",
  "\.idea\",
  "\build\"
)

$textFiles = Get-ChildItem -LiteralPath $repoRoot -Recurse -File -Force |
  Where-Object {
    $path = $_.FullName
    $extension = $_.Extension
    $isIgnoredDirectory = $false
    foreach ($excluded in $excludedDirectories) {
      if ($path.Contains($excluded)) {
        $isIgnoredDirectory = $true
        break
      }
    }

    -not $isIgnoredDirectory -and
    $_.FullName -ne $PSCommandPath -and (
      $textExtensions.Contains($extension) -or
      $_.Name -in @(".gitignore")
    )
  }

foreach ($file in $textFiles) {
  foreach ($pattern in $forbiddenPatterns) {
    $matches = Select-String -LiteralPath $file.FullName -Pattern $pattern -CaseSensitive
    foreach ($match in $matches) {
      $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $file.FullName)
      Add-Failure "Forbidden pattern '$pattern' in ${relativePath}:$($match.LineNumber)"
    }
  }
}

if ($warnings.Count -gt 0) {
  Write-Host ""
  Write-Host "Warnings:"
  foreach ($warning in $warnings) {
    Write-Host " - $warning"
  }
}

if ($failures.Count -gt 0) {
  Write-Host ""
  Write-Host "Release readiness failed:"
  foreach ($failure in $failures) {
    Write-Host " - $failure"
  }
  exit 1
}

Write-Host "Release readiness checks passed."
