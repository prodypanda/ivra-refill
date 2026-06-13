.\scripts\generate_version.ps1

$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^(.*?)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Remove quotes if they exist
            $value = $value -replace '^"|"$','' -replace "^'|'$",""
            Set-Item -Path Env:$name -Value $value
        }
    }
}

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_ANON_KEY) {
    Write-Error "SUPABASE_URL and SUPABASE_ANON_KEY must be set in .env or environment"
    exit 1
}

flutter build apk --release --tree-shake-icons --dart-define=SUPABASE_URL="$env:SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$env:SUPABASE_ANON_KEY"
.\deploy\assemble_public.ps1 -SupabaseUrl "$env:SUPABASE_URL" -SupabaseAnonKey "$env:SUPABASE_ANON_KEY"
firebase deploy --only hosting
