param(
    [int]$Port = 8080,
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = "Continue"

$mime = @{
    ".html" = "text/html; charset=utf-8"
    ".htm"  = "text/html; charset=utf-8"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".gif"  = "image/gif"
    ".svg"  = "image/svg+xml"
    ".webp" = "image/webp"
    ".ico"  = "image/x-icon"
    ".mp4"  = "video/mp4"
    ".webm" = "video/webm"
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://127.0.0.1:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    Write-Host "Failed to start on $prefix. Trying port $($Port + 1)..." -ForegroundColor Red
    $Port = $Port + 1
    $prefix = "http://127.0.0.1:$Port/"
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($prefix)
    $listener.Start()
}

Write-Host "Local web server running at: $prefix" -ForegroundColor Green
Write-Host "Serving directory: $Root" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop." -ForegroundColor DarkGray

$rootFullPath = [System.IO.Path]::GetFullPath($Root)

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        try {
            $rawPath = [System.Uri]::UnescapeDataString($request.Url.AbsolutePath)
            if ($rawPath -eq "/" -or $rawPath -eq "") {
                $rawPath = "/index.html"
            }

            $relative = $rawPath.TrimStart("/").Replace('/', [System.IO.Path]::DirectorySeparatorChar)
            $targetPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($rootFullPath, $relative))

            if (-not $targetPath.StartsWith($rootFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                $response.StatusCode = 403
                $msg = [System.Text.Encoding]::UTF8.GetBytes("403 Forbidden")
                $response.OutputStream.Write($msg, 0, $msg.Length)
            } elseif ([System.IO.File]::Exists($targetPath)) {
                $ext = [System.IO.Path]::GetExtension($targetPath).ToLowerInvariant()
                $response.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
                
                $fileInfo = New-Object System.IO.FileInfo($targetPath)
                $response.ContentLength64 = $fileInfo.Length
                $response.AddHeader("Access-Control-Allow-Origin", "*")
                $response.AddHeader("Cache-Control", "public, max-age=3600")

                $fileStream = [System.IO.File]::OpenRead($targetPath)
                try {
                    $fileStream.CopyTo($response.OutputStream)
                } finally {
                    $fileStream.Close()
                    $fileStream.Dispose()
                }
            } else {
                $response.StatusCode = 404
                $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $rawPath")
                $response.OutputStream.Write($msg, 0, $msg.Length)
            }
        } catch {
            # Disconnect / aborted connection is normal
        } finally {
            try {
                $response.OutputStream.Flush()
                $response.Close()
            } catch {
            }
        }
    } catch {
        if (-not $listener.IsListening) { break }
    }
}
