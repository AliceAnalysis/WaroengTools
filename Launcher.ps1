# =========================================================================
# WAROENG TWEAK - WEB LAUNCHER (Inspired by Massgrave)
# =========================================================================

# 1. MENAMPILKAN PERINGATAN (GUI)
Add-Type -AssemblyName System.Windows.Forms
$warningMsg = "PERHATIAN!`n`nAplikasi ini berisi script Tweak tingkat lanjut (termasuk mematikan Telemetry & Defender).`n`nSilakan matikan sementara 'Real-time Protection' dan 'Tamper Protection' di Windows Security SEKARANG.`n`nJika sudah dimatikan, klik OK untuk membuka aplikasi.`n(Jika setelah klik OK aplikasi tidak terbuka, berarti Defender masih menyala dan memblokirnya)."
$result = [System.Windows.Forms.MessageBox]::Show($warningMsg, "Waroeng Tweak - Info Penting", 0, 48)

if ($result -ne "OK") {
    Write-Host "Dibatalkan oleh pengguna." -ForegroundColor Yellow
    exit
}

# 2. PROSES DOWNLOAD & EKSEKUSI (MASSGRAVE METHOD)
& {
    $psv = (Get-Host).Version.Major
    $URL = 'https://raw.githubusercontent.com/AliceAnalysis/WaroengTools/refs/heads/main/WaroengTweak.ps1'

    # Cek ketersediaan .NET Framework
    try {
        [void][System.AppDomain]::CurrentDomain.GetAssemblies(); [void][System.Math]::Sqrt(144)
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Powershell gagal memuat .NET command."
        return
    }

    # Fungsi cek Antivirus Pihak Ketiga
    function Check3rdAV {
        $cmd = if ($psv -ge 3) { 'Get-CimInstance' } else { 'Get-WmiObject' }
        $avList = & $cmd -Namespace root\SecurityCenter2 -Class AntiVirusProduct -ErrorAction SilentlyContinue | 
                  Where-Object { $_.displayName -notlike '*windows*' } | Select-Object -ExpandProperty displayName

        if ($avList) {
            Write-Host 'Antivirus pihak ketiga mungkin memblokir script ini: ' -ForegroundColor White -BackgroundColor Blue -NoNewline
            Write-Host " $($avList -join ', ')" -ForegroundColor DarkRed -BackgroundColor White
        }
    }

    # Set protokol ke TLS 1.2 agar koneksi ke GitHub tidak ditolak
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

    Write-Progress -Activity "Downloading Waroeng Tweak..." -Status "Please wait"
    $response = $null
    
    # Proses Download Script dari GitHub
    try {
        if ($psv -ge 3) {
            $response = Invoke-RestMethod -Uri $URL -UseBasicParsing
        } else {
            $w = New-Object Net.WebClient
            $response = $w.DownloadString($URL)
        }
    } catch {
        Check3rdAV
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Gagal mengunduh script dari GitHub! Pastikan koneksi internet stabil dan Firewall/AV tidak memblokir koneksi."
        return
    }
    Write-Progress -Activity "Downloading Waroeng Tweak..." -Status "Done" -Completed

    # ==========================================
    # VERIFIKASI KEAMANAN: HASH SHA256
    # ==========================================
    # Ganti string di bawah ini dengan Hash SHA256 dari file terbarumu!
    $releaseHash = 'A2514F4BC80693CE3259D27FF81B4A1BF8BBA2698555C2B2862337908248B037' 

    $stream = New-Object IO.MemoryStream
    $writer = New-Object IO.StreamWriter $stream
    $writer.Write($response)
    $writer.Flush()
    $stream.Position = 0
    $hash = [BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash($stream)) -replace '-'
    
    if ($hash -ne $releaseHash) {
        Write-Host ""
        Write-Host " [!] PERINGATAN KEAMANAN (SECURITY ALERT) [!] " -ForegroundColor White -BackgroundColor Red
        Write-Host " Hash file yang diunduh ($hash) TIDAK COCOK dengan versi resmi!" -ForegroundColor Red
        Write-Host " Proses dibatalkan untuk mencegah eksekusi script berbahaya." -ForegroundColor Yellow
        $response = $null
        return
    }
    # ==========================================

    if (-not $response) {
        Write-Host "Gagal mendapatkan respon dari server." -ForegroundColor Red
        return
    }

    # Membuat Temp File untuk Script
    $rand = [Guid]::NewGuid().Guid
    $isAdmin = [bool]([Security.Principal.WindowsIdentity]::GetCurrent().Groups -match 'S-1-5-32-544')
    $FilePath = if ($isAdmin) { "$env:SystemRoot\Temp\WaroengTweak_$rand.ps1" } else { "$env:USERPROFILE\AppData\Local\Temp\WaroengTweak_$rand.ps1" }
    
    # Tulis response dari GitHub ke dalam file .ps1
    Set-Content -Path $FilePath -Value $response -Encoding UTF8

    if (-not (Test-Path $FilePath)) {
        Check3rdAV
        Write-Host "Gagal membuat file temporary di sistem. Cek Antivirus Anda!" -ForegroundColor Red
        return
    }

    Write-Host "Membuka Waroeng Tweak..." -ForegroundColor Cyan

    # Eksekusi Script
    # Menggunakan -WindowStyle Hidden dan meminta hak Admin (RunAs)
    if ($psv -lt 3) {
        $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$FilePath`"" -Verb RunAs -PassThru
        $p.WaitForExit()
    } else {
        $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$FilePath`"" -Verb RunAs -PassThru
        # Tunggu sampai aplikasi ditutup agar kita bisa menghapus file temp-nya
        $p.WaitForExit() 
    }   
    
    # Hapus file script setelah aplikasi Waroeng Tweak ditutup
    Remove-Item -Path $FilePath -Force -ErrorAction SilentlyContinue
}