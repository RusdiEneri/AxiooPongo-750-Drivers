# AxiooPongo-750-Drivers

Repository otomasi dan pemeliharaan driver resmi untuk **Axioo Pongo 750 (Model Code: NP50RNC1)**.

Repository ini menyediakan sistem terintegrasi untuk **pengambilan metadata driver resmi (scraper API Axioo), instalasi otomatis, deteksi perangkat keras, perbaikan Precision Touchpad, dan verifikasi pasca-instalasi** pada Windows 11 64-bit.

---

## 🎯 Fitur & Arsitektur Utama

1. **Official Axioo API as Source of Truth**:
   Metadata driver diambil secara otomatis dari API resmi Axioo tanpa daftar statis manual yang rawan usang.
2. **Special Driver Integration (Intel Serial IO)**:
   Mengintegrasikan driver Intel Serial IO resmi dari Microsoft Update Catalog untuk memperbaiki rantai deteksi Windows Precision Touchpad (I2C HID).
3. **Automated Master Installer (`install.ps1`)**:
   Membaca manifest `generated/drivers.json`, mengunduh paket resmi via HTTPS, memasang driver INF melalui `pnputil`, dan melakukan rescan perangkat keras.
4. **Dedicated Touchpad Repair (`install-touchpad.ps1`)**:
   Memasang Intel Serial IO GPIO & I2C secara terisolasi untuk memulihkan fungsi multi-touch gesture 2/3/4 jari.
5. **Hardware Detection & Verification (`detect.ps1` & `verify.ps1`)**:
   Mendiagnosis status stack perangkat keras dan memverifikasi kesiapan driver.
6. **Scheduled CI/CD (`.github/workflows/scrape-drivers.yml`)**:
   Memeriksa pembaruan driver secara berkala dan hanya melakukan commit apabila terdapat perubahan metadata.

---

## 💻 Spesifikasi Target

| Parameter | Spesifikasi |
|---|---|
| **Brand** | Axioo |
| **Series** | PONGO |
| **Model** | 750 |
| **Vendor / Model Code** | NP50RNC1 |
| **Template ID** | 311 (`NBAXP7-C7D-165XH`) |
| **Target OS** | Windows 11 (64-bit) |

---

## 📦 Daftar Driver Resmi

### Axioo Official Drivers (API Endpoint)

| Kategori | Nama Driver | Versi Resmi | Sumber |
|---|---|---:|---|
| **VGA** | Intel Graphic | `32.0.101.5768` | Axioo Official API |
| **VGA** | NVIDIA Graphic | `55.99` | Axioo Official API |
| **AUDIO** | Audio | `6.0.9697.1` | Axioo Official API |
| **WIFI** | WiFi | `23.60.1.2` | Axioo Official API |
| **BLUETOOTH** | Bluetooth | `23.60.0.1` | Axioo Official API |
| **LAN** | LAN | `10.072.0524.2024` | Axioo Official API |
| **CARD READER** | Card Reader | `2.1.101.10700` | Axioo Official API |
| **CHIPSET** | Intel Management Engine | `2425.6.26.0` | Axioo Official API |
| **CHIPSET** | Intel Chipset | `10.1.19899.8597` | Axioo Official API |
| **HID FILTER** | HID Event Filter | `2.2.2.10` | Axioo Official API |
| **OTHERS** | DTT | `9.0.11701.44281` | Axioo Official API |
| **OTHERS** | Speed Shift | `1003.20240522` | Axioo Official API |
| **OTHERS** | GNA | `03.05.00.1578` | Axioo Official API |
| **OTHERS** | Control Center 3.0 | `6.093` | Axioo Official API |

### Special Driver — Touchpad Precision Stack

| Komponen | Versi | Sumber |
|---|---:|---|
| **Intel Serial IO I2C Host Controller** | `30.100.2531.31` | Microsoft Update Catalog |
| **Intel Serial IO GPIO Host Controller** | `30.100.2531.31` | Microsoft Update Catalog |

Hardware ID terkait:
```text
PCI\VEN_8086&DEV_51E8
ACPI\INTC1055
ACPI\ELAN0412
```

Rantai dependensi yang tervalidasi:
```text
Intel Serial IO GPIO (ACPI\INTC1055)
        ↓
Intel Serial IO I2C (PCI\VEN_8086&DEV_51E8)
        ↓
I2C HID Device (ACPI\ELAN0412)
        ↓
HID-compliant touch pad
        ↓
Microsoft Input Configuration Device
        ↓
Windows Precision Touchpad / Multi-Touch Gestures
```

> [!NOTE]
> Kemunculan `ACPI\ELAN0412` sebagai `PS/2 Compatible Mouse` bersamaan dengan `HID-compliant touch pad` adalah hal yang normal pada Windows 11 setelah Intel Serial IO terpasang.

---

## 🚀 Panduan Penggunaan

### 1. Automatic Installation (Master Installer)

Jalankan PowerShell sebagai **Administrator**:

