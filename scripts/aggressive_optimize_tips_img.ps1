$ErrorActionPreference = 'Stop'

$projectRoot = 'C:\laragon\www\meo_sinhton'
$tipsFolder = Join-Path $projectRoot 'assets\data_img\tips_img'
$dataFolder = Join-Path $projectRoot 'assets\data'
$maxDim = 1024
$jpegQuality = 62L

Add-Type -AssemblyName System.Drawing

function New-ResizedBitmap {
    param(
        [System.Drawing.Image]$Image,
        [int]$MaxDimension
    )

    $w = $Image.Width
    $h = $Image.Height

    if ($w -le $MaxDimension -and $h -le $MaxDimension) {
        $copy = New-Object System.Drawing.Bitmap($w, $h)
        $g = [System.Drawing.Graphics]::FromImage($copy)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.DrawImage($Image, 0, 0, $w, $h)
        $g.Dispose()
        return $copy
    }

    if ($w -ge $h) {
        $newW = $MaxDimension
        $newH = [int][Math]::Round(($h * 1.0 * $MaxDimension) / $w)
    } else {
        $newH = $MaxDimension
        $newW = [int][Math]::Round(($w * 1.0 * $MaxDimension) / $h)
    }

    if ($newW -lt 1) { $newW = 1 }
    if ($newH -lt 1) { $newH = 1 }

    $bitmap = New-Object System.Drawing.Bitmap($newW, $newH)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
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
$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($encQuality, $jpegQuality)

$beforeBytes = (Get-ChildItem -Path $tipsFolder -File -Recurse | Measure-Object Length -Sum).Sum

$convertedPngToJpg = 0
$resizedJpg = 0
$resizedPng = 0
$skipped = 0
$errorCount = 0

$pathMap = @{}

$tempFiles = Get-ChildItem -Path $tipsFolder -File -Recurse -Filter '*.tmp' -ErrorAction SilentlyContinue
if ($tempFiles) {
    $tempFiles | Remove-Item -Force -ErrorAction SilentlyContinue
}

$files = Get-ChildItem -Path $tipsFolder -File -Recurse
foreach ($file in $files) {
    $ext = $file.Extension.ToLowerInvariant()
    if ($ext -notin @('.jpg', '.jpeg', '.png')) {
        $skipped++
        continue
    }

    $image = $null
    $resized = $null

    try {
        $image = [System.Drawing.Image]::FromFile($file.FullName)
        $resized = New-ResizedBitmap -Image $image -MaxDimension $maxDim

        $isPng = $ext -eq '.png'
        $hasAlpha = ($image.Flags -band [int][System.Drawing.Imaging.ImageFlags]::HasAlpha) -ne 0

        if ($isPng -and -not $hasAlpha) {
            $newPath = [System.IO.Path]::ChangeExtension($file.FullName, '.jpg')
            $tmp = "$newPath.tmp"
            $resized.Save($tmp, $jpgCodec, $encoderParams)

            $resized.Dispose()
            $resized = $null
            $image.Dispose()
            $image = $null

            if (Test-Path $newPath) { Remove-Item -Force $newPath }
            Move-Item -Force $tmp $newPath
            Remove-Item -Force $file.FullName

            $oldRel = ($file.FullName.Replace($projectRoot + '\\', '')).Replace('\\', '/')
            $newRel = ($newPath.Replace($projectRoot + '\\', '')).Replace('\\', '/')
            $pathMap[$oldRel] = $newRel
            $convertedPngToJpg++
        } elseif ($ext -in @('.jpg', '.jpeg')) {
            $tmp = "$($file.FullName).tmp"
            $resized.Save($tmp, $jpgCodec, $encoderParams)

            $resized.Dispose()
            $resized = $null
            $image.Dispose()
            $image = $null

            Move-Item -Force $tmp $file.FullName
            $resizedJpg++
        } else {
            $tmp = "$($file.FullName).tmp"
            $resized.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)

            $resized.Dispose()
            $resized = $null
            $image.Dispose()
            $image = $null

            Move-Item -Force $tmp $file.FullName
            $resizedPng++
        }
    } catch {
        $skipped++
        $errorCount++
        if ($errorCount -le 5) {
            Write-Output "error_file=$($file.FullName)"
            Write-Output "error_message=$($_.Exception.Message)"
        }
        Get-ChildItem -Path $tipsFolder -File -Recurse -Filter '*.tmp' -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    } finally {
        if ($resized) { $resized.Dispose() }
        if ($image) { $image.Dispose() }
    }
}

if ($pathMap.Count -gt 0) {
    Get-ChildItem -Path $dataFolder -Filter '*.json' -File -Recurse | ForEach-Object {
        $content = Get-Content -Raw -LiteralPath $_.FullName
        foreach ($oldPath in $pathMap.Keys) {
            $newPath = $pathMap[$oldPath]
            $escapedOld = [Regex]::Escape($oldPath)
            $content = [Regex]::Replace($content, $escapedOld, $newPath)
        }
        Set-Content -LiteralPath $_.FullName -Value $content -Encoding UTF8
    }
}

$afterBytes = (Get-ChildItem -Path $tipsFolder -File -Recurse | Measure-Object Length -Sum).Sum
$savedBytes = $beforeBytes - $afterBytes
$savedPercent = if ($beforeBytes -gt 0) { [Math]::Round(($savedBytes * 100.0) / $beforeBytes, 2) } else { 0 }

Write-Output "before_bytes=$beforeBytes"
Write-Output "after_bytes=$afterBytes"
Write-Output "saved_bytes=$savedBytes"
Write-Output "saved_percent=$savedPercent"
Write-Output "jpg_resized=$resizedJpg"
Write-Output "png_resized=$resizedPng"
Write-Output "png_to_jpg=$convertedPngToJpg"
Write-Output "skipped=$skipped"
Write-Output "json_paths_updated=$($pathMap.Count)"
