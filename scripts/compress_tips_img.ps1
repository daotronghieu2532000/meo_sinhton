$ErrorActionPreference = 'Stop'
$folder = 'C:\laragon\www\meo_sinhton\assets\data_img\tips_img'

Add-Type -AssemblyName System.Drawing

$before = (Get-ChildItem -Path $folder -File -Recurse | Measure-Object Length -Sum).Sum
$jpgCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
    Where-Object { $_.MimeType -eq 'image/jpeg' }
$enc = [System.Drawing.Imaging.Encoder]::Quality

$jpgCount = 0
$pngCount = 0

Get-ChildItem -Path $folder -File -Recurse | ForEach-Object {
    $ext = $_.Extension.ToLowerInvariant()

    if ($ext -in @('.jpg', '.jpeg')) {
        $img = $null
        $tmp = "$($_.FullName).tmp"
        try {
            $img = [System.Drawing.Image]::FromFile($_.FullName)
            $eps = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $eps.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($enc, 78L)
            $img.Save($tmp, $jpgCodec, $eps)
            $img.Dispose()
            Move-Item -Force $tmp $_.FullName
            $jpgCount++
        } catch {
            if ($img) { $img.Dispose() }
            if (Test-Path $tmp) { Remove-Item -Force $tmp }
        }
    } elseif ($ext -eq '.png') {
        $img = $null
        $tmp = "$($_.FullName).tmp"
        try {
            $img = [System.Drawing.Image]::FromFile($_.FullName)
            $img.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
            $img.Dispose()
            Move-Item -Force $tmp $_.FullName
            $pngCount++
        } catch {
            if ($img) { $img.Dispose() }
            if (Test-Path $tmp) { Remove-Item -Force $tmp }
        }
    }
}

$after = (Get-ChildItem -Path $folder -File -Recurse | Measure-Object Length -Sum).Sum
$saved = $before - $after
$pct = if ($before -gt 0) { [math]::Round(($saved * 100.0) / $before, 2) } else { 0 }

Write-Output "before_bytes=$before"
Write-Output "after_bytes=$after"
Write-Output "saved_bytes=$saved"
Write-Output "saved_percent=$pct"
Write-Output "jpg_processed=$jpgCount"
Write-Output "png_processed=$pngCount"
