#requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Temp = Join-Path $env:TEMP "AxiooPongo750-Touchpad"

Write-Host "========================================="
Write-Host " Axioo Pongo 750 Touchpad Repair"
Write-Host "========================================="

New-Item -ItemType Directory -Force -Path $Temp | Out-Null

# -------------------------------------------------
# Hardware IDs
# -------------------------------------------------

$i2cId  = "PCI\VEN_8086&DEV_51E8"
$gpioId = "ACPI\INTC1055"
$elanId = "ACPI\ELAN0412"

Write-Host ""
Write-Host "[1/5] Checking hardware..."

pnputil /enum-devices /instanceid "$i2cId*" | Out-Host
pnputil /enum-devices /instanceid "$gpioId*" | Out-Host
pnputil /enum-devices /instanceid "$elanId*" | Out-Host

# -------------------------------------------------
# Download Serial IO
# -------------------------------------------------

$SerialIOUrl = "PASTE_CAB_URL_HERE"
$Cab = Join-Path $Temp "SerialIO.cab"

Write-Host ""
Write-Host "[2/5] Downloading Intel Serial IO..."

Invoke-WebRequest `
    -Uri $SerialIOUrl `
    -OutFile $Cab `
    -UseBasicParsing

# -------------------------------------------------
# Extract
# -------------------------------------------------

$Extract = Join-Path $Temp "SerialIO"

Remove-Item $Extract -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $Extract | Out-Null

Write-Host ""
Write-Host "[3/5] Extracting Serial IO..."

expand.exe -F:* $Cab $Extract

# -------------------------------------------------
# Install GPIO + I2C
# -------------------------------------------------

Write-Host ""
Write-Host "[4/5] Installing Intel Serial IO..."

pnputil /add-driver `
    "$Extract\iaLPSS2_GPIO2_ADL.inf" `
    /install

pnputil /add-driver `
    "$Extract\iaLPSS2_I2C_ADL.inf" `
    /install

# -------------------------------------------------
# Hardware rescan
# -------------------------------------------------

Write-Host ""
Write-Host "[5/5] Rescanning hardware..."

pnputil /scan-devices

Write-Host ""
Write-Host "Touchpad Serial IO installation completed."
Write-Host "Restart Windows now."