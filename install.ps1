# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) - Master Driver Installer
# Automatically reads manifest from generated/drivers.json
# ==============================================================================

[CmdletBinding(DefaultParameterSetName = "Interactive")]
param(
    [Parameter(ParameterSetName = "Batch")]
    [switch]$All,

    [Parameter(ParameterSetName = "Batch")]
    [switch]$TouchpadOnly,

    [Parameter(ParameterSetName = "Batch")]
    [string[]]$Drivers,

    [Parameter(ParameterSetName = "Batch")]
    [string[]]$Categories,

    [Parameter(ParameterSetName = "Batch")]
    [switch]$SkipSpecial,

    [Parameter()]
    [switch]$DetectOnly,

    [Parameter()]
    [switch]$SkipVerify,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [string]$ManifestPath
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ------------------------------------------------------------------------------
# 1. Administrator Elevation Check
# ------------------------------------------------------------------------------
function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ------------------------------------------------------------------------------
# 2. Path & Manifest Resolution
# ------------------------------------------------------------------------------
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path 2>$null }
$RemoteManifestUrl = "https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/generated/drivers.json"

function Get-DriverManifest {
    param([string]$CustomPath)

    if ($CustomPath) {
        if (Test-Path $CustomPath) {
            return (Get-Content $CustomPath -Raw -Encoding utf8) | ConvertFrom-Json
        }
        if ($CustomPath -match '^https?://') {
            return (Invoke-RestMethod -Uri $CustomPath -Headers @{ "User-Agent" = "Mozilla/5.0" })
        }
    }

    if ($ScriptDir) {
        $localGen = Join-Path $ScriptDir "generated\drivers.json"
        if (Test-Path $localGen) {
            return (Get-Content $localGen -Raw -Encoding utf8) | ConvertFrom-Json
        }
    }

    # Fallback to Remote
    Write-Host "Mengambil manifest driver resmi dari repository..." -ForegroundColor Cyan
    try {
        return (Invoke-RestMethod -Uri $RemoteManifestUrl -Headers @{ "User-Agent" = "Mozilla/5.0" })
    }
    catch {
        throw "Gagal memuat manifest driver (lokal maupun remote): $_"
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Axioo Pongo 750 Master Driver Installer" -ForegroundColor Cyan
Write-Host " Target: Axioo Pongo 750 (NP50RNC1) - Win11 x64" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

if ($DetectOnly) {
    if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "detect.ps1"))) {
        & (Join-Path $ScriptDir "detect.ps1")
    } else {
        Write-Host "Menjalankan deteksi hardware..." -ForegroundColor Cyan
        $devs = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue
        $devs | Where-Object { $_.InstanceId -match '51E8|INTC1055|ELAN0412' -or $_.FriendlyName -match 'touch pad|I2C HID|Input Configuration' } | Format-Table InstanceId, FriendlyName, Status -AutoSize
    }
    exit 0
}

# Enforce Administrator for installation
if (-not (Test-IsAdmin)) {
    Write-Error "Instalasi driver membutuhkan hak akses Administrator. Jalankan PowerShell sebagai Administrator."
    exit 1
}

$manifest = Get-DriverManifest -CustomPath $ManifestPath
Write-Host "Manifest dimuat: $($manifest.model.brand) $($manifest.model.series) $($manifest.model.model) ($($manifest.model.code))" -ForegroundColor Green

# ------------------------------------------------------------------------------
# 3. Target Driver Selection
# ------------------------------------------------------------------------------
$selectedDrivers = [System.Collections.Generic.List[PSObject]]::new()

# Collect special drivers
$specialList = [System.Collections.Generic.List[PSObject]]::new()
if ($manifest.special) {
    foreach ($prop in $manifest.special.PSObject.Properties) {
        $sp = $prop.Value
        $specialObj = [PSCustomObject]@{
            id            = $prop.Name
            name          = $sp.name
            category      = $sp.category
            version       = $sp.version
            download_url  = $sp.url
            source        = $sp.source
            hardware_ids  = $sp.hardware_ids
            install       = $sp.install
            is_special    = $true
        }
        $specialList.Add($specialObj)
    }
}

# Combine all available drivers
$allDriversList = [System.Collections.Generic.List[PSObject]]::new()
foreach ($d in $manifest.drivers) {
    $allDriversList.Add($d)
}
foreach ($sp in $specialList) {
    $allDriversList.Add($sp)
}

