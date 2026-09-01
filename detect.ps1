$devices = Get-PnpDevice -PresentOnly

$checks = @{
    "SerialIO-I2C" = $devices | Where-Object {
        $_.InstanceId -like "PCI\VEN_8086&DEV_51E8*"
    }

    "SerialIO-GPIO" = $devices | Where-Object {
        $_.InstanceId -like "ACPI\INTC1055*"
    }

    "Touchpad" = $devices | Where-Object {
        $_.FriendlyName -eq "HID-compliant touch pad"
    }

    "I2C-HID" = $devices | Where-Object {
        $_.FriendlyName -eq "I2C HID Device"
    }

    "Microsoft-Input-Configuration" = $devices | Where-Object {
        $_.FriendlyName -eq "Microsoft Input Configuration Device"
    }
}

$checks.GetEnumerator() | ForEach-Object {

    if ($_.Value) {
        Write-Host "[OK]   $($_.Key)"
    }
    else {
        Write-Host "[FAIL] $($_.Key)"
    }
}