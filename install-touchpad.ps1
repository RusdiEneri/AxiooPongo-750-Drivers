# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) - Touchpad Repair Script
# Validated Intel Serial IO Driver for Windows Precision Touchpad (I2C HID)
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$SkipVerify
)

# Menggunakan Continue agar tidak crash total, kita tangani error secara manual di catch block
$ErrorActionPreference = "Continue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ------------------------------------------------------------------------------
# 0. Self-Recovery untuk eksekusi via 'irm | iex'
# ------------------------------------------------------------------------------
if (-not $PSScriptRoot -and -not $MyInvocation.MyCommand.Path) {
    Write-Host "Script dijalankan via pipe (irm | iex). Mengunduh ke direktori sementara..." -ForegroundColor Yellow
    $tempScript = Join-Path $env:TEMP "AxiooTouchpadRepair.ps1"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install-touchpad.ps1" -OutFile $tempScript -UseBasicParsing
        & $tempScript @PSBoundParameters
        exit $LASTEXITCODE
    } catch {
        Write-Error "Gagal mengunduh script ke direktori sementara: $_"
        exit 1
    }
}

function Test-IsAdmin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Error "Script ini membutuhkan hak akses Administrator. Jalankan PowerShell sebagai Administrator."
    exit 1
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Axioo Pongo 750 Touchpad Repair" -ForegroundColor Cyan
Write-Host " Target: Windows Precision Touchpad (I2C HID)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# 1. Determine Driver URL and Configuration
# ------------------------------------------------------------------------------
$FallbackUrl = "https://catalog.s.download.windowsupdate.com/d/msdownload/update/driver/drvs/2025/11/fc633db2-319c-4acb-815c-877902b824ff_8e228ba0068deff3460565a3294e27cdd428ac5c.cab"
$SerialIOUrl = $FallbackUrl

$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path 2>$null }
if ($ScriptDir) {
    $ConfigFile = Join-Path $ScriptDir "config\special-drivers.json"
    if (Test-Path $ConfigFile) {
        try {
            $config = (Get-Content $ConfigFile -Raw -Encoding utf8) | ConvertFrom-Json
            if ($config."serial-io" -and $config."serial-io".url) {
                $SerialIOUrl = $config."serial-io".url
            }
        } catch {}
    }
}

$TempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("AxiooTouchpadRepair_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    # --------------------------------------------------------------------------
    # 2. Check Hardware
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[1/5] Memeriksa kondisi perangkat keras..." -ForegroundColor Yellow

    $pnpDevices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue

    $i2cDev  = $pnpDevices | Where-Object { $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" }
    $gpioDev = $pnpDevices | Where-Object { $_.InstanceId -like "ACPI\INTC1055*" }
    $elanDev = $pnpDevices | Where-Object { $_.InstanceId -like "ACPI\ELAN0412*" }

    Write-Host "  - Intel Serial IO I2C (51E8)   : $(if ($i2cDev) { "$($i2cDev.FriendlyName) [$($i2cDev.Status)]" } else { 'Tidak terdeteksi / driver belum terpasang' })"
    Write-Host "  - Intel Serial IO GPIO (INTC1055): $(if ($gpioDev) { "$($gpioDev.FriendlyName) [$($gpioDev.Status)]" } else { 'Tidak terdeteksi / driver belum terpasang' })"
    Write-Host "  - ELAN Touchpad (ELAN0412)     : $(if ($elanDev) { "$($elanDev.FriendlyName) [$($elanDev.Status)]" } else { 'Tidak terdeteksi' })"

    # --------------------------------------------------------------------------
    # 3. Download Intel Serial IO Package (With Auto-Retry & Timeout)
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[2/5] Mengunduh driver Intel Serial IO (v30.100.2531.31)..." -ForegroundColor Yellow
    Write-Host "  URL: $SerialIOUrl"

    $CabPath = Join-Path $TempDir "SerialIO.cab"
    
    $maxRetries = 3
    $downloadSuccess = $false
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            Invoke-WebRequest -Uri $SerialIOUrl -OutFile $CabPath -UseBasicParsing -Headers @{ "User-Agent" = "Mozilla/5.0" } -TimeoutSec 120
            if ((Test-Path $CabPath) -and (Get-Item $CabPath).Length -gt 0) {
                $downloadSuccess = $true
                break
            } else {
                throw "File unduhan kosong (0 bytes)."
            }
        } catch {
            Write-Warning "  [Percobaan $i/$maxRetries] Gagal mengunduh: $($_.Exception.Message)"
            if ($i -lt $maxRetries) {
                Write-Host "  Menunggu 5 detik sebelum mencoba lagi..." -ForegroundColor Gray
                Start-Sleep -Seconds 5
            }
        }
    }

    if (-not $downloadSuccess) {
        throw "Gagal mengunduh paket Serial IO CAB setelah $maxRetries percobaan. Pastikan koneksi internet stabil atau coba gunakan Hotspot HP (DNS ISP mungkin memblokir server Microsoft)."
    }

    # --------------------------------------------------------------------------
    # 4. Extract CAB
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[3/5] Mengekstrak file driver..." -ForegroundColor Yellow

    $ExtractDir = Join-Path $TempDir "Extracted"
    New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null

    $expandOutput = & expand.exe -F:* "$CabPath" "$ExtractDir" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Ekstraksi CAB gagal: $expandOutput"
    }

    $gpioInf = Join-Path $ExtractDir "iaLPSS2_GPIO2_ADL.inf"
    $i2cInf  = Join-Path $ExtractDir "iaLPSS2_I2C_ADL.inf"

    if (-not (Test-Path $gpioInf) -or -not (Test-Path $i2cInf)) {
        throw "File INF (iaLPSS2_GPIO2_ADL.inf / iaLPSS2_I2C_ADL.inf) tidak ditemukan dalam ekstraksi."
    }

    # --------------------------------------------------------------------------
    # 5. Install Intel Serial IO INF
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[4/5] Memasang driver Intel Serial IO GPIO & I2C via pnputil..." -ForegroundColor Yellow

    Write-Host "  - Installing GPIO Driver (iaLPSS2_GPIO2_ADL.inf)..."
    $pnpGpio = & pnputil.exe /add-driver "$gpioInf" /install 2>&1
    Write-Host "       $(($pnpGpio | Select-Object -First 3) -join ' ')"

    Write-Host "  - Installing I2C Driver (iaLPSS2_I2C_ADL.inf)..."
    $pnpI2c = & pnputil.exe /add-driver "$i2cInf" /install 2>&1
    Write-Host "       $(($pnpI2c | Select-Object -First 3) -join ' ')"

    # --------------------------------------------------------------------------
    # 6. Rescan Hardware
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Host "[5/5] Melakukan refresh perangkat (pnputil /scan-devices)..." -ForegroundColor Yellow
    & pnputil.exe /scan-devices 2>&1 | Out-Null
    Start-Sleep -Seconds 2

    # --------------------------------------------------------------------------
    # 7. Post-Installation Verification
    # --------------------------------------------------------------------------
    if (-not $SkipVerify) {
        Write-Host ""
        Write-Host "=========================================" -ForegroundColor Cyan
        Write-Host " Touchpad Verification" -ForegroundColor Cyan
        Write-Host "=========================================" -ForegroundColor Cyan

        $devices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue

        $checks = [ordered]@{
            "Intel Serial IO I2C"                 = ($devices | Where-Object { $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" -and $_.Status -eq "OK" })
            "Intel Serial IO GPIO"                = ($devices | Where-Object { $_.InstanceId -like "ACPI\INTC1055*" -and $_.Status -eq "OK" })
            "I2C HID Device"                      = ($devices | Where-Object { $_.FriendlyName -eq "I2C HID Device" -and $_.Status -eq "OK" })
            "HID-compliant touch pad"             = ($devices | Where-Object { $_.FriendlyName -eq "HID-compliant touch pad" -and $_.Status -eq "OK" })
            "Microsoft Input Configuration Device" = ($devices | Where-Object { $_.FriendlyName -eq "Microsoft Input Configuration Device" -and $_.Status -eq "OK" })
        }

        $allPassed = $true
        foreach ($key in $checks.Keys) {
            if ($checks[$key]) {
                Write-Host "[OK]   $key" -ForegroundColor Green
            } else {
                Write-Host "[FAIL] $key" -ForegroundColor Red
                $allPassed = $false
            }
        }

        Write-Host ""
        if ($allPassed) {
            Write-Host "Touchpad verification PASSED." -ForegroundColor Green
            Write-Host ""
            Write-Host "Catatan: Jika gesture belum aktif seketika, silakan restart Windows." -ForegroundColor Cyan
            Write-Host "Setelah restart, periksa: Settings -> Bluetooth & devices -> Touchpad." -ForegroundColor Cyan
        } else {
            Write-Host "Touchpad verification: Beberapa komponen memerlukan restart Windows untuk menginisialisasi stack I2C HID." -ForegroundColor Yellow
            Write-Host "Silakan RESTART Windows sekarang." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host ""
    Write-Error "Terjadi kesalahan fatal: $_"
    Write-Host "[TIPS] Jika error terkait 'remote name could not be resolved', matikan WiFi dan gunakan Tethering Hotspot HP sementara waktu, lalu jalankan ulang script ini." -ForegroundColor Magenta
}
finally {
    if (Test-Path $TempDir) {
        Remove-Item $TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}