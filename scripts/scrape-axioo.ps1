# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) Driver Scraper (PowerShell)
# Official Source of Truth: https://driver.axiooworld.com
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BaseUrl          = "https://driver.axiooworld.com"
$SeriesReff       = "13"
$TargetModel      = "750"
$TargetVendorCode = "NP50RNC1"

$ScriptDir  = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$RootDir    = Split-Path -Parent $ScriptDir
$OutputDir  = Join-Path $RootDir "generated"
$SpecialFile = Join-Path $RootDir "config\special-drivers.json"

$Headers = @{
    "User-Agent"       = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AxiooPongo750-Scraper/1.0"
    "Accept"           = "application/json, text/javascript, */*; q=0.01"
    "Accept-Language"  = "id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7"
    "X-Requested-With" = "XMLHttpRequest"
    "Referer"          = "$BaseUrl/"
}

function Normalize-Version([string]$Description) {
    if (-not $Description) { return $null }
    if ($Description -match 'Version\s*:\s*([^,]+)') {
        return $Matches[1].Trim()
    }
    return $null
}

function Derive-FriendlyName([string]$Description, [string]$Title) {
    if (-not $Description) {
        if ($Title) { return $Title } else { return "Driver" }
    }
    $parts = $Description -split ',\s*Version\s*:'
    if ($parts.Count -gt 1 -and $parts[0].Trim().Length -gt 0) {
        return $parts[0].Trim()
    }
    if ($Title) { return $Title }
    return $Description
}

