Berikut adalah **`README.md`** yang sudah saya rombak total agar **sangat ramah untuk user awam**. Saya menambahkan:

1. **Quick Start (3 Langkah)** di paling atas agar user bisa langsung praktik tanpa baca panjang-panjang.
2. **Panduan Step-by-Step dengan detail** (cara buka PowerShell sebagai Admin, cara copy-paste, dll).
3. **Bagian "Pilih Script Mana?"** untuk membantu user memutuskan.
4. **FAQ & Troubleshooting** untuk masalah umum (Execution Policy, DNS, script tidak jalan).
5. **Bahasa yang disederhanakan** tanpa menghilangkan info teknis untuk advanced users.

Salin seluruh teks di dalam kotak di bawah ini:

```markdown
# AxiooPongo-750-Drivers

> 🛠️ **Installer Driver Otomatis untuk Axioo Pongo 750 (NP50RNC1) — Windows 11 64-bit**
>
> Script ini akan **mengunduh, menginstal, dan memverifikasi** semua driver resmi Axioo secara otomatis. Cocok untuk install ulang Windows, perbaikan touchpad, atau update driver massal.

---

## ⚡ Quick Start (Untuk User Awam — 3 Langkah)

> [!IMPORTANT]
> **Wajib:** Gunakan koneksi internet yang stabil. Total unduhan ~2.5 GB.
> Jika WiFi rumah bermasalah, **tethering ke Hotspot HP** sangat disarankan.

### Langkah 1 — Buka PowerShell sebagai Administrator
1. Tekan tombol **Windows** di keyboard.
2. Ketik: `PowerShell`
3. Klik kanan pada **Windows PowerShell** → pilih **Run as administrator**.
4. Klik **Yes** jika muncul peringatan UAC.

### Langkah 2 — Copy-Paste Perintah Ini
Salin perintah di bawah ini, lalu **klik kanan** di jendela PowerShell untuk paste, dan tekan **Enter**:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install.ps1 | iex
```

> [!TIP]
> Perintah di atas sudah **otomatis mengizinkan eksekusi script** (bypass Execution Policy) **hanya untuk sesi ini saja**, jadi aman dan tidak mengubah pengaturan Windows secara permanen.

### Langkah 3 — Pilih Mode Instalasi
Setelah muncul menu, ketik angka lalu tekan **Enter**:

| Ketik | Untuk |
|:---:|---|
| **`3`** | 🏆 **Instal SEMUA driver** (paling lengkap, disarankan setelah install ulang Windows) |
| **`1`** | 🔧 **Perbaiki Touchpad** saja (jika touchpad tidak bisa gesture multi-jari) |
| **`2`** | ⚙️ **Driver pokok** (Chipset, Audio, LAN, WiFi, Bluetooth, Touchpad) |
| **`4`** | 🔍 **Cek kondisi hardware** (diagnosis tanpa menginstal apa pun) |
| **`5`** | ✅ **Verifikasi Touchpad** (cek apakah stack touchpad sudah benar) |
| **`Q`** | ❌ Keluar |

**Selesai!** Tunggu sampai muncul tulisan `Seluruh proses instalasi selesai!` lalu **restart laptop**.

---

## 🤔 Bingung Pilih Script yang Mana?

| Kondisi Laptop Anda | Script yang Harus Dijalankan |
|---|---|
| Baru install ulang Windows, belum ada driver sama sekali | **`install.ps1`** → pilih opsi **`3`** |
| Laptop normal, cuma touchpad tidak bisa gesture 2/3/4 jari | **`install-touchpad.ps1`** |
| Ingin tahu driver apa saja yang sudah/belum terpasang | **`detect.ps1`** |
| Ingin memastikan touchpad sudah terinstal dengan benar | **`verify.ps1`** |
| Driver bermasalah setelah update Windows | **`install.ps1`** → pilih opsi **`3`** |

---

## 🚀 Panduan Lengkap per Script

### 1️⃣ Master Installer (`install.ps1`) — Instal Semua Driver

**Via Online (tanpa download repo):**
```powershell
irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install.ps1 | iex
```

**Via Lokal (jika sudah clone/download repo):**
```powershell
.\install.ps1
```

**Mode Batch (tanpa menu interaktif):**
```powershell
# Instal semua driver
.\install.ps1 -All

# Hanya perbaiki touchpad
.\install.ps1 -TouchpadOnly

# Hanya driver kategori tertentu
.\install.ps1 -Categories "VGA", "AUDIO"

# Hanya driver tertentu berdasarkan ID
.\install.ps1 -Drivers "vga-intel", "audio-realtek"

# Skip driver special (Intel Serial IO)
.\install.ps1 -All -SkipSpecial

# Hapus cache unduhan (paksa download ulang dari nol)
.\install.ps1 -ClearCache
```

> [!NOTE]
> **Smart Cache:** File driver yang sudah berhasil diunduh akan disimpan di `%LOCALAPPDATA%\AxiooPongoCache`. Jika instalasi terputus di tengah jalan, jalankan ulang script dan driver yang sudah terunduh **tidak akan di-download ulang**. Hemat kuota & waktu!

---

### 2️⃣ Touchpad Repair (`install-touchpad.ps1`)

Gunakan jika touchpad berfungsi sebagai pointer tapi **gesture multi-jari (scroll 2 jari, swipe 3 jari, dll) tidak muncul** di Settings.

**Via Online:**
```powershell
irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install-touchpad.ps1 | iex
```

**Via Lokal:**
```powershell
.\install-touchpad.ps1
```

Setelah selesai:
1. **Restart Windows** (wajib!)
2. Buka **Settings** → **Bluetooth & devices** → **Touchpad**
3. Pastikan muncul opsi gesture multi-touch.

---

### 3️⃣ Hardware Detection (`detect.ps1`)

Untuk **mendiagnosis** kondisi hardware dan driver tanpa menginstal apa pun:

```powershell
.\detect.ps1
```

Contoh keluaran jika semua sehat:
```text
=========================================
 Axioo Pongo 750 Device Detection
=========================================

[ Touchpad & Serial IO Stack ]
[OK]   SerialIO-I2C                 : Intel(R) Serial IO I2C Host Controller - 51E8 [OK]
[OK]   SerialIO-GPIO                : Intel(R) Serial IO GPIO Host Controller - INTC1055 [OK]
[OK]   I2C-HID                      : I2C HID Device [OK]
[OK]   Touchpad                     : HID-compliant touch pad [OK]
[OK]   Microsoft-Input-Config       : Microsoft Input Configuration Device [OK]

[ Core Hardware Subsystems ]
[OK]   Intel Graphics     : Intel(R) UHD Graphics
[OK]   NVIDIA Graphics    : NVIDIA GeForce RTX 4050 Laptop GPU
[OK]   Audio              : Realtek(R) Audio
[OK]   WiFi               : Intel(R) Wi-Fi 6E AX211 160MHz Wireless Network Adapter
[OK]   LAN                : Realtek PCIe GbE Family Controller
[OK]   Bluetooth          : Intel(R) Wireless Bluetooth(R)

[ Assessment ]
STATUS: Precision Touchpad aktif dan siap digunakan.
```

Arti status:
| Status | Arti |
|:---:|---|
| `[OK]` | ✅ Driver terpasang & perangkat berfungsi normal |
| `[WARN]` | ⚠️ Driver terpasang tapi status perangkat tidak OK |
| `[FAIL]` | ❌ Perangkat tidak terdeteksi / driver belum terpasang |
| `[INFO]` | ℹ️ Informasi tambahan (bukan error) |

---

### 4️⃣ Post-Installation Verification (`verify.ps1`)

Untuk **memverifikasi** apakah stack Precision Touchpad sudah terinstal dengan benar:

```powershell
.\verify.ps1
```

Contoh keluaran jika sukses:
```text
=========================================
 Axioo Pongo 750 Post-Installation Verify
=========================================

[OK]   Intel Serial IO I2C
[OK]   Intel Serial IO GPIO
[OK]   I2C HID Device
[OK]   HID-compliant touch pad
[OK]   Microsoft Input Configuration Device

========================================================
 Touchpad verification PASSED.
========================================================
```

Jika ada yang `[FAIL]`, script akan menampilkan komponen mana yang bermasalah dan saran tindakannya.

---

## 🛠️ Troubleshooting (Masalah Umum)

### ❌ Error: `running scripts is disabled on this system`

**Penyebab:** Windows memblokir eksekusi file `.ps1` secara default.

