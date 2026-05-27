function Read-IvraDotEnv {
  param(
    [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent) ".env")
  )

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

    if (
      ($value.StartsWith('"') -and $value.EndsWith('"')) -or
      ($value.StartsWith("'") -and $value.EndsWith("'"))
    ) {
      $value = $value.Substring(1, $value.Length - 2)
    }

    if ($key.Length -gt 0) {
      $values[$key] = $value
      [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
  }

  return $values
}

function Get-IvraDartDefines {
  param(
    [hashtable]$Values,
    [switch]$RequireSupabase
  )

  $supabaseUrl = $env:SUPABASE_URL
  $supabaseAnonKey = $env:SUPABASE_ANON_KEY

  if ($Values.ContainsKey("SUPABASE_URL")) {
    $supabaseUrl = $Values["SUPABASE_URL"]
  }

  if ($Values.ContainsKey("SUPABASE_ANON_KEY")) {
    $supabaseAnonKey = $Values["SUPABASE_ANON_KEY"]
  }

  $hasRealSupabaseValues =
    -not [string]::IsNullOrWhiteSpace($supabaseUrl) -and
    -not [string]::IsNullOrWhiteSpace($supabaseAnonKey) -and
    $supabaseUrl -notlike "*YOUR_PROJECT*" -and
    $supabaseAnonKey -notlike "YOUR_*"

  if (-not $hasRealSupabaseValues) {
    if ($RequireSupabase) {
      throw "Production Supabase values are required. Create .env with SUPABASE_URL and SUPABASE_ANON_KEY, or run the script with -Demo for a demo build."
    }

    Write-Host "No real Supabase values found; using demo mode."
    return @()
  }

  return @(
    "--dart-define=SUPABASE_URL=$supabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$supabaseAnonKey"
  )
}

function Get-IvraFlutterCommand {
  if (-not [string]::IsNullOrWhiteSpace($env:FLUTTER_BIN)) {
    return $env:FLUTTER_BIN
  }

  return "flutter"
}

function Invoke-IvraFlutter {
  param(
    [string[]]$FlutterArgs
  )

  $flutter = Get-IvraFlutterCommand
  Write-Host "Running: $flutter $($FlutterArgs -join ' ')"
  & $flutter @FlutterArgs
  exit $LASTEXITCODE
}
