# Waroeng Tools

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg?style=flat-square&logo=powershell)](https://microsoft.com/powershell)
[![OS Support](https://img.shields.io/badge/Windows-10%20%2F%2011-0078d4.svg?style=flat-square&logo=windows)](https://microsoft.com/windows)
[![Release Version](https://img.shields.io/badge/Version-6.7-emerald.svg?style=flat-square)](#)
[![Developer](https://img.shields.io/badge/Creator-Alice%20Analysis-orange.svg?style=flat-square)](https://github.com)

**Waroeng Tools** adalah aplikasi utilitas berbasis GUI (Graphical User Interface) premium, ringan, dan sangat bertenaga yang dibangun menggunakan **Native PowerShell**. Alat ini dirancang khusus untuk mengoptimalkan performa sistem operasi Windows, menghapus aplikasi bawaan (*bloatware*) yang menguras memori, serta memulihkan privasi penuh pengguna dengan mematikan telemetri pelacak bawaan Microsoft secara aman dan bersih.

# Cara Menjalankan & Mengakses Aplikasi

Karena aplikasi ini memerlukan modifikasi pada level registri sistem dan file hosts, Anda **wajib menjalankannya dengan Hak Akses Administrator**. 

Pilih salah satu dari **4 metode akses** di bawah ini yang paling sesuai dengan kondisi sistem Anda:

### Kategori A: Eksekusi Online (Tanpa Unduh Manual)
Buka **PowerShell (Admin)** atau **Terminal (Admin)**, lalu pilih salah satu perintah berikut:

* **Metode 1: Perintah Instan Utama (Rekomendasi)**
    ```powershell
    irm waroengtools.my.id | iex
    ```
    *(Mengunduh skrip terbaru secara otomatis langsung ke dalam memori RAM sementara dan langsung memunculkan GUI).*

* **Metode 2: Solusi Anti-Blokir / DNS Terganggu (DoH Curl)**
    Jika koneksi provider internet Anda mengganggu pemanggilan domain, gunakan perintah berbasis *DNS-over-HTTPS Cloudflare* ini:
    ```powershell
    iex (curl.exe -s --doh-url https://1.1.1.1/dns-query waroengtools.my.id | Out-String)
    ```

---

### Kategori B: Eksekusi Offline / Manual

* **Metode 3: Unduh Berkas Skrip Secara Manual**
    1. Unduh berkas skrip `WaroengTweak.ps1` dari repositori ini ke penyimpanan lokal Anda.
    2. Klik kanan pada tombol **Start Windows**, lalu pilih **PowerShell (Admin)** atau **Terminal (Admin)**.
    3. Izinkan eksekusi skrip lokal pada sistem Windows Anda dengan mengetikkan perintah berikut:
       ```powershell
       Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
       ```
    4. Jalankan skrip tersebut:
       ```powershell
       Launcher_Offline.ps1
---

## ⚠️ Pemberitahuan Hak Cipta (Copyright Notice)

> **Mohon Perhatian:**
> 
> * **English:** Please do not change this script to make it your own without giving me credit in the script.
> * **Bahasa Indonesia:** Tolong jangan ubah skrip ini untuk menjadikannya seolah-olah milik Anda sendiri tanpa mencantumkan kredit/sumber asli kepada saya di dalam skrip. Hargailah waktu dan kerja keras yang dituangkan dalam pembuatan alat ini.