if ($TouchpadOnly) {
    $selectedDrivers.AddRange($specialList)
    $hidFilter = $manifest.drivers | Where-Object { $_.id -like "*hid-filter*" }
    if ($hidFilter) { $selectedDrivers.Add($hidFilter) }
}
elseif ($All) {
    foreach ($d in $manifest.drivers) { $selectedDrivers.Add($d) }
    if (-not $SkipSpecial) {
        foreach ($sp in $specialList) { $selectedDrivers.Add($sp) }
    }
}
elseif ($Drivers -and $Drivers.Count -gt 0) {
    foreach ($id in $Drivers) {
        $match = $allDriversList | Where-Object { $_.id -eq $id -or $_.name -like "*$id*" }
        if ($match) { $selectedDrivers.AddRange($match) }
        else { Write-Warning "Driver ID '$id' tidak ditemukan dalam manifest." }
    }
}
elseif ($Categories -and $Categories.Count -gt 0) {
    foreach ($cat in $Categories) {
        $matches = $allDriversList | Where-Object { $_.category -like "*$cat*" }
        if ($matches) { $selectedDrivers.AddRange($matches) }
    }
}
else {
    # Interactive Console Menu
    Write-Host "`nPilih mode instalasi:" -ForegroundColor Yellow
    Write-Host "  [1] Touchpad Repair & Precision Stack (Intel Serial IO + HID Filter) [Disarankan]"
    Write-Host "  [2] Driver Pokok / Essential (Serial IO, Chipset, Audio, LAN, WiFi, Bluetooth, HID Filter)"
    Write-Host "  [3] Semua Driver Resmi Axioo + Special Drivers (Full Suite)"
    Write-Host "  [4] Deteksi Perangkat (Detect Hardware)"
    Write-Host "  [5] Verifikasi Touchpad (Verify)"
    Write-Host "  [Q] Keluar"
    
    $choice = Read-Host "`nMasukkan pilihan [1-5 / Q]"
    switch ($choice) {
        "1" {
            $selectedDrivers.AddRange($specialList)
            $hidFilter = $manifest.drivers | Where-Object { $_.id -like "*hid-filter*" }
            if ($hidFilter) { $selectedDrivers.Add($hidFilter) }
        }
        "2" {
            $selectedDrivers.AddRange($specialList)
            $essentialCategories = @("CHIPSET", "AUDIO", "LAN", "WIFI", "BLUETOOTH", "HID FILTER", "CARD READER")
            foreach ($d in $manifest.drivers) {
                if ($essentialCategories -contains $d.category.ToUpper()) {
                    $selectedDrivers.Add($d)
                }
            }
        }
        "3" {
            foreach ($d in $manifest.drivers) { $selectedDrivers.Add($d) }
            foreach ($sp in $specialList) { $selectedDrivers.Add($sp) }
        }
        "4" {
            if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "detect.ps1"))) {
                & (Join-Path $ScriptDir "detect.ps1")
            }
            exit 0
        }
        "5" {
            if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "verify.ps1"))) {
                & (Join-Path $ScriptDir "verify.ps1")
            }
            exit 0
        }
        default {
            Write-Host "Dibatalkan oleh pengguna."
            exit 0
        }
    }
}

if ($selectedDrivers.Count -eq 0) {
    Write-Warning "Tidak ada driver yang dipilih untuk diinstal."
    exit 0
}

# ------------------------------------------------------------------------------
# 4. Installation Execution
# ------------------------------------------------------------------------------
Write-Host "`nDriver yang akan diinstal ($($selectedDrivers.Count) paket):" -ForegroundColor Cyan
foreach ($d in $selectedDrivers) {
    Write-Host "  - [$($d.category)] $($d.name) (v$($d.version))"
}

