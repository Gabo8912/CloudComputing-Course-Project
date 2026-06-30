<#
.SYNOPSIS
    Package the Node.js app and deploy it to the App Service (manual / local).

.DESCRIPTION
    1. Zips ONLY the source (server.js, package.json, package-lock.json, views/).
       node_modules is intentionally excluded: the App Service builds the
       dependencies server-side via Oryx (SCM_DO_BUILD_DURING_DEPLOYMENT=true).
    2. Deploys the zip with `az webapp deployment source config-zip`.

    IMPORTANT: the zip is built with the .NET ZipArchive using forward-slash
    entry names. PowerShell's Compress-Archive stores nested paths with
    backslashes (e.g. "views\index.ejs"), which breaks the Linux deployment
    (rsync: Invalid argument). Do not replace this with Compress-Archive.

    Resource group and app name default to the Terraform outputs.

.EXAMPLE
    ./deploy.ps1
    ./deploy.ps1 -ResourceGroup clouddevops-dev-rg -AppName clouddevops-dev-app-xxxxx
#>

param(
    [string]$ResourceGroup,
    [string]$AppName
)

$ErrorActionPreference = "Stop"
$root    = Split-Path $PSScriptRoot -Parent
$appDir  = Join-Path $root "app"
$zipPath = Join-Path $root "app-src.zip"

# Fall back to Terraform outputs when parameters are not provided.
if (-not $ResourceGroup -or -not $AppName) {
    Push-Location (Join-Path $root "terraform")
    if (-not $ResourceGroup) { $ResourceGroup = (terraform output -raw resource_group_name) }
    if (-not $AppName)       { $AppName       = (terraform output -raw app_service_name) }
    Pop-Location
}

# Source files to ship (relative paths use forward slashes for Linux).
$items = @(
    "server.js",
    "package.json",
    "package-lock.json",
    "views/index.ejs",
    "views/upload.ejs"
)

Write-Host "==> Packaging source -> $zipPath" -ForegroundColor Cyan
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($rel in $items) {
        $abs = Join-Path $appDir ($rel -replace '/', '\')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $abs, $rel) | Out-Null
    }
} finally {
    $zip.Dispose()
}

Write-Host "==> Deploying to App Service '$AppName' (rg: $ResourceGroup)" -ForegroundColor Cyan
Write-Host "    (Oryx will run 'npm install' on the server; this can take ~1-2 min)" -ForegroundColor DarkGray
az webapp deployment source config-zip `
    --resource-group $ResourceGroup `
    --name $AppName `
    --src $zipPath

Write-Host "Deployment complete." -ForegroundColor Green