**Solusi:** Jalankan perintah ini **sebelum** menjalankan script:
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
```
Lalu jalankan ulang scriptnya.

> [!TIP]
> Atau gunakan **satu baris gabungan** agar tidak perlu dua kali ketik:
> ```powershell
> Set-ExecutionPolicy Bypass -Scope Process -Force; irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install.ps1 | iex
> ```

---

### ❌ Error: `The remote name could not be resolved`

**Penyebab:** DNS ISP (IndiHome, Biznet, FirstMedia, dll) gagal menerjemahkan nama domain server.

**Solusi (pilih salah satu):**

**A. Tethering ke Hotspot HP (paling cepat & ampuh):**
1. Matikan WiFi laptop.
2. Nyalakan Hotspot di HP Anda.
3. Sambungkan laptop ke Hotspot HP.
4. Jalankan ulang script.

**B. Ganti DNS ke Google/Cloudflare:**
1. Buka PowerShell (Admin).
2. Ketik perintah ini:
   ```powershell
   Get-NetAdapter | Where-Object Status -eq "Up" | Set-DnsClientServerAddress -ServerAddresses ("8.8.8.8", "1.1.1.1")
   ipconfig /flushdns
   ```
3. Jalankan ulang script.

**C. Flush DNS & Reset Network:**
```powershell
ipconfig /flushdns
ipconfig /registerdns
netsh winsock reset
netsh int ip reset
```
Lalu **restart laptop** dan coba lagi.

> [!IMPORTANT]
> Jika instalasi terputus karena error ini, **jangan khawatir!** Script sudah dilengkapi **Smart Cache**. Driver yang sudah berhasil diunduh sebelumnya **tidak akan di-download ulang**. Cukup perbaiki koneksi lalu jalankan ulang.

---

### ❌ Error: `Cannot bind argument to parameter 'Path' because it is null`

**Penyebab:** Menjalankan script versi lama via `irm | iex` (pipe).

**Solusi:** Script versi terbaru sudah otomatis menangani ini. Pastikan Anda menggunakan script terbaru dari repository ini. Jika masih terjadi, download script dulu lalu jalankan lokal:
```powershell
irm https://raw.githubusercontent.com/RusdiEneri/AxiooPongo-750-Drivers/main/install.ps1 -OutFile "$env:TEMP\install.ps1"
& "$env:TEMP\install.ps1"
```

---

### ❌ Touchpad masih belum bisa gesture setelah instalasi

1. **Restart Windows** (wajib, jangan cuma sleep/hibernate).
2. Jalankan `verify.ps1` untuk cek apakah semua komponen sudah OK.
3. Jika ada yang `[FAIL]`, jalankan `install-touchpad.ps1`.
4. Restart lagi.
5. Buka **Settings** → **Bluetooth & devices** → **Touchpad**.

> [!NOTE]
> Jika di Device Manager muncul `PS/2 Compatible Mouse` **bersamaan** dengan `HID-compliant touch pad`, itu **NORMAL** di Windows 11 setelah Intel Serial IO terpasang. Bukan error.

---

### ❌ Script berjalan sangat lambat / timeout saat download

**Penyebab:** Koneksi internet lambat atau server sedang ramai.

**Solusi:**
- Script otomatis mencoba ulang **3 kali** dengan jeda 5 detik.
- Jika tetap gagal, script akan **melewati** driver tersebut dan lanjut ke driver berikutnya (tidak berhenti total).
- Coba jalankan di jam yang berbeda (tengah malam biasanya lebih cepat).
- Gunakan koneksi kabel LAN jika memungkinkan.

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

## 📦 Daftar Driver yang Diinstal

### Driver Resmi Axioo (14 Paket)

| Kategori | Nama Driver | Versi | Ukuran ± |
|---|---|---:|---:|
| **VGA** | Intel Graphic | `32.0.101.5768` | 886 MB |
| **VGA** | NVIDIA Graphic | `55.99` | 628 MB |
| **AUDIO** | Realtek Audio | `6.0.9697.1` | 293 MB |
| **OTHERS** | Control Center 3.0 | `6.093` | 199 MB |
| **WIFI** | Intel WiFi | `23.60.1.2` | 81 MB |
| **BLUETOOTH** | Intel Bluetooth | `23.60.0.1` | ~40 MB |
| **LAN** | Realtek LAN | `10.072.0524.2024` | ~15 MB |
| **CHIPSET** | Intel Management Engine | `2425.6.26.0` | ~50 MB |
| **CHIPSET** | Intel Chipset | `10.1.19899.8597` | ~30 MB |
| **CARD READER** | BayHub Card Reader | `2.1.101.10700` | ~10 MB |
| **HID FILTER** | HID Event Filter | `2.2.2.10` | ~5 MB |
| **OTHERS** | DTT | `9.0.11701.44281` | ~20 MB |
| **OTHERS** | Speed Shift | `1003.20240522` | ~5 MB |
| **OTHERS** | GNA | `03.05.00.1578` | ~10 MB |

### Driver Special — Touchpad Precision Stack

| Komponen | Versi | Sumber |
|---|---:|---|
| **Intel Serial IO I2C Host Controller** | `30.100.2531.31` | Microsoft Update Catalog |
| **Intel Serial IO GPIO Host Controller** | `30.100.2531.31` | Microsoft Update Catalog |

**Rantai dependensi Touchpad:**
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
Windows Precision Touchpad / Multi-Touch Gestures ✅
```

