# ==============================================================================
# Axioo Pongo 750 (NP50RNC1) - Post-Installation Verification Script
# ==============================================================================

[CmdletBinding()]
param()

$failed = $false

function Test-Device {
    param (
        [string]$Name,
        [scriptblock]$Condition
    )

    $result = & $Condition

    if ($result) {
        Write-Host "[OK]   $Name" -ForegroundColor Green
    }
    else {
        Write-Host "[FAIL] $Name" -ForegroundColor Red
        $script:failed = $true
    }
}

Test-Device "Intel Serial IO I2C" {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*" -and
        $_.Status -eq "OK"
    }
}

Test-Device "Intel Serial IO GPIO" {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.InstanceId -like "ACPI\INTC1055*" -and
        $_.Status -eq "OK"
    }
}

Test-Device "I2C HID Device" {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -eq "I2C HID Device" -and
        $_.Status -eq "OK"
    }
}

Test-Device "HID-compliant touch pad" {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -eq "HID-compliant touch pad" -and
        $_.Status -eq "OK"
    }
}

Test-Device "Microsoft Input Configuration Device" {
    Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object {
        $_.FriendlyName -eq "Microsoft Input Configuration Device" -and
        $_.Status -eq "OK"
    }
}

Write-Host ""
if ($failed) {
    Write-Host "Touchpad verification FAILED." -ForegroundColor Red
    exit 1
}

Write-Host "Touchpad verification PASSED." -ForegroundColor Green
exit 0