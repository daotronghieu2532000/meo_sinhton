$ErrorActionPreference = 'Stop'

$projectRoot = 'C:\laragon\www\meo_sinhton'
$tipsFolder = Join-Path $projectRoot 'assets\data_img\tips_img'
$dataFolder = Join-Path $projectRoot 'assets\data'
$maxDim = 900
$jpegQualityForJpg = 50L
$jpegQualityForPng = 52L

Add-Type -AssemblyName System.Drawing

function New-ResizedBitmap {
    param(
        [System.Drawing.Image]$Image,
        [int]$MaxDimension,
        [bool]$force24bpp = $false
    )

    $w = $Image.Width
    $h = $Image.Height

    $newW = $w
    $newH = $h

    if ($w -gt $MaxDimension -or $h -gt $MaxDimension) {
        if ($w -ge $h) {
            $newW = $MaxDimension
            $newH = [int][Math]::Round(($h * 1.0 * $MaxDimension) / $w)
        } else {
            $newH = $MaxDimension
            $newW = [int][Math]::Round(($w * 1.0 * $MaxDimension) / $h)
        }
    }

    if ($newW -lt 1) { $newW = 1 }
    if ($newH -lt 1) { $newH = 1 }

    $pixelFormat = if ($force24bpp) { [System.Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [System.Drawing.Imaging.PixelFormat]::Format32bppArgb }
    $bitmap = New-Object System.Drawing.Bitmap($newW, $newH, $pixelFormat)

    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    if ($force24bpp) {
        $graphics.Clear([System.Drawing.Color]::White)
    }
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($Image, 0, 0, $newW, $newH)
    $graphics.Dispose()

    return $bitmap
}

$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
$encQuality = [System.Drawing.Imaging.Encoder]::Quality

$beforeBytes = (Get-ChildItem -Path $tipsFolder -File -Recurse | Measure-Object Length -Sum).Sum

$jpgOptimized = 0
$pngConverted = 0
$webpSkipped = 0
$otherSkipped = 0
$errors = 0

$pathMap = @{}

Get-ChildItem -Path $tipsFolder -File -Recurse -Filter '*.tmp' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$files = Get-ChildItem -Path $tipsFolder -File -Recurse
foreach ($file in $files) {
    $ext = $file.Extension.ToLowerInvariant()
    if ($ext -eq '.webp') {
        $webpSkipped++
        continue
    }

    if ($ext -notin @('.jpg', '.jpeg', '.png')) {
        $otherSkipped++
        continue
    }

    $img = $null
    $bmp = $null
    try {
        $img = [System.Drawing.Image]::FromFile($file.FullName)

        if ($ext -in @('.jpg', '.jpeg')) {
            $bmp = New-ResizedBitmap -Image $img -MaxDimension $maxDim -force24bpp $true
            $tmp = "$($file.FullName).tmp"
            $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encQuality, $jpegQualityForJpg)
            $bmp.Save($tmp, $jpgCodec, $ep)

            $bmp.Dispose(); $bmp = $null
            $img.Dispose(); $img = $null

            Move-Item -Force $tmp $file.FullName
            $jpgOptimized++
        } elseif ($ext -eq '.png') {
            $bmp = New-ResizedBitmap -Image $img -MaxDimension $maxDim -force24bpp $true
            $newPath = [System.IO.Path]::ChangeExtension($file.FullName, '.jpg')
            $tmp = "$newPath.tmp"
            $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encQuality, $jpegQualityForPng)
            $bmp.Save($tmp, $jpgCodec, $ep)

            $bmp.Dispose(); $bmp = $null
            $img.Dispose(); $img = $null

            if (Test-Path $newPath) { Remove-Item -Force $newPath }
            Move-Item -Force $tmp $newPath
            Remove-Item -Force $file.FullName

            $oldRel = ($file.FullName.Replace($projectRoot + '\\', '')).Replace('\\', '/')
            $newRel = ($newPath.Replace($projectRoot + '\\', '')).Replace('\\', '/')
            $pathMap[$oldRel] = $newRel
            $pngConverted++
        }
    } catch {
        $errors++
        if ($errors -le 10) {
            Write-Output "error_file=$($file.FullName)"
            Write-Output "error_message=$($_.Exception.Message)"
        }
    } finally {
        if ($bmp) { $bmp.Dispose() }
        if ($img) { $img.Dispose() }
    }
}

if ($pathMap.Count -gt 0) {
    Get-ChildItem -Path $dataFolder -Filter '*.json' -File -Recurse | ForEach-Object {
        $content = Get-Content -Raw -LiteralPath $_.FullName
        foreach ($oldPath in $pathMap.Keys) {
            $newPath = $pathMap[$oldPath]
            $content = $content.Replace($oldPath, $newPath)
        }
        Set-Content -LiteralPath $_.FullName -Value $content -Encoding UTF8
    }
}

Get-ChildItem -Path $tipsFolder -File -Recurse -Filter '*.tmp' -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

$afterBytes = (Get-ChildItem -Path $tipsFolder -File -Recurse | Measure-Object Length -Sum).Sum
$savedBytes = $beforeBytes - $afterBytes
$savedPercent = if ($beforeBytes -gt 0) { [Math]::Round(($savedBytes * 100.0) / $beforeBytes, 2) } else { 0 }

Write-Output "before_bytes=$beforeBytes"
Write-Output "after_bytes=$afterBytes"
Write-Output "saved_bytes=$savedBytes"
Write-Output "saved_percent=$savedPercent"
Write-Output "jpg_optimized=$jpgOptimized"
Write-Output "png_converted_to_jpg=$pngConverted"
Write-Output "json_paths_updated=$($pathMap.Count)"
Write-Output "webp_skipped=$webpSkipped"
Write-Output "other_skipped=$otherSkipped"
Write-Output "errors=$errors"
