param(
  [string]$OutputDir = (Join-Path (Split-Path $PSScriptRoot -Parent) "android\app\src\main\res")
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function New-IvraLauncherIcon {
  param(
    [int]$Size,
    [string]$Path
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

  $safeMargin = [math]::Round($Size * 0.08)
  $innerRect = New-Object System.Drawing.RectangleF $safeMargin, $safeMargin, ($Size - ($safeMargin * 2)), ($Size - ($safeMargin * 2))

  $dropPath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $centerX = $innerRect.X + ($innerRect.Width * 0.64)
  $topY = $innerRect.Y + ($innerRect.Height * 0.18)
  $bottomY = $innerRect.Y + ($innerRect.Height * 0.66)
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

function New-IvraSplashImage {
  param(
    [string]$Path
  )

  $width = 420
  $height = 180
  $bitmap = New-Object System.Drawing.Bitmap $width, $height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $graphics.Clear([System.Drawing.Color]::Transparent)

  $mint = [System.Drawing.Color]::FromArgb(184, 235, 220)
  $white = [System.Drawing.Color]::FromArgb(255, 255, 255)
  $shadow = [System.Drawing.Color]::FromArgb(42, 0, 0, 0)

  $font = New-Object System.Drawing.Font "Segoe UI", 86, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $format = New-Object System.Drawing.StringFormat
  $format.Alignment = [System.Drawing.StringAlignment]::Near
  $format.LineAlignment = [System.Drawing.StringAlignment]::Center
  $textRect = New-Object System.Drawing.RectangleF 0, 18, 250, 130
  $graphics.DrawString("Ivra", $font, (New-Object System.Drawing.SolidBrush $white), $textRect, $format)

  $dropPath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $centerX = 330
  $topY = 34
  $bottomY = 134
  $dropWidth = 48
  $dropPath.AddBezier(
    $centerX, $topY,
    $centerX + $dropWidth, $topY + 40,
    $centerX + 38, $bottomY,
    $centerX, $bottomY
  )
  $dropPath.AddBezier(
    $centerX, $bottomY,
    $centerX - 38, $bottomY,
    $centerX - $dropWidth, $topY + 40,
    $centerX, $topY
  )
  $dropPath.CloseFigure()

  $shadowMatrix = New-Object System.Drawing.Drawing2D.Matrix
  $shadowMatrix.Translate(6, 8)
  $dropShadow = $dropPath.Clone()
  $dropShadow.Transform($shadowMatrix)
  $graphics.FillPath((New-Object System.Drawing.SolidBrush $shadow), $dropShadow)
  $graphics.FillPath((New-Object System.Drawing.SolidBrush $mint), $dropPath)

  $graphics.Dispose()
  $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Dispose()
}

function New-IvraForegroundImage {
  param(
    [int]$Size,
    [string]$Path
  )

  $bitmap = New-Object System.Drawing.Bitmap $Size, $Size
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

  $graphics.Clear([System.Drawing.Color]::Transparent)

  $mint = [System.Drawing.Color]::FromArgb(184, 235, 220)
  $white = [System.Drawing.Color]::FromArgb(255, 255, 255)
  $shadow = [System.Drawing.Color]::FromArgb(42, 0, 0, 0)

  $safeMargin = [math]::Round($Size * 0.16)
  $innerRect = New-Object System.Drawing.RectangleF $safeMargin, $safeMargin, ($Size - ($safeMargin * 2)), ($Size - ($safeMargin * 2))

  $dropPath = New-Object System.Drawing.Drawing2D.GraphicsPath
  $centerX = $innerRect.X + ($innerRect.Width * 0.64)
  $topY = $innerRect.Y + ($innerRect.Height * 0.18)
  $bottomY = $innerRect.Y + ($innerRect.Height * 0.66)
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

$densitySizes = @{
  "mipmap-mdpi" = 48
  "mipmap-hdpi" = 72
  "mipmap-xhdpi" = 96
  "mipmap-xxhdpi" = 144
  "mipmap-xxxhdpi" = 192
}

foreach ($entry in $densitySizes.GetEnumerator()) {
  $directory = Join-Path $OutputDir $entry.Key
  if (-not (Test-Path -LiteralPath $directory)) {
    New-Item -ItemType Directory -Path $directory | Out-Null
  }

  New-IvraLauncherIcon -Size $entry.Value -Path (Join-Path $directory "ic_launcher.png")
}

$splashDirectory = Join-Path $OutputDir "drawable-nodpi"
if (-not (Test-Path -LiteralPath $splashDirectory)) {
  New-Item -ItemType Directory -Path $splashDirectory | Out-Null
}

New-IvraSplashImage -Path (Join-Path $splashDirectory "launch_image.png")
New-IvraForegroundImage -Size 432 -Path (Join-Path $splashDirectory "ic_launcher_foreground.png")
New-IvraForegroundImage -Size 432 -Path (Join-Path $splashDirectory "splash_icon.png")

Write-Host "Generated Ivra Android launcher and splash images in $OutputDir"
