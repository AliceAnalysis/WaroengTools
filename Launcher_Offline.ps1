<#
=========================================================================
 WAROENG TWEAK - OFFLINE LAUNCHER
=========================================================================
 Deskripsi: Launcher lokal untuk mengunduh, mengupdate, dan menjalankan 
 Waroeng Tools. File akan disimpan secara permanen agar bisa dibuka 
 saat tidak ada koneksi internet.
=========================================================================
#>

# ---------------------------------------------------------------------
# 1. PERSIAPAN DIREKTORI PENYIMPANAN LOKAL (OFFLINE FOLDER)
# ---------------------------------------------------------------------
$InstallDir = "$env:LOCALAPPDATA\WaroengTools"
$FilePath = "$InstallDir\WaroengTweak.ps1"
$URL = 'https://raw.githubusercontent.com/AliceAnalysis/WaroengTools/refs/heads/main/WaroengTweak.ps1'

# Buat folder jika belum ada
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ---------------------------------------------------------------------
# FUNGSI 1: MENGUNDUH / UPDATE APLIKASI DARI GITHUB (BUTUH INTERNET)
# ---------------------------------------------------------------------
function Update-WaroengTools {
    Clear-Host
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host " -> MENGUNDUH WAROENG TOOLS DARI SERVER..." -ForegroundColor Yellow
    Write-Host "=================================================" -ForegroundColor Yellow
    Write-Host ""

    # Paksa protokol TLS 1.2 untuk keamanan koneksi
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    try {
        $psv = (Get-Host).Version.Major
        if ($psv -ge 3) {
            $response = Invoke-RestMethod -Uri $URL -UseBasicParsing
        } else {
            $w = New-Object Net.WebClient
            $response = $w.DownloadString($URL)
        }

        # Simpan file secara permanen ke AppData Lokal
        Set-Content -Path $FilePath -Value $response -Encoding UTF8 -Force
        
        Write-Host "[+] BERHASIL!" -ForegroundColor Green
        Write-Host "    Aplikasi versi terbaru telah berhasil diunduh dan dipasang." -ForegroundColor Green
        Write-Host "    Lokasi File: $FilePath" -ForegroundColor Gray
    } catch {
        Write-Host "[-] GAGAL MENGUNDUH UPDATE!" -ForegroundColor Red
        Write-Host "    Pastikan koneksi internet Anda stabil dan tidak diblokir Antivirus." -ForegroundColor Yellow
        Write-Host "    Detail Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    }

    Write-Host "`nTekan ENTER untuk kembali ke Menu Utama..." -ForegroundColor Cyan
    [void](Read-Host)
}

# ---------------------------------------------------------------------
# FUNGSI 2: MEMBUKA APLIKASI (BISA OFFLINE)
# ---------------------------------------------------------------------
function Launch-WaroengTools {
    Clear-Host
    
    # Cek apakah file sudah pernah didownload
    if (-not (Test-Path $FilePath)) {
        Write-Host "=================================================" -ForegroundColor Red
        Write-Host " [!] APLIKASI BELUM TERINSTAL / TIDAK DITEMUKAN" -ForegroundColor Red
        Write-Host "=================================================" -ForegroundColor Red
        Write-Host "`nSilakan pilih menu Nomor 2 (Update / Download Aplikasi) terlebih dahulu." -ForegroundColor Yellow
        Write-Host "`nTekan ENTER untuk kembali ke Menu Utama..." -ForegroundColor Cyan
        [void](Read-Host)
        return
    }

    # Menampilkan Peringatan GUI
    Add-Type -AssemblyName System.Windows.Forms
    $warningMsg = "PERHATIAN!`n`nAplikasi ini berisi script Tweak tingkat lanjut (termasuk mematikan Telemetry & Defender).`n`nSilakan matikan sementara 'Real-time Protection' dan 'Tamper Protection' di Windows Security SEKARANG.`n`nJika sudah dimatikan, klik OK untuk membuka aplikasi.`n(Jika setelah klik OK aplikasi tidak terbuka, berarti Defender masih menyala dan memblokirnya)."
    $result = [System.Windows.Forms.MessageBox]::Show($warningMsg, "Waroeng Tweak - Info Penting", 1, 48)

    if ($result -ne "OK") {
        Write-Host "[-] Eksekusi dibatalkan oleh pengguna." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }

    Write-Host "[*] Membuka Waroeng Tools... Silakan tunggu." -ForegroundColor Cyan

    # --- UNLOCK: Mengubah Kebijakan Eksekusi agar Skrip Bisa Berjalan ---
    try { Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force } catch {}

    # Eksekusi Script sebagai Administrator
    try {
        $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$FilePath`"" -Verb RunAs -PassThru
        
        # Menunggu sampai GUI aplikasi Waroeng ditutup oleh pengguna
        $p.WaitForExit()
    } catch {
        Write-Host "[-] Gagal menjalankan aplikasi. Pastikan Anda memberikan akses Administrator (UAC)." -ForegroundColor Red
        Start-Sleep -Seconds 3
    }

    # --- LOCK: Mengembalikan Kebijakan Eksekusi ke Restricted ---
    try { Set-ExecutionPolicy Restricted -Scope CurrentUser -Force } catch {}
}


# ---------------------------------------------------------------------
# MENU UTAMA (LOOP)
# ---------------------------------------------------------------------
while ($true) {
    Clear-Host
    # Modifikasi judul window terminal
    $Host.UI.RawUI.WindowTitle = "Waroeng Tools - Offline Launcher"

    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host "         WAROENG TOOLS - OFFLINE LAUNCHER        " -ForegroundColor White
    Write-Host "=================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] Buka Aplikasi Waroeng Tools (Bisa Offline)" -ForegroundColor Green
    Write-Host "  [2] Update / Download Aplikasi dari Server" -ForegroundColor Yellow
    Write-Host "  [3] Keluar" -ForegroundColor Red
    Write-Host ""
    Write-Host "=================================================" -ForegroundColor Cyan

    $choice = Read-Host "Masukkan pilihan Anda (1/2/3)"

    switch ($choice) {
        '1' { Launch-WaroengTools }
        '2' { Update-WaroengTools }
        '3' { exit }
        default { 
            Write-Host "[-] Pilihan tidak valid! Silakan masukkan angka 1, 2, atau 3." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
