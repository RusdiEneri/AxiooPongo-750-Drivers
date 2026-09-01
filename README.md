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
````

Setelah driver Serial IO terpasang dengan benar, perangkat touchpad diharapkan terdeteksi sebagai:

```text
I2C HID Device
HID-compliant touch pad
Microsoft Input Configuration Device
```

Hal ini memungkinkan fitur seperti:

* Two-finger scrolling
* Pinch-to-zoom
* Three-finger gestures
* Four-finger gestures

## 🚀 Installation

### Automatic Installation

Jalankan PowerShell sebagai **Administrator**:

```powershell
irm https://raw.githubusercontent.com/USERNAME/AxiooPongo-750-Drivers/main/install.ps1 | iex
```

> Ganti `USERNAME` dengan username GitHub pemilik repository.

Installer akan:

1. Membaca konfigurasi driver
2. Mengecek hardware
3. Mengunduh driver
4. Memasang driver
5. Melakukan hardware rescan
6. Melakukan verifikasi hasil instalasi

---

## 🖱️ Touchpad Repair

Gunakan fitur ini apabila touchpad hanya berfungsi sebagai mouse biasa dan gesture 2/3/4 jari tidak tersedia.

Contoh gejala:

```text
PS/2 Compatible Mouse
```

dan Settings → Touchpad hanya menampilkan opsi dasar seperti:

```text
Taps
Touchpad sensitivity
```

Jalankan:

```powershell
irm https://raw.githubusercontent.com/USERNAME/AxiooPongo-750-Drivers/main/install-touchpad.ps1 | iex
```

Repair akan memperbaiki dependency berikut:

```text
Intel Serial IO GPIO
        ↓
Intel Serial IO I2C
        ↓
I2C HID Device
        ↓
HID-compliant touch pad
        ↓
Microsoft Input Configuration Device
```

Setelah proses selesai, **restart Windows**.

Kemudian buka:

```text
Settings
→ Bluetooth & devices
→ Touchpad
```

dan pastikan opsi multi-touch gesture sudah tersedia.

## 🔍 Driver Detection

Untuk mengecek kondisi driver:

```powershell
.\detect.ps1
```

Contoh hasil yang diharapkan:

```text
[OK]   SerialIO-I2C
[OK]   SerialIO-GPIO
[OK]   Touchpad
[OK]   I2C-HID
[OK]   Microsoft-Input-Configuration
```

## ✅ Verification

Setelah instalasi:

```powershell
.\verify.ps1
```

Verification akan memeriksa:

* Intel Serial IO I2C
* Intel Serial IO GPIO
* I2C HID Device
* HID-compliant touch pad
* Microsoft Input Configuration Device

Contoh:

```text
[OK]   Intel Serial IO I2C
[OK]   Intel Serial IO GPIO
[OK]   I2C HID Device
[OK]   HID-compliant touch pad
[OK]   Microsoft Input Configuration Device

Touchpad verification PASSED.
```

## 📋 Version Metadata

Versi driver disimpan pada:

```text
version.json
```

Contoh:

```json
{
  "generated_at": "2026-09-01T00:00:00Z",
  "model": "PONGO 750 NP50RNC1",
  "drivers": {
    "intel-graphics": "32.0.101.5768",
    "audio": "6.0.9697.1",
    "nvidia": "55.99",
    "wifi": "23.60.1.2",
    "bluetooth": "23.60.0.1",
    "hid-filter": "2.2.2.10",
    "intel-chipset": "10.1.19899.8597",
    "serial-io": "30.100.2531.31"
  }
}
```

`version.json` dihasilkan secara otomatis oleh GitHub Actions agar informasi versi tetap mudah diperbarui.

## 🤖 GitHub Actions

Repository menggunakan GitHub Actions untuk:

* Memperbarui metadata driver
* Menghasilkan `version.json`
* Mengecek perubahan versi
* Commit perubahan secara otomatis
* Menjaga repository tetap mudah dipelihara

Workflow berada di:

```text
.github/workflows/
├── update-drivers.yml
└── release.yml
```

## ⚠️ Notes

Repository ini ditujukan khusus untuk:

```text
Axioo Pongo 750
Model: NP50RNC1
Windows 11 x64
```

Driver sebaiknya dipasang sesuai perangkat dan hardware ID masing-masing.

Khusus touchpad, **jangan menginstal driver ELAN/Synaptics secara acak** apabila perangkat belum memiliki Intel Serial IO I²C/GPIO yang benar.

## 📁 Repository Structure

```text
AxiooPongo-750-Drivers/
│
├── .github/
│   └── workflows/
│       ├── update-drivers.yml
│       └── release.yml
│
├── drivers.json
├── version.json
│
├── install.ps1
├── install-touchpad.ps1
├── detect.ps1
├── verify.ps1
│
├── README.md
└── LICENSE
```

## 📜 License

Lihat file [`LICENSE`](LICENSE).

Driver yang didistribusikan melalui repository ini tetap merupakan milik masing-masing vendor/pemegang haknya.

Repository ini berfungsi sebagai **maintenance, automation, dan convenience layer** untuk Axioo Pongo 750.

