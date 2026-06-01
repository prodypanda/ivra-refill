# Assembles the deployable `public/` folder:
#   public/            -> the marketing landing page (deploy/landing/*)
#   public/app/        -> the Flutter web app (served under /app/)
#
# Usage (from the repo root, PowerShell):
#   .\deploy\assemble_public.ps1 -SupabaseUrl "https://xxxx.supabase.co" -SupabaseAnonKey "sb_publishable_..."
#
# Then deploy `public/` with your host of choice (see deploy/DEPLOYMENT.md).

param(
  [Parameter(Mandatory = $true)] [string] $SupabaseUrl,
  [Parameter(Mandatory = $true)] [string] $SupabaseAnonKey
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host "==> Building Flutter web app (base href /app/)..." -ForegroundColor Cyan
flutter build web --release `
  --base-href "/app/" `
  --dart-define=SUPABASE_URL=$SupabaseUrl `
  --dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey

Write-Host "==> Assembling public/ ..." -ForegroundColor Cyan
$public = Join-Path $repoRoot "public"
if (Test-Path $public) { Remove-Item $public -Recurse -Force }
New-Item -ItemType Directory -Path $public | Out-Null

# Landing page at the site root.
Copy-Item -Path (Join-Path $repoRoot "deploy\landing\*") -Destination $public -Recurse -Force

# Flutter web app under /app/.
New-Item -ItemType Directory -Path (Join-Path $public "app") | Out-Null
Copy-Item -Path (Join-Path $repoRoot "build\web\*") -Destination (Join-Path $public "app") -Recurse -Force

# Hosting config alongside public/ for `firebase deploy`.
Copy-Item -Path (Join-Path $repoRoot "deploy\firebase.json") -Destination $repoRoot -Force

Write-Host "==> Done. public/ is ready to deploy." -ForegroundColor Green
Write-Host "    Landing : $public\index.html"
Write-Host "    Web app : $public\app\index.html"
Write-Host ""
Write-Host "Reminder: edit window.IVRA_CONFIG in deploy/landing/index.html so" -ForegroundColor Yellow
Write-Host "WEB_APP_URL and DOWNLOAD_URL point at your real URLs before assembling." -ForegroundColor Yellow
