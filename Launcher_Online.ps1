<?php
header("Content-Type: text/plain");
?>
# =========================================================================
# WAROENG TWEAK - WEB LAUNCHER (AUTOMATED EXECUTION POLICY)
# =========================================================================
# Script ini dirancang untuk dijalankan langsung via web / shortcut URL.
# Alur kerja otomatis: Unlock -> Verifikasi Keamanan -> Eksekusi -> Re-lock.
# =========================================================================

& {
    # ---------------------------------------------------------------------
    # # 1. UNLOCK ENVIRONMENT (MENGUBAH KEBIJAKAN EKSEKUSI)
    # Penjelasan: Mengizinkan PowerShell menjalankan script lokal sementara waktu
    # agar proses instalasi tidak dicegah oleh sistem Windows.
    # ---------------------------------------------------------------------
    try {
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    } catch {}

    # Inisialisasi Deteksi Versi PowerShell Utama
    $psv = (Get-Host).Version.Major
    $URL = 'https://raw.githubusercontent.com/AliceAnalysis/WaroengTools/refs/heads/main/WaroengTweak.ps1'


    # ---------------------------------------------------------------------
    # # 2. VALIDASI PRASYARAT (.NET FRAMEWORK)
    # Penjelasan: Memastikan library .NET Framework termuat dengan benar di memori. 
    # Jika gagal, script tidak bisa memproses operasi tingkat lanjut (seperti enkripsi hash).
    # ---------------------------------------------------------------------
    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies()
        [void][System.Math]::Sqrt(144)
    } catch {
        Write-Host "[!] Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Powershell gagal memuat perintah inti .NET. Proses dihentikan." -ForegroundColor Yellow
        return
    }


    # ---------------------------------------------------------------------
    # # 3. DEKLARASI FUNGSI DETEKSI ANTIVIRUS PIHAK KETIGA
    # Penjelasan: Fungsi bantuan untuk memindai apakah ada AV selain Windows Defender
    # (seperti Avast, Kaspersky, Smadav, dll.) yang berpotensi memblokir proses script.
    # ---------------------------------------------------------------------
    function Check3rdAV {
        $cmd = if ($psv -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
        $avList = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue | 
                  Where-Object { $_.displayName -notlike '*windows*' } | Select-Object -ExpandProperty displayName

        if ($avList) {
            Write-Host '-------------------------------------------------' -ForegroundColor Custom
            Write-Host ' Antivirus pihak ketiga terdeteksi aktif: ' -ForegroundColor White -BackgroundColor Blue -NoNewline
            Write-Host " $($avList -join ', ')" -ForegroundColor DarkRed -BackgroundColor White
            Write-Host ' Antivirus ini mungkin akan memblokir aktivitas script.' -ForegroundColor Yellow
            Write-Host '-------------------------------------------------' -ForegroundColor Custom
        }
    }


    # ---------------------------------------------------------------------
    # # 4. CONFIG NETWORK & PROTOKOL KEAMANAN (TLS 1.2)
    # Penjelasan: Memaksa koneksi menggunakan enkripsi TLS 1.2. 
    # Tanpa baris ini, Windows lama (Windows 7/8/10 versi lawas) akan ditolak oleh server GitHub.
    # ---------------------------------------------------------------------
    try { 
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    } catch {}


    # ---------------------------------------------------------------------
    # # 5. PROSES UNDUH (DOWNLOAD) SCRIPT DARI REPOSITORY GITHUB
    # Penjelasan: Mengunduh script utama WaroengTweak.ps1 langsung ke memori RAM 
    # menggunakan metode yang sesuai dengan versi PowerShell pengguna (modern vs lawas).
    # ---------------------------------------------------------------------
    Write-Progress -Activity "Downloading Waroeng Tweak..." -Status "Silakan tunggu..."
    $response = $null
    
    try {
        if ($psv -ge 3) {
            # Menggunakan Invoke-RestMethod untuk PowerShell v3 ke atas (Lebih cepat)
            $response = Invoke-RestMethod -Uri $URL -UseBasicParsing
        } else {
            # Fallback menggunakan Net.WebClient untuk PowerShell v2 lawas
            $w = New-Object Net.WebClient
            $response = $w.DownloadString($URL)
        }
    } catch {
        Write-Progress -Activity "Downloading Waroeng Tweak..." -Status "Gagal!" -Completed
        Write-Host "[!] Koneksi Gagal!" -ForegroundColor Red
        Check3rdAV
        Write-Host "Detail Error: $($_.Exception.Message)" -ForegroundColor Custom
        Write-Host "Gagal mengunduh script! Pastikan internet aktif atau matikan Firewall/AV Anda." -ForegroundColor Yellow
        return
    }
    Write-Progress -Activity "Downloading Waroeng Tweak..." -Status "Selesai!" -Completed


    # ---------------------------------------------------------------------
    # # 6. VERIFIKASI KEAMANAN (INTEGRITAS FILE VIA HASH SHA256)
    # Penjelasan: Memeriksa sidik jari digital (Hash) dari kode yang diunduh.
    # Jika kode di GitHub dimodifikasi/disisipi malware oleh hacker, proses langsung diblokir.
    # ---------------------------------------------------------------------
    # CATATAN: Ganti nilai ini jika Anda melakukan update resmi pada file WaroengTweak.ps1
    $releaseHash = 'F9ACADD0E6B014E24FF1F3E6B7AC5509B9026CF8A5AF729A6FC07D3E85C04CDE' 

    $stream = New-Object IO.MemoryStream
    $writer = New-Object IO.StreamWriter $stream
    $writer.Write($response)
    $writer.Flush()
    $stream.Position = 0
    $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'
    
    # Validasi kesesuaian nilai Hash
    if ($hash -ne $releaseHash) {
        Write-Host ""
        Write-Host " [!] PERINGATAN KEAMANAN (SECURITY ALERT) [!] " -ForegroundColor White -BackgroundColor Red
        Write-Host " Hash file yang diunduh ($hash) TIDAK COCOK dengan versi resmi!" -ForegroundColor Red
        Write-Host " Proses dibatalkan demi keamanan untuk mencegah eksekusi script berbahaya." -ForegroundColor Yellow
        $response = $null
        return
    }

    # Memastikan data response tidak kosong setelah lolos pengecekan hash
    if (-not $response) {
        Write-Host "[!] Gagal mendapatkan respon data dari server GitHub." -ForegroundColor Red
        return
    }


    # ---------------------------------------------------------------------
    # # 7. RENDER PERINGATAN PENGGUNA (GUI MESSAGEBOX)
    # Penjelasan: Memunculkan jendela pop-up konfirmasi standar Windows untuk 
    # memperingatkan pengguna agar menonaktifkan pelindung Windows Defender sementara waktu.
    # ---------------------------------------------------------------------
    Add-Type -AssemblyName System.Windows.Forms
    $warningMsg = "PERHATIAN!`n`nAplikasi ini berisi script Tweak tingkat lanjut (termasuk mematikan Telemetry & Defender).`n`nSilakan matikan sementara 'Real-time Protection' dan 'Tamper Protection' di Windows Security SEKARANG.`n`nJika sudah dimatikan, klik OK untuk membuka aplikasi.`n(Jika setelah klik OK aplikasi tidak terbuka, berarti Defender masih menyala dan memblokirnya)."
    $result = [System.Windows.Forms.MessageBox]::Show($warningMsg, "Waroeng Tweak - Info Penting", 0, 48)

    if ($result -ne "OK") {
        Write-Host "[-] Dibatalkan oleh pengguna." -ForegroundColor Yellow
        exit
    }


    # ---------------------------------------------------------------------
    # # 8. ALOKASI (.PS1) SECARA AMAN 
    # Penjelasan: Folder ditentukan berdasarkan hak akses user (System Temp vs User Temp).
    # ---------------------------------------------------------------------
    $rand = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\WaroengTweak_$rand.ps1" } else { "$env:USERPROFILE\AppData\Local\Temp\WaroengTweak_$rand.ps1" }
    
    # Menulis kode mentah dari RAM ke dalam penyimpanan lokal dengan enkripsi UTF8
    Set-Content -Path $FilePath -Value $response -Encoding UTF8

    # Memastikan file temporer sukses terbuat dan tidak dicegat AV di detik pertama
    if (-not (Test-Path $FilePath)) {
        Check3rdAV
        Write-Host "[!] Gagal membuat file temporary di sistem. Folder dikunci atau diblokir Antivirus!" -ForegroundColor Red
        return
    }


    # ---------------------------------------------------------------------
    # # 9. EKSEKUSI UTAMA (START MAIN APPLICATION AS ADMINISTRATOR)
    # Penjelasan: Menjalankan file `.ps1` temporer tersebut dengan hak Administrator tertinggi 
    # (`-Verb RunAs`) dan menyembunyikan launcher latar belakang (`-WindowStyle Hidden`).
    # Jendela GUI utama Waroeng Tools Anda akan terbuka dari proses ini.
    # ---------------------------------------------------------------------
    Write-Host "Membuka Waroeng Tweak..." -ForegroundColor Cyan

    $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$FilePath`"" -Verb RunAs -PassThru
    $p.WaitForExit() 
    

    # ---------------------------------------------------------------------
    # # 10. CLEANUP & RE-LOCK SYSTEM (PEMBERSIHAN JEJAK KEAMANAN)
    # Penjelasan: Setelah pengguna menutup aplikasi Waroeng Tools, launcher akan otomatis 
    # menghapus file temporary agar bersih dari penyimpanan, serta mengembalikan kebijakan 
    # eksekusi komputer pengguna ke tingkat paling aman ('Restricted').
    # ---------------------------------------------------------------------
    # Menghapus file temporary (.ps1)
    Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue

    # Mengunci kembali celah eksekusi PowerShell demi keamanan PC pengguna
    try {
        Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
    } catch {}
}
