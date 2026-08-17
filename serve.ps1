<#
    Optional: serves the dashboard over http://localhost:8931 instead of opening
    it as a file. Only needed if your browser blocks requests from file:// pages.

    Usage:  .\serve.ps1        (Ctrl+C to stop)
#>
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Start-Process 'http://localhost:8931/eurostat-dashboard.html'
py -m http.server 8931 --directory $root
