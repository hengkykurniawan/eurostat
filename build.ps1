<#
    Builds eurostat-dashboard.html — a single self-contained file.

    It downloads Eurostat's table of contents (the list of every dataset),
    compacts it to JSON, gzips it, and embeds it in the app template so the
    search box works without any server.

    Usage:
        .\build.ps1              # uses a cached table of contents if present
        .\build.ps1 -Refresh     # re-downloads the catalogue from Eurostat
#>
param([switch]$Refresh)

$ErrorActionPreference = 'Stop'
$root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$src      = Join-Path $root 'src'
$tocPath  = Join-Path $src 'toc.txt'
$template = Join-Path $src 'app.template.html'
$outFile  = Join-Path $root 'eurostat-dashboard.html'

if ($Refresh -or -not (Test-Path $tocPath)) {
    Write-Host 'Downloading Eurostat table of contents...'
    Invoke-WebRequest -Uri 'https://ec.europa.eu/eurostat/api/dissemination/catalogue/toc/txt?lang=en' `
        -UseBasicParsing -TimeoutSec 300 -OutFile $tocPath
}

Write-Host 'Parsing catalogue...'
$lines    = Get-Content $tocPath -Encoding UTF8
$themes   = New-Object System.Collections.ArrayList
$themeIdx = @{}
$stack    = New-Object System.Collections.ArrayList
$items    = New-Object System.Collections.ArrayList

for ($i = 1; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $f = $line -split "`t"
    if ($f.Count -lt 3) { continue }

    $rawTitle = $f[0].Trim('"')
    $title    = $rawTitle.TrimStart(' ')
    $depth    = [int](($rawTitle.Length - $title.Length) / 4)   # 4 spaces per level
    $code     = $f[1].Trim('"').Trim()
    $type     = $f[2].Trim('"').Trim()

    if ($type -eq 'folder') {
        while ($stack.Count -gt $depth) { $stack.RemoveAt($stack.Count - 1) }
        while ($stack.Count -lt $depth) { [void]$stack.Add('') }
        [void]$stack.Add($title)
        continue
    }
    if ($type -ne 'dataset' -and $type -ne 'table') { continue }

    while ($stack.Count -gt $depth) { $stack.RemoveAt($stack.Count - 1) }
    $path = ($stack | Where-Object { $_ -ne '' }) -join ' > '
    if (-not $themeIdx.ContainsKey($path)) {
        $themeIdx[$path] = $themes.Count
        [void]$themes.Add($path)
    }

    $upd  = if ($f.Count -gt 3) { $f[3].Trim('"').Trim() } else { '' }
    $ds   = if ($f.Count -gt 5) { $f[5].Trim('"').Trim() } else { '' }
    $de   = if ($f.Count -gt 6) { $f[6].Trim('"').Trim() } else { '' }
    $vals = 0
    if ($f.Count -gt 7) { [void][int64]::TryParse(($f[7].Trim('"').Trim()), [ref]$vals) }

    [void]$items.Add(@($code, $title, $themeIdx[$path], $upd, $ds, $de, $vals))
}
Write-Host ("  {0} datasets, {1} themes" -f $items.Count, $themes.Count)

$json = ([ordered]@{
    built  = (Get-Date -Format 'yyyy-MM-dd')
    themes = @($themes)
    fields = @('code', 'title', 'theme', 'updated', 'start', 'end', 'values')
    items  = @($items)
} | ConvertTo-Json -Depth 6 -Compress)

$bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
$ms    = New-Object System.IO.MemoryStream
$gz    = New-Object System.IO.Compression.GZipStream($ms, [System.IO.Compression.CompressionLevel]::Optimal)
$gz.Write($bytes, 0, $bytes.Length)
$gz.Close()
$b64 = [Convert]::ToBase64String($ms.ToArray())

Write-Host 'Writing dashboard...'
$html = [System.IO.File]::ReadAllText($template, [System.Text.Encoding]::UTF8)
if ($html -notmatch '__CATALOG_B64__') { throw "Template is missing the __CATALOG_B64__ placeholder." }
$html = $html.Replace('__CATALOG_B64__', $b64)
[System.IO.File]::WriteAllText($outFile, $html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host ("Done -> {0} ({1:N0} KB)" -f $outFile, ((Get-Item $outFile).Length / 1KB))