---

## 🏗️ Fitur & Arsitektur (Untuk Advanced Users)

1. **Official Axioo API as Source of Truth**:
   Metadata driver diambil dari API resmi Axioo, bukan daftar statis manual.
2. **Special Driver Integration (Intel Serial IO)**:
   Driver Intel Serial IO dari Microsoft Update Catalog untuk memperbaiki rantai deteksi I2C HID.
3. **Robust Master Installer (`install.ps1`)**:
   - Smart Local Cache di `%LOCALAPPDATA%\AxiooPongoCache`.
   - Auto-retry (3x) dengan timeout 120 detik per unduhan.
   - Graceful skip: jika 1 driver gagal, script lanjut ke driver berikutnya.
   - Self-recovery untuk eksekusi via `irm | iex`.
4. **Dedicated Touchpad Repair (`install-touchpad.ps1`)**:
   Instalasi terisolasi Intel Serial IO GPIO & I2C dengan auto-retry.
5. **Hardware Detection & Verification (`detect.ps1` & `verify.ps1`)**:
   Diagnosis & verifikasi dengan exit code untuk scripting/CI.
6. **Scheduled CI/CD (`.github/workflows/scrape-drivers.yml`)**:
   Auto-update metadata driver secara berkala.

---

## 📂 Struktur Repository

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
│   ├── scrape-axioo.ps1            # Scraper API versi PowerShell
│   └── scrape-axioo.mjs            # Scraper API versi Node.js ESM
│
├── install.ps1                     # 🚀 Master installer (Smart Cache + Auto-Retry)
├── install-touchpad.ps1            # 🔧 Perbaikan Precision Touchpad
├── detect.ps1                      # 🔍 Deteksi hardware & status driver
├── verify.ps1                      # ✅ Verifikasi pasca-instalasi
│
├── README.md                       # Dokumentasi ini
└── LICENSE                         # Lisensi repository
```

---

## 🔬 Menjalankan Scraper API (Untuk Developer)

Untuk memperbarui metadata `generated/drivers.json` dari API Axioo:

**PowerShell (Windows):**
```powershell
.\scripts\scrape-axioo.ps1
```

**Node.js (Lintas Platform / CI):**
```bash
node scripts/scrape-axioo.mjs
```

---

## 📜 Lisensi & Atribusi

- Script otomasi dalam repository ini dilisensikan di bawah lisensi open source.
- Driver dan perangkat lunak yang diunduh merupakan hak cipta dan merek dagang milik masing-masing vendor (Axioo, Intel, NVIDIA, Realtek, BayHub, Microsoft).

---

## ❓ FAQ

**Q: Apakah aman menjalankan script ini?**
A: Ya. Script hanya mengunduh driver dari **server resmi Axioo** (`driver.axiooworld.com`) dan **Microsoft Update Catalog** (`catalog.s.download.windowsupdate.com`). Tidak ada pihak ketiga.

**Q: Apakah perlu install ulang Windows dulu?**
A: Tidak harus. Script bisa dijalankan kapan saja untuk update/perbaikan driver.

**Q: Berapa lama proses instalasi?**
A: Tergantung kecepatan internet. Unduhan ~2.5 GB. Dengan koneksi 50 Mbps, sekitar 10-15 menit. Proses instalasi driver sendiri sekitar 5-10 menit.

**Q: Apakah harus restart setelah instalasi?**
A: **Ya, sangat disarankan.** Beberapa driver (terutama Intel Serial IO & NVIDIA) membutuhkan restart untuk inisialisasi penuh.

**Q: Saya pakai Axioo Pongo 735, bisa pakai script ini?**
A: **Tidak.** Script ini khusus untuk **Pongo 750 (NP50RNC1)**. Hardware ID dan driver berbeda. Menggunakan script ini pada model lain bisa menyebabkan konflik driver.

**Q: Cache unduhan tersimpan di mana? Bagaimana cara menghapusnya?**
A: Di `%LOCALAPPDATA%\AxiooPongoCache`. Hapus manual via Explorer, atau jalankan:
```powershell
.\install.ps1 -ClearCache
```