$ErrorActionPreference = 'Stop'
$pubspec = Get-Content "pubspec.yaml" -Raw
$match = [regex]::Match($pubspec, '(?m)^version:\s*(.+)$')
if ($match.Success) {
    $version = $match.Groups[1].Value.Trim()
    $displayVersion = $version.Split('+')[0]
    $content = "// GENERATED FILE. DO NOT EDIT.
const appVersion = '$displayVersion';
"
    Set-Content -Path "lib\src\version.dart" -Value $content
    Write-Host "Generated lib\src\version.dart with version $version"
} else {
    Write-Error "Could not find version in pubspec.yaml"
}