function Derive-InstallType([string]$FileRepo) {
    $fileLower = if ($FileRepo) { $FileRepo.ToLower() } else { "" }
    if ($fileLower.Contains("hidfilter") -or $fileLower.Contains("hid_filter")) {
        return @{
            type = "inf"
            inf  = "HidEventFilter.inf"
        }
    }
    if ($fileLower.Contains("chipset_intel") -or $fileLower.Contains("speedshift") -or $fileLower.Contains("gna_")) {
        return @{
            type = "inf"
        }
    }
    return @{
        type = "package"
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Axioo Pongo 750 Driver Scraper" -ForegroundColor Cyan
Write-Host " Target: Model $TargetModel / Code $TargetVendorCode" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Get models
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[1/3] Mengambil daftar model PONGO..." -ForegroundColor Yellow
$modelsUrl = "$BaseUrl/fetch/get_models?reff=$SeriesReff"

try {
    $modelsResp = Invoke-RestMethod -Uri $modelsUrl -Headers $Headers -Method Get
}
catch {
    throw "Gagal menghubungi endpoint get_models: $_"
}

if ($modelsResp.status -ne "success" -or -not $modelsResp.data) {
    throw "Endpoint get_models mengembalikan respons tidak valid."
}

$model = $modelsResp.data | Where-Object { $_.model_name -eq $TargetModel }

if (-not $model) {
    throw "Model '$TargetModel' tidak ditemukan pada series '$SeriesReff'."
}

Write-Host "  Model       : $($model.model_name)"
Write-Host "  Model Reff  : $($model.id)"
Write-Host "  Series Reff : $SeriesReff"

# ------------------------------------------------------------------------------
# 2. Get template
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[2/3] Mengambil template produk..." -ForegroundColor Yellow
$templateUrl = "$BaseUrl/fetch/get_template_item?series_reff=$SeriesReff&model_reff=$($model.id)&group_by=true"

try {
    $templateResp = Invoke-RestMethod -Uri $templateUrl -Headers $Headers -Method Get
}
catch {
    throw "Gagal menghubungi endpoint get_template_item: $_"
}

if ($templateResp.status -ne "success" -or -not $templateResp.data) {
    throw "Endpoint get_template_item mengembalikan respons tidak valid."
}

$template = $templateResp.data | Where-Object { $_.vendor_code -eq $TargetVendorCode }

if (-not $template) {
    throw "Vendor code '$TargetVendorCode' tidak ditemukan pada model '$TargetModel'."
}

Write-Host "  Template ID  : $($template.template_id)"
Write-Host "  Vendor Code  : $($template.vendor_code)"
Write-Host "  Template     : $($template.template_name)"
Write-Host "  Item Code    : $($template.item_code)"

# ------------------------------------------------------------------------------
# 3. Get driver list
# ------------------------------------------------------------------------------
Write-Host ""
Write-Host "[3/3] Mengambil daftar driver resmi..." -ForegroundColor Yellow
$driverUrl = "$BaseUrl/fetch/get_driver_list_by_product"

$postBody = @{
    series   = $SeriesReff
    model    = "$($model.id)"
    template = $TargetVendorCode
}

try {
    $driverResp = Invoke-RestMethod -Uri $driverUrl -Headers $Headers -Method Post -Body $postBody
}
catch {
    throw "Gagal menghubungi endpoint get_driver_list_by_product: $_"
}

if ($driverResp.status -ne "success" -or -not ($driverResp.data -is [System.Array] -or $driverResp.data.Count -gt 0)) {
    throw "Endpoint get_driver_list_by_product tidak mengembalikan daftar driver yang valid."
}

Write-Host "  Jumlah driver resmi ditemukan: $($driverResp.data.Count)" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 4. Normalize drivers
# ------------------------------------------------------------------------------
$driversList = [System.Collections.Generic.List[PSObject]]::new()

foreach ($item in $driverResp.data) {
    $titleSlug = ($item.title -replace '[^a-zA-Z0-9]+', '-').Trim('-').ToLower()
    if (-not $titleSlug) { $titleSlug = "driver" }
    $driverId = "$titleSlug-$($item.repo_id)"

    $version = Normalize-Version $item.description
    $friendlyName = Derive-FriendlyName $item.description $item.title
    $installType = Derive-InstallType $item.file_repo

    $driverObj = [ordered]@{
        id            = $driverId
        repo_id       = [string]$item.repo_id
        date          = [string]$item.date
        year          = [string]$item.year
        author        = if ($item.author) { [string]$item.author } else { "RND" }
        title         = [string]$item.title
        category      = [string]$item.title
        name          = $friendlyName
        description   = [string]$item.description
        version       = $version
        series        = [string]$item.series
        model         = [string]$item.model
        vendor_code   = [string]$item.vendor_code
        template_name = [string]$item.template_name
        folder_repo   = [string]$item.folder_repo
        file_repo     = [string]$item.file_repo
        download_url  = [string]$item.download_url
        download_size = [string]$item.download_size
        source        = "axioo"
        install       = $installType
    }

    $driversList.Add([PSCustomObject]$driverObj)
}

# ------------------------------------------------------------------------------
# 5. Load special drivers (Intel Serial IO, etc.)
# ------------------------------------------------------------------------------
$specialDrivers = @{}
if (Test-Path $SpecialFile) {
    try {
        $specialRaw = Get-Content $SpecialFile -Raw -Encoding utf8
        $specialDrivers = $specialRaw | ConvertFrom-Json
        Write-Host "  Special drivers loaded from config/special-drivers.json"
    }
    catch {
        Write-Warning "Gagal memuat special-drivers.json: $_"
    }
}

# ------------------------------------------------------------------------------
# 6. Generate generated/drivers.json
# ------------------------------------------------------------------------------
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$generatedManifest = [ordered]@{
    generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    model        = [ordered]@{
        brand       = "Axioo"
        series      = "PONGO"
        model       = $TargetModel
        code        = $TargetVendorCode
        series_reff = $SeriesReff
        model_reff  = [string]$model.id
        target_os   = "Windows 11 x64"
    }
    template     = [ordered]@{
        id        = [string]$template.template_id
        name      = [string]$template.template_name
        item_code = [string]$template.item_code
    }
    source       = [ordered]@{
        website           = $BaseUrl
        models_endpoint   = "/fetch/get_models"
        template_endpoint = "/fetch/get_template_item"
        driver_endpoint   = "/fetch/get_driver_list_by_product"
    }
    drivers      = $driversList
    special      = $specialDrivers
}

$driversJsonPath = Join-Path $OutputDir "drivers.json"
$generatedManifest | ConvertTo-Json -Depth 10 | Out-File -FilePath $driversJsonPath -Encoding utf8

# ------------------------------------------------------------------------------
# 7. Generate generated/version.json
# ------------------------------------------------------------------------------
$versionsDict = [ordered]@{}

foreach ($d in $driversList) {
    $versionsDict[$d.id] = [ordered]@{
        category = $d.category
        name     = $d.name
        version  = $d.version
        date     = $d.date
        repo_id  = $d.repo_id
        file     = $d.file_repo
        url      = $d.download_url
    }
}

if ($specialDrivers) {
    foreach ($prop in $specialDrivers.PSObject.Properties) {
        $sp = $prop.Value
        $versionsDict[$prop.Name] = [ordered]@{
            category = $sp.category
            name     = $sp.name
            version  = $sp.version
            source   = $sp.source
            url      = $sp.url
        }
    }
}

$versionData = [ordered]@{
    generated_at = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    model        = "Axioo Pongo 750"
    vendor_code  = $TargetVendorCode
    target_os    = "Windows 11 x64"
    versions     = $versionsDict
}

$versionJsonPath = Join-Path $OutputDir "version.json"
$versionData | ConvertTo-Json -Depth 10 | Out-File -FilePath $versionJsonPath -Encoding utf8

Write-Host ""
Write-Host "Scraping berhasil selesai!" -ForegroundColor Green
Write-Host "Output:" -ForegroundColor Green
Write-Host "  - generated/drivers.json"
Write-Host "  - generated/version.json"
