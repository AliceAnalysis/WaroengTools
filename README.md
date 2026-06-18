# Waroeng Tools

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg?style=flat-square&logo=powershell)](https://microsoft.com/powershell)
[![OS Support](https://img.shields.io/badge/Windows-10%20%2F%2011-0078d4.svg?style=flat-square&logo=windows)](https://microsoft.com/windows)
[![Release Version](https://img.shields.io/badge/Version-6.7-emerald.svg?style=flat-square)](#)
[![Developer](https://img.shields.io/badge/Creator-Alice%20Analysis-orange.svg?style=flat-square)](https://github.com)

**Waroeng Tools** adalah aplikasi utilitas berbasis GUI (Graphical User Interface) premium, ringan, dan sangat bertenaga yang dibangun menggunakan **Native PowerShell**. Alat ini dirancang khusus untuk mengoptimalkan performa sistem operasi Windows, menghapus aplikasi bawaan (*bloatware*) yang menguras memori, serta memulihkan privasi penuh pengguna dengan mematikan telemetri pelacak bawaan Microsoft secara aman dan bersih.

---

## Cara Menjalankan & Mengakses Aplikasi

Karena aplikasi ini memerlukan modifikasi pada level registri sistem dan file hosts, Anda **wajib menjalankannya dengan Hak Akses Administrator**. 

Pilih salah satu dari **2 kategori akses** di bawah ini yang paling sesuai dengan kondisi sistem Anda:

### Kategori A: Eksekusi Instan Online (Menggunakan Perintah)
Buka **PowerShell (Admin)** atau **Terminal (Admin)**, lalu pilih salah satu perintah berikut:

* **Metode 1: One Command**
    ```powershell
    irm waroengtools.my.id | iex
    ```
    *(Mengunduh skrip terbaru secara otomatis langsung ke dalam memori RAM sementara dan langsung memunculkan GUI).*

* **Metode 2: Solusi DNS (DoH Curl)**
    Jika koneksi provider internet Anda mengganggu pemanggilan domain, gunakan perintah berbasis *DNS-over-HTTPS Cloudflare* ini:
    ```powershell
    iex (curl.exe -s --doh-url https://1.1.1.1/dns-query waroengtools.my.id | Out-String)
    ```

---

### Kategori B: Launcher Lokal

* **Metode 3: Menggunakan Launcher_Offline.ps1**
    Jika Anda ingin menggunakan aplikasi tanpa perlu selalu mengetik perintah di atas, atau ingin membukanya dalam keadaan **tanpa koneksi internet (Offline)**, gunakan skrip Launcher resmi:
    
    1. Unduh berkas **`Launcher_Offline.ps1`** dari repositori ini ke folder lokal komputer Anda (misal: *Desktop* atau *Documents*).
    2. Klik kanan pada file `Launcher_Offline.ps1` lalu pilih **Run with PowerShell**, **ATAU** jalankan lewat **PowerShell (Admin)** dengan perintah berikut:
       ```powershell
       Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
       .\Launcher_Offline.ps1
       ```
    3. **Navigasi Menu Launcher:**
       * **Pilih Menu [2] (Update / Download)** saat pertama kali menggunakan launcher untuk mengunduh modul sistem inti Waroeng Tools secara permanen ke komputer Anda.
       * **Pilih Menu [1] (Buka Aplikasi)** untuk langsung membuka dashboard utama kapan saja secara instan, bahkan saat PC Anda sedang **Offline**.

---

## Fitur Utama Aplikasi

Waroeng Tools hadir dengan dashboard navigasi modern berisikan perkakas esensial yang dibagi ke dalam beberapa kategori utama:

### 1. Privacy & Anti-Telemetry Guard
* **Disable OS Data Collection:** Menghentikan pengumpulan data latar belakang (telemetri), pelacakan ketikan (*typing feedback*), serta fitur *Activity Feed* Windows yang diam-diam memonitor aktivitas Anda.
* **Block Tracking Hosts:** Memfilter file `hosts` sistem dari ratusan domain pelacak pihak ketiga (Dropbox, MS Telemetry, dll.) menggunakan algoritma pencarian string kilat.
* **Cloud Clipboard Sync Controller:** Memutus sinkronisasi otomatis riwayat salinan teks (*clipboard*) ke server luar untuk menjaga keamanan data sensitif/password Anda, sembari mempertahankan riwayat lokal (`Win + V`).

### 2. Optimization & Bloatware Remover
* **Smart UWP App Uninstaller:** Menghapus bersih aplikasi bawaan Windows yang tidak berguna (seperti Candy Crush, Spotify, Xbox Game Overlay, Maps, Zune, dll.) untuk menghemat RAM dan storage.
* **Auto Bypass Deprovisioned Store:** Mengunci registri sistem agar aplikasi *bloatware* yang sudah dihapus tidak dipaksa terinstal kembali secara otomatis saat Windows melakukan update.
* **Soft-Deleted System Folder Recovery:** Memulihkan folder aplikasi inti yang terkunci pada direktori `SystemApps` dengan mengambil alih izin keamanan dari *TrustedInstaller*.

### 3. Modern UI/UX Dashboard
* **Elegant Dark Mode UI:** Antarmuka visual Windows Forms premium yang nyaman di mata dengan penataan grid dan tata letak koordinat tombol yang sangat presisi.
* **Real-time Engine Logging:** Pemantauan proses eksekusi langsung lewat terminal log di dalam aplikasi, dilengkapi tombol **Export Log** (Ikon Disket) real-time dengan efek *hover LimeGreen*.
* **Real-time Clock & Divider Transparan:** Menampilkan jam digital aktif di baris menu atas yang dipisahkan oleh separator elegan.

### 4. Integrated Professional Toolkit
* **Windows & Office Activation:** Integrasi pemanggilan aman dengan modul aktivasi sistem terpercaya tanpa merusak integritas file enkripsi Windows.
* **Office Scrubber Suite:** Pembersihan total berkas-berkas sampah sisa instalasi Microsoft Office lama agar instalasi Office baru berjalan lancar tanpa korup data.

---

## ⚠️ Pemberitahuan Hak Cipta (Copyright Notice)

> **Mohon Perhatian:**
> 
> * **English:** Please do not change this script to make it your own without giving me credit in the script.
> * **Bahasa Indonesia:** Tolong jangan ubah skrip ini untuk menjadikannya seolah-olah milik Anda sendiri tanpa mencantumkan kredit/sumber asli kepada saya di dalam skrip. Hargailah waktu dan kerja keras yang dituangkan dalam pembuatan alat ini.
