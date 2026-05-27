param(
  [switch]$BootstrapFirstAdmin,
  [switch]$SeedRlsDemoData,
  [switch]$RlsVerification,
  [switch]$All,
  [string]$AdminUserId = $env:IVRA_APP_ADMIN_ID,
  [string]$AppManagerUserId = $env:IVRA_APP_MANAGER_ID,
  [string]$HotelManagerUserId = $env:IVRA_HOTEL_MANAGER_ID,
  [string]$HotelStaffUserId = $env:IVRA_HOTEL_STAFF_ID,
  [string]$HotelAId = $env:IVRA_RLS_HOTEL_A_ID,
  [string]$HotelBId = $env:IVRA_RLS_HOTEL_B_ID,
  [string]$AdminEmail = $env:IVRA_ADMIN_EMAIL,
  [string]$AppManagerEmail = $env:IVRA_APP_MANAGER_EMAIL,
  [string]$HotelManagerEmail = $env:IVRA_HOTEL_MANAGER_EMAIL,
  [string]$HotelStaffEmail = $env:IVRA_HOTEL_STAFF_EMAIL,
  [string]$AdminFullName = $env:IVRA_ADMIN_FULL_NAME,
  [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) ".generated\supabase")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent

if (-not ($BootstrapFirstAdmin -or $SeedRlsDemoData -or $RlsVerification -or $All)) {
  $All = $true
}

if ($All) {
  $BootstrapFirstAdmin = $true
  $SeedRlsDemoData = $true
  $RlsVerification = $true
}

if ([string]::IsNullOrWhiteSpace($HotelAId)) {
  $HotelAId = "10000000-0000-4000-8000-000000000001"
}

if ([string]::IsNullOrWhiteSpace($HotelBId)) {
  $HotelBId = "10000000-0000-4000-8000-000000000002"
}

if ([string]::IsNullOrWhiteSpace($AdminFullName)) {
  $AdminFullName = "Ivra Admin"
}

function Test-Uuid {
  param([string]$Value)

  $ignored = [Guid]::Empty
  return [Guid]::TryParse($Value, [ref]$ignored)
}

function Assert-Uuid {
  param(
    [string]$Name,
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value) -or -not (Test-Uuid $Value)) {
    throw "$Name must be a valid UUID."
  }
}

function Assert-Text {
  param(
    [string]$Name,
    [string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw "$Name is required."
  }
}

function Assert-NonTemplateEmail {
  param(
    [string]$Name,
    [string]$Value
  )

  Assert-Text -Name $Name -Value $Value

  if ($Value -like "*@ivra.test") {
    throw "$Name is still a template email. Use the real Supabase Auth email."
  }
}

function ConvertTo-SqlLiteralValue {
  param([string]$Value)

  return $Value.Replace("'", "''")
}

function Write-RenderedSql {
  param(
    [string]$SourceRelativePath,
    [string]$OutputFileName,
    [hashtable]$Replacements
  )

  $sourcePath = Join-Path $repoRoot $SourceRelativePath
  if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Template not found: $SourceRelativePath"
  }

  if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
  }

  $content = Get-Content -LiteralPath $sourcePath -Raw
  foreach ($key in $Replacements.Keys) {
    $content = $content.Replace($key, [string]$Replacements[$key])
  }

  $targetPath = Join-Path $OutputDir $OutputFileName
  Set-Content -LiteralPath $targetPath -Value $content -Encoding UTF8

  Write-Host "Rendered $targetPath"
}

$placeholderAdminId = "00000000-0000-0000-0000-000000000001"
$placeholderAppManagerId = "00000000-0000-0000-0000-000000000002"
$placeholderHotelManagerId = "00000000-0000-0000-0000-000000000003"
$placeholderHotelStaffId = "00000000-0000-0000-0000-000000000004"
$placeholderHotelAId = "10000000-0000-4000-8000-000000000001"
$placeholderHotelBId = "10000000-0000-4000-8000-000000000002"

