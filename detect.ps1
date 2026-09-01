# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) - Hardware & Driver Detection Script
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Axioo Pongo 750 Device Detection" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$devices = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue

# ------------------------------------------------------------------------------
# 1. Essential Touchpad & Serial IO Stack
# ------------------------------------------------------------------------------
Write-Host "`n[ Touchpad & Serial IO Stack ]" -ForegroundColor Yellow

$touchpadChecks = @(
    @{
        Key           = "SerialIO-I2C"
        RequiredName  = "Intel(R) Serial IO I2C Host Controller - 51E8"
        HardwareId    = "PCI\VEN_8086&DEV_51E8"
        Device        = ($devices | Where-Object { $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" })
    },
    @{
        Key           = "SerialIO-GPIO"
        RequiredName  = "Intel(R) Serial IO GPIO Host Controller - INTC1055"
        HardwareId    = "ACPI\INTC1055"
        Device        = ($devices | Where-Object { $_.InstanceId -like "ACPI\INTC1055*" })
    },
    @{
        Key           = "I2C-HID"
        RequiredName  = "I2C HID Device"
        HardwareId    = "ACPI\ELAN0412 (I2C)"
        Device        = ($devices | Where-Object { $_.FriendlyName -eq "I2C HID Device" })
    },
    @{
        Key           = "Touchpad"
        RequiredName  = "HID-compliant touch pad"
        HardwareId    = "HID\ELAN0412"
        Device        = ($devices | Where-Object { $_.FriendlyName -eq "HID-compliant touch pad" })
    },
    @{
        Key           = "Microsoft-Input-Configuration"
        RequiredName  = "Microsoft Input Configuration Device"
        HardwareId    = "HID\ELAN0412"
        Device        = ($devices | Where-Object { $_.FriendlyName -eq "Microsoft Input Configuration Device" })
    }
)

foreach ($item in $touchpadChecks) {
    $dev = $item.Device | Select-Object -First 1
    if ($dev -and $dev.Status -eq "OK") {
        Write-Host "[OK]   $($item.Key.PadRight(30)) : $($dev.FriendlyName) [$($dev.Status)]" -ForegroundColor Green
    } elseif ($dev) {
        Write-Host "[WARN] $($item.Key.PadRight(30)) : $($dev.FriendlyName) [$($dev.Status)]" -ForegroundColor Yellow
    } else {
        Write-Host "[FAIL] $($item.Key.PadRight(30)) : Device tidak terdeteksi / driver belum terpasang" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# 2. ELAN ACPI / Legacy Detection Check
# ------------------------------------------------------------------------------
Write-Host "`n[ ELAN Touchpad Hardware Status ]" -ForegroundColor Yellow

$elanAcpi = $devices | Where-Object { $_.InstanceId -like "ACPI\ELAN0412*" }
if ($elanAcpi) {
    foreach ($e in $elanAcpi) {
        Write-Host "[INFO] Instance: $($e.InstanceId)" -ForegroundColor Cyan
        Write-Host "       Name    : $($e.FriendlyName) [$($e.Status)]" -ForegroundColor Cyan
    }
} else {
    Write-Host "[INFO] ACPI\ELAN0412 tidak terdeteksi pada tabel ACPI." -ForegroundColor DarkGray
}

# ------------------------------------------------------------------------------
# 3. Core Subsystems (GPU, Audio, Network)
# ------------------------------------------------------------------------------
Write-Host "`n[ Core Hardware Subsystems ]" -ForegroundColor Yellow

$subsystems = @(
    @{ Name = "Intel Graphics"; Dev = ($devices | Where-Object { $_.Class -eq "Display" -and $_.FriendlyName -match "Intel" }) },
    @{ Name = "NVIDIA Graphics"; Dev = ($devices | Where-Object { $_.Class -eq "Display" -and $_.FriendlyName -match "NVIDIA|GeForce|RTX" }) },
    @{ Name = "Audio"; Dev = ($devices | Where-Object { $_.Class -eq "MEDIA" -and $_.FriendlyName -match "Realtek|High Definition Audio" }) },
    @{ Name = "WiFi"; Dev = ($devices | Where-Object { $_.Class -eq "Net" -and $_.FriendlyName -match "Wi-Fi|Wireless|Intel" }) },
    @{ Name = "LAN"; Dev = ($devices | Where-Object { $_.Class -eq "Net" -and $_.FriendlyName -match "Realtek|GbE|Ethernet" }) },
    @{ Name = "Bluetooth"; Dev = ($devices | Where-Object { $_.Class -eq "Bluetooth" -and $_.FriendlyName -match "Bluetooth" }) }
)

foreach ($sub in $subsystems) {
    $d = $sub.Dev | Select-Object -First 1
    if ($d -and $d.Status -eq "OK") {
        Write-Host "[OK]   $($sub.Name.PadRight(20)) : $($d.FriendlyName)" -ForegroundColor Green
    } elseif ($d) {
        Write-Host "[WARN] $($sub.Name.PadRight(20)) : $($d.FriendlyName) [$($d.Status)]" -ForegroundColor Yellow
    } else {
        Write-Host "[INFO] $($sub.Name.PadRight(20)) : Belum terdeteksi atau menggunakan generic driver" -ForegroundColor DarkGray
    }
}

# ------------------------------------------------------------------------------
# 4. Touchpad Diagnosis Assessment
# ------------------------------------------------------------------------------
Write-Host "`n[ Assessment ]" -ForegroundColor Yellow

$hasI2C     = ($devices | Where-Object { $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" -and $_.Status -eq "OK" })
$hasGPIO    = ($devices | Where-Object { $_.InstanceId -like "ACPI\INTC1055*" -and $_.Status -eq "OK" })
$hasHidPad  = ($devices | Where-Object { $_.FriendlyName -eq "HID-compliant touch pad" -and $_.Status -eq "OK" })
$hasI2cHid  = ($devices | Where-Object { $_.FriendlyName -eq "I2C HID Device" -and $_.Status -eq "OK" })

if ($hasHidPad -and $hasI2cHid -and $hasI2C -and $hasGPIO) {
    Write-Host "STATUS: Precision Touchpad aktif dan siap digunakan." -ForegroundColor Green
    Write-Host "Catatan: Jika ACPI\ELAN0412 juga muncul sebagai PS/2 Compatible Mouse, hal tersebut adalah normal di Windows 11." -ForegroundColor Cyan
} elseif (-not $hasI2C -or -not $hasGPIO) {
    Write-Host "STATUS: Intel Serial IO (I2C / GPIO) belum terpasang atau bermasalah." -ForegroundColor Red
    Write-Host "Tindakan disarankan: Jalankan .\install-touchpad.ps1 untuk memasang Intel Serial IO." -ForegroundColor Yellow
} else {
    Write-Host "STATUS: Driver telah terpasang namun perangkat HID belum aktif. Disarankan me-restart Windows." -ForegroundColor Yellow
}