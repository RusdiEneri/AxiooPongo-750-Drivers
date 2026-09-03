# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) - Post-Installation Verification Script
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

# ------------------------------------------------------------------------------
# 0. Self-Recovery untuk eksekusi via 'irm | iex'
# ------------------------------------------------------------------------------
if (-not $PSScriptRoot -and -not $MyInvocation.MyCommand.Path) {
    $tempScript = Join-Path $env:TEMP "AxiooVerify.ps1"
    try {
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/verify.ps1" -OutFile $tempScript -UseBasicParsing -TimeoutSec 30
        & $tempScript @PSBoundParameters
        exit $LASTEXITCODE
    } catch {
        Write-Error "Gagal mengunduh script ke direktori sementara: $_"
        exit 1
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Axioo Pongo 750 Post-Installation Verify" -ForegroundColor Cyan
Write-Host " Target: Precision Touchpad Stack" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. Fetch Devices (Hanya 1x Query untuk Performa Optimal)
# ------------------------------------------------------------------------------
Write-Host "[INFO] Memindai perangkat keras (PnP Devices)..." -ForegroundColor Yellow
$devices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 2. Verification Checks
# ------------------------------------------------------------------------------
$checks = @(
    @{
        Name      = "Intel Serial IO I2C"
        Condition = { $devices | Where-Object { $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" -and $_.Status -eq "OK" } }
    },
    @{
        Name      = "Intel Serial IO GPIO"
        Condition = { $devices | Where-Object { $_.InstanceId -like "ACPI\INTC1055*" -and $_.Status -eq "OK" } }
    },
    @{
        Name      = "I2C HID Device"
        Condition = { $devices | Where-Object { $_.FriendlyName -eq "I2C HID Device" -and $_.Status -eq "OK" } }
    },
    @{
        Name      = "HID-compliant touch pad"
        Condition = { $devices | Where-Object { $_.FriendlyName -eq "HID-compliant touch pad" -and $_.Status -eq "OK" } }
    },
    @{
        Name      = "Microsoft Input Configuration Device"
        Condition = { $devices | Where-Object { $_.FriendlyName -eq "Microsoft Input Configuration Device" -and $_.Status -eq "OK" } }
    }
)

$failed = $false
$failedItems = [System.Collections.Generic.List[string]]::new()

foreach ($check in $checks) {
    $result = & $check.Condition
    
    if ($result) {
        Write-Host "[OK]   $($check.Name)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($check.Name)" -ForegroundColor Red
        $failed = $true
        $failedItems.Add($check.Name)
    }
}

# ------------------------------------------------------------------------------
# 3. Assessment & Exit Code
# ------------------------------------------------------------------------------
Write-Host ""
if ($failed) {
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host " Touchpad verification FAILED." -ForegroundColor Red
    Write-Host "========================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Komponen yang bermasalah:" -ForegroundColor Yellow
    foreach ($item in $failedItems) {
        Write-Host "  - $item" -ForegroundColor DarkYellow
    }
    Write-Host ""
    Write-Host "Tindakan yang disarankan:" -ForegroundColor Cyan
    Write-Host "  1. Pastikan Anda sudah me-RESTART Windows setelah instalasi driver." -ForegroundColor White
    Write-Host "  2. Jika belum, jalankan: .\install-touchpad.ps1" -ForegroundColor White
    Write-Host "  3. Periksa Device Manager untuk perangkat dengan tanda seru kuning (!)." -ForegroundColor White
    exit 1
}

Write-Host "========================================================" -ForegroundColor Green
Write-Host " Touchpad verification PASSED." -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Stack Precision Touchpad telah terinstal dengan benar." -ForegroundColor Cyan
Write-Host "Anda dapat mengatur gesture 2/3/4 jari di: Settings -> Bluetooth & devices -> Touchpad" -ForegroundColor Cyan
exit 0