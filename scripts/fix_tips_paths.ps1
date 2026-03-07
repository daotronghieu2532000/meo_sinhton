$ErrorActionPreference = 'Stop'
$dataFolder = 'C:\laragon\www\meo_sinhton\assets\data'

$files = Get-ChildItem -Path $dataFolder -Filter '*.json' -File -Recurse
$changedFiles = 0

foreach ($file in $files) {
    $content = Get-Content -Raw -LiteralPath $file.FullName
    $updated = [Regex]::Replace(
        $content,
        'assets/data_img/tips_img/([^""\\]+)\.png',
        'assets/data_img/tips_img/$1.jpg'
    )

    if ($updated -ne $content) {
        Set-Content -LiteralPath $file.FullName -Value $updated -Encoding UTF8
        $changedFiles++
    }
}

Write-Output "json_changed_files=$changedFiles"
