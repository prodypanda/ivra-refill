param(
  [string]$EnvPath,
  [string]$SupabaseUrl = $env:SUPABASE_URL,
  [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY,
  [string]$HotelId = $env:IVRA_RLS_HOTEL_A_ID,
  [string]$OtherHotelId = $env:IVRA_RLS_HOTEL_B_ID,
  [string]$AppAdminEmail = $env:IVRA_ADMIN_EMAIL,
  [string]$AppAdminPassword = $env:IVRA_APP_ADMIN_PASSWORD,
  [string]$AppManagerEmail = $env:IVRA_APP_MANAGER_EMAIL,
  [string]$AppManagerPassword = $env:IVRA_APP_MANAGER_PASSWORD,
  [string]$HotelManagerEmail = $env:IVRA_HOTEL_MANAGER_EMAIL,
  [string]$HotelManagerPassword = $env:IVRA_HOTEL_MANAGER_PASSWORD,
  [string]$HotelStaffEmail = $env:IVRA_HOTEL_STAFF_EMAIL,
  [string]$HotelStaffPassword = $env:IVRA_HOTEL_STAFF_PASSWORD,
  [string]$OutputPath,
  [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_ivra_env.ps1"

$repoRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($EnvPath)) {
  $EnvPath = Join-Path $repoRoot ".env"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $repoRoot ".generated\supabase\rls-rest-verification.md"
}

$envValues = Read-IvraDotEnv -Path $EnvPath
$results = New-Object System.Collections.Generic.List[object]

function Resolve-ConfigValue {
  param(
    [string]$Name,
    [string]$CurrentValue,
    [string[]]$FallbackNames = @()
  )

  if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
    return $CurrentValue.Trim()
  }

  foreach ($candidate in @($Name) + $FallbackNames) {
    if ($envValues.ContainsKey($candidate)) {
      $value = [string]$envValues[$candidate]
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value.Trim()
      }
    }

    $envValue = [Environment]::GetEnvironmentVariable($candidate, "Process")
    if (-not [string]::IsNullOrWhiteSpace($envValue)) {
      return $envValue.Trim()
    }
  }

  return $null
}

function Read-PlainSecret {
  param([string]$Prompt)

  $secure = Read-Host $Prompt -AsSecureString
  $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
  try {
    return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
  } finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
  }
}

function Require-Value {
  param(
    [string]$Name,
    [string]$Value,
    [string]$Prompt,
    [switch]$Secret
  )

  if (-not [string]::IsNullOrWhiteSpace($Value)) {
    return $Value.Trim()
  }

  if ($NonInteractive) {
    throw "$Name is required. Set it in .env, the environment, or pass it as a parameter."
  }

  if ($Secret) {
    $enteredSecret = Read-PlainSecret -Prompt $Prompt
    if ([string]::IsNullOrWhiteSpace($enteredSecret)) {
      throw "$Name is required."
    }
    return $enteredSecret
  }

  $enteredValue = Read-Host $Prompt
  if ([string]::IsNullOrWhiteSpace($enteredValue)) {
    throw "$Name is required."
  }
  return $enteredValue.Trim()
}

function Add-Check {
  param(
    [string]$Role,
    [string]$Name,
    [bool]$Passed,
    [string]$Details = ""
  )

  $results.Add([pscustomobject]@{
      Role    = $Role
      Check   = $Name
      Passed  = $Passed
      Details = $Details
    }) | Out-Null

  $status = if ($Passed) { "PASS" } else { "FAIL" }
  Write-Host "[$status] ${Role}: $Name"
  if (-not [string]::IsNullOrWhiteSpace($Details)) {
    Write-Host "       $Details"
  }
}

function ConvertTo-Array {
  param($Value)

  if ($null -eq $Value) {
    return @()
  }

  if ($Value -is [System.Array]) {
    return @($Value)
  }

  return @($Value)
}

function Invoke-JsonRequest {
  param(
    [string]$Method,
    [string]$Uri,
    [hashtable]$Headers,
    $Body = $null
  )

  try {
    $parameters = @{
      Method  = $Method
      Uri     = $Uri
      Headers = $Headers
    }

    if ($null -ne $Body) {
      $parameters["ContentType"] = "application/json"
      $parameters["Body"] = ($Body | ConvertTo-Json -Depth 20)
    }

    $data = Invoke-RestMethod @parameters
    return [pscustomobject]@{
      Ok         = $true
      StatusCode = 200
      Data       = $data
      Error      = $null
    }
  } catch {
    $statusCode = 0
    if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
      $statusCode = [int]$_.Exception.Response.StatusCode
    }

    return [pscustomobject]@{
      Ok         = $false
      StatusCode = $statusCode
      Data       = $null
      Error      = $_.Exception.Message
    }
  }
}

function Invoke-SupabaseAuth {
  param(
    [string]$Email,
    [string]$Password
  )

  $uri = "$($SupabaseUrl.TrimEnd('/'))/auth/v1/token?grant_type=password"
  $headers = @{
    apikey = $SupabaseAnonKey
    Accept = "application/json"
  }
  return Invoke-JsonRequest -Method "Post" -Uri $uri -Headers $headers -Body @{
    email    = $Email
    password = $Password
  }
}

function Invoke-SupabaseRest {
  param(
    $Session,
    [string]$Path,
    [string]$Method = "Get",
    $Body = $null
  )

  $headers = @{
    apikey        = $SupabaseAnonKey
    Authorization = "Bearer $($Session.AccessToken)"
    Accept        = "application/json"
  }
  $uri = "$($SupabaseUrl.TrimEnd('/'))$Path"
  return Invoke-JsonRequest -Method $Method -Uri $uri -Headers $headers -Body $Body
}

function Invoke-SupabaseAnonRest {
  param([string]$Path)

  $headers = @{
    apikey = $SupabaseAnonKey
    Accept = "application/json"
  }
  $uri = "$($SupabaseUrl.TrimEnd('/'))$Path"
  return Invoke-JsonRequest -Method "Get" -Uri $uri -Headers $headers
}

function Test-HotelScope {
  param(
    [array]$Rows,
    [string]$ExpectedHotelId,
    [string]$ForbiddenHotelId
  )

  if ([string]::IsNullOrWhiteSpace($ExpectedHotelId)) {
    return [pscustomobject]@{ Passed = $true; Details = "No expected hotel id supplied; scope count only." }
  }

  $hotelIds = @($Rows | ForEach-Object {
      if ($null -ne $_.hotel_id) {
        $_.hotel_id
      } else {
        $_.id
      }
    } | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })
  $forbiddenHits = @()
  if (-not [string]::IsNullOrWhiteSpace($ForbiddenHotelId)) {
    $forbiddenHits = @($hotelIds | Where-Object { [string]$_ -eq $ForbiddenHotelId })
  }

  $outsideScope = @($hotelIds | Where-Object { [string]$_ -ne $ExpectedHotelId })
  $passed = $outsideScope.Count -eq 0 -and $forbiddenHits.Count -eq 0
  $details = "Rows: $($Rows.Count); hotel ids visible: $((@($hotelIds) | Select-Object -Unique) -join ', ')"
  return [pscustomobject]@{ Passed = $passed; Details = $details }
}