```powershell
# Instalasi langsung dari GitHub:
irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install.ps1 | iex
```

Atau jalankan secara lokal dari folder repository:

```powershell
# Mode interaktif (menampilkan menu pilihan):
.\install.ps1

# Memasang seluruh driver (Full Suite):
.\install.ps1 -All

# Hanya memasang stack Touchpad (Intel Serial IO + HID Filter):
.\install.ps1 -TouchpadOnly
```

---

### 2. Touchpad Repair

Gunakan script ini apabila touchpad hanya berfungsi sebagai pointer dasar dan pengaturan gesture multi-jari tidak muncul di Settings Windows:

```powershell
# Eksekusi langsung via web:
irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install-touchpad.ps1 | iex
```

Atau jalankan secara lokal:

```powershell
.\install-touchpad.ps1
```

Setelah script selesai, **restart Windows** dan buka:
`Settings` $\rightarrow$ `Bluetooth & devices` $\rightarrow$ `Touchpad` untuk memastikan gesture multi-touch aktif.

---

### 3. Hardware & Driver Detection

Untuk mendeteksi kondisi perangkat keras dan status driver saat ini:

```powershell
.\detect.ps1
```

Contoh keluaran yang diharapkan:

```text
=========================================
 Axioo Pongo 750 Device Detection
=========================================

[ Touchpad & Serial IO Stack ]
[OK]   SerialIO-I2C                   : Intel(R) Serial IO I2C Host Controller - 51E8 [OK]
[OK]   SerialIO-GPIO                  : Intel(R) Serial IO GPIO Host Controller - INTC1055 [OK]
[OK]   I2C-HID                        : I2C HID Device [OK]
[OK]   Touchpad                       : HID-compliant touch pad [OK]
[OK]   Microsoft-Input-Configuration  : Microsoft Input Configuration Device [OK]

[ ELAN Touchpad Hardware Status ]
[INFO] Instance: ACPI\ELAN0412\0
       Name    : PS/2 Compatible Mouse [OK]
[INFO] Instance: ACPI\ELAN0412\4&81F98AE&0
       Name    : I2C HID Device [OK]

[ Core Hardware Subsystems ]
[OK]   Intel Graphics       : Intel(R) UHD Graphics
[OK]   NVIDIA Graphics      : NVIDIA GeForce RTX 4050 Laptop GPU
[OK]   Audio                : Realtek(R) Audio
[OK]   WiFi                 : Microsoft Wi-Fi Direct Virtual Adapter
[OK]   LAN                  : Realtek PCIe GbE Family Controller
[OK]   Bluetooth            : Intel(R) Wireless Bluetooth(R)

[ Assessment ]
STATUS: Precision Touchpad aktif dan siap digunakan.
```

---

### 4. Post-Installation Verification

Untuk memverifikasi integritas stack Precision Touchpad:

```powershell
.\verify.ps1
```

Contoh keluaran yang diharapkan:

```text
[OK]   Intel Serial IO I2C
[OK]   Intel Serial IO GPIO
[OK]   I2C HID Device
[OK]   HID-compliant touch pad
[OK]   Microsoft Input Configuration Device

Touchpad verification PASSED.
```

---

### 5. Menjalankan Scraper API

Untuk memperbarui metadata `generated/drivers.json` dan `generated/version.json` langsung dari API Axioo:

**Menggunakan PowerShell (Natif Windows):**
```powershell
.\scripts\scrape-axioo.ps1
```

**Menggunakan Node.js (Lintas Platform / CI):**
```bash
node scripts/scrape-axioo.mjs
```

---

## 📁 Struktur Repository Final

```text
AxiooPongo-750-Drivers/
│
├── .github/
│   └── workflows/
│       └── scrape-drivers.yml      # CI/CD scraper schedule & auto-commit
│
├── config/
│   └── special-drivers.json        # Konfigurasi driver eksternal (Intel Serial IO)
│
├── generated/
│   ├── drivers.json                # Metadata resmi hasil scraping API Axioo
│   └── version.json                # Lookup versi terkompilasi
│
├── scripts/
│   ├── scrape-axioo.ps1            # Scraper API resmi versi PowerShell
│   └── scrape-axioo.mjs            # Scraper API resmi versi Node.js ESM
│
├── install.ps1                     # Master installer driver
├── install-touchpad.ps1            # Script perbaikan Precision Touchpad
├── detect.ps1                      # Skrip deteksi perangkat & status driver
├── verify.ps1                      # Skrip verifikasi pasca-instalasi
│
├── README.md                       # Dokumentasi resmi
└── LICENSE                         # Lisensi repository
```

---

## 📜 Lisensi & Atribusi

- File script otomasi dalam repository ini dilisensikan di bawah lisensi open source.
- Driver dan perangkat lunak yang diunduh merupakan hak cipta dan merek dagang milik masing-masing vendor (Axioo, Intel, NVIDIA, Realtek, BayHub, Microsoft).
