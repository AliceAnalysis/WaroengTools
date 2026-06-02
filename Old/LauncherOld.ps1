# --- LAUNCHER WAROENG TWEAK ---

Add-Type -AssemblyName System.Windows.Forms

$warningMsg = "PERHATIAN!`n`nAplikasi ini berisi script Tweak tingkat lanjut (termasuk mematikan Telemetry & Defender).`n`nSilakan matikan sementara 'Real-time Protection' dan 'Tamper Protection' di Windows Security SEKARANG.`n`nJika sudah dimatikan, klik OK untuk membuka aplikasi.`n(Jika setelah klik OK aplikasi tidak terbuka, berarti Defender masih menyala dan memblokirnya)."

# Tampilkan pesan peringatan (Aman dari Defender karena file ini tidak berisi script virus)
$result = [System.Windows.Forms.MessageBox]::Show($warningMsg, "Waroeng Tweak - Info Penting", 0, 48)

if ($result -eq "OK") {
    # Dapatkan lokasi file script utama yang berada di folder yang sama
    $mainScript = Join-Path -Path $PSScriptRoot -ChildPath "WaroengTweak.ps1" # <--- Pastikan nama file ini sama dengan file utamamu!

    if (Test-Path $mainScript) {
        Write-Host "Membuka Waroeng Tweak..." -ForegroundColor Cyan
        # Jalankan script utama
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$mainScript`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("File script utama (WaroengTweak.ps1) tidak ditemukan di folder ini!", "Error", 0, 16)
    }
}