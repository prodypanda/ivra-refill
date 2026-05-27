param(
  [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) "web")
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-IvraIcon {
  param(
    [int]$Size,
    [string]$Path,
    [bool]$Maskable = $false
  )

  $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $green = [System.Drawing.Color]::FromArgb(19, 124, 107)
  $mint = [System.Drawing.Color]::FromArgb(184, 235, 220)
  $white = [System.Drawing.Color]::FromArgb(255, 255, 255)
  $shadow = [System.Drawing.Color]::FromArgb(42, 0, 0, 0)

  $graphics.Clear($green)

  if ($Maskable) {
    $safeMargin = [math]::Round($Size * 0.14)
    $innerRect = New-Object System.Drawing.RectangleF $safeMargin, $safeMargin, ($Size - ($safeMargin * 2)), ($Size - ($safeMargin * 2))
  } else {
    $innerRect = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
  }

  $dropPath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $centerX = $innerRect.X + ($innerRect.Width * 0.64)
  $topY = $innerRect.Y + ($innerRect.Height * 0.18)
  $bottomY = $innerRect.Y + ($innerRect.Height * 0.64)
  $dropWidth = $innerRect.Width * 0.24
  $dropPath.AddBezier(
    $centerX, $topY,
    $centerX + $dropWidth, $topY + ($innerRect.Height * 0.18),
    $centerX + ($dropWidth * 0.82), $bottomY,
    $centerX, $bottomY
  )
  $dropPath.AddBezier(
    $centerX, $bottomY,
    $centerX - ($dropWidth * 0.82), $bottomY,
    $centerX - $dropWidth, $topY + ($innerRect.Height * 0.18),
    $centerX, $topY
  )
  $dropPath.CloseFigure()

  $shadowMatrix = New-Object System.Drawing.Drawing2D.Matrix
  $shadowMatrix.Translate(($Size * 0.018), ($Size * 0.022))
  $dropShadow = $dropPath.Clone()
  $dropShadow.Transform($shadowMatrix)
  $graphics.FillPath((New-Object System.Drawing.SolidBrush $shadow), $dropShadow)
  $graphics.FillPath((New-Object System.Drawing.SolidBrush $mint), $dropPath)

  $fontSize = [math]::Round($innerRect.Height * 0.54)
  $font = New-Object System.Drawing.Font "Segoe UI", $fontSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Center
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center

  $textRect = New-Object System.Drawing.RectangleF (
    $innerRect.X + ($innerRect.Width * 0.08)
  ), (
    $innerRect.Y + ($innerRect.Height * 0.2)
  ), (
    $innerRect.Width * 0.44
  ), (
    $innerRect.Height * 0.6
  )

  $graphics.DrawString("I", $font, (New-Object System.Drawing.SolidBrush $white), $textRect, $format)

  $graphics.Dispose()
  $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

if (-not (Test-Path -LiteralPath $OutputDir)) {
  New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$iconsDir = Join-Path $OutputDir "icons"
if (-not (Test-Path -LiteralPath $iconsDir)) {
  New-Item -ItemType Directory -Path $iconsDir | Out-Null
}

New-IvraIcon -Size 32 -Path (Join-Path $OutputDir "favicon.png")
New-IvraIcon -Size 192 -Path (Join-Path $iconsDir "Icon-192.png")
New-IvraIcon -Size 512 -Path (Join-Path $iconsDir "Icon-512.png")
New-IvraIcon -Size 192 -Path (Join-Path $iconsDir "Icon-maskable-192.png") -Maskable $true
New-IvraIcon -Size 512 -Path (Join-Path $iconsDir "Icon-maskable-512.png") -Maskable $true

Write-Host "Generated Ivra web icons in $OutputDir"