if ($BootstrapFirstAdmin) {
  Assert-Uuid -Name "AdminUserId" -Value $AdminUserId
  Assert-NonTemplateEmail -Name "AdminEmail" -Value $AdminEmail
  Assert-Text -Name "AdminFullName" -Value $AdminFullName

  Write-RenderedSql `
    -SourceRelativePath "supabase\bootstrap_first_admin.sql" `
    -OutputFileName "bootstrap_first_admin.rendered.sql" `
    -Replacements @{
      $placeholderAdminId = $AdminUserId
      "admin@ivra.test" = (ConvertTo-SqlLiteralValue $AdminEmail)
      "Ivra Admin" = (ConvertTo-SqlLiteralValue $AdminFullName)
    }
}

if ($SeedRlsDemoData) {
  Assert-Uuid -Name "AdminUserId" -Value $AdminUserId
  Assert-Uuid -Name "AppManagerUserId" -Value $AppManagerUserId
  Assert-Uuid -Name "HotelManagerUserId" -Value $HotelManagerUserId
  Assert-Uuid -Name "HotelStaffUserId" -Value $HotelStaffUserId
  Assert-Uuid -Name "HotelAId" -Value $HotelAId
  Assert-Uuid -Name "HotelBId" -Value $HotelBId
  Assert-NonTemplateEmail -Name "AdminEmail" -Value $AdminEmail
  Assert-NonTemplateEmail -Name "AppManagerEmail" -Value $AppManagerEmail
  Assert-NonTemplateEmail -Name "HotelManagerEmail" -Value $HotelManagerEmail
  Assert-NonTemplateEmail -Name "HotelStaffEmail" -Value $HotelStaffEmail

  Write-RenderedSql `
    -SourceRelativePath "supabase\seed_rls_demo_data.sql" `
    -OutputFileName "seed_rls_demo_data.rendered.sql" `
    -Replacements @{
      $placeholderAdminId = $AdminUserId
      $placeholderAppManagerId = $AppManagerUserId
      $placeholderHotelManagerId = $HotelManagerUserId
      $placeholderHotelStaffId = $HotelStaffUserId
      $placeholderHotelAId = $HotelAId
      $placeholderHotelBId = $HotelBId
      "app-admin@ivra.test" = (ConvertTo-SqlLiteralValue $AdminEmail)
      "app-manager@ivra.test" = (ConvertTo-SqlLiteralValue $AppManagerEmail)
      "hotel-manager@ivra.test" = (ConvertTo-SqlLiteralValue $HotelManagerEmail)
      "hotel-staff@ivra.test" = (ConvertTo-SqlLiteralValue $HotelStaffEmail)
    }
}

if ($RlsVerification) {
  Assert-Uuid -Name "AdminUserId" -Value $AdminUserId
  Assert-Uuid -Name "AppManagerUserId" -Value $AppManagerUserId
  Assert-Uuid -Name "HotelManagerUserId" -Value $HotelManagerUserId
  Assert-Uuid -Name "HotelStaffUserId" -Value $HotelStaffUserId
  Assert-Uuid -Name "HotelAId" -Value $HotelAId
  Assert-Uuid -Name "HotelBId" -Value $HotelBId

  Write-RenderedSql `
    -SourceRelativePath "supabase\rls_verification.sql" `
    -OutputFileName "rls_verification.rendered.sql" `
    -Replacements @{
      $placeholderAdminId = $AdminUserId
      $placeholderAppManagerId = $AppManagerUserId
      $placeholderHotelManagerId = $HotelManagerUserId
      $placeholderHotelStaffId = $HotelStaffUserId
      $placeholderHotelAId = $HotelAId
      $placeholderHotelBId = $HotelBId
    }
}

Write-Host ""
Write-Host "Rendered SQL files are local deployment artifacts and are ignored by git."
Write-Host "Review each rendered file before pasting it into the Supabase SQL editor."