$SupabaseUrl = Require-Value `
  -Name "SUPABASE_URL" `
  -Value (Resolve-ConfigValue -Name "SUPABASE_URL" -CurrentValue $SupabaseUrl) `
  -Prompt "Supabase project URL"

$SupabaseAnonKey = Require-Value `
  -Name "SUPABASE_ANON_KEY" `
  -Value (Resolve-ConfigValue -Name "SUPABASE_ANON_KEY" -CurrentValue $SupabaseAnonKey) `
  -Prompt "Supabase anon key" `
  -Secret

$HotelId = Resolve-ConfigValue -Name "IVRA_RLS_HOTEL_A_ID" -CurrentValue $HotelId
$OtherHotelId = Resolve-ConfigValue -Name "IVRA_RLS_HOTEL_B_ID" -CurrentValue $OtherHotelId

$roleInputs = @(
  @{
    Name = "app_admin"
    Email = Require-Value -Name "IVRA_ADMIN_EMAIL" -Value (Resolve-ConfigValue -Name "IVRA_ADMIN_EMAIL" -CurrentValue $AppAdminEmail) -Prompt "App Admin email"
    Password = Require-Value -Name "IVRA_APP_ADMIN_PASSWORD" -Value (Resolve-ConfigValue -Name "IVRA_APP_ADMIN_PASSWORD" -CurrentValue $AppAdminPassword) -Prompt "App Admin password" -Secret
    Scoped = $false
  },
  @{
    Name = "app_manager"
    Email = Require-Value -Name "IVRA_APP_MANAGER_EMAIL" -Value (Resolve-ConfigValue -Name "IVRA_APP_MANAGER_EMAIL" -CurrentValue $AppManagerEmail) -Prompt "App Manager email"
    Password = Require-Value -Name "IVRA_APP_MANAGER_PASSWORD" -Value (Resolve-ConfigValue -Name "IVRA_APP_MANAGER_PASSWORD" -CurrentValue $AppManagerPassword) -Prompt "App Manager password" -Secret
    Scoped = $false
  },
  @{
    Name = "hotel_manager"
    Email = Require-Value -Name "IVRA_HOTEL_MANAGER_EMAIL" -Value (Resolve-ConfigValue -Name "IVRA_HOTEL_MANAGER_EMAIL" -CurrentValue $HotelManagerEmail) -Prompt "Hotel Manager email"
    Password = Require-Value -Name "IVRA_HOTEL_MANAGER_PASSWORD" -Value (Resolve-ConfigValue -Name "IVRA_HOTEL_MANAGER_PASSWORD" -CurrentValue $HotelManagerPassword) -Prompt "Hotel Manager password" -Secret
    Scoped = $true
  },
  @{
    Name = "hotel_staff"
    Email = Require-Value -Name "IVRA_HOTEL_STAFF_EMAIL" -Value (Resolve-ConfigValue -Name "IVRA_HOTEL_STAFF_EMAIL" -CurrentValue $HotelStaffEmail) -Prompt "Hotel Staff email"
    Password = Require-Value -Name "IVRA_HOTEL_STAFF_PASSWORD" -Value (Resolve-ConfigValue -Name "IVRA_HOTEL_STAFF_PASSWORD" -CurrentValue $HotelStaffPassword) -Prompt "Hotel Staff password" -Secret
    Scoped = $true
  }
)

Write-Host "Ivra Supabase RLS REST verification"
Write-Host "URL: $SupabaseUrl"
Write-Host "Output: $OutputPath"
Write-Host ""

$anonProducts = Invoke-SupabaseAnonRest -Path "/rest/v1/products?select=id&limit=1"
$anonProductRows = ConvertTo-Array $anonProducts.Data
Add-Check -Role "anon" -Name "cannot read products" -Passed ((-not $anonProducts.Ok) -or $anonProductRows.Count -eq 0) -Details "Status: $($anonProducts.StatusCode); rows: $($anonProductRows.Count)"

$anonHotels = Invoke-SupabaseAnonRest -Path "/rest/v1/hotels?select=id&limit=1"
$anonHotelRows = ConvertTo-Array $anonHotels.Data
Add-Check -Role "anon" -Name "cannot read hotels" -Passed ((-not $anonHotels.Ok) -or $anonHotelRows.Count -eq 0) -Details "Status: $($anonHotels.StatusCode); rows: $($anonHotelRows.Count)"

foreach ($roleInput in $roleInputs) {
  $auth = Invoke-SupabaseAuth -Email $roleInput.Email -Password $roleInput.Password
  if (-not $auth.Ok) {
    Add-Check -Role $roleInput.Name -Name "can sign in" -Passed $false -Details $auth.Error
    continue
  }

  $session = [pscustomobject]@{
    AccessToken = $auth.Data.access_token
    UserId      = $auth.Data.user.id
  }

  Add-Check -Role $roleInput.Name -Name "can sign in" -Passed $true -Details "User: $($session.UserId)"

  $profileResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/profiles?id=eq.$($session.UserId)&select=id,role,hotel_id,is_active"
  $profiles = ConvertTo-Array $profileResponse.Data
  $profile = if ($profiles.Count -gt 0) { $profiles[0] } else { $null }
  Add-Check -Role $roleInput.Name -Name "profile is readable" -Passed ($profileResponse.Ok -and $profiles.Count -eq 1) -Details "Rows: $($profiles.Count)"

  if ($null -ne $profile) {
    Add-Check -Role $roleInput.Name -Name "profile role matches" -Passed ([string]$profile.role -eq [string]$roleInput.Name) -Details "Actual role: $($profile.role)"
    Add-Check -Role $roleInput.Name -Name "profile is active" -Passed ([bool]$profile.is_active) -Details "Active: $($profile.is_active)"

    if ($roleInput.Scoped -and -not [string]::IsNullOrWhiteSpace($HotelId)) {
      Add-Check -Role $roleInput.Name -Name "profile hotel matches expected hotel" -Passed ([string]$profile.hotel_id -eq $HotelId) -Details "Profile hotel: $($profile.hotel_id)"
    }
  }

  $productsResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/products?select=id,sku&limit=1"
  $products = ConvertTo-Array $productsResponse.Data
  Add-Check -Role $roleInput.Name -Name "can read product catalog" -Passed ($productsResponse.Ok -and $products.Count -gt 0) -Details "Rows: $($products.Count)"

  $hotelsResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/hotels?select=id,name&order=name.asc"
  $hotels = ConvertTo-Array $hotelsResponse.Data
  if ($roleInput.Scoped) {
    $scope = Test-HotelScope -Rows $hotels -ExpectedHotelId $HotelId -ForbiddenHotelId $OtherHotelId
    Add-Check -Role $roleInput.Name -Name "hotels are limited to assigned hotel" -Passed ($hotelsResponse.Ok -and $scope.Passed) -Details $scope.Details
  } else {
    Add-Check -Role $roleInput.Name -Name "can read hotel list" -Passed ($hotelsResponse.Ok -and $hotels.Count -gt 0) -Details "Rows: $($hotels.Count)"
  }

  $inventoryResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/hotel_inventory?select=hotel_id,product_id,full_bottles,full_bidons&limit=100"
  $inventory = ConvertTo-Array $inventoryResponse.Data
  if ($roleInput.Scoped) {
    $scope = Test-HotelScope -Rows $inventory -ExpectedHotelId $HotelId -ForbiddenHotelId $OtherHotelId
    Add-Check -Role $roleInput.Name -Name "inventory is limited to assigned hotel" -Passed ($inventoryResponse.Ok -and $scope.Passed) -Details $scope.Details
  } else {
    Add-Check -Role $roleInput.Name -Name "can read inventory" -Passed $inventoryResponse.Ok -Details "Rows: $($inventory.Count)"
  }

  $dashboardResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/rpc/dashboard_metrics" -Method "Post" -Body @{}
  Add-Check -Role $roleInput.Name -Name "dashboard metrics RPC is allowed" -Passed $dashboardResponse.Ok -Details "Status: $($dashboardResponse.StatusCode)"

  $directApprovalBody = @{
    hotel_id     = $HotelId
    title        = "RLS REST direct insert should fail"
    target_table = "hotels"
    target_id    = $HotelId
    action       = "update"
    old_data     = @{}
    new_data     = @{ notes = "should fail" }
    requested_by = $session.UserId
  }
  $directApprovalResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/approval_requests" -Method "Post" -Body $directApprovalBody
  Add-Check -Role $roleInput.Name -Name "direct approval table insert is denied" -Passed (-not $directApprovalResponse.Ok) -Details "Status: $($directApprovalResponse.StatusCode)"

  $directRefillEventBody = @{
    hotel_id              = $HotelId
    room_product_id       = "00000000-0000-0000-0000-000000000000"
    event_type            = "refill"
    previous_refill_count = 0
    new_refill_count      = 1
    performed_by          = $session.UserId
  }
  $directRefillResponse = Invoke-SupabaseRest -Session $session -Path "/rest/v1/refill_events" -Method "Post" -Body $directRefillEventBody
  Add-Check -Role $roleInput.Name -Name "direct refill event insert is denied" -Passed (-not $directRefillResponse.Ok) -Details "Status: $($directRefillResponse.StatusCode)"
}

$outputDirectory = Split-Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
  New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
}

$generatedAt = (Get-Date).ToUniversalTime().ToString("o")
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("# Ivra Supabase RLS REST Verification") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("- Generated UTC: $generatedAt") | Out-Null
$lines.Add("- Supabase URL: $SupabaseUrl") | Out-Null
$lines.Add("- Expected hotel: $HotelId") | Out-Null
$lines.Add("- Forbidden hotel: $OtherHotelId") | Out-Null
$lines.Add("") | Out-Null
$lines.Add("| Role | Check | Result | Details |") | Out-Null
$lines.Add("| --- | --- | --- | --- |") | Out-Null

foreach ($result in $results) {
  $status = if ($result.Passed) { "PASS" } else { "FAIL" }
  $details = ([string]$result.Details).Replace("|", "\|")
  $lines.Add("| $($result.Role) | $($result.Check) | $status | $details |") | Out-Null
}

Set-Content -LiteralPath $OutputPath -Value $lines -Encoding UTF8

$failed = @($results | Where-Object { -not $_.Passed })
Write-Host ""
Write-Host "RLS verification report written: $OutputPath"

if ($failed.Count -gt 0) {
  Write-Host ""
  Write-Host "RLS verification failed:"
  foreach ($failure in $failed) {
    Write-Host " - $($failure.Role): $($failure.Check)"
  }
  exit 1
}

Write-Host "RLS verification passed."
