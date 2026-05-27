param(
  [string]$ProjectRef = $env:SUPABASE_PROJECT_REF,
  [switch]$Login,
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$repoRoot = Split-Path $PSScriptRoot -Parent
$envValues = Read-IvraDotEnv

if ($envValues.ContainsKey("SUPABASE_PROJECT_REF")) {
  $ProjectRef = $envValues["SUPABASE_PROJECT_REF"]
}

if (
  [string]::IsNullOrWhiteSpace($ProjectRef) -or
  $ProjectRef -eq "YOUR_PROJECT_REF" -or
  $ProjectRef -like "YOUR_*"
) {
  throw "Set SUPABASE_PROJECT_REF in .env or pass -ProjectRef before deploying."
}

if (-not $DryRun) {
  $supabaseCommand = Get-Command supabase -ErrorAction SilentlyContinue
  if ($null -eq $supabaseCommand) {
    throw "Supabase CLI was not found on PATH. Install it first, then rerun this script."
  }
}

$migrationPath = Join-Path $repoRoot "supabase\migrations\0001_initial_schema.sql"
if (-not (Test-Path -LiteralPath $migrationPath -PathType Leaf)) {
  throw "Missing migration file: $migrationPath"
}

function Invoke-Step {
  param(
    [string]$Description,
    [string[]]$CommandArgs
  )

  Write-Host ""
  Write-Host $Description
  Write-Host "supabase $($CommandArgs -join ' ')"

  if ($DryRun) {
    return
  }

  & supabase @CommandArgs
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
}

Write-Host "Ivra Supabase deployment"
Write-Host "Project ref: $ProjectRef"
Write-Host "Migration: $migrationPath"

if ($Login) {
  Invoke-Step -Description "Logging in to Supabase" -CommandArgs @("login")
} else {
  Write-Host ""
  Write-Host "Skipping 'supabase login'. Use -Login if this machine is not already authenticated."
}

Invoke-Step -Description "Linking local project to Supabase" -CommandArgs @("link", "--project-ref", $ProjectRef)
Invoke-Step -Description "Applying migrations" -CommandArgs @("db", "push")

Write-Host ""
if ($DryRun) {
  Write-Host "Dry run complete. No Supabase commands were executed."
} else {
  Write-Host "Supabase migration deployment complete."
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Create the first Supabase Auth user."
Write-Host "2. Run supabase/bootstrap_first_admin.sql after replacing placeholders."
Write-Host "3. Create App Manager, Hotel Manager, and Hotel Staff accounts."
Write-Host "4. Run supabase/rls_verification.sql after replacing placeholders."
Write-Host "5. Mark the Supabase checklist items complete only after live verification passes."