$TempBase = Join-Path ([System.IO.Path]::GetTempPath()) ("AxiooInstaller_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $TempBase | Out-Null

try {
    $counter = 0
    foreach ($driver in $selectedDrivers) {
        $counter++
        Write-Host "`n========================================================" -ForegroundColor Cyan
        Write-Host "[$counter/$($selectedDrivers.Count)] Memproses: $($driver.name) ($($driver.category))" -ForegroundColor Cyan
        Write-Host "========================================================" -ForegroundColor Cyan

        $url = $driver.download_url
        if (-not $url) {
            Write-Warning "URL download kosong untuk $($driver.name), melewati..."
            continue
        }

        $fileName = if ($driver.file_repo) { $driver.file_repo } else { Split-Path $url -Leaf }
        $targetFile = Join-Path $TempBase $fileName
        $extractDir = Join-Path $TempBase ("Extracted_" + $driver.id)

        # 4.1 Download
        Write-Host "  Mengunduh dari: $url" -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $url -OutFile $targetFile -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0" }
        }
        catch {
            Write-Error "  [ERROR] Gagal mengunduh $($fileName): $_"
            continue
        }

        if (-not (Test-Path $targetFile) -or (Get-Item $targetFile).Length -eq 0) {
            Write-Error "  [ERROR] File unduhan $fileName kosong atau tidak ditemukan."
            continue
        }

        Write-Host "  Unduhan selesai: $([Math]::Round((Get-Item $targetFile).Length / 1MB, 2)) MB" -ForegroundColor Green

        # 4.2 Extraction
        New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
        $ext = [System.IO.Path]::GetExtension($fileName).ToLower()

        Write-Host "  Mengekstrak paket..." -ForegroundColor Yellow
        if ($ext -eq ".cab") {
            $expandOut = & expand.exe -F:* "$targetFile" "$extractDir" 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "  Peringatan expand CAB: $expandOut"
            }
        }
        elseif ($ext -eq ".zip") {
            try {
                Expand-Archive -Path $targetFile -DestinationPath $extractDir -Force
            }
            catch {
                Write-Warning "  Peringatan ekstraksi ZIP: $_"
            }
        }

        # 4.3 Install via pnputil / package
        Write-Host "  Memasang driver ke sistem..." -ForegroundColor Yellow

        # Priority: Check and install INFs using pnputil
        $infFiles = Get-ChildItem -Path $extractDir -Filter "*.inf" -Recurse -File -ErrorAction SilentlyContinue
        $installedInf = $false

        if ($infFiles -and $infFiles.Count -gt 0) {
            Write-Host "  Ditemukan $($infFiles.Count) file INF driver:"
            foreach ($inf in $infFiles) {
                Write-Host "    -> pnputil /add-driver `"$($inf.FullName)`" /install"
                $pnpResult = & pnputil.exe /add-driver "$($inf.FullName)" /install 2>&1
                Write-Host "       $($pnpResult | Select-Object -First 3 -join ' ')"
            }
            $installedInf = $true
        }

        # If package installer setup.exe exists and no INF or package type is specified
        if ($driver.install -and $driver.install.type -eq "package" -and -not $installedInf) {
            $setupExe = Get-ChildItem -Path $extractDir -Filter "*setup*.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            if (-not $setupExe) {
                $setupExe = Get-ChildItem -Path $extractDir -Filter "*.exe" -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
            }

            if ($setupExe) {
                Write-Host "  Menjalankan installer: $($setupExe.Name)" -ForegroundColor Yellow
                try {
                    $process = Start-Process -FilePath $setupExe.FullName -ArgumentList "/s /qn /quiet" -PassThru -Wait -ErrorAction SilentlyContinue
                    Write-Host "  Installer selesai dengan exit code: $($process.ExitCode)" -ForegroundColor Green
                }
                catch {
                    Write-Warning "  Gagal menjalankan setup executable secara silent. Silakan pasang manual dari: $($setupExe.FullName)"
                }
            }
        }

        Write-Host "  [OK] Paket $($driver.name) telah diproses." -ForegroundColor Green
    }

    # --------------------------------------------------------------------------
    # 5. Rescan Hardware
    # --------------------------------------------------------------------------
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host "Melakukan PnP Hardware Rescan (pnputil /scan-devices)..." -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan
    & pnputil.exe /scan-devices 2>&1 | Out-Null
    Start-Sleep -Seconds 2

    # --------------------------------------------------------------------------
    # 6. Verification
    # --------------------------------------------------------------------------
    if (-not $SkipVerify) {
        Write-Host ""
        if ($ScriptDir -and (Test-Path (Join-Path $ScriptDir "verify.ps1"))) {
            & (Join-Path $ScriptDir "verify.ps1")
        }
    }

    Write-Host ""
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host " Seluruh proses instalasi selesai!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
}
finally {
    if (Test-Path $TempBase) {
        Remove-Item $TempBase -Recurse -Force -ErrorAction SilentlyContinue
    }
}
