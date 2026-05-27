param(
  [string]$KeystorePath = "C:\secure\ivra-release.jks",
  [string]$KeyAlias = "ivra",
  [int]$ValidityDays = 10000,
  [string]$DistinguishedName = "CN=Ivra, OU=Operations, O=Ivra, L=Tunis, ST=Tunis, C=TN",
  [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path $PSScriptRoot -Parent
$androidDir = Join-Path $repoRoot "android"
$keyPropertiesPath = Join-Path $androidDir "key.properties"

function Convert-SecureStringToPlainText {
  param([securestring]$Value)

  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Value)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

if ((Test-Path -LiteralPath $keyPropertiesPath) -and -not $Force) {
  throw "android/key.properties already exists. Use -Force to overwrite it."
}

if ((Test-Path -LiteralPath $KeystorePath) -and -not $Force) {
  throw "Keystore already exists at $KeystorePath. Use -Force to overwrite it."
}

$keytool = Get-Command keytool -ErrorAction SilentlyContinue
if ($null -eq $keytool -and -not [string]::IsNullOrWhiteSpace($env:JAVA_HOME)) {
  $candidate = Join-Path $env:JAVA_HOME "bin\keytool.exe"
  if (Test-Path -LiteralPath $candidate -PathType Leaf) {
    $keytool = Get-Item -LiteralPath $candidate
  }
}

if ($null -eq $keytool) {
  throw "keytool was not found on PATH or JAVA_HOME. Install a JDK or use Android Studio's bundled JDK."
}

$keystoreDirectory = Split-Path $KeystorePath -Parent
if (-not (Test-Path -LiteralPath $keystoreDirectory)) {
  New-Item -ItemType Directory -Path $keystoreDirectory | Out-Null
}

$storePasswordSecure = Read-Host "Enter release keystore password" -AsSecureString
$keyPasswordSecure = Read-Host "Enter release key password" -AsSecureString

$storePassword = Convert-SecureStringToPlainText $storePasswordSecure
$keyPassword = Convert-SecureStringToPlainText $keyPasswordSecure

if ([string]::IsNullOrWhiteSpace($storePassword) -or [string]::IsNullOrWhiteSpace($keyPassword)) {
  throw "Passwords cannot be empty."
}

if (Test-Path -LiteralPath $KeystorePath) {
  Remove-Item -LiteralPath $KeystorePath -Force
}

Write-Host "Creating Android release keystore at $KeystorePath"
& $keytool.Source `
  -genkeypair `
  -v `
  -keystore $KeystorePath `
  -storepass $storePassword `
  -keypass $keyPassword `
  -alias $KeyAlias `
  -keyalg RSA `
  -keysize 2048 `
  -validity $ValidityDays `
  -dname $DistinguishedName

if ($LASTEXITCODE -ne 0) {
  exit $LASTEXITCODE
}

$safeStoreFile = $KeystorePath.Replace("\", "/")
$content = @"
storeFile=$safeStoreFile
storePassword=$storePassword
keyAlias=$KeyAlias
keyPassword=$keyPassword
"@

Set-Content -LiteralPath $keyPropertiesPath -Value $content -Encoding UTF8

Write-Host "Wrote android/key.properties"
Write-Host "Both android/key.properties and *.jks files are ignored by git."
Write-Host "Run .\scripts\build_android_release.ps1 to verify release signing."

