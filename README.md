# AxiooPongo-750-Drivers

Driver repository untuk **Axioo Pongo 750 (NP50RNC1)**.

Repository ini dibuat untuk memudahkan proses **download, instalasi, maintenance, dan repair driver** setelah melakukan clean install Windows, terutama pada Windows 11.

## 🎯 Tujuan

Repository ini menyediakan:

- Koleksi driver untuk Axioo Pongo 750
- Informasi versi driver terbaru melalui `version.json`
- Script instalasi otomatis
- Script pengecekan driver
- Script verifikasi setelah instalasi
- **Touchpad Repair** untuk mengatasi masalah Precision Touchpad / multi-touch gesture
- Integrasi GitHub Actions untuk maintenance dan pembaruan metadata driver

## 💻 Device

| Item | Detail |
|---|---|
| Brand | Axioo |
| Series | PONGO |
| Model | 750 |
| Model Code | NP50RNC1 |
| OS | Windows 11 64-bit |

## 📦 Driver

Driver yang digunakan dalam repository ini mengikuti driver yang tersedia untuk **Axioo Pongo 750 / NP50RNC1**.

| Category | Driver | Version |
|---|---|---:|
| VGA | Intel Graphic | 32.0.101.5768 |
| VGA | NVIDIA Graphic | 55.99 |
| AUDIO | Audio | 6.0.9697.1 |
| WIFI | WiFi | 23.60.1.2 |
| BLUETOOTH | Bluetooth | 23.60.0.1 |
| LAN | LAN | 10.072.0524.2024 |
| CARD READER | Card Reader | 2.1.101.10700 |
| CHIPSET | Intel Management Engine | 2425.6.26.0 |
| CHIPSET | Intel Chipset | 10.1.19899.8597 |
| HID FILTER | HID Event Filter | 2.2.2.10 |
| OTHERS | DTT | 9.0.11701.44281 |
| OTHERS | Speed Shift | 1003.20240522 |
| OTHERS | GNA | 03.05.00.1578 |
| OTHERS | Control Center 3.0 | 6.093 |

### 🔧 Special Driver — Touchpad

Touchpad Pongo 750 membutuhkan Intel Serial IO agar perangkat dapat terdeteksi melalui I²C.

| Component | Version |
|---|---:|
| Intel Serial IO I2C Host Controller | 30.100.2531.31 |
| Intel Serial IO GPIO Host Controller | 30.100.2531.31 |

Hardware ID yang terkait:

```text
PCI\VEN_8086&DEV_51E8
ACPI\INTC1055