<#
:: =====================================================================
:: WAROENG TOOLS - v6.6.3
:: Creator: Bagas Alam Saputra
:: =====================================================================
:: 
:: Update Log v6.6.3:
:: [NATIVE POWERSHELL ENGINE & OPTIMIZATION]
:: 1. SCRIPT OVERHAUL: Merombak total ribuan baris kode "Revert Tweak" menjadi skrip Native PowerShell murni yang jauh lebih bersih dan ringan.
:: 2. BLAZING FAST EXECUTION: Peningkatan performa ekstrem pada fitur "Remove Bloatware" dan "Block Tracking Hosts", menghemat waktu eksekusi dari menit menjadi hitungan milidetik.
:: 3. CLIPBOARD LOGIC FIX: Menyesuaikan logika sinkronisasi Cloud Clipboard agar fitur riwayat lokal (Windows + V) dapat aktif/nonaktif dengan sempurna tanpa menyebabkan error sistem.
:: 4. SMART REGISTRY & UI REFRESH: Menyederhanakan manipulasi pembacaan/penulisan Registry dan menambahkan fitur Auto-Restart Explorer.exe agar perubahan antarmuka (UI) langsung diterapkan.
:: 5. SMART UWP RESTORE: Memperbaiki logika pemulihan aplikasi bawaan Windows (Bloatware) dengan kemampuan bypass "Deprovisioned" secara otomatis.
::
:: [SPECIAL THANKS & CREDITS]
:: - massgrave (MAS)
:: - abbodi1406 (OfficeScrubber)
::
:: [COPYRIGHT NOTICE]
:: PLEASE DO NOT CHANGE THIS SCRIPT TO MAKE IT YOUR OWN WITHOUT GIVING ME CREDIT IN THE SCRIPT.
:: TOLONG JANGAN UBAH SKRIP INI UNTUK MENJADIKANNYA SEOLAH-OLAH MILIK ANDA SENDIRI TANPA MENCANTUMKAN CREDIT KEPADA SAYA DI DALAM SKRIP.
:: 
:: =====================================================================
#>

# =========================================================================
# FASE 1: ELEVASI HAK AKSES ADMINISTRATOR (UAC BYPASS LOGIC)
# =========================================================================
# Mengecek apakah user saat ini menjalankan PowerShell dengan hak akses Administrator.
# Menggunakan library keamanan bawaan .NET (.WindowsPrincipal dan .WindowsBuiltInRole).
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Jika BUKAN Administrator, maka sistem akan mencoba "memaksa" elevasi akses.
if (-not $isAdmin) {
    try {
        # Pengecekan krusial: Memastikan skrip ini sedang berjalan dari file fisik (.ps1).
        # Variabel $PSCommandPath akan bernilai kosong jika skrip hanya di-copy-paste ke terminal.
        if ($PSCommandPath) {
            
            # Membuka kembali jendela PowerShell baru dan menjalankan file skrip ini.
            # Parameter paling penting di sini adalah '-Verb RunAs'. 
            # Perintah inilah yang memicu munculnya jendela konfirmasi biru/kuning (UAC Prompt) dari Windows.
            Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
            
            # Langsung mematikan/menutup jendela PowerShell lama yang tidak memiliki akses Admin.
            Exit 
        } else {
            # Jika user menjalankan skrip tanpa menyimpannya ke file (misal di PowerShell ISE belum di-save),
            # tampilkan peringatan GUI agar sistem tidak crash atau terjebak dalam loop.
            [System.Windows.Forms.MessageBox]::Show("Harap simpan script ini sebagai file .ps1 terlebih dahulu agar fitur Auto-Admin bisa bekerja.", "Error", "OK", "Error")
            Exit
        }
    } catch {
        # Blok catch ini berfungsi sebagai "Fail-Safe".
        # Jika jendela UAC muncul lalu user menekan tombol "NO" atau "Cancel",
        # maka akan terjadi error (Exception). Kita tangkap error itu dan tutup skripnya secara halus.
        Exit
    }
}
# =========================================================================

# =========================================================================
# FASE 2: PERSIAPAN ANTARMUKA GRAFIS (WINDOWS FORMS)
# =========================================================================
# Memuat library .NET Framework yang diperlukan untuk menggambar GUI dan warna.
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GLOBAL VARIABLES & THEME CONFIGURATION ---
# Variabel global untuk mendeteksi apakah aplikasi sedang menggunakan mode gelap atau tidak.
$global:IsDarkMode = $false # Default: Aplikasi dimulai dengan tema Terang (Light Mode)

# Menggunakan struktur data 'Hashtable' untuk menyimpan palet warna.
# Ini adalah metode profesional (Theme Engine) agar pewarnaan UI terpusat di satu tempat.
$ThemePalettes = @{
    Dark = @{
        Bg      = [System.Drawing.Color]::FromArgb(18, 18, 18)        # Latar belakang gelap gulita
        Card    = [System.Drawing.Color]::FromArgb(30, 30, 35)        # Warna panel/kotak sedikit lebih terang
        Text    = [System.Drawing.Color]::FromArgb(240, 240, 240)     # Teks putih keabu-abuan agar tidak silau
        Accent  = [System.Drawing.Color]::FromArgb(86, 182, 194)      # Warna Aksen: Cyan (Biru Muda)
        Header  = [System.Drawing.Color]::FromArgb(0, 110, 200)       # Header Atas: Biru Khas Windows
        Side    = [System.Drawing.Color]::FromArgb(25, 25, 30)        # Latar Sidebar kiri
        Icon    = [char]0xE706 # Kode font ikon 'Matahari' (Segoe MDL2) untuk tombol ganti ke Light
    }
    Light = @{
        Bg      = [System.Drawing.Color]::FromArgb(238, 241, 245)     # Latar belakang putih keabu-abuan (mirip Settings Windows 11)
        Card    = [System.Drawing.Color]::White                       # Panel warna putih bersih
        Text    = [System.Drawing.Color]::FromArgb(40, 40, 40)        # Teks hitam keabu-abuan
        Accent  = [System.Drawing.Color]::FromArgb(0, 100, 180)       # Warna Aksen: Biru Tua
        Header  = [System.Drawing.Color]::FromArgb(0, 110, 200)       # Header Atas: Biru Khas Windows
        Side    = [System.Drawing.Color]::FromArgb(28, 33, 40)        # Latar Sidebar tetap gelap agar kontras
        Icon    = [char]0xE708 # Kode font ikon 'Bulan' (Segoe MDL2) untuk tombol ganti ke Dark
    }
}

# Menyuntikkan palet warna ke variabel $p berdasarkan status DarkMode saat aplikasi baru dibuka.
$p = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

# =========================================================================
# FASE 3: INSTANSIASI JENDELA UTAMA (MAIN FORM)
# =========================================================================
# Membuat "Kanvas Kosong" atau jendela utama aplikasi
$form = New-Object System.Windows.Forms.Form
$form.Text = "Waroeng Tools v6.6.3"                           # Judul aplikasi di kiri atas jendela
$form.Size = New-Object System.Drawing.Size(1150, 800)      # Ukuran resolusi jendela (Lebar x Tinggi)
$form.StartPosition = "CenterScreen"                        # Agar jendela otomatis muncul tepat di tengah monitor
$form.FormBorderStyle = "FixedSingle"                       # Mengunci jendela agar ujungnya tidak bisa ditarik/diperbesar (no resize)
$form.MaximizeBox = $false                                  # Menonaktifkan tombol "Maximize" (Perbesar Layar Penuh)
$form.BackColor = $p.Bg                                     # Mengatur warna latar belakang kanvas menggunakan palet tema

# --- INJEKSI ICON APLIKASI ---
try {
    # Trik Cerdas: Alih-alih menyertakan file .ico (yang akan menambah ukuran file), 
    # script ini "mencuri/mengekstrak" icon bawaan Windows dari file iscsicpl.exe (iSCSI Initiator)
    # untuk dijadikan icon aplikasi Waroeng Tools.
    $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("$env:windir\System32\iscsicpl.exe")
} catch {
    # Jika karena suatu alasan file iscsicpl.exe tidak ada, gunakan icon default aplikasi PowerShell.
    Write-Host "Gagal memuat icon, menggunakan icon default."
}

# =========================================================================
# FASE 4: FUNGSI PENGGANTI TEMA (THEME SWITCHER ENGINE)
# =========================================================================
function Toggle-Theme {
    # Membalikkan status (toggle) variabel global. 
    # Jika sebelumnya $false (Light), maka diubah menjadi $true (Dark), dan sebaliknya.
    $global:IsDarkMode = -not $global:IsDarkMode
    
    # Menentukan palet warna baru berdasarkan status yang baru saja diubah
    $newP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }
    
    # ---------------------------------------------------------------------
    # 1. Update Warna Latar Belakang Kontainer Utama
    # ---------------------------------------------------------------------
    # Mengubah warna 'Kanvas Utama', 'Panel Kanan', dan 'Panel Konten' secara instan
    $form.BackColor = $newP.Bg
    $rightPanel.BackColor = $newP.Bg
    $contentPanel.BackColor = $newP.Bg
    
    # ---------------------------------------------------------------------
    # 2. Update Warna Elemen Spesifik (Dashboard Card)
    # ---------------------------------------------------------------------
    # Mencari kotak Dashboard (DashCard) di dalam Panel Konten menggunakan Where-Object
    $dashBox = $contentPanel.Controls | Where-Object { $_.Name -eq "DashCard" }
    
    # Jika kotak Dashboard ditemukan, ubah warnanya
    if ($dashBox) {
        $dashBox.BackColor = $newP.Card
        
        # Looping (perulangan) untuk mengecek setiap teks (Label) yang ada di dalam kotak Dashboard
        # Kita menggunakan '.Tag' sebagai penanda unik untuk membedakan mana teks judul dan mana teks nilai
        foreach ($ctrl in $dashBox.Controls) {
            # Jika Tag-nya "ValText" (Teks Nilai/Data), beri warna teks standar (Putih/Hitam)
            if ($ctrl.Tag -eq "ValText") { $ctrl.ForeColor = $newP.Text }
            
            # Jika Tag-nya "LabelText" (Teks Judul), beri warna aksen (Cyan/Biru) agar mencolok
            if ($ctrl.Tag -eq "LabelText") { $ctrl.ForeColor = $newP.Accent }
        }
    }

    # ---------------------------------------------------------------------
    # 3. Update Ikon Tombol & Log Sistem
    # ---------------------------------------------------------------------
    # Mengganti ikon tombol (Matahari untuk Light Mode, Bulan untuk Dark Mode)
    $btnTheme.Text = $newP.Icon
    
    # Menentukan nama mode saat ini untuk dicatat ke dalam Log
    $modeName = if ($global:IsDarkMode) { "Dark" } else { "Light" }
    
    # Mencatat aktivitas penggantian tema ke dalam panel Log Aplikasi
    Write-Log "Theme switched to: $modeName"
}

# =========================================================================
# FASE 5: PEMBUATAN TATA LETAK UTAMA (MAIN LAYOUTING)
# =========================================================================

# ---------------------------------------------------------------------
# 1. SIDEBAR (PANEL KIRI)
# ---------------------------------------------------------------------
$sidebar = New-Object System.Windows.Forms.Panel
$sidebar.Dock = "Left"          # Merapat dan memanjang penuh ke sisi Kiri jendela
$sidebar.Width = 270            # Lebar tetap sebesar 270 pixel
# UI Choice: Sidebar sengaja "dikunci" menggunakan warna Dark Side secara permanen
# Ini memberikan ilusi desain profesional (layaknya aplikasi Discord atau Spotify) meski tema utamanya diganti.
$sidebar.BackColor = $ThemePalettes.Dark.Side 
$form.Controls.Add($sidebar)    # Memasukkan Sidebar ke dalam Kanvas Utama

# ---------------------------------------------------------------------
# 2. RIGHT PANEL (PANEL KANAN / KONTEN UTAMA)
# ---------------------------------------------------------------------
$rightPanel = New-Object System.Windows.Forms.Panel
$rightPanel.Dock = "Fill"       # Mengisi seluruh SISA ruang kosong yang tidak dipakai oleh Sidebar
$rightPanel.BackColor = $p.Bg   # Mengikuti warna palet tema aktif
$form.Controls.Add($rightPanel)
$rightPanel.BringToFront()      # Memastikan panel ini tidak tertimpa oleh elemen lain

# =========================================================================
# FASE 6: INJEKSI IDENTITAS & BRANDING (SIDEBAR HEADER)
# =========================================================================

# Membuat Teks Judul Aplikasi (Brand)
$lblBrand = New-Object System.Windows.Forms.Label
$lblBrand.Text = "WAROENG TOOLS"
$lblBrand.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$lblBrand.ForeColor = [System.Drawing.Color]::White     # Teks putih tegas
$lblBrand.AutoSize = $true                              # Ukuran kotak menyesuaikan panjang teks
$lblBrand.Location = New-Object System.Drawing.Point(25, 30) # Posisi (X, Y) dari pojok kiri atas
$sidebar.Controls.Add($lblBrand)                        # Memasukkan Teks ke dalam Sidebar

# Membuat Teks Sub-Judul (Kategori Aplikasi)
$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "IT SYSTEM UTILITY"
$lblSub.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Regular)
$lblSub.ForeColor = [System.Drawing.Color]::Gray        # Teks abu-abu agar tidak menyaingi Judul
$lblSub.AutoSize = $true
$lblSub.Location = New-Object System.Drawing.Point(28, 65)
$sidebar.Controls.Add($lblSub)

# Membuat Teks Identitas Pembuat (Credit)
$lblCreator = New-Object System.Windows.Forms.Label
$lblCreator.Text = "Creator: Bagas Alam Saputra"
$lblCreator.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblCreator.ForeColor = $ThemePalettes.Dark.Accent      # Menggunakan warna Cyan dari palet agar senada
$lblCreator.AutoSize = $true
$lblCreator.Location = New-Object System.Drawing.Point(28, 85)
$sidebar.Controls.Add($lblCreator)

# =========================================================================
# FASE 7: PEMBUATAN STRUKTUR PANEL KANAN (HEADER, KONTEN, LOG)
# =========================================================================
# 1. PANEL HEADER (Bagian Atas)
# Berfungsi sebagai tempat judul halaman, tombol aksi, jam, dan profil user.
$header = New-Object System.Windows.Forms.Panel
$header.Dock = "Top"             # Menempel penuh di bagian atas
$header.Height = 85              # Tinggi header tetap (85 pixel)
$header.BackColor = $p.Header    # Mengikuti warna palet Header (Biru)
$rightPanel.Controls.Add($header)

# 2. PANEL LOG (Bagian Bawah)
# Berfungsi sebagai terminal mini untuk menampilkan riwayat aktivitas (Log) aplikasi.
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = "Bottom"        # Menempel penuh di bagian bawah
$logPanel.Height = 100           # Tinggi terminal log (100 pixel)
$logPanel.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25) # Warna gelap pekat
$rightPanel.Controls.Add($logPanel)

# 3. PANEL KONTEN UTAMA (Bagian Tengah)
# Berfungsi sebagai area kerja tempat menu utama/tweak ditampilkan.
$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Dock = "Fill"      # Mengisi sisa ruang di antara Header dan Log
$contentPanel.BackColor = $p.Bg  # Mengikuti warna palet Latar Belakang (Gelap/Terang)
$contentPanel.Padding = New-Object System.Windows.Forms.Padding(30) # Memberi jarak aman 30px dari tepi
$contentPanel.AutoScroll = $true # Menambahkan fungsi scroll jika isi konten terlalu panjang
$rightPanel.Controls.Add($contentPanel)
$contentPanel.BringToFront()     # Memastikan panel ini berada di lapisan teratas

# =========================================================================
# FASE 8: PENGISIAN ELEMEN HEADER & INTERAKTIVITAS
# =========================================================================
# --- JUDUL HALAMAN KIRI ---
$lblPageTitle = New-Object System.Windows.Forms.Label
$lblPageTitle.Text = "Dashboard"
$lblPageTitle.Font = New-Object System.Drawing.Font("Segoe UI", 20, [System.Drawing.FontStyle]::Bold)
$lblPageTitle.ForeColor = [System.Drawing.Color]::White
$lblPageTitle.AutoSize = $true
$lblPageTitle.Location = New-Object System.Drawing.Point(30, 22)
$header.Controls.Add($lblPageTitle)

# --- KONTAINER INFO KANAN (Tempat Tombol & Profil) ---
# Menggunakan panel transparan di sebelah kanan agar elemen di dalamnya mudah diatur (X, Y)
$headInfo = New-Object System.Windows.Forms.Panel
$headInfo.Width = 600
$headInfo.Height = 85
$headInfo.Dock = "Right"         # Menempel di sisi kanan Header
$headInfo.BackColor = "Transparent"
$header.Controls.Add($headInfo)

# -------------------------------------------------------------------------
# ELEMEN 1: TOMBOL EXPORT LOG (Ikon Disket/Save)
# -------------------------------------------------------------------------
$btnExportLog = New-Object System.Windows.Forms.Label
$btnExportLog.Text = [char]0xE74E # Kode Ikon 'Save' dari font bawaan Windows
$btnExportLog.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 15) # Font rahasia Windows 10/11
$btnExportLog.ForeColor = [System.Drawing.Color]::White
$btnExportLog.AutoSize = $true
$btnExportLog.Cursor = "Hand"     # Mengubah kursor panah menjadi ikon 'Tangan' saat disorot
$btnExportLog.Location = New-Object System.Drawing.Point(185, 31)

# EVENT HANDLER: Menambahkan aksi interaktif pada tombol
$btnExportLog.Add_Click({ Export-Log }) # Jika diklik, jalankan fungsi Export-Log
$btnExportLog.Add_MouseEnter({ $btnExportLog.ForeColor = [System.Drawing.Color]::LimeGreen }) # Sorot -> Hijau
$btnExportLog.Add_MouseLeave({ $btnExportLog.ForeColor = [System.Drawing.Color]::White })     # Lepas -> Putih
$headInfo.Controls.Add($btnExportLog)

# (PEMBATAS VISUAL 1)
$sepLine1 = New-Object System.Windows.Forms.Panel
$sepLine1.Width = 1; $sepLine1.Height = 20; $sepLine1.BackColor = [System.Drawing.Color]::FromArgb(80, 255, 255, 255)
$sepLine1.Location = New-Object System.Drawing.Point(220, 32); $headInfo.Controls.Add($sepLine1)

# -------------------------------------------------------------------------
# ELEMEN 2: TOMBOL THEME SWITCHER (Ikon Matahari/Bulan)
# -------------------------------------------------------------------------
$btnTheme = New-Object System.Windows.Forms.Label
$btnTheme.Text = $p.Icon # Memanggil ikon berdasarkan variabel Tema (Light/Dark)
$btnTheme.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 15)
$btnTheme.ForeColor = [System.Drawing.Color]::White
$btnTheme.AutoSize = $true
$btnTheme.Cursor = "Hand"
$btnTheme.Location = New-Object System.Drawing.Point(235, 31)

# EVENT HANDLER
$btnTheme.Add_Click({ Toggle-Theme }) # Jika diklik, jalankan fungsi Toggle-Theme
$btnTheme.Add_MouseEnter({ $btnTheme.ForeColor = [System.Drawing.Color]::Yellow }) # Sorot -> Kuning
$btnTheme.Add_MouseLeave({ $btnTheme.ForeColor = [System.Drawing.Color]::White })  # Lepas -> Putih
$headInfo.Controls.Add($btnTheme)

# (PEMBATAS VISUAL 2)
$sepLine2 = New-Object System.Windows.Forms.Panel
$sepLine2.Width = 1; $sepLine2.Height = 20; $sepLine2.BackColor = [System.Drawing.Color]::FromArgb(80, 255, 255, 255)
$sepLine2.Location = New-Object System.Drawing.Point(270, 32); $headInfo.Controls.Add($sepLine2)

# -------------------------------------------------------------------------
# ELEMEN 3: JAM REAL-TIME & TIMER ENGINE
# -------------------------------------------------------------------------
# Membuat teks statis "00:00:00" sebagai cetakan (placeholder) awal
$lblClock = New-Object System.Windows.Forms.Label
$lblClock.Text = "00:00:00"
$lblClock.Font = New-Object System.Drawing.Font("Segoe UI", 16)
$lblClock.ForeColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$lblClock.AutoSize = $true
$lblClock.Location = New-Object System.Drawing.Point(285, 27)
$headInfo.Controls.Add($lblClock)

# ENGINE TIMER: Membuat proses yang berjalan di latar belakang (asynchronous)
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000 # 1000 milidetik = 1 Detik
# Setiap 1 detik (Tick), perbarui teks pada variabel $lblClock dengan waktu sistem terbaru (Jam:Menit:Detik)
$timer.Add_Tick({ $lblClock.Text = Get-Date -Format "HH:mm:ss" })
$timer.Start() # Menyalakan mesin waktu

# (PEMBATAS VISUAL 3 UTAMA)
$sepLine3 = New-Object System.Windows.Forms.Panel
$sepLine3.Width = 1; $sepLine3.Height = 40; $sepLine3.BackColor = [System.Drawing.Color]::FromArgb(100, 255, 255, 255)
$sepLine3.Location = New-Object System.Drawing.Point(395, 22); $headInfo.Controls.Add($sepLine3)

# -------------------------------------------------------------------------
# ELEMEN 4: IDENTITAS USER KOMPUTER LOKAL
# -------------------------------------------------------------------------
$lblUserInfo = New-Object System.Windows.Forms.Label
# Menarik nama akun Windows yang sedang login dan membuatnya KAPITAL
$lblUserInfo.Text = "$($env:USERNAME.ToUpper())" 
$lblUserInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblUserInfo.ForeColor = [System.Drawing.Color]::White
$lblUserInfo.AutoSize = $true
$lblUserInfo.Location = New-Object System.Drawing.Point(415, 24)
$headInfo.Controls.Add($lblUserInfo)

$lblPCInfo = New-Object System.Windows.Forms.Label
# Menarik nama perangkat (Hostname) dari sistem Windows
$lblPCInfo.Text = "$($env:COMPUTERNAME)"
$lblPCInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$lblPCInfo.ForeColor = [System.Drawing.Color]::FromArgb(200, 255, 255, 255)
$lblPCInfo.AutoSize = $true
$lblPCInfo.Location = New-Object System.Drawing.Point(415, 44)
$headInfo.Controls.Add($lblPCInfo)

# ELEMEN 5: IKON FOTO PROFIL (User Icon)
$lblUserIcon = New-Object System.Windows.Forms.Label
$lblUserIcon.Text = [char]0xE77B # Kode Ikon 'Orang/User' dari font bawaan
$lblUserIcon.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 22)
$lblUserIcon.ForeColor = [System.Drawing.Color]::White
$lblUserIcon.AutoSize = $true
$lblUserIcon.Location = New-Object System.Drawing.Point(535, 24)
$headInfo.Controls.Add($lblUserIcon)

# =========================================================================
# FASE 9: SISTEM LOGGING (TERMINAL AKTIVITAS)
# =========================================================================
# Membuat kotak teks canggih (RichTextBox) yang bertingkah seperti terminal hacker
$txtLog = New-Object System.Windows.Forms.RichTextBox
$txtLog.Dock = "Fill"
$txtLog.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 25)
$txtLog.ForeColor = [System.Drawing.Color]::LimeGreen # Warna font Hijau khas Terminal Linux
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9) # Font *Monospace* agar lurus dan rapi
$txtLog.BorderStyle = "None"
$txtLog.ReadOnly = $true # KUNCI: Mencegah user mengetik manual di dalam kotak log ini
$txtLog.Text = "System initialized..."
$logPanel.Controls.Add($txtLog)

# -------------------------------------------------------------------------
# FUNGSI PENCATATAN AKTIVITAS (WRITE-LOG)
# -------------------------------------------------------------------------
function Write-Log ($Msg) {
    # Mengambil jam, menit, dan detik saat event terjadi
    $Time = Get-Date -Format "HH:mm:ss"
    
    # Menambahkan teks ke baris baru (`n) dengan format: [WAKTU] Pesan Aktivitas
    $txtLog.AppendText("`n[$Time] $Msg")
    
    # Fungsi otomatis menggulir (scroll) layar log ke tulisan paling bawah/terbaru
    $txtLog.ScrollToCaret()
}

# -------------------------------------------------------------------------
# FUNGSI EXPORT LOG (SIMPAN KE .TXT)
# -------------------------------------------------------------------------
function Export-Log {
    # Memunculkan jendela dialog standar Windows untuk menyimpan file
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Text Document (*.txt)|*.txt" # Hanya menerima format .txt
    $saveDialog.Title = "Save Waroeng Tools Log"
    # Menentukan nama file otomatis berdasarkan tanggal dan waktu ekspor (contoh: WaroengTools_Log_20261109_153022.txt)
    $saveDialog.FileName = "WaroengTools_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    # Jika user menekan tombol "Save/OK" pada jendela dialog
    if ($saveDialog.ShowDialog() -eq "OK") {
        
        # Mengekstrak seluruh teks yang ada di terminal log, lalu menulisnya ke dalam file yang dipilih user
        $txtLog.Text | Out-File -FilePath $saveDialog.FileName -Encoding UTF8
        
        # Mencatat aktivitas ekspor ke dalam log itu sendiri
        Write-Log "System log successfully exported to: $($saveDialog.FileName)"
        
        # Menampilkan notifikasi sukses berupa *Pop-up MessageBox*
        [System.Windows.Forms.MessageBox]::Show("Log berhasil diekspor!", "Export Success", "OK", "Information")
    }
}

# =========================================================================
# FASE 10: MESIN PEMBACA SPESIFIKASI SISTEM (HARDWARE & SOFTWARE ENGINE)
# =========================================================================
function Get-DetailedSpecs {
    try {
        # -----------------------------------------------------------------
        # 1. ANALISIS PENGGUNAAN MEMORI (RAM USAGE)
        # -----------------------------------------------------------------
        # Mengambil data OS untuk melihat kapasitas RAM yang terbaca oleh Windows
        $os = Get-CimInstance Win32_OperatingSystem
        
        # Kapasitas asli dalam format Kilobytes (KB), kita bagi 1MB agar berubah menjadi Gigabytes (GB)
        $totalVis = $os.TotalVisibleMemorySize / 1MB 
        $freeMem  = $os.FreePhysicalMemory / 1MB
        $usedMem  = $totalVis - $freeMem
        
        # Membulatkan angka desimal agar rapi (contoh: 7.8 GB, bukan 7.8231 GB)
        $usedGB  = [math]::Round($usedMem, 1)
        $totalGB = [math]::Round($totalVis, 0)
        
        # Menghitung persentase beban RAM saat ini
        $perc    = [math]::Round(($usedMem / $totalVis) * 100, 0)
        $ramFinalStr = "$usedGB GB Used / $totalGB GB ($perc%)"

        # -----------------------------------------------------------------
        # 2. ANALISIS SLOT FISIK RAM (MOTHERBOARD INFO)
        # -----------------------------------------------------------------
        # Mengambil informasi jumlah Slot RAM yang ada di Motherboard
        $memArray = Get-CimInstance Win32_PhysicalMemoryArray
        $totalSlots = 0
        
        if ($memArray) {
            # Menjumlahkan slot (berguna jika PC/Server memiliki lebih dari 1 papan sirkuit)
            foreach ($arr in $memArray) { $totalSlots += $arr.MemoryDevices }
        }

        # Mengambil data kepingan RAM (Sticks) yang benar-benar terpasang
        $memSticks = Get-CimInstance Win32_PhysicalMemory
        $usedSlotsCount = $memSticks.Count
        
        # Validasi (Fail-Safe): Jika dijalankan di Virtual Machine (VM), 
        # kadang jumlah total slot terbaca 0. Kita paksa samakan dengan jumlah RAM terpasang.
        if ($totalSlots -lt $usedSlotsCount) { $totalSlots = $usedSlotsCount }
        
        $freeSlots = $totalSlots - $usedSlotsCount
        $slotString = "$usedSlotsCount Used / $totalSlots Total ($freeSlots Available)"
        
        # Menganalisis Kecepatan (MHz) dan Kapasitas masing-masing keping RAM
        $ramSpeeds = @()
        foreach ($stick in $memSticks) {
            $cap = [math]::Round($stick.Capacity / 1GB, 0) # Konversi Byte ke GB
            $ramSpeeds += "${cap}GB-$($stick.Speed)MHz"    # Output: 8GB-3200MHz
        }
        $ramSpeedStr = $ramSpeeds -join " / "

        # -----------------------------------------------------------------
        # 3. ANALISIS HARDWARE UTAMA & VERSI OS
        # -----------------------------------------------------------------
        # Membaca Registry Windows untuk mendapatkan versi OS yang lebih akurat (misal: 22H2 / 21H1)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        $regInfo = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
        $dispVer = if ($regInfo.DisplayVersion) { $regInfo.DisplayVersion } else { $regInfo.ReleaseId }
        $osFinalString = "$($os.Caption) ($dispVer / $($os.Version))"

        # Mengambil data Model PC, Prosesor (CPU), dan Kartu Grafis (GPU)
        $cs   = Get-CimInstance Win32_ComputerSystem
        $cpu  = Get-CimInstance Win32_Processor
        $gpus = Get-CimInstance Win32_VideoController
        
        # Jika ada 2 GPU (misal Laptop Intel + Nvidia), gabungkan namanya dengan tanda "+"
        $gpuName = ($gpus | ForEach-Object { $_.Name }) -join " + "

        # -----------------------------------------------------------------
        # 4. ANALISIS PENYIMPANAN FISIK (DISK STORAGE)
        # -----------------------------------------------------------------
        $storageList = @()
        try {
            # Menggunakan Get-PhysicalDisk (fitur modern Windows) untuk mendapat nama asli Harddisk/SSD
            $pDisks = Get-PhysicalDisk | Sort-Object DeviceId
            foreach ($d in $pDisks) {
                $sizeGB = [math]::Round($d.Size / 1GB, 2)
                $storageList += "$($d.FriendlyName) ($sizeGB GB)"
            }
        } catch { 
            # Jika gagal (biasanya karena limitasi hak akses), beri nilai default
            $storageList += "Disk Info Unavailable" 
        }

        # -----------------------------------------------------------------
        # 5. DETEKSI STATUS KEAMANAN (ANTIVIRUS ENGINE)
        # -----------------------------------------------------------------
        try {
            $avStatus = "Unknown"
            
            # Cek Level 1: Mencari Antivirus Pihak Ketiga (Avast, McAfee, dll) via Security Center
            $3rdPartyAV = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction SilentlyContinue | 
                          Where-Object { $_.displayName -notmatch "Windows Defender|Microsoft Defender" }
            
            if ($3rdPartyAV) {
                $avStatus = "$($3rdPartyAV.displayName) (Active)"
            } else {
                # Cek Level 2: Jika tidak ada AV luar, periksa modul Windows Defender bawaan
                $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
                
                if ($defenderStatus) {
                    # Mengecek apakah proteksi Real-Time (pelindung utama) sedang menyala atau dimatikan
                    if ($defenderStatus.RealTimeProtectionEnabled -eq $true) {
                        $avStatus = "Windows Defender (Real-time: ON)"
                    } else {
                        $avStatus = "Windows Defender (Real-time: OFF / Disabled)"
                    }
                } else {
                    $avStatus = "Windows Defender (Services Offline)"
                }
            }
        } catch { 
            $avStatus = "Detection Failed" 
        }

        # -----------------------------------------------------------------
        # 6. PENGEMBALIAN DATA (RETURN HASHTABLE)
        # -----------------------------------------------------------------
        # Membungkus semua variabel yang sudah diolah ke dalam satu objek 'Hashtable'
        # agar mudah dipanggil dan ditampilkan di layar antarmuka (GUI)
        return @{
            OSVer     = $osFinalString
            Model     = "$($cs.Model) ($($cs.Manufacturer))"
            User      = "$($env:USERNAME) on $($env:COMPUTERNAME)"
            CPU       = "$($cpu.Name)"
            GPU       = "$gpuName"
            RAM_Main  = $ramFinalStr
            RAM_Speed = "$ramSpeedStr"
            RAM_Slots = "$slotString"  
            Storage   = $storageList
            AV        = "$avStatus"
        }
    } catch { 
        # Fail-safe: Jika seluruh fungsi crash, kembalikan nilai kosong (null) agar aplikasi tidak force-close
        return $null 
    }
}

# ---------------------------------------------------------------------
    # 3.5 FUNGSI INTERNAL: MODAL POPUP DETAIL STORAGE 
    # ---------------------------------------------------------------------
    function Show-StorageDetails ($StorageList, $ThemeColors) {
        $dlg = New-Object System.Windows.Forms.Form
        $dlg.Size = New-Object System.Drawing.Size(420, 320)
        $dlg.StartPosition = "CenterScreen"
        $dlg.FormBorderStyle = "None"
        $dlg.BackColor = $ThemeColors.Card
        $dlg.TopMost = $true

        $rad = 20
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($dlg.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($dlg.Width - $rad, $dlg.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $dlg.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $dlg.Region = New-Object System.Drawing.Region($path)

        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = "Detail Penyimpanan Fisik"
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = $ThemeColors.Accent
        $lblTitle.Location = New-Object System.Drawing.Point(25, 22)
        $lblTitle.AutoSize = $true
        $dlg.Controls.Add($lblTitle)

        $lblDesc = New-Object System.Windows.Forms.Label
        $lblDesc.Text = "Daftar hardware storage terdeteksi di sistem:"
        $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lblDesc.ForeColor = [System.Drawing.Color]::Gray
        $lblDesc.Location = New-Object System.Drawing.Point(26, 52)
        $lblDesc.AutoSize = $true
        $dlg.Controls.Add($lblDesc)

        $pnlList = New-Object System.Windows.Forms.FlowLayoutPanel
        $pnlList.Location = New-Object System.Drawing.Point(25, 85)
        $pnlList.Size = New-Object System.Drawing.Size(370, 160)
        $pnlList.AutoScroll = $true
        $pnlList.FlowDirection = "TopDown"
        $pnlList.WrapContents = $false
        
        $index = 1
        foreach ($drive in $StorageList) {
            $lblDrive = New-Object System.Windows.Forms.Label
            $lblDrive.Text = "$index. $drive"
            $lblDrive.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblDrive.ForeColor = $ThemeColors.Text
            $lblDrive.Width = 340
            $lblDrive.AutoSize = $true
            $lblDrive.Margin = New-Object System.Windows.Forms.Padding(0, 0, 0, 12)
            $pnlList.Controls.Add($lblDrive)
            $index++
        }
        $dlg.Controls.Add($pnlList)

        $btnClose = New-Object System.Windows.Forms.Button
        $btnClose.Text = "Tutup"
        $btnClose.Size = New-Object System.Drawing.Size(110, 36)
        $btnClose.Location = New-Object System.Drawing.Point(285, 260)
        $btnClose.BackColor = $ThemeColors.Accent
        $btnClose.ForeColor = [System.Drawing.Color]::White
        $btnClose.FlatStyle = "Flat"
        $btnClose.FlatAppearance.BorderSize = 0
        $btnClose.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $btnClose.Cursor = "Hand"
        $btnClose.Add_Click({ $dlg.Close() })
        $dlg.Controls.Add($btnClose)

        $pnlLine = New-Object System.Windows.Forms.Panel
        $pnlLine.Size = New-Object System.Drawing.Size($dlg.Width, 3)
        $pnlLine.Location = New-Object System.Drawing.Point(0, ($dlg.Height - 3))
        $pnlLine.BackColor = $ThemeColors.Accent
        $dlg.Controls.Add($pnlLine)

        $dlg.ShowDialog() | Out-Null
    }

# =========================================================================
# FASE 11: FUNGSI RENDER HALAMAN DASHBOARD (TAMPILAN SPESIFIKASI)
# =========================================================================
function Render-Dashboard {
    # ---------------------------------------------------------------------
    # 1. PERSIAPAN DATA & TEMA
    # ---------------------------------------------------------------------
    # Menarik seluruh data spesifikasi (OS, CPU, RAM) dari fungsi sebelumnya
    $data = Get-DetailedSpecs
    
    # Menentukan palet warna yang harus dipakai saat ini (tergantung mode Light/Dark)
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    # KUNCI UTAMA: Membersihkan kanvas (Content Panel) dari elemen halaman sebelumnya
    # Tanpa perintah ini, jika user berpindah menu, halamannya akan menumpuk!
    $contentPanel.Controls.Clear()

    # Membuat panel penampung khusus untuk halaman Dashboard
    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true # Memastikan scroll nyala agar kartu di bawah tetap bisa dilihat

    # ---------------------------------------------------------------------
    # 2. PEMBUATAN ELEMEN: SPANDUK SELAMAT DATANG (WELCOME BANNER)
    # ---------------------------------------------------------------------
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(750, 110) # Lebar 750px, Tinggi 110px
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30) # Jarak 30px dari kiri dan atas
    $bannerCard.BackColor = $cP.Header 
    
    # --- LOGIKA DESAIN: Membuat Sudut Melengkung (Rounded Corners) ---
    $banRadius = 20 # Tingkat kelengkungan
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    # Menggambar 4 busur (arc) di keempat sudut kotak banner
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90) # Kiri Atas
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90) # Kanan Atas
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90) # Kanan Bawah
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90) # Kiri Bawah
    $banPath.CloseAllFigures() # Menutup garis agar menyatu menjadi kotak utuh
    # Menerapkan bentuk hasil potongan tersebut ke panel banner
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    # --- Teks Judul Banner ---
    $lblWelcome = New-Object System.Windows.Forms.Label
    $lblWelcome.Text = "Pusat Kendali Waroeng Tools"
    $lblWelcome.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblWelcome.ForeColor = [System.Drawing.Color]::White
    $lblWelcome.AutoSize = $true
    $lblWelcome.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblWelcome)

    # --- Teks Sub-Judul Banner (Profil User) ---
    $lblSubWelcome = New-Object System.Windows.Forms.Label
    $lblSubWelcome.Text = "Pengguna: $($env:USERNAME) di $($env:COMPUTERNAME)"
    $lblSubWelcome.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubWelcome.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubWelcome.AutoSize = $true
    $lblSubWelcome.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubWelcome)

    $pnlMain.Controls.Add($bannerCard)

    # ---------------------------------------------------------------------
    # 3. PEMBUATAN ELEMEN: GRID KONTAINER (TEMPAT KARTU SPESIFIKASI)
    # ---------------------------------------------------------------------
    # Menggunakan FlowLayoutPanel: Panel pintar yang otomatis menyusun isinya secara berurutan
    $flpCards = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpCards.Location = New-Object System.Drawing.Point(25, 160)
    
    # --- LOGIKA RESPONSIVITAS KARTU ---
    # Membatasi lebar maksimal panel agar 1 baris hanya muat 2 kartu.
    # Jika ada kartu ke-3, ia akan dipaksa turun ke baris bawah.
    $flpCards.MaximumSize = New-Object System.Drawing.Size(770, 0)
    $flpCards.Size = New-Object System.Drawing.Size(770, 0)
    $flpCards.AutoSize = $true
    $flpCards.AutoSizeMode = "GrowAndShrink" # Tinggi panel akan bertambah otomatis mengikuti jumlah kartu
    $flpCards.AutoScroll = $false 
    $flpCards.WrapContents = $true # KUNCI: Fitur yang membungkus/memaksa isi turun ke baris baru
    $flpCards.FlowDirection = "LeftToRight" # Arah penyusunan: dari kiri ke kanan

    # ---------------------------------------------------------------------
    # 4. FUNGSI INTERNAL: TEMPLATE PEMBUAT KARTU SPESIFIKASI (FIXED EVENT BINDING)
    # ---------------------------------------------------------------------
    function Create-SpecCard ($Title, $MainValue, $SubValue, $RawData = $null) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(360, 120) 
        $card.Margin = New-Object System.Windows.Forms.Padding(5, 5, 15, 15)
        $card.BackColor = $cP.Card
        
        # Simpan warna tema asli di memori properti 'Tag' milik kartu
        # Agar saat mouse keluar, kita tahu warna apa yang harus dikembalikan
        $card.Tag = @{
            NormalColor = $cP.Card
            HoverColor  = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(55, 55, 60) } else { [System.Drawing.Color]::FromArgb(240, 245, 255) }
            DataRaw     = $RawData
            ThemeColors = $cP
        }

        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = $cP.Accent
        $lTitle.Location = New-Object System.Drawing.Point(15, 12)
        $lTitle.AutoSize = $true
        $card.Controls.Add($lTitle)

        $lMain = New-Object System.Windows.Forms.Label
        $lMain.Text = $MainValue
        $lMain.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $lMain.ForeColor = $cP.Text
        $lMain.Location = New-Object System.Drawing.Point(15, 35)
        $lMain.AutoSize = $false
        $lMain.Size = New-Object System.Drawing.Size(330, 45)
        
        if ($Title -eq "PENYIMPANAN") {
            $lMain.AutoEllipsis = $true
        }
        $card.Controls.Add($lMain)

        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $SubValue
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(15, 82)
        $lSub.AutoSize = $false
        $lSub.Size = New-Object System.Drawing.Size(330, 30)
        $card.Controls.Add($lSub)

        # --- LOGIKA INTERAKTIF (TANPA CLOSURE) ---
        if ($Title -eq "PENYIMPANAN" -and $RawData -and $RawData.Count -gt 2) {
            $icoExpand = New-Object System.Windows.Forms.Label
            $icoExpand.Text = [char]0xE710 
            $icoExpand.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 10, [System.Drawing.FontStyle]::Bold)
            $icoExpand.ForeColor = $cP.Accent
            $icoExpand.Location = New-Object System.Drawing.Point(330, 13)
            $icoExpand.AutoSize = $true
            $card.Controls.Add($icoExpand)

            $card.Cursor = "Hand"
            $lMain.Cursor = "Hand"
            $lSub.Cursor = "Hand"
            $icoExpand.Cursor = "Hand"

            # Event Hover (Ambil kontrol induk dan ubah warnanya berdasarkan data di Tag)
            $hoverEnter = {
                $ctrl = $this
                if ($ctrl -isnot [System.Windows.Forms.Panel]) { $ctrl = $ctrl.Parent }
                $ctrl.BackColor = $ctrl.Tag.HoverColor
            }
            
            $hoverLeave = {
                $ctrl = $this
                if ($ctrl -isnot [System.Windows.Forms.Panel]) { $ctrl = $ctrl.Parent }
                $ctrl.BackColor = $ctrl.Tag.NormalColor
            }

            $card.Add_MouseEnter($hoverEnter); $lMain.Add_MouseEnter($hoverEnter); $lSub.Add_MouseEnter($hoverEnter)
            $card.Add_MouseLeave($hoverLeave); $lMain.Add_MouseLeave($hoverLeave); $lSub.Add_MouseLeave($hoverLeave)

            # Event Click (Ambil data array dari Tag, lalu panggil fungsi Global)
            $actionClick = {
                $ctrl = $this
                if ($ctrl -isnot [System.Windows.Forms.Panel]) { $ctrl = $ctrl.Parent }
                
                $dataTarget = $ctrl.Tag.DataRaw
                $warnaTema  = $ctrl.Tag.ThemeColors
                
                # Memanggil fungsi Show-StorageDetails
                Show-StorageDetails -StorageList $dataTarget -ThemeColors $warnaTema
            }

            $card.Add_Click($actionClick)
            $lMain.Add_Click($actionClick)
            $lSub.Add_Click($actionClick)
            $icoExpand.Add_Click($actionClick)
        }

        return $card
    }

    # ---------------------------------------------------------------------
    # 5. EKSEKUSI PEMBUATAN KARTU (DATA INJECTION)
    # ---------------------------------------------------------------------
    if ($data) {
        # Jika berhasil menarik data dari komputer, masukkan ke template kartu (Create-SpecCard)
        # Format: (Fungsi "Judul" $DataUtama $DataSub)
        $flpCards.Controls.Add((Create-SpecCard "SISTEM OPERASI" $data.OSVer $data.Model))
        $flpCards.Controls.Add((Create-SpecCard "PROCESSOR (CPU)" $data.CPU ""))
        
        # Merakit teks Sub-RAM secara manual sebelum dimasukkan ke fungsi
        $ramSub = "$($data.RAM_Speed) | Slots: $($data.RAM_Slots)"
        $flpCards.Controls.Add((Create-SpecCard "MEMORY (RAM)" $data.RAM_Main $ramSub))
        
        $flpCards.Controls.Add((Create-SpecCard "GRAPHICS (GPU)" $data.GPU ""))
        
        # --- MODIFIKASI KARTU PENYIMPANAN ---
        if ($data.Storage) {
            $jmlDrive = $data.Storage.Count
            
            # Jika drive hanya ada 1 ATAU 2, gabungkan teksnya langsung (Tidak ada efek pop-up)
            if ($jmlDrive -le 2) {
                # Menggunakan pemisah " | " agar jika ada 2 drive tampilannya lebih rapi
                $diskStr = $data.Storage -join " | "
                $diskSub = "Physical Drive"
                
                # Kirim parameter data mentah sebagai $null agar kartu tidak bisa diklik
                $flpCards.Controls.Add((Create-SpecCard "PENYIMPANAN" $diskStr $diskSub $null))
            } 
            # Jika drive LEBIH DARI 2 (3, 4, 5, dst), aktifkan mode pop-up interaktif
            else {
                $diskStr = "Terdapat $jmlDrive Penyimpanan Fisik"
                $diskSub = "Klik kartu untuk melihat detail ➜"
                
                # Kirim data $data.Storage untuk diproses oleh pop-up
                $flpCards.Controls.Add((Create-SpecCard "PENYIMPANAN" $diskStr $diskSub $data.Storage))
            }
        } else {
            $flpCards.Controls.Add((Create-SpecCard "PENYIMPANAN" "No Disk Found" "Physical Drive" $null))
        }
        
        $flpCards.Controls.Add((Create-SpecCard "STATUS KEAMANAN" $data.AV "AntiVirus Product"))
    } else {
        # Jika sistem gagal membaca data hardware, tampilkan pesan error
        $lblErr = New-Object System.Windows.Forms.Label
        $lblErr.Text = "Gagal mengambil informasi sistem."
        $lblErr.ForeColor = [System.Drawing.Color]::Red
        $lblErr.AutoSize = $true
        $flpCards.Controls.Add($lblErr)
    }

    # Merakit semua bagian ke dalam panel utama (Main Panel)
    $pnlMain.Controls.Add($flpCards)
    $contentPanel.Controls.Add($pnlMain)
    
    # Catatan terminal kecil bahwa proses render grafis telah berhasil
    Write-Host "Render Pusat Kendali Berhasil"
}

# -------------------------------------------------------------------------
# FUNGSI PLACEHOLDER (Halaman Sementara)
# -------------------------------------------------------------------------
# Fungsi ini digunakan untuk mengisi halaman menu lain (selain Dashboard) yang isinya belum selesai dibuat
function Render-Placeholder ($Title) {
    $contentPanel.Controls.Clear()
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "$Title - Module Is Under Construction..."
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 24)
    $lbl.ForeColor = [System.Drawing.Color]::Gray
    $lbl.AutoSize = $true
    $lbl.Location = New-Object System.Drawing.Point(40, 40)
    $contentPanel.Controls.Add($lbl)
}
# =========================================================================

# =========================================================================
# FASE 12: MODUL SOFTWARE CENTER (PACKAGE MANAGER ENGINE)
# =========================================================================

# --- DATABASE APLIKASI & FITUR (DIPERLUAS & SUPER LENGKAP) ---
$global:SoftwareDatabase = @(
    # ======================================================================
    # 1. WINDOWS APPS & FEATURES (Tab: Windows)
    # ======================================================================
    
    # --- Windows Apps (Aplikasi Bawaan Windows / Bloatware) ---
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Alarms & Clock"; ID="Microsoft.WindowsAlarms_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Bing Search"; ID="Microsoft.BingSearch_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Calculator"; ID="Microsoft.WindowsCalculator_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Camera"; ID="Microsoft.WindowsCamera_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Dev Home"; ID="Microsoft.Windows.DevHome_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Get Help"; ID="Microsoft.GetHelp_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Mail and Calendar"; ID="microsoft.windowscommunicationsapps_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Media Player"; ID="Microsoft.ZuneMusic_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Microsoft Edge"; ID="Microsoft.MicrosoftEdge.Stable_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Microsoft Store"; ID="Microsoft.WindowsStore_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Movies & TV"; ID="Microsoft.ZuneVideo_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Photos"; ID="Microsoft.Windows.Photos_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Snipping Tool"; ID="Microsoft.ScreenSketch_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Sound Recorder"; ID="Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Sticky Notes"; ID="Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="3D Viewer"; ID="Microsoft.Microsoft3DViewer_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Clipchamp"; ID="Clipchamp.Clipchamp_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Copilot"; ID="Microsoft.Copilot_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Cortana"; ID="Microsoft.549981C3F5F10_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Feedback Hub"; ID="Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Maps"; ID="Microsoft.WindowsMaps_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Microsoft Family Safety"; ID="Microsoft.FamilySafety_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Microsoft News"; ID="Microsoft.BingNews_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Microsoft Teams"; ID="MicrosoftTeams_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Mixed Reality Portal"; ID="Microsoft.MixedReality.Portal_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="MS 365 Copilot"; ID="Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="MSN Weather"; ID="Microsoft.BingWeather_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Notepad"; ID="Microsoft.WindowsNotepad_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="OneDrive"; ID="Microsoft.OneDriveSync_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="OneNote"; ID="Microsoft.Office.OneNote_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Outlook for Windows"; ID="Microsoft.OutlookForWindows_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Paint"; ID="Microsoft.Paint_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Paint 3D"; ID="Microsoft.MSPaint_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="People"; ID="Microsoft.People_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Phone Link"; ID="Microsoft.YourPhone_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Power Automate"; ID="Microsoft.PowerAutomateDesktop_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Quick Assist"; ID="MicrosoftCorporationII.QuickAssist_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Skype"; ID="Microsoft.SkypeApp_kzf8qxf38zg5c"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Solitaire Collection"; ID="Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Terminal"; ID="Microsoft.WindowsTerminal_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Tips"; ID="Microsoft.Getstarted_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="To Do"; ID="Microsoft.Todos_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Xbox"; ID="Microsoft.GamingApp_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Xbox Game Bar"; ID="Microsoft.XboxGamingOverlay_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Xbox Game Bar Plugin"; ID="Microsoft.XboxGameOverlay_8wekyb3d8bbwe"; Type="UWP" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Apps"; Name="Xbox Identity Provider"; ID="Microsoft.XboxIdentityProvider_8wekyb3d8bbwe"; Type="UWP" }

    # --- Windows Capabilities ---
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Notepad (Legacy)"; ID="Microsoft.Windows.Notepad~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Windows Media Player"; ID="Media.WindowsMediaPlayer~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="WordPad"; ID="Microsoft.Windows.WordPad~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Internet Explorer"; ID="Browser.InternetExplorer~~~~0.0.11.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="OpenSSH Client"; ID="OpenSSH.Client~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="OpenSSH Server"; ID="OpenSSH.Server~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Paint (Legacy)"; ID="Microsoft.Windows.MSPaint~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="PowerShell ISE"; ID="Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Quick Assist (Legacy)"; ID="App.Support.QuickAssist~~~~0.0.1.0"; Type="Capability" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Capabilities"; Name="Steps Recorder"; ID="App.StepsRecorder~~~~0.0.1.0"; Type="Capability" }

    # --- Windows Optional Features ---
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name=".NET Framework 3.5"; ID="NetFx3"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Hyper-V"; ID="Microsoft-Hyper-V-All"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Hyper-V Management Tools"; ID="Microsoft-Hyper-V-Tools-All"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Recall"; ID="Recall"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Subsystem for Linux"; ID="Microsoft-Windows-Subsystem-Linux"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Windows Hypervisor Platform"; ID="HypervisorPlatform"; Type="Feature" }
    [PSCustomObject]@{ Tab="Windows"; Category="Windows Optional Features"; Name="Windows Sandbox"; ID="Containers-DisposableClientVM"; Type="Feature" }

    # ======================================================================
    # 2. THIRD PARTY SOFTWARE (Tab: ThirdParty)
    # ======================================================================
    
    # --- Browser ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Microsoft Edge WebView2"; Winget="Microsoft.EdgeWebView2Runtime"; Choco="webview2-runtime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Google Chrome"; Winget="Google.Chrome"; Choco="googlechrome"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Mozilla Firefox"; Winget="Mozilla.Firefox"; Choco="firefox"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Brave"; Winget="Brave.Brave"; Choco="brave"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Opera"; Winget="Opera.Opera"; Choco="opera"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Opera GX"; Winget="Opera.OperaGX"; Choco="opera-gx"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Arc Browser"; Winget="TheBrowserCompany.Arc"; Choco="arc"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Tor Browser"; Winget="TorProject.TorBrowser"; Choco="tor-browser"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Vivaldi"; Winget="VivaldiTechnologies.Vivaldi"; Choco="vivaldi"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Waterfox"; Winget="Waterfox.Waterfox"; Choco="waterfox"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Zen Browser"; Winget="Zen-Team.Zen-Browser"; Choco="zen-browser --pre"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Thorium"; Winget="Alex313031.Thorium"; Choco="thorium"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="LibreWolf"; Winget="LibreWolf.LibreWolf"; Choco="librewolf"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="DuckDuckGo"; Winget="DuckDuckGo.Desktop"; Choco="duckduckgo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Falkon"; Winget="KDE.Falkon"; Choco="falkon"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Pale Moon"; Winget="MoonchildProductions.PaleMoon"; Choco="palemoon"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Mullvad Browser"; Winget="MullvadVPN.MullvadBrowser"; Choco="mullvad-browser"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Floorp"; Winget="Ablaze.Floorp"; Choco="floorp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Ungoogled Chromium"; Winget="eloston.ungoogled-chromium"; Choco="ungoogled-chromium"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Mercury"; Winget="Alex313031.Mercury"; Choco="mercury"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="Maxthon Browser"; Winget="Maxthon.Maxthon"; Choco="maxthon"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Browser"; Name="DuckDuckGo"; Winget="DuckDuckGo.DesktopBrowser"; Choco="duckduckgo"; Type="App" }

    # --- Compression ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Compression"; Name="7-Zip"; Winget="7zip.7zip"; Choco="7zip"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Compression"; Name="WinRAR"; Winget="RARLab.WinRAR"; Choco="winrar"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Compression"; Name="PeaZip"; Winget="GiorgioTani.PeaZip"; Choco="peazip"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Compression"; Name="NanaZip"; Winget="M2Team.NanaZip"; Choco="nanazip"; Type="App" }

    # --- Communications & Messaging ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Discord"; Winget="Discord.Discord"; Choco="discord"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Telegram"; Winget="Telegram.TelegramDesktop"; Choco="telegram"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Zoom"; Winget="Zoom.Zoom"; Choco="zoom"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Slack"; Winget="SlackTechnologies.Slack"; Choco="slack"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Teams"; Winget="Microsoft.Teams"; Choco="microsoft-teams"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Signal"; Winget="Signal.Signal"; Choco="signal"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Thunderbird"; Winget="Mozilla.Thunderbird"; Choco="thunderbird"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Viber"; Winget="Viber.Viber"; Choco="viber"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Element"; Winget="Element.Element"; Choco="element"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Beeper"; Winget="Beeper.Beeper"; Choco="beeper"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Jami"; Winget="Savoir-faireLinux.Jami"; Choco="jami"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="qTox"; Winget="qTox.qTox"; Choco="qtox"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Vesktop"; Winget="Vencord.Vesktop"; Choco="vesktop"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Zulip"; Winget="Zulip.Zulip"; Choco="zulip"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Betterbird"; Winget="Betterbird.Betterbird"; Choco="betterbird"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Ferdium"; Winget="Ferdium.Ferdium"; Choco="ferdium"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Linphone"; Winget="BelledonneCommunications.Linphone"; Choco="linphone"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Revolt"; Winget="Revolt.Revolt"; Choco="revolt"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Chatterino"; Winget="Chatterino.Chatterino"; Choco="chatterino"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Hexchat"; Winget="HexChat.HexChat"; Choco="hexchat"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Session"; Winget="Oxen.Session"; Choco="session"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Unigram"; Winget="Unigram.Unigram"; Choco="unigram"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Pidgin"; Winget="Pidgin.Pidgin"; Choco="pidgin"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Proton Mail"; Winget="Proton.ProtonMail"; Choco="protonmail"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Trillian"; Winget="CeruleanStudios.Trillian"; Choco="trillian"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Unigram"; Winget="Unigram.Unigram"; Choco="unigram"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="WhatsApp"; Winget="WhatsApp.WhatsApp"; Choco="whatsapp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Zoom"; Winget="Zoom.Zoom"; Choco="zoom"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Communications & Messaging"; Name="Zulip"; Winget="Zulip.Zulip"; Choco="zulip"; Type="App" }

    # --- Development ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="VS Code"; Winget="Microsoft.VisualStudioCode"; Choco="vscode"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Visual Studio 2022"; Winget="Microsoft.VisualStudio.2022.Community"; Choco="visualstudio2022community"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Notepad++"; Winget="Notepad++.Notepad++"; Choco="notepadplusplus"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Git"; Winget="Git.Git"; Choco="git"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="GitHub Desktop"; Winget="GitHub.GitHubDesktop"; Choco="github-desktop"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="GitHub CLI"; Winget="GitHub.cli"; Choco="gh"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Python 3"; Winget="Python.Python.3.12"; Choco="python"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="NodeJS LTS"; Winget="OpenJS.NodeJS.LTS"; Choco="nodejs-lts"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Yarn"; Winget="Yarn.Yarn"; Choco="yarn"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Docker Desktop"; Winget="Docker.DockerDesktop"; Choco="docker-desktop"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Postman"; Winget="Postman.Postman"; Choco="postman"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Anaconda"; Winget="Anaconda.Anaconda3"; Choco="anaconda3"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Rust"; Winget="Rustlang.Rustup"; Choco="rust"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Go"; Winget="GoLang.Go"; Choco="golang"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Neovim"; Winget="Neovim.Neovim"; Choco="neovim"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Sublime Text"; Winget="SublimeHQ.SublimeText.4"; Choco="sublimetext4"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="WinSCP"; Winget="WinSCP.WinSCP"; Choco="winscp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="WinMerge"; Winget="WinMerge.WinMerge"; Choco="winmerge"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="PuTTY"; Winget="PuTTY.PuTTY"; Choco="putty"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Eclipse"; Winget="EclipseFoundation.EclipseJava"; Choco="eclipse"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Meld"; Winget="yousseb.Meld"; Choco="meld"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Aegisub"; Winget="Aegisub.Aegisub"; Choco="aegisub"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="DaxStudio"; Winget="DaxStudio.DaxStudio"; Choco="daxstudio"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Amazon Corretto 8 (LTS)"; Winget="Amazon.Corretto.8"; Choco="corretto8jre"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Amazon Corretto 11 (LTS)"; Winget="Amazon.Corretto.11"; Choco="corretto11jre"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Amazon Corretto 17 (LTS)"; Winget="Amazon.Corretto.17"; Choco="corretto17jre"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Amazon Corretto 21 (LTS)"; Winget="Amazon.Corretto.21"; Choco="corretto21jdk"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Amazon Corretto 25 (LTS)"; Winget="Amazon.Corretto.25"; Choco="corretto25jdk"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="JetBrains Toolbox"; Winget="JetBrains.Toolbox"; Choco="jetbrains-toolbox"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Pixi"; Winget="prefix-dev.pixi"; Choco="pixi"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Python Version Manager (pyenv)"; Winget="pyenv-win.pyenv-win"; Choco="pyenv-win"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Sublime Merge"; Winget="SublimeHQ.SublimeMerge"; Choco="sublimemerge"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Eclipse Temurin"; Winget="EclipseAdoptium.Temurin.21.JDK"; Choco="temurin21"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Git Butler"; Winget="GitButler.GitButler"; Choco="gitbutler"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Gitify"; Winget="manosim.Gitify"; Choco="gitify"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Helix"; Winget="Helix.Helix"; Choco="helix"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Lazygit"; Winget="JesseDuffield.lazygit"; Choco="lazygit"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="NodeJS (Current)"; Winget="OpenJS.NodeJS"; Choco="nodejs"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Oh My Posh"; Winget="JanDeDobbeleer.OhMyPosh"; Choco="oh-my-posh"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Thonny Python IDE"; Winget="Thonny.Thonny"; Choco="thonny"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Zed"; Winget="Zed.Zed"; Choco="zed"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Clink"; Winget="chrisant996.Clink"; Choco="clink"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Fast Node Manager"; Winget="Schniz.fnm"; Choco="fnm"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Git Extensions"; Winget="GitExtensionsTeam.GitExtensions"; Choco="gitextensions"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="GitKraken Client"; Winget="Axosoft.GitKraken"; Choco="gitkraken"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="ImHex (Hex Editor)"; Winget="WerWolv.ImHex"; Choco="imhex"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Miniconda"; Winget="Anaconda.Miniconda3"; Choco="miniconda3"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Swift toolchain"; Winget="Apple.Swift"; Choco="swift"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Unity Hub"; Winget="Unity.UnityHub"; Choco="unity-hub"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="VS Codium"; Winget="VSCodium.VSCodium"; Choco="vscodium"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="CMake"; Winget="Kitware.CMake"; Choco="cmake"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Fork"; Winget="DanPristupov.Fork"; Choco="fork"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Godot Engine"; Winget="GodotEngine.GodotEngine"; Choco="godot"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Code With Mu (Mu Editor)"; Winget="CodeWithMu.Mu"; Choco="mu-editor"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Node Version Manager"; Winget="CoreyButler.NVMforWindows"; Choco="nvm"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Pulsar"; Winget="pulsar-edit.pulsar"; Choco="pulsar"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Starship (Shell Prompt)"; Winget="Starship.Starship"; Choco="starship"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="System Informer"; Winget="winsiderss.systeminformer"; Choco="systeminformer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Vagrant"; Winget="HashiCorp.Vagrant"; Choco="vagrant"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Development"; Name="Wezterm"; Winget="wez.wezterm"; Choco="wezterm"; Type="App" }

    # --- Document ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="OpenOffice"; Winget="Apache.OpenOffice"; Choco="openoffice"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Evernote"; Winget="Evernote.Evernote"; Choco="evernote"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Okular"; Winget="KDE.Okular"; Choco="okular"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Adobe Acrobat Reader"; Winget="Adobe.Acrobat.Reader.64-bit"; Choco="adobereader"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="CherryTree"; Winget="giuspen.cherrytree"; Choco="cherrytree"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="PDF24 Creator"; Winget="GeekSoftware.PDF24Creator"; Choco="pdf24"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Calibre"; Winget="KovidGoyal.Calibre"; Choco="calibre"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Joplin (FOSS Notes)"; Winget="LaurentCozic.Joplin"; Choco="joplin"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="massCode (Snippet Manager)"; Winget="AntonReshetov.massCode"; Choco="masscode"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Simplenote"; Winget="Automattic.Simplenote"; Choco="simplenote"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Xournal++"; Winget="XournalPlusPlus.XournalPlusPlus"; Choco="xournalplusplus"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Zotero"; Winget="Zotero.Zotero"; Choco="zotero"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="AFFiNE"; Winget="AFFiNE.AFFiNE"; Choco="affine"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Foxit PDF Editor"; Winget="Foxit.FoxitPDFEditor"; Choco="foxit-phantompdf"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="NAPS2 (Document Scanner)"; Winget="Cyanfish.NAPS2"; Choco="naps2"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="PDFgear"; Winget="PDFgear.PDFgear"; Choco="pdfgear"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Zim Desktop Wiki"; Winget="jaapkarssenberg.ZimDesktopWiki"; Choco="zim"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Anki"; Winget="Anki.Anki"; Choco="anki"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Foxit PDF Reader"; Winget="Foxit.FoxitReader"; Choco="foxitreader"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Logseq"; Winget="Logseq.Logseq"; Choco="logseq"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="ONLYOffice Desktop"; Winget="ONLYOFFICE.DesktopEditors"; Choco="onlyoffice"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="PDFsam Basic"; Winget="PDFsam.PDFsamBasic"; Choco="pdfsam"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Anki"; Winget="Anki.Anki"; Choco="anki"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="LibreOffice"; Winget="TheDocumentFoundation.LibreOffice"; Choco="libreoffice"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Logseq"; Winget="Logseq.Logseq"; Choco="logseq"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="NAPS2 (Scanner)"; Winget="BenOlden-Cooligan.NAPS2"; Choco="naps2"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Notepad++"; Winget="Notepad++.Notepad++"; Choco="notepadplusplus"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Obsidian"; Winget="Obsidian.Obsidian"; Choco="obsidian"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="PDFsam Basic"; Winget="AndreaVacondio.PDFsamBasic"; Choco="pdfsam"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="Sumatra PDF"; Winget="SumatraPDF.SumatraPDF"; Choco="sumatrapdf"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Document"; Name="WinMerge"; Winget="WinMerge.WinMerge"; Choco="winmerge"; Type="App" }

    # --- Utilities & System Tools ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="PowerToys"; Winget="Microsoft.PowerToys"; Choco="powertoys"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="HWiNFO"; Winget="REALiX.HWiNFO"; Choco="hwinfo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Revo Uninstaller Free"; Winget="RevoUninstaller.RevoUninstaller"; Choco="revo-uninstaller"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="AnyDesk"; Winget="AnyDeskSoftwareGmbH.AnyDesk"; Choco="anydesk"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Everything (Search)"; Winget="voidtools.Everything"; Choco="everything"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Bitwarden"; Winget="Bitwarden.Bitwarden"; Choco="bitwarden"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Oracle VirtualBox"; Winget="Oracle.VirtualBox"; Choco="virtualbox"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Bulk Crap Uninstaller"; Winget="Klocman.BulkCrapUninstaller"; Choco="bulk-crap-uninstaller"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="WizTree"; Winget="AntibodySoftware.WizTree"; Choco="wiztree"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Crystal Disk Info"; Winget="CrystalDewWorld.CrystalDiskInfo"; Choco="crystaldiskinfo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="AutoHotkey"; Winget="AutoHotkey.AutoHotkey"; Choco="autohotkey"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="qBittorrent"; Winget="qBittorrent.qBittorrent"; Choco="qbittorrent"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="JDownloader 2"; Winget="JDownloader.JDownloader"; Choco="jdownloader"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="KeePassXC"; Winget="KeePassXCTeam.KeePassXC"; Choco="keepassxc"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Bitwarden"; Winget="Bitwarden.Bitwarden"; Choco="bitwarden"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="LocalSend"; Winget="LocalSend.LocalSend"; Choco="localsend"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="Process Lasso"; Winget="Bitsum.ProcessLasso"; Choco="processlasso"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Utilities & System Tools"; Name="UniGetUI"; Winget="marticliment.UniGetUI"; Choco="unigetui"; Type="App" }

    # --- Games ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Cemu"; Winget="Cemu.Cemu"; Choco="cemu"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Emulation Station"; Winget="EmulationStation.EmulationStationDesktopEdition"; Choco="emulationstation"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Moonlight/GameStream Client"; Winget="MoonlightGameStreamingProject.Moonlight"; Choco="moonlight-qt"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="PS Remote Play"; Winget="Sony.PlayStationRemotePlay"; Choco="psremoteplay"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Sunshine/GameStream Server"; Winget="LizardByte.Sunshine"; Choco="sunshine"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Virtual Desktop Streamer"; Winget="GuyGodin.VirtualDesktopStreamer"; Choco="virtual-desktop-streamer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Clone Hero"; Winget="srylain.CloneHero"; Choco="clonehero"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Heroic Games Launcher"; Winget="HeroicGamesLauncher.HeroicGamesLauncher"; Choco="heroic"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Playnite"; Winget="JosefNemec.Playnite"; Choco="playnite"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="SideQuestVR"; Winget="SideQuest.SideQuest"; Choco="sidequest"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="TCNO Account Switcher"; Winget="TCNOco.TcNoAccountSwitcher"; Choco="tcno-account-switcher"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="XEMU"; Winget="xemu.xemu"; Choco="xemu"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="EA App"; Winget="ElectronicArts.EADesktop"; Choco="ea-app"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="GeForce NOW"; Winget="Nvidia.GeForceNow"; Choco="geforcenow"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Itch.io"; Winget="itchio.itch"; Choco="itch"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Prism Launcher"; Winget="PrismLauncher.PrismLauncher"; Choco="prismlauncher"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Epic Games Launcher"; Winget="EpicGames.EpicGamesLauncher"; Choco="epicgameslauncher"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Steam"; Winget="Valve.Steam"; Choco="steam"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Sunshine GameStream"; Winget="LizardByte.Sunshine"; Choco="sunshine"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Games"; Name="Ubisoft Connect"; Winget="Ubisoft.Connect"; Choco="uplay"; Type="App" }

    # --- File & Disk Management ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="Rufus"; Winget="Rufus.Rufus"; Choco="rufus"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskInfo (Standard)"; Winget="CrystalDewWorld.CrystalDiskInfo"; Choco="crystaldiskinfo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskInfo (Shizuku Ed)"; Winget="CrystalDewWorld.CrystalDiskInfo.Shizuku"; Choco="crystaldiskinfo-shizuku"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskInfo (Kurei Ed)"; Winget="CrystalDewWorld.CrystalDiskInfo.KureiKei"; Choco="crystaldiskinfo-kureikei"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskInfo (Aoi Ed)"; Winget="CrystalDewWorld.CrystalDiskInfo.Aoi"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskMark (Standard)"; Winget="CrystalDewWorld.CrystalDiskMark"; Choco="crystaldiskmark"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskMark (Shizuku Ed)"; Winget="CrystalDewWorld.CrystalDiskMark.Shizuku"; Choco="crystaldiskmark-shizuku"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskMark (Kurei Ed)"; Winget="CrystalDewWorld.CrystalDiskMark.KureiKei"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="CrystalDiskMark (Aoi Ed)"; Winget="CrystalDewWorld.CrystalDiskMark.Aoi"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="TreeSize Free"; Winget="JAMSoftware.TreeSize.Free"; Choco="treesizefree"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="FileZilla Client"; Winget="TimKosse.FileZilla.Client"; Choco="filezilla"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="AOMEI Partition Assistant"; Winget="AOMEI.PartitionAssistant"; Choco="aomeipartitionassistant"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="AOMEI Backupper"; Winget="AOMEI.Backupper"; Choco="aomei-backupper"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="EaseUS Partition Master"; Winget="EaseUS.PartitionMaster"; Choco="easeuspartitionmaster"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="EaseUS Todo Backup"; Winget="EaseUS.TodoBackup"; Choco="easeustodobackup"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="MiniTool Partition Wizard"; Winget="MiniTool.PartitionWizard"; Choco="minitoolpartitionwizard"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="MiniTool ShadowMaker"; Winget="MiniTool.ShadowMaker"; Choco="minitoolshadowmaker"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="Macrium Reflect"; Winget="Macrium.Reflect"; Choco="macriumreflect"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="File & Disk Management"; Name="Veeam Agent for Windows"; Winget="Veeam.Agent.Windows"; Choco="veeam-agent"; Type="App" }

    # --- Multimedia ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="AIMP"; Winget="AIMP.AIMP"; Choco="aimp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Audacity"; Winget="Audacity.Audacity"; Choco="audacity"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Blender (3D Graphics)"; Winget="BlenderFoundation.Blender"; Choco="blender"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="CapCut"; Winget="Bytedance.CapCut"; Choco="capcut"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Clementine"; Winget="Clementine.Clementine"; Choco="clementine"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="darktable"; Winget="darktable.darktable"; Choco="darktable"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="digiKam"; Winget="KDE.digiKam"; Choco="digikam"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="EarTrumpet (Audio)"; Winget="File-New-Project.EarTrumpet"; Choco="eartrumpet"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Equalizer APO"; Winget="jthedering.EqualizerAPO"; Choco="equalizerapo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="FFmpeg (full)"; Winget="Gyan.FFmpeg"; Choco="ffmpeg"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Fire Alpaca"; Winget="FireAlpaca.FireAlpaca"; Choco="firealpaca"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Flameshot (Screenshots)"; Winget="Flameshot.Flameshot"; Choco="flameshot"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="foobar2000"; Winget="PeterPawlowski.foobar2000"; Choco="foobar2000"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="fre:ac"; Winget="RobertKausch.freac"; Choco="freac"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="FreeCAD"; Winget="FreeCAD.FreeCAD"; Choco="freecad"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="FxSound"; Winget="FxSound.FxSound"; Choco="fxsound"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="GIMP (Image Editor)"; Winget="GIMP.GIMP"; Choco="gimp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="GOM Player"; Winget="GOMLab.GOMPlayer"; Choco="gom-player"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Greenshot (Screenshots)"; Winget="Greenshot.Greenshot"; Choco="greenshot"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="HandBrake"; Winget="HandBrake.HandBrake"; Choco="handbrake"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Harmonoid"; Winget="harmonoid.harmonoid"; Choco="harmonoid"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="ImageGlass (Image Viewer)"; Winget="ImageGlass.ImageGlass"; Choco="imageglass"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="ImgBurn"; Winget="LIGHTNINGUK.ImgBurn"; Choco="imgburn"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Inkscape"; Winget="Inkscape.Inkscape"; Choco="inkscape"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="VLC Media Player"; Winget="VideoLAN.VLC"; Choco="vlc"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="OBS Studio"; Winget="OBSProject.OBSStudio"; Choco="obs-studio"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="iTunes"; Winget="Apple.iTunes"; Choco="itunes"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Jellyfin Media Player"; Winget="Jellyfin.JellyfinMediaPlayer"; Choco="jellyfin-media-player"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Jellyfin Server"; Winget="Jellyfin.JellyfinServer"; Choco="jellyfin"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Kdenlive (Video Editor)"; Winget="KDE.Kdenlive"; Choco="kdenlive"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Kicad"; Winget="KiCad.KiCad"; Choco="kicad"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="K-Lite Codec Standard"; Winget="CodecGuide.K-LiteCodecPack.Standard"; Choco="k-litecodecpackstandard"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="K-Lite Codec Pack (Mega)"; Winget="CodecGuide.K-LiteCodecPack.Mega"; Choco="k-litecodecpackmega"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Kodi Media Center"; Winget="XBMCFoundation.Kodi"; Choco="kodi"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Krita (Image Editor)"; Winget="KDE.Krita"; Choco="krita"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Lightshot (Screenshots)"; Winget="Skillbrains.Lightshot"; Choco="lightshot"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Media Player Classic - Home Cine"; Winget="clsid2.mpc-hc"; Choco="mpc-hc"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="MediaInfo GUI"; Winget="MediaArea.MediaInfo.GUI"; Choco="mediainfo"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="MediaMonkey"; Winget="VentisMedia.MediaMonkey"; Choco="mediamonkey"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Modern Flyouts"; Winget="ModernFlyoutsCommunity.ModernFlyouts"; Choco="modernflyouts"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="MPC-BE"; Winget="MPC-BE.MPC-BE"; Choco="mpc-be"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Mp3tag (Audio Metadata)"; Winget="FlorianHeidenreich.Mp3tag"; Choco="mp3tag"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="MuseScore"; Winget="MuseScore.MuseScore"; Choco="musescore"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="MusicBee"; Winget="StevenMayall.MusicBee"; Choco="musicbee"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="NDI Tools"; Winget="NewTek.NDITools"; Choco="ndi-tools"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="nGlide (3dfx)"; Winget="ZeusSoftware.nGlide"; Choco="nglide"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Nomacs (Image viewer)"; Winget="nomacs.nomacs"; Choco="nomacs"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="OpenSCAD"; Winget="OpenSCAD.OpenSCAD"; Choco="openscad"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Paint.NET"; Winget="dotPDNLLC.paintdotnet"; Choco="paint.net"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Plex Desktop"; Winget="Plex.Plex"; Choco="plex"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Plex Media Server"; Winget="Plex.PlexMediaServer"; Choco="plexmediaserver"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Policy Plus"; Winget="Fleex255.PolicyPlus"; Choco="policyplus"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="PotPlayer"; Winget="Daum.PotPlayer"; Choco="potplayer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="QGIS"; Winget="OSGeo.QGIS"; Choco="qgis"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="ShareX (Screenshots)"; Winget="ShareX.ShareX"; Choco="sharex"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Shotcut"; Winget="Meltytech.Shotcut"; Choco="shotcut"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="SMPlayer"; Winget="SMPlayer.SMPlayer"; Choco="smplayer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Spotify"; Winget="Spotify.Spotify"; Choco="spotify"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Strawberry (Music Player)"; Winget="strawberrymusicplayer.strawberry"; Choco="strawberry"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Streamlabs Desktop"; Winget="Streamlabs.StreamlabsDesktop"; Choco="streamlabs-obs"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Stremio"; Winget="Stremio.Stremio"; Choco="stremio"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Subtitle Edit"; Winget="Nikse.SubtitleEdit"; Choco="subtitleedit"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="TagScanner"; Winget="SergeySerkov.TagScanner"; Choco="tagscanner"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Tidal"; Winget="TIDALMusicAS.TIDAL"; Choco="tidal"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Videomass"; Winget="Jeansidharta.Videomass"; Choco="videomass"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Voicemeeter (Audio)"; Winget="VB-Audio.Voicemeeter"; Choco="voicemeeter"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Voicemeeter Potato"; Winget="VB-Audio.Voicemeeter.Potato"; Choco="voicemeeter-potato"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Volume2"; Winget="irzyxa.Volume2"; Choco="volume2"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Multimedia"; Name="Yt-dlp"; Winget="yt-dlp.yt-dlp"; Choco="yt-dlp"; Type="App" }

    # --- Remote Access ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="AnyDesk"; Winget="AnyDeskSoftwareGmbH.AnyDesk"; Choco="anydesk"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="Chrome Remote Desktop"; Winget="Google.ChromeRemoteDesktop"; Choco="chrome-remote-desktop-host"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="Deskflow"; Winget="Deskflow.Deskflow"; Choco="deskflow"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="Input Leap"; Winget="InputLeap.InputLeap"; Choco="inputleap"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="Parsec"; Winget="Parsec.Parsec"; Choco="parsec"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="RealVNC Server"; Winget="RealVNC.VNCServer"; Choco="realvnc"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="RealVNC Viewer"; Winget="RealVNC.VNCViewer"; Choco="vnc-viewer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="TeamViewer 15"; Winget="TeamViewer.TeamViewer"; Choco="teamviewer"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Remote Access"; Name="UltraViewer"; Winget="DucFabulous.UltraViewer"; Choco="ultraviewer"; Type="App" }

    # --- Network ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Nmap"; Winget="Insecure.Nmap"; Choco="nmap"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Tailscale"; Winget="Tailscale.Tailscale"; Choco="tailscale"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Advanced IP Scanner"; Winget="Famatech.AdvancedIPScanner"; Choco="advanced-ip-scanner"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Angry IP Scanner"; Winget="AngryIPScanner.AngryIPScanner"; Choco="angryip"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="EFI Boot Editor"; Winget="MiroKaku.EFIBootEditor"; Choco="efibooteditor"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="HeidiSQL"; Winget="HeidiSQL.HeidiSQL"; Choco="heidisql"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="mRemoteNG"; Winget="mRemoteNG.mRemoteNG"; Choco="mremoteng"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Mullvad VPN"; Winget="MullvadVPN.MullvadVPN"; Choco="mullvadvpn"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="NetBird"; Winget="NetBird.NetBird"; Choco="netbird"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Nmap"; Winget="Insecure.Nmap"; Choco="nmap"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="OpenVPN Connect"; Winget="OpenVPNTechnologies.OpenVPNConnect"; Choco="openvpn"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Portmaster"; Winget="Safing.Portmaster"; Choco="portmaster"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="PuTTY"; Winget="PuTTY.PuTTY"; Choco="putty"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="RustDesk"; Winget="RustDesk.RustDesk"; Choco="rustdesk"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Simplewall"; Winget="henrypp.simplewall"; Choco="simplewall"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Ventoy"; Winget="ventoy.Ventoy"; Choco="ventoy"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="WinSCP"; Winget="WinSCP.WinSCP"; Choco="winscp"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="WireGuard"; Winget="WireGuard.WireGuard"; Choco="wireguard"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="Wireshark"; Winget="WiresharkFoundation.Wireshark"; Choco="wireshark"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Network & IT Tools"; Name="XPipe"; Winget="XPipe.XPipe"; Choco="xpipe"; Type="App" }

    # --- Privacy & Security ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="Malwarebytes"; Winget="Malwarebytes.Malwarebytes"; Choco="malwarebytes"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="Malwarebytes AdwCleaner"; Winget="Malwarebytes.AdwCleaner"; Choco="adwcleaner"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="Malwarebytes WFC"; Winget="Malwarebytes.WindowsFirewallControl"; Choco="binisoft-windows-firewall-control"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="OnionShare"; Winget="OnionShare.OnionShare"; Choco="onionshare"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="Sniffnet"; Winget="EugenioGallego.Sniffnet"; Choco="sniffnet"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="Teleguard"; Winget="Swisscows.TeleGuard"; Choco="teleguard"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Privacy & Security"; Name="O&O ShutUp10++"; Winget="O&OSoftware.O&OShutUp10++"; Choco="ooshutup10"; Type="App" }

    # --- Runtimes & Dependencies ---
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name=".NET Framework 4.8.1"; Winget="Microsoft.DotNet.Framework.DeveloperPack_4"; Choco="netfx-4.8.1"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="DirectX End-User Runtime"; Winget="Microsoft.DirectX"; Choco="directx"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Java Runtime Environment"; Winget="Oracle.JavaRuntimeEnvironment"; Choco="jre8"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Microsoft .NET Runtime 3.1"; Winget="Microsoft.DotNet.DesktopRuntime.3_1"; Choco="dotnetcore-desktopruntime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Microsoft .NET Runtime 5.0"; Winget="Microsoft.DotNet.DesktopRuntime.5_0"; Choco="dotnet-5.0-desktopruntime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Microsoft .NET Runtime 6.0"; Winget="Microsoft.DotNet.Runtime.6_0"; Choco="dotnet-6.0-runtime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Microsoft .NET Runtime 7.0"; Winget="Microsoft.DotNet.DesktopRuntime.7_0"; Choco="dotnet-7.0-desktopruntime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Microsoft .NET Runtime 8.0"; Winget="Microsoft.DotNet.Runtime.8_0"; Choco="dotnet-8.0-runtime"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2005 (x86)"; Winget="Microsoft.VCRedist.2005.x86"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2005 (x64)"; Winget="Microsoft.VCRedist.2005.x64"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2008 (x86)"; Winget="Microsoft.VCRedist.2008.x86"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2008 (x64)"; Winget="Microsoft.VCRedist.2008.x64"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2010 (x86)"; Winget="Microsoft.VCRedist.2010.x86"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2010 (x64)"; Winget="Microsoft.VCRedist.2010.x64"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2012 (x86)"; Winget="Microsoft.VCRedist.2012.x86"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2012 (x64)"; Winget="Microsoft.VCRedist.2012.x64"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2013 (x86)"; Winget="Microsoft.VCRedist.2013.x86"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2013 (x64)"; Winget="Microsoft.VCRedist.2013.x64"; Choco=""; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2015-2022 (x64)"; Winget="Microsoft.VCRedist.2015+.x64"; Choco="vcredist140"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2015-2022 (x86)"; Winget="Microsoft.VCRedist.2015+.x86"; Choco="vcredist-all"; Type="App" }
    [PSCustomObject]@{ Tab="ThirdParty"; Category="Runtimes & Dependencies"; Name="Visual C++ 2015-2022 (ARM64)"; Winget="Microsoft.VCRedist.2015+.arm64"; Choco=""; Type="App" }
)

# -------------------------------------------------------------------------
# FUNGSI 1: INISIALISASI & PERBAIKAN PACKAGE MANAGER (WINGET & CHOCO)
# -------------------------------------------------------------------------
function Action-InitPackageManagers {
    Write-Log "Action Triggered: User initiated Package Managers Initialization."
    
    # 1. Pop-up Konfirmasi: Memastikan user tidak tidak sengaja mengklik tombol
    $confirm = [System.Windows.Forms.MessageBox]::Show(
        "Apakah kamu ingin memeriksa, menginstal, atau memperbarui Package Manager (Chocolatey & Winget)?", 
        "Konfirmasi Init", "YesNo", "Question"
    )

    if ($confirm -eq "No") { 
        Write-Log "Process Cancelled: User aborted Package Managers Initialization."
        return 
    }

    Write-Log "Process Started: Launching PowerShell to check and update Winget and Chocolatey..."

    # 2. Pembuatan Skrip Pekerja (Worker Script)
    # Trik: Kita menulis perintah instalasi ke dalam teks, lalu menyimpannya sebagai file.
    # Tujuannya agar proses instalasi berjalan di jendela terminal baru, BUKAN di dalam aplikasi GUI kita,
    # sehingga aplikasi Waroeng Tools tidak mengalami "Not Responding" (Freeze) saat mengunduh.
    $scriptContent = @'
Add-Type -AssemblyName System.Windows.Forms
Write-Host "=== PACKAGE MANAGERS INITIALIZATION & UPDATE ===" -ForegroundColor Cyan

# Fungsi me-refresh variabel Environment agar perintah 'choco' langsung dikenali tanpa restart PC
function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

Write-Host "`n[1] Memeriksa Chocolatey..." -ForegroundColor Yellow
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Menginstal Chocolatey, mohon tunggu..." -ForegroundColor White
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Refresh-Path
    $status = "Instalasi Chocolatey SELESAI."
} else {
    Write-Host "Chocolatey sudah terinstal. Memperbarui..." -ForegroundColor Cyan
    choco upgrade chocolatey -y
    $status = "Update Chocolatey SELESAI."
}

Write-Host "`n[2] Memeriksa Winget..." -ForegroundColor Yellow
if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget tidak ditemukan! Membuka MS Store..." -ForegroundColor Red
    Start-Process "ms-windows-store://pdp/?ProductId=9nblggh4nns1"
} else {
    Write-Host "Winget sudah terinstal. Memperbarui..." -ForegroundColor Cyan
    winget upgrade --id Microsoft.AppInstaller -e --accept-package-agreements --accept-source-agreements
}

Write-Host "`n=== PROSES SELESAI ===" -ForegroundColor Cyan
[System.Windows.Forms.MessageBox]::Show("$status`n`nSistem mendeteksi perubahan Path. Harap RESTART aplikasi Waroeng Tools.", "Penting", "OK", "Warning")
'@

    # Menyimpan dan mengeksekusi skrip di atas dengan hak Administrator
    $tempScript = "$env:TEMP\InitPackageManagers.ps1"
    $scriptContent | Out-File -FilePath $tempScript -Encoding UTF8
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs

    [System.Windows.Forms.MessageBox]::Show("Proses sedang berjalan. Silakan cek jendela PowerShell yang muncul.", "Sedang Berjalan", "OK", "Information")
}

# -------------------------------------------------------------------------
# FUNGSI 2: MESIN EKSEKUSI UTAMA (INSTALL / UNINSTALL / UPGRADE)
# -------------------------------------------------------------------------
function Execute-SoftwareAction ($ActionType) {
    try {
        # 1. Mendeteksi mesin repositori mana yang dipilih oleh user di radio button
        $pkgManager = if ($global:rbChoco.Checked) { "Chocolatey" } else { "Winget" }
        Write-Log "Action Triggered: User initiated Software '$ActionType' operation via $pkgManager."
        
        # 2. Menyisir (Scanning) Seluruh Checkbox yang Dicentang
        $selectedIds = @()
        $allCheckboxes = @()
        
        # Mengumpulkan semua objek checkbox dari Tab Windows dan Tab ThirdParty
        if ($null -ne $global:pnlWinList) { $allCheckboxes += $global:pnlWinList.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } }
        if ($null -ne $global:pnlThirdList) { $allCheckboxes += $global:pnlThirdList.Controls | Where-Object { $_ -is [System.Windows.Forms.CheckBox] -and $_.Checked } }

        # Mengekstrak ID Aplikasi (dari properti .Tag) berdasarkan mesin yang dipilih
        foreach ($chk in $allCheckboxes) {
            if ($null -ne $chk.Tag) {
                if ($pkgManager -eq "Winget" -and $chk.Tag.Winget) {
                    $selectedIds += $chk.Tag.Winget       # Contoh ID Winget: Google.Chrome
                } elseif ($pkgManager -eq "Chocolatey" -and $chk.Tag.Choco) {
                    $selectedIds += $chk.Tag.Choco        # Contoh ID Choco: googlechrome
                }
            }
        }

        # 3. Validasi: Cegah proses jika tidak ada aplikasi yang valid untuk diinstal
        if ($selectedIds.Count -eq 0) {
            Write-Log "Process Aborted: No valid applications selected."
            [System.Windows.Forms.MessageBox]::Show("Silakan centang aplikasi atau pastikan aplikasi mendukung Package Manager ($pkgManager).", "Peringatan", "OK", "Warning")
            return
        }

        Write-Log "-> Selected Application(s) for ${ActionType}: $($selectedIds -join ', ')"

        # 4. Merakit Sintaks Perintah (Command Builder)
        $command = ""
        $idsString = $selectedIds -join " "

        if ($pkgManager -eq "Winget") {
            if ($ActionType -eq "Install") {
                # Argumen Winget wajib dipisah per baris agar tidak error jika menginstal banyak aplikasi sekaligus
                $cmdChunks = $selectedIds | ForEach-Object { "winget install --id $_ -e --accept-package-agreements --accept-source-agreements" }
                $command = $cmdChunks -join "`r`n" 
            } elseif ($ActionType -eq "Uninstall") {
                $cmdChunks = $selectedIds | ForEach-Object { "winget uninstall --id $_ -e" }
                $command = $cmdChunks -join "`r`n"
            }
        } else {
            # Argumen Chocolatey bisa digabung dalam 1 baris (contoh: choco install vlc chrome firefox -y)
            if ($ActionType -eq "Install") { $command = "choco install $idsString -y" } 
            elseif ($ActionType -eq "Uninstall") { $command = "choco uninstall $idsString -y" }
        }

        # 5. Eksekusi Perintah di Latar Belakang menggunakan Skrip Sementara (Temp Script)
        if ($command) {
            $psLines = @(
                "Write-Host '=== Memulai $ActionType via $pkgManager ===' -ForegroundColor Cyan",
                "Write-Host 'Mengeksekusi perintah...' -ForegroundColor Yellow`n",
                $command,
                "`nWrite-Host '=== PROSES SELESAI ===' -ForegroundColor Green",
                "Read-Host 'Tekan ENTER untuk menutup jendela ini...'"
            )
            
            $tempActionScript = "$env:TEMP\RunSoftwareAction.ps1"
            $psLines -join "`r`n" | Out-File -FilePath $tempActionScript -Encoding UTF8
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempActionScript`"" -Verb RunAs
        }
    } catch {
        # Tangkap error jika user menekan "NO" saat muncul UAC (User Account Control)
        Write-Log "Failed: UAC cancelled or system error. Details: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Proses dibatalkan atau terjadi kesalahan sistem.", "Info", "OK", "Information")
    }
}

# --- RENDER UI SOFTWARE CENTER ---
# =========================================================================
# FUNGSI 3: PEMBUATAN ANTARMUKA (RENDER UI) SOFTWARE CENTER
# =========================================================================
function Render-SoftwareCenter {
    $contentPanel.Controls.Clear()

    if ($global:IsDarkMode) {
        $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
    } else {
        $contentPanel.BackColor = [System.Drawing.Color]::FromArgb(240, 242, 245)
    }
    
    $cpWidth = $contentPanel.Width
    $cpHeight = $contentPanel.Height

    # --- Helper Rounded ---
    $SetRounded = {
        param($ctrl, $r)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { 
            return 
        }
        
        $D = $r * 2
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p.AddArc(0, 0, $D, $D, 180, 90)
        $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
        $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
        $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
        $p.CloseAllFigures()
        $ctrl.Region = New-Object System.Drawing.Region($p)
    }

    # --- Warna Tema ---
    $themeBlue   = [System.Drawing.Color]::FromArgb(0, 102, 204)
    $themeRed    = [System.Drawing.Color]::FromArgb(211, 47, 47)

    # ---------------------------------------------------------------------
    # 1. HEADER
    # ---------------------------------------------------------------------
    $pnlHeader = New-Object System.Windows.Forms.Panel
    $pnlHeader.Bounds = New-Object System.Drawing.Rectangle(15, 10, ($cpWidth - 30), 85)
    $pnlHeader.Anchor = "Top, Left, Right"
    $pnlHeader.BackColor = $themeBlue
    $contentPanel.Controls.Add($pnlHeader)
    &$SetRounded $pnlHeader 15

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "SOFTWARE CENTER"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(20, 15)
    $pnlHeader.Controls.Add($lblTitle)

    # --- Package Manager Radio ---
    $lblPkg = New-Object System.Windows.Forms.Label
    $lblPkg.Text = "Package Manager:"
    $lblPkg.AutoSize = $true
    $lblPkg.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $lblPkg.ForeColor = [System.Drawing.Color]::White
    $lblPkg.Location = New-Object System.Drawing.Point(22, 52)
    $pnlHeader.Controls.Add($lblPkg)

    $global:rbWinget = New-Object System.Windows.Forms.RadioButton
    $global:rbWinget.Text = "Winget"
    $global:rbWinget.Checked = $true
    $global:rbWinget.AutoSize = $true
    $global:rbWinget.ForeColor = [System.Drawing.Color]::White
    $global:rbWinget.Location = New-Object System.Drawing.Point(145, 50)
    $pnlHeader.Controls.Add($global:rbWinget)

    $global:rbChoco = New-Object System.Windows.Forms.RadioButton
    $global:rbChoco.Text = "Chocolatey"
    $global:rbChoco.AutoSize = $true
    $global:rbChoco.ForeColor = [System.Drawing.Color]::White
    $global:rbChoco.Location = New-Object System.Drawing.Point(230, 50)
    $pnlHeader.Controls.Add($global:rbChoco)

    $btnInit = New-Object System.Windows.Forms.Button
    $btnInit.Text = "Fix / Install Package Manager"
    $btnInit.Size = New-Object System.Drawing.Size(210, 30)
    $btnInit.Location = New-Object System.Drawing.Point(($pnlHeader.Width - 230), 25)
    $btnInit.Anchor = "Top, Right" 
    $btnInit.BackColor = [System.Drawing.Color]::White
    $btnInit.ForeColor = $themeBlue
    $btnInit.FlatStyle = "Flat"
    $btnInit.FlatAppearance.BorderSize = 0
    $btnInit.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $btnInit.Add_Click({ Action-InitPackageManagers })
    $pnlHeader.Controls.Add($btnInit)
    &$SetRounded $btnInit 10

    # ---------------------------------------------------------------------
    # 2. FOOTER (Panel Aksi)
    # ---------------------------------------------------------------------
    $pnlFooter = New-Object System.Windows.Forms.Panel
    $pnlFooter.Bounds = New-Object System.Drawing.Rectangle(15, ($cpHeight - 130), ($cpWidth - 30), 115)
    $pnlFooter.Anchor = "Bottom, Left, Right"
    
    if ($global:IsDarkMode) {
        $pnlFooter.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 50)
    } else {
        $pnlFooter.BackColor = [System.Drawing.Color]::White
    }
    
    $contentPanel.Controls.Add($pnlFooter)
    &$SetRounded $pnlFooter 15

    $pnlActions = New-Object System.Windows.Forms.FlowLayoutPanel
    $pnlActions.Dock = "Fill"
    $pnlActions.Padding = New-Object System.Windows.Forms.Padding(10, 15, 10, 10)
    $pnlActions.AutoScroll = $true
    $pnlFooter.Controls.Add($pnlActions)

    # --- Fungsi Pembuat Tombol ---
    function Create-StandardButton ($Text, $BgColor, $Action) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Text
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
        $btn.AutoSize = $true
        $btn.Height = 36
        $btn.Padding = New-Object System.Windows.Forms.Padding(12, 0, 12, 0)
        $btn.Margin = New-Object System.Windows.Forms.Padding(5)
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.Cursor = "Hand"
        $btn.BackColor = $BgColor
        $btn.ForeColor = [System.Drawing.Color]::White
        
        $r = [math]::Min(255, $BgColor.R + 25)
        $g = [math]::Min(255, $BgColor.G + 25)
        $b = [math]::Min(255, $BgColor.B + 25)
        $hoverColor = [System.Drawing.Color]::FromArgb($BgColor.A, $r, $g, $b)
        $normalColor = $BgColor
        
        $btn.Add_MouseEnter({ $this.BackColor = $hoverColor }.GetNewClosure())
        $btn.Add_MouseLeave({ $this.BackColor = $normalColor }.GetNewClosure())
        $btn.Add_Click($Action)
        
        $pnlActions.Controls.Add($btn)
        
        # Panggil handle untuk memastikan UI dirender sebelum dilengkungkan
        $null = $btn.Handle
        &$SetRounded $btn 12
        
        return $btn
    }

    # --- Koleksi Tombol Eksekusi ---
    Create-StandardButton "Install / Upgrade Selected" $themeBlue { 
        Execute-SoftwareAction "Install" 
    }
    
    Create-StandardButton "Uninstall Selected Items" $themeRed { 
        Execute-SoftwareAction "Uninstall" 
    }
    
    Create-StandardButton "Upgrade All Items" $themeBlue {
        if ($global:rbWinget.Checked) { 
            $pm = "Winget" 
        } else { 
            $pm = "Chocolatey" 
        }
        
        Write-Log "Action Triggered: User initiated 'Upgrade All Software' via $pm."
        
        if ($global:rbWinget.Checked) { 
            Start-Process cmd "/k winget upgrade --all --include-unknown" 
        } else { 
            Start-Process cmd "/k choco upgrade all -y" 
        }
    }
    
    Create-StandardButton "Selected Apps" $themeBlue {
        Write-Log "Action Triggered: User viewed the list of selected applications."
        $sel = @()
        
        foreach ($c in $global:pnlWinList.Controls) { 
            if ($c -is [System.Windows.Forms.CheckBox] -and $c.Checked) { 
                $sel += "[SYS] $($c.Text)" 
            } 
        }
        
        foreach ($c in $global:pnlThirdList.Controls) { 
            if ($c -is [System.Windows.Forms.CheckBox] -and $c.Checked) { 
                $sel += "[APP] $($c.Text)" 
            } 
        }
        
        if ($sel.Count -eq 0) { 
            [System.Windows.Forms.MessageBox]::Show("Tidak ada aplikasi dipilih.", "Info") 
        } else { 
            [System.Windows.Forms.MessageBox]::Show(($sel -join "`n"), "Daftar Terpilih") 
        }
    }
    
    Create-StandardButton "Clear Selection" $themeBlue {
        Write-Log "Action Triggered: User cleared all software checkboxes."
        
        foreach ($c in $global:pnlWinList.Controls) { 
            if ($c -is [System.Windows.Forms.CheckBox]) { 
                $c.Checked = $false 
            } 
        }
        
        foreach ($c in $global:pnlThirdList.Controls) { 
            if ($c -is [System.Windows.Forms.CheckBox]) { 
                $c.Checked = $false 
            } 
        }
    }
    
    Create-StandardButton "Show Installed Items" $themeBlue { 
        Write-Log "Action Triggered: User requested list of installed items via Winget."
        Start-Process cmd "/k winget list" 
    }

    # ---------------------------------------------------------------------
    # 3. TAB CONTROL & DAFTAR APLIKASI
    # ---------------------------------------------------------------------
    $tabControl = New-Object System.Windows.Forms.TabControl
    $tabControl.Location = New-Object System.Drawing.Point(15, 105)
    $tabControl.Size = New-Object System.Drawing.Size(($cpWidth - 30), ($cpHeight - 250))
    $tabControl.Anchor = "Top, Bottom, Left, Right"

    # --- Fungsi Pembangun Daftar Centang Dinamis ---
    function Build-ScrollableList ($TabName) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Dock = "Fill"
        $panel.AutoScroll = $true
        
        if ($global:IsDarkMode) {
            $panel.BackColor = [System.Drawing.Color]::FromArgb(25,25,30)
        } else {
            $panel.BackColor = [System.Drawing.Color]::White
        }
        
        $yPos = 15
        $categories = $global:SoftwareDatabase | Where-Object { $_.Tab -eq $TabName } | Select-Object -ExpandProperty Category -Unique

        foreach ($cat in $categories) {
            # Render Judul Kategori
            $lblHeader = New-Object System.Windows.Forms.Label
            $lblHeader.Text = "  $cat  "
            $lblHeader.AutoSize = $true
            $lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblHeader.ForeColor = [System.Drawing.Color]::White
            $lblHeader.BackColor = $themeBlue
            $lblHeader.Location = New-Object System.Drawing.Point(15, $yPos)
            
            $panel.Controls.Add($lblHeader)
            
            $null = $lblHeader.Handle
            &$SetRounded $lblHeader 6
            $yPos += 35

            # Render Checkbox Aplikasi
            $items = $global:SoftwareDatabase | Where-Object { $_.Tab -eq $TabName -and $_.Category -eq $cat }
            $colIndex = 0
            $colWidth = 210

            foreach ($item in $items) {
                $chk = New-Object System.Windows.Forms.CheckBox
                $chk.Text = $item.Name
                $chk.AutoSize = $true
                $chk.Cursor = "Hand"
                
                if ($global:IsDarkMode) {
                    $chk.ForeColor = [System.Drawing.Color]::White
                } else {
                    $chk.ForeColor = [System.Drawing.Color]::Black
                }
                
                $chk.Location = New-Object System.Drawing.Point((25 + ($colIndex * $colWidth)), $yPos)
                $chk.Tag = $item 

                $panel.Controls.Add($chk)
                
                $colIndex++ 
                if ($colIndex -ge 3) { 
                    $colIndex = 0
                    $yPos += 25 
                }
            }
            
            if ($colIndex -ne 0) { 
                $yPos += 25 
            }
            $yPos += 15
        }
        return $panel
    }

    # ---> SETUP TAB 1: System & Features
    $t1 = New-Object System.Windows.Forms.TabPage
    $t1.Text = "System & Features"
    $global:pnlWinList = Build-ScrollableList "Windows"
    $t1.Controls.Add($global:pnlWinList)
    
    # ---> SETUP TAB 2: Third Party Software
    $t2 = New-Object System.Windows.Forms.TabPage
    $t2.Text = "Third Party Software"
    $global:pnlThirdList = Build-ScrollableList "ThirdParty"
    $t2.Controls.Add($global:pnlThirdList)

    # ---> SETUP TAB 3: Custom Search & Install
    $t3 = New-Object System.Windows.Forms.TabPage
    $t3.Text = "Search & Custom Install"
    
    $pnlCustom = New-Object System.Windows.Forms.Panel
    $pnlCustom.Dock = "Fill"
    
    if ($global:IsDarkMode) {
        $pnlCustom.BackColor = [System.Drawing.Color]::FromArgb(25,25,30)
    } else {
        $pnlCustom.BackColor = [System.Drawing.Color]::White
    }
    
    $lblInfoCustom = New-Object System.Windows.Forms.Label
    $lblInfoCustom.Text = "Aplikasi yang kamu cari belum ada di daftar utama? Cari dan install secara manual di sini!`n`nTIPS PENTING: Jika aplikasi tidak ditemukan menggunakan Winget, cobalah ganti Package Manager ke Chocolatey (di bagian atas), dan sebaliknya."
    $lblInfoCustom.Location = New-Object System.Drawing.Point(20, 20)
    $lblInfoCustom.Size = New-Object System.Drawing.Size(($tabControl.Width - 60), 65)
    $lblInfoCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
    
    if ($global:IsDarkMode) {
        $lblInfoCustom.ForeColor = [System.Drawing.Color]::LightSkyBlue
    } else {
        $lblInfoCustom.ForeColor = [System.Drawing.Color]::DarkBlue
    }
    
    $pnlCustom.Controls.Add($lblInfoCustom)

    $lblInput = New-Object System.Windows.Forms.Label
    $lblInput.Text = "Masukkan Nama atau ID Aplikasi (Cth: VLC, Google.Chrome, telegram):"
    $lblInput.Location = New-Object System.Drawing.Point(20, 100)
    $lblInput.AutoSize = $true
    $lblInput.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    if ($global:IsDarkMode) {
        $lblInput.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblInput.ForeColor = [System.Drawing.Color]::Black
    }
    
    $pnlCustom.Controls.Add($lblInput)

    $global:txtCustomApp = New-Object System.Windows.Forms.TextBox
    $global:txtCustomApp.Location = New-Object System.Drawing.Point(20, 125)
    $global:txtCustomApp.Size = New-Object System.Drawing.Size(350, 30)
    $global:txtCustomApp.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $pnlCustom.Controls.Add($global:txtCustomApp)

    # Tombol Cari (Search)
    $btnSearchCustom = New-Object System.Windows.Forms.Button
    $btnSearchCustom.Text = "Cari Software"
    $btnSearchCustom.Location = New-Object System.Drawing.Point(20, 170)
    $btnSearchCustom.Size = New-Object System.Drawing.Size(150, 35)
    $btnSearchCustom.BackColor = $themeBlue
    $btnSearchCustom.ForeColor = [System.Drawing.Color]::White
    $btnSearchCustom.FlatStyle = "Flat"
    $btnSearchCustom.FlatAppearance.BorderSize = 0
    $btnSearchCustom.Cursor = "Hand"
    $btnSearchCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    $btnSearchCustom.Add_Click({
        $query = $global:txtCustomApp.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($query)) {
            Write-Log "Process Aborted: Custom search query is empty."
            [System.Windows.Forms.MessageBox]::Show("Masukkan nama software terlebih dahulu di kotak teks!", "Peringatan", "OK", "Warning")
            return
        }
        
        if ($global:rbChoco.Checked) {
            $pm = "Chocolatey"
        } else {
            $pm = "Winget"
        }
        
        Write-Log "Action Triggered: User searched for custom app '$query' via $pm."

        if ($global:rbChoco.Checked) {
            Start-Process cmd -ArgumentList "/k title Mencari $query di Chocolatey && Memeriksa di Chocolatey... && . && choco search `"$query`""
        } else {
            Start-Process cmd -ArgumentList "/k title Mencari $query di Winget && Memeriksa di Winget... && . && winget search `"$query`""
        }
    })
    
    $pnlCustom.Controls.Add($btnSearchCustom)
    $null = $btnSearchCustom.Handle
    &$SetRounded $btnSearchCustom 8

    # Tombol Install Manual
    $btnInstallCustom = New-Object System.Windows.Forms.Button
    $btnInstallCustom.Text = "Install Software"
    $btnInstallCustom.Location = New-Object System.Drawing.Point(180, 170)
    $btnInstallCustom.Size = New-Object System.Drawing.Size(150, 35)
    $btnInstallCustom.BackColor = [System.Drawing.Color]::MediumSeaGreen
    $btnInstallCustom.ForeColor = [System.Drawing.Color]::White
    $btnInstallCustom.FlatStyle = "Flat"
    $btnInstallCustom.FlatAppearance.BorderSize = 0
    $btnInstallCustom.Cursor = "Hand"
    $btnInstallCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    $btnInstallCustom.Add_Click({
        $query = $global:txtCustomApp.Text.Trim()
        
        if ([string]::IsNullOrWhiteSpace($query)) {
            Write-Log "Process Aborted: Custom install query is empty."
            [System.Windows.Forms.MessageBox]::Show("Masukkan nama atau ID software terlebih dahulu di kotak teks!", "Peringatan", "OK", "Warning")
            return
        }
        
        if ($global:rbChoco.Checked) {
            $pkgMngr = "Chocolatey"
        } else {
            $pkgMngr = "Winget"
        }
        
        $msg = "Pastikan kamu sudah menemukan ID yang tepat dari tombol pencarian.`nIngin menginstal '$query' menggunakan $pkgMngr?"
        $confirm = [System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Install", "YesNo", "Question")
        
        if ($confirm -eq "Yes") {
            Write-Log "Action Triggered: User initiated custom installation for '$query' via $pkgMngr."
            
            if ($global:rbChoco.Checked) {
                $cmd = "Write-Host 'Menginstal $query via Chocolatey...' -ForegroundColor Cyan; choco install '$query' -y; Write-Host '`nSelesai!' -ForegroundColor Green; Read-Host 'Tekan ENTER untuk menutup...'"
            } else {
                $cmd = "Write-Host 'Menginstal $query via Winget...' -ForegroundColor Cyan; winget install --id '$query' -e --accept-package-agreements --accept-source-agreements; Write-Host '`nSelesai!' -ForegroundColor Green; Read-Host 'Tekan ENTER untuk menutup...'"
            }
            
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`"" -Verb RunAs
        } else {
            Write-Log "Process Cancelled: User aborted custom installation for '$query'."
        }
    })
    
    $pnlCustom.Controls.Add($btnInstallCustom)
    $null = $btnInstallCustom.Handle
    &$SetRounded $btnInstallCustom 8

    $t3.Controls.Add($pnlCustom)

    # --- Memasukkan Semua Tab ke TabControl Utama ---
    $tabControl.TabPages.AddRange(@($t1, $t2, $t3))
    $contentPanel.Controls.Add($tabControl)

    # ---------------------------------------------------------------------
    # FUNGSI PEMBANGUN DAFTAR APLIKASI OTOMATIS (DYNAMIC GRID LIST)
    # ---------------------------------------------------------------------
    function Build-ScrollableList ($TabName) {
        $panel = New-Object System.Windows.Forms.Panel
        $panel.Dock = "Fill"
        $panel.AutoScroll = $true
        
        # Menyesuaikan warna latar belakang panel daftar aplikasi
        if ($global:IsDarkMode) {
            $panel.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
        } else {
            $panel.BackColor = [System.Drawing.Color]::White
        }
        
        $yPos = 15
        
        # Menyaring (Filter) nama kategori unik dari Database sesuai nama Tab
        $categories = $global:SoftwareDatabase | Where-Object { $_.Tab -eq $TabName } | Select-Object -ExpandProperty Category -Unique

        foreach ($cat in $categories) {
            # --- Membuat Label Judul Kategori (Contoh: "WEB BROWSER") ---
            $lblHeader = New-Object System.Windows.Forms.Label
            $lblHeader.Text = "  $cat  "
            $lblHeader.AutoSize = $true
            $lblHeader.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
            $lblHeader.ForeColor = [System.Drawing.Color]::White
            $lblHeader.BackColor = $themeBlue
            $lblHeader.Location = New-Object System.Drawing.Point(15, $yPos)
            
            $panel.Controls.Add($lblHeader)
            
            # Memanggil handle agar elemen dirender di memori sebelum dilengkungkan sudutnya
            $null = $lblHeader.Handle
            &$SetRounded $lblHeader 6
            
            # Menambah jarak (Y) ke bawah untuk posisi checkbox aplikasi
            $yPos += 35

            # Mengambil daftar aplikasi spesifik untuk kategori ini
            $items = $global:SoftwareDatabase | Where-Object { $_.Tab -eq $TabName -and $_.Category -eq $cat }
            
            # Variabel untuk mengatur sistem Grid (3 Kolom)
            $colIndex = 0
            $colWidth = 210

            foreach ($item in $items) {
                # --- Membuat Checkbox Aplikasi ---
                $chk = New-Object System.Windows.Forms.CheckBox
                $chk.Text = $item.Name
                $chk.AutoSize = $true
                $chk.Cursor = "Hand"
                
                if ($global:IsDarkMode) {
                    $chk.ForeColor = [System.Drawing.Color]::White
                } else {
                    $chk.ForeColor = [System.Drawing.Color]::Black
                }
                
                # Perhitungan Kordinat X: Titik awal 25 + (indeks kolom * jarak lebar antar kolom)
                $xPos = 25 + ($colIndex * $colWidth)
                $chk.Location = New-Object System.Drawing.Point($xPos, $yPos)
                
                # INJEKSI DATA PENTING:
                # Memasukkan seluruh data aplikasi (termasuk ID Winget/Choco) ke dalam objek Checkbox
                $chk.Tag = $item 

                $panel.Controls.Add($chk)
                
                # Logika Baris Baru:
                # Geser ke kolom berikutnya. Jika sudah kolom ke-3 (indeks 3), kembalikan ke kolom 0 dan turunkan Y.
                $colIndex++ 
                if ($colIndex -ge 3) { 
                    $colIndex = 0
                    $yPos += 25 
                }
            }
            
            # Jika baris terakhir tidak genap 3 (misal hanya 1 atau 2 aplikasi),
            # kita tetap harus menambahkan jarak Y agar kategori berikutnya tidak menumpuk
            if ($colIndex -ne 0) { 
                $yPos += 25 
            }
            
            # Jarak ekstra antar blok kategori
            $yPos += 15
        }
        
        return $panel
    }

    # ---------------------------------------------------------------------
    # PERAKITAN TAB CONTROL
    # ---------------------------------------------------------------------
    # === TAB 1: SYSTEM & FEATURES ===
    $t1 = New-Object System.Windows.Forms.TabPage
    $t1.Text = "System & Features"
    $global:pnlWinList = Build-ScrollableList "Windows"
    $t1.Controls.Add($global:pnlWinList)
    
    # === TAB 2: THIRD PARTY SOFTWARE ===
    $t2 = New-Object System.Windows.Forms.TabPage
    $t2.Text = "Third Party Software"
    $global:pnlThirdList = Build-ScrollableList "ThirdParty"
    $t2.Controls.Add($global:pnlThirdList)

    # === TAB 3: CUSTOM SEARCH & INSTALL ===
    $t3 = New-Object System.Windows.Forms.TabPage
    $t3.Text = "Search & Custom Install"
    
    $pnlCustom = New-Object System.Windows.Forms.Panel
    $pnlCustom.Dock = "Fill"
    
    if ($global:IsDarkMode) {
        $pnlCustom.BackColor = [System.Drawing.Color]::FromArgb(25, 25, 30)
    } else {
        $pnlCustom.BackColor = [System.Drawing.Color]::White
    }
    
    # -- Teks Informasi/Edukasi --
    $lblInfoCustom = New-Object System.Windows.Forms.Label
    $lblInfoCustom.Text = "Aplikasi yang kamu cari belum ada di daftar utama? Cari dan install secara manual di sini!`n`nTIPS PENTING: Jika aplikasi tidak ditemukan menggunakan Winget, cobalah ganti Package Manager ke Chocolatey (di bagian atas), dan sebaliknya. Beberapa aplikasi hanya tersedia di salah satu repositori."
    $lblInfoCustom.Location = New-Object System.Drawing.Point(20, 20)
    $lblInfoCustom.Size = New-Object System.Drawing.Size(($tabControl.Width - 60), 65)
    $lblInfoCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
    
    if ($global:IsDarkMode) {
        $lblInfoCustom.ForeColor = [System.Drawing.Color]::LightSkyBlue
    } else {
        $lblInfoCustom.ForeColor = [System.Drawing.Color]::DarkBlue
    }
    
    $pnlCustom.Controls.Add($lblInfoCustom)

    # -- Teks Judul Input --
    $lblInput = New-Object System.Windows.Forms.Label
    $lblInput.Text = "Masukkan Nama atau ID Aplikasi (Cth: VLC, Google.Chrome, telegram):"
    $lblInput.Location = New-Object System.Drawing.Point(20, 100)
    $lblInput.AutoSize = $true
    $lblInput.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    if ($global:IsDarkMode) {
        $lblInput.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblInput.ForeColor = [System.Drawing.Color]::Black
    }
    
    $pnlCustom.Controls.Add($lblInput)

    # -- Kotak Input Teks (Textbox) --
    $global:txtCustomApp = New-Object System.Windows.Forms.TextBox
    $global:txtCustomApp.Location = New-Object System.Drawing.Point(20, 125)
    $global:txtCustomApp.Size = New-Object System.Drawing.Size(350, 30)
    $global:txtCustomApp.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $pnlCustom.Controls.Add($global:txtCustomApp)

    # ---------------------------------------------------------------------
    # TOMBOL AKSI: CARI SOFTWARE (SEARCH)
    # ---------------------------------------------------------------------
    $btnSearchCustom = New-Object System.Windows.Forms.Button
    $btnSearchCustom.Text = "Cari Software"
    $btnSearchCustom.Location = New-Object System.Drawing.Point(20, 170)
    $btnSearchCustom.Size = New-Object System.Drawing.Size(150, 35)
    $btnSearchCustom.BackColor = $themeBlue
    $btnSearchCustom.ForeColor = [System.Drawing.Color]::White
    $btnSearchCustom.FlatStyle = "Flat"
    $btnSearchCustom.FlatAppearance.BorderSize = 0
    $btnSearchCustom.Cursor = "Hand"
    $btnSearchCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    $btnSearchCustom.Add_Click({
        $query = $global:txtCustomApp.Text.Trim()
        
        if ([string]::IsNullOrWhiteSpace($query)) {
            Write-Log "Process Aborted: Custom search query is empty."
            [System.Windows.Forms.MessageBox]::Show("Masukkan nama software terlebih dahulu di kotak teks!", "Peringatan", "OK", "Warning")
            return
        }
        
        if ($global:rbChoco.Checked) {
            $pm = "Chocolatey"
        } else {
            $pm = "Winget"
        }
        
        Write-Log "Action Triggered: User searched for custom app '$query' via $pm."

        # Menjalankan CMD di background dan membiarkan jendelanya tetap terbuka (/k)
        # Sintaks && digunakan khusus untuk CMD (Command Prompt), bukan PowerShell
        if ($global:rbChoco.Checked) {
            $cmdArgs = "/k title Mencari $query di Chocolatey && Memeriksa di Chocolatey... && choco search `"$query`""
            Start-Process cmd -ArgumentList $cmdArgs
        } else {
            $cmdArgs = "/k title Mencari $query di Winget && Memeriksa di Winget... && winget search `"$query`""
            Start-Process cmd -ArgumentList $cmdArgs
        }
    })
    
    $pnlCustom.Controls.Add($btnSearchCustom)
    $null = $btnSearchCustom.Handle
    &$SetRounded $btnSearchCustom 8

    # ---------------------------------------------------------------------
    # TOMBOL AKSI: INSTALL MANUAL
    # ---------------------------------------------------------------------
    $btnInstallCustom = New-Object System.Windows.Forms.Button
    $btnInstallCustom.Text = "Install Software"
    $btnInstallCustom.Location = New-Object System.Drawing.Point(180, 170)
    $btnInstallCustom.Size = New-Object System.Drawing.Size(150, 35)
    $btnInstallCustom.BackColor = [System.Drawing.Color]::MediumSeaGreen
    $btnInstallCustom.ForeColor = [System.Drawing.Color]::White
    $btnInstallCustom.FlatStyle = "Flat"
    $btnInstallCustom.FlatAppearance.BorderSize = 0
    $btnInstallCustom.Cursor = "Hand"
    $btnInstallCustom.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    
    $btnInstallCustom.Add_Click({
        $query = $global:txtCustomApp.Text.Trim()
        
        if ([string]::IsNullOrWhiteSpace($query)) {
            Write-Log "Process Aborted: Custom install query is empty."
            [System.Windows.Forms.MessageBox]::Show("Masukkan nama atau ID software terlebih dahulu di kotak teks!", "Peringatan", "OK", "Warning")
            return
        }
        
        if ($global:rbChoco.Checked) {
            $pkgMngr = "Chocolatey"
        } else {
            $pkgMngr = "Winget"
        }
        
        $msg = "Pastikan kamu sudah menemukan ID yang tepat dari tombol pencarian.`nIngin menginstal '$query' menggunakan $pkgMngr?"
        $confirm = [System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Install", "YesNo", "Question")
        
        if ($confirm -eq "Yes") {
            Write-Log "Action Triggered: User initiated custom installation for '$query' via $pkgMngr."
            
            # Merakit perintah PowerShell menggunakan Array agar rapi (menghindari penggunaan titik koma manual)
            if ($global:rbChoco.Checked) {
                $cmdLines = @(
                    "Write-Host 'Menginstal $query via Chocolatey...' -ForegroundColor Cyan"
                    "choco install '$query' -y"
                    "Write-Host '`nSelesai!' -ForegroundColor Green"
                    "Read-Host 'Tekan ENTER untuk menutup...'"
                )
            } else {
                $cmdLines = @(
                    "Write-Host 'Menginstal $query via Winget...' -ForegroundColor Cyan"
                    "winget install --id '$query' -e --accept-package-agreements --accept-source-agreements"
                    "Write-Host '`nSelesai!' -ForegroundColor Green"
                    "Read-Host 'Tekan ENTER untuk menutup...'"
                )
            }
            
            # Menggabungkan array menjadi satu string komando yang bisa dibaca PowerShell (-Command)
            $finalCmd = $cmdLines -join "; "
            
            Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$finalCmd`"" -Verb RunAs
        } else {
            Write-Log "Process Cancelled: User aborted custom installation for '$query'."
        }
    })
    
    $pnlCustom.Controls.Add($btnInstallCustom)
    $null = $btnInstallCustom.Handle
    &$SetRounded $btnInstallCustom 8

    $t3.Controls.Add($pnlCustom)

    # ---------------------------------------------------------------------
    # PENYUSUNAN AKHIR
    # ---------------------------------------------------------------------
    # Memasukkan semua Tab (System, Third Party, Custom) ke dalam TabControl
    $tabControl.TabPages.AddRange(@($t1, $t2, $t3))
    
    # Memasukkan TabControl ke dalam Panel Konten Utama aplikasi
    $contentPanel.Controls.Add($tabControl)
}

# ========================================================
# SELESAI BAGIAN SOFTWARE CENTER
# ========================================================

# =========================================================================
# FASE 13: MODUL MANAJEMEN WINDOWS DEFENDER & KEAMANAN SISTEM
# =========================================================================

# -------------------------------------------------------------------------
# FUNGSI 1: RESET IT POLICIES (UNLOCK SETTINGS)
# -------------------------------------------------------------------------
# Fungsi ini berguna jika PC terkunci oleh pengaturan organisasi (Managed by your organization)
# yang menyebabkan user tidak bisa mengubah pengaturan Windows.
function Action-DefEnableIT {
    Write-Log "Starting IT Limit Fix (Reset Policies)..."
    
    # Daftar panjang lokasi Registry tempat Windows menyimpan batasan (Policies)
    $keys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies",
        "HKCU:\Software\Microsoft\WindowsSelfHost", 
        "HKCU:\Software\Policies",
        "HKLM:\Software\Microsoft\Policies", 
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate",
        "HKLM:\Software\Microsoft\WindowsSelfHost", 
        "HKLM:\Software\Policies",
        "HKLM:\Software\WOW6432Node\Microsoft\Policies",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies"
    )
    
    # Melakukan perulangan untuk mengecek setiap lokasi di atas
    foreach ($k in $keys) { 
        # Jika folder (Path) tersebut ada di sistem, maka hapus paksa beserta isinya
        if (Test-Path $k) { 
            Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue 
        } 
    }
    
    [System.Windows.Forms.MessageBox]::Show("IT Limit Policies have been reset!", "Success", "OK", "Information")
}

# -------------------------------------------------------------------------
# FUNGSI 2: MEMATIKAN WINDOWS DEFENDER (DISABLE)
# -------------------------------------------------------------------------
function Action-DefDisable {
    # Peringatan wajib: Tamper Protection harus mati secara manual dari dalam Windows Security,
    # karena Microsoft melindunginya agar tidak bisa dimatikan lewat script.
    $msg = "PENTING: Fitur ini HANYA BEKERJA jika 'Tamper Protection' di Windows Security sudah dimatikan secara manual.`n`nApakah Anda sudah mematikannya?"
    $ask = [System.Windows.Forms.MessageBox]::Show($msg, "Cek Tamper Protection", "YesNo", "Warning")
    
    if ($ask -eq "Yes") {
        Write-Log "Disabling Windows Defender..."
        try {
            # --- 1. Mematikan fitur inti AntiSpyware dan AntiVirus ---
            $basePath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
            cmd.exe /c "reg add `"$basePath`" /v `"DisableAntiSpyware`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$basePath`" /v `"DisableRealtimeMonitoring`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$basePath`" /v `"DisableAntiVirus`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$basePath`" /v `"DisableSpecialRunningModes`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$basePath`" /v `"DisableRoutinelyTakingAction`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$basePath`" /v `"ServiceKeepAlive`" /t REG_DWORD /d 0 /f" | Out-Null

            # --- 2. Mematikan modul Real-Time Protection (Pemindaian Otomatis) ---
            $rtPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
            cmd.exe /c "reg add `"$rtPath`" /v `"DisableBehaviorMonitoring`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$rtPath`" /v `"DisableOnAccessProtection`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$rtPath`" /v `"DisableScanOnRealtimeEnable`" /t REG_DWORD /d 1 /f" | Out-Null
            cmd.exe /c "reg add `"$rtPath`" /v `"DisableRealtimeMonitoring`" /t REG_DWORD /d 1 /f" | Out-Null

            # --- 3. Mematikan Auto-Update Signature (Database Virus) ---
            $sigPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates"
            cmd.exe /c "reg add `"$sigPath`" /v `"ForceUpdateFromMU`" /t REG_DWORD /d 0 /f" | Out-Null

            # --- 4. Mematikan Telemetri (Pengiriman Sample Data ke Microsoft) ---
            $spyPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"
            cmd.exe /c "reg add `"$spyPath`" /v `"DisableBlockAtFirstSeen`" /t REG_DWORD /d 1 /f" | Out-Null
            # SubmitSamplesConsent bernilai 2 berarti "Jangan Pernah Kirim Data" (Never Send)
            cmd.exe /c "reg add `"$spyPath`" /v `"SubmitSamplesConsent`" /t REG_DWORD /d 2 /f" | Out-Null
            
            $mpPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine"
            cmd.exe /c "reg add `"$mpPath`" /v `"MpEnablePus`" /t REG_DWORD /d 0 /f" | Out-Null
            cmd.exe /c "reg add `"$mpPath`" /v `"MpEngineRunTime`" /t REG_DWORD /d 0 /f" | Out-Null

            $repPath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting"
            cmd.exe /c "reg add `"$repPath`" /v `"DisableEnhancedNotifications`" /t REG_DWORD /d 1 /f" | Out-Null

            # --- 5. Mematikan Service secara Paksa via SC (Service Controller) ---
            cmd.exe /c "sc stop WinDefend" | Out-Null
            cmd.exe /c "sc stop Sense" | Out-Null
            cmd.exe /c "sc config WinDefend start= disabled" | Out-Null
            cmd.exe /c "sc config Sense start= disabled" | Out-Null

            [System.Windows.Forms.MessageBox]::Show("Windows Defender telah dinonaktifkan secara mendalam via Registry.`nSilakan RESTART PC Anda agar efeknya bekerja penuh.", "Done", "OK", "Information")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Gagal mengeksekusi perintah. Pastikan Anda menjalankan aplikasi ini sebagai Administrator (Run as Admin).", "Error", "OK", "Error")
        }
    }
}

# -------------------------------------------------------------------------
# FUNGSI 3: MENGHIDUPKAN WINDOWS DEFENDER KEMBALI (ENABLE)
# -------------------------------------------------------------------------
function Action-DefEnable {
    Write-Log "Enabling Windows Defender..."
    try {
        # Mengembalikan fitur dengan cara menghapus seluruh Policy buatan kita di atas.
        # Jika folder Registry ini dihapus, Windows akan kembali menggunakan pengaturan standar pabrik.
        $basePath = "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender"
        cmd.exe /c "reg delete `"$basePath`" /f" | Out-Null
        
        # Menyalakan ulang Service dan mengubah startup type menjadi Otomatis
        cmd.exe /c "sc config WinDefend start= auto" | Out-Null
        cmd.exe /c "sc config Sense start= auto" | Out-Null
        cmd.exe /c "sc start WinDefend" | Out-Null
        cmd.exe /c "sc start Sense" | Out-Null

        [System.Windows.Forms.MessageBox]::Show("Pengaturan Windows Defender telah dikembalikan ke standar pabrik.`nSilakan RESTART PC Anda agar fitur perlindungan aktif kembali.", "Success", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan. Pastikan aplikasi berjalan sebagai Administrator.", "Error", "OK", "Error")
    }
}

# -------------------------------------------------------------------------
# FUNGSI 4: PEMBUATAN ANTARMUKA (RENDER UI) WINDOWS DEFENDER
# -------------------------------------------------------------------------
function Render-WindowsDefender {
    $contentPanel.Controls.Clear()
    
    if ($global:IsDarkMode) { 
        $cP = $ThemePalettes.Dark 
    } else { 
        $cP = $ThemePalettes.Light 
    }

    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    # Efek sudut melengkung pada banner
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Windows Defender Manager"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Kelola proteksi bawaan Windows dan bersihkan batasan sistem (IT Policies) dengan aman."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. GRID UNTUK ACTION CARDS (TOMBOL MENU) ---
    $flpCards = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpCards.Location = New-Object System.Drawing.Point(25, 160)
    $flpCards.Size = New-Object System.Drawing.Size(770, 0)
    $flpCards.AutoSize = $true
    $flpCards.AutoSizeMode = "GrowAndShrink"
    $flpCards.AutoScroll = $false 
    $flpCards.FlowDirection = "TopDown"
    $flpCards.WrapContents = $false

    # --- FUNGSI INTERNAL: TEMPLATE PEMBUAT KARTU TOMBOL ---
    function Create-ActionCard ($Title, $Desc, $IconCode, $ColorName, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(735, 90)
        $card.Margin = New-Object System.Windows.Forms.Padding(5, 5, 15, 10)
        $card.BackColor = $cP.Card
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand

        # Sudut melengkung untuk setiap kartu
        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        # Ikon Kartu
        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(20, 25)
        
        try { 
            $ico.ForeColor = [System.Drawing.Color]::FromName($ColorName) 
        } catch { 
            $ico.ForeColor = $cP.Accent 
        }
        
        $card.Controls.Add($ico)

        # Judul Kartu
        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = $cP.Text
        $lTitle.Location = New-Object System.Drawing.Point(80, 20)
        $lTitle.AutoSize = $true
        $card.Controls.Add($lTitle)

        # Deskripsi Kartu
        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(80, 48)
        $lSub.Size = New-Object System.Drawing.Size(630, 20)
        $lSub.AutoSize = $false
        $lSub.AutoEllipsis = $true
        $card.Controls.Add($lSub)

        # --- LOGIKA HOVER (SOROT MOUSE) ---
        # Setiap elemen di dalam kartu ditambahkan sensor (Event Listener).
        # Logika dipecah ke bawah tanpa menggunakan titik koma.
        
        $hoverAction = {
            if ($global:IsDarkMode) {
                $this.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 55)
            } else {
                $this.BackColor = [System.Drawing.Color]::FromArgb(235, 235, 235)
            }
        }.GetNewClosure()

        $leaveAction = {
            if ($global:IsDarkMode) {
                $this.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
            } else {
                $this.BackColor = [System.Drawing.Color]::White
            }
        }.GetNewClosure()
        
        $childHoverAction = {
            if ($global:IsDarkMode) {
                $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 55)
            } else {
                $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(235, 235, 235)
            }
        }.GetNewClosure()

        $childLeaveAction = {
            if ($global:IsDarkMode) {
                $this.Parent.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 35)
            } else {
                $this.Parent.BackColor = [System.Drawing.Color]::White
            }
        }.GetNewClosure()

        # Memasang sensor Hover ke panel utama (Kartu)
        $card.Add_MouseEnter($hoverAction)
        $card.Add_MouseLeave($leaveAction)

        # Memasang sensor Hover ke elemen di dalam Kartu (Ikon, Judul, Deskripsi)
        $ico.Add_MouseEnter($childHoverAction)
        $ico.Add_MouseLeave($childLeaveAction)
        
        $lTitle.Add_MouseEnter($childHoverAction)
        $lTitle.Add_MouseLeave($childLeaveAction)
        
        $lSub.Add_MouseEnter($childHoverAction)
        $lSub.Add_MouseLeave($childLeaveAction)

        # --- LOGIKA KLIK (EKSEKUSI FUNGSI) ---
        # Menambahkan aksi klik pada semua elemen, sehingga user bisa mengeklik di area mana saja dari kartu.
        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)

        return $card
    }

    # --- Pemasangan Action Cards ---
    $flpCards.Controls.Add((Create-ActionCard "Reset IT Policies (Unlock Settings)" "Hapus semua batasan/policy lokal Windows. Berguna jika Defender terkunci 'Managed by your organization'." 0xE90F "Orange" { Action-DefEnableIT }))
    $flpCards.Controls.Add((Create-ActionCard "Disable Windows Defender" "Matikan perlindungan Real-time, AntiVirus, dan Spyware secara paksa lewat Registry." 0xE711 "Red" { Action-DefDisable }))
    $flpCards.Controls.Add((Create-ActionCard "Enable Windows Defender" "Pulihkan pengaturan Default perlindungan Windows dan nyalakan ulang servis." 0xE8FB "LimeGreen" { Action-DefEnable }))

    $pnlMain.Controls.Add($flpCards)
    $contentPanel.Controls.Add($pnlMain)
}

# ==========================================
# SELESAI RENDER WINDOWS UPDATES
# ==========================================

# =========================================================================
# FASE 14: MODUL MANAJEMEN WINDOWS UPDATE (LOGIC ENGINE)
# =========================================================================

# -------------------------------------------------------------------------
# FUNGSI 1: MEMATIKAN WINDOWS UPDATE (PAUSE HINGGA TAHUN 2075)
# -------------------------------------------------------------------------
function Action-UpdateDisable {
    Write-Log "Process Started: Disabling Windows Update..."
    try {
        # Mengubah kursor panah menjadi ikon "Loading/Wait"
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor

        # 1. Matikan dan Nonaktifkan (Disable) semua servis terkait Windows Update
        $services = @("wuauserv", "bits", "dosvc", "UsoSvc", "WaaSMedicSvc")
        foreach ($svc in $services) {
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }

        # 2. Atur Waktu Jeda (Pause) di Registry
        # Format waktu wajib mengikuti standar ISO 8601 (Tahun-Bulan-Hari T Jam:Menit:Detik Z)
        $now = "2025-01-01T00:00:00Z"
        $future = "2075-01-01T00:00:00Z" # Update ditahan sampai tahun 2075
        
        # Eksekusi Registry UX Settings (Tampilan di menu Settings Windows)
        $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        
        if (-not (Test-Path $uxPath)) { 
            New-Item -Path $uxPath -Force | Out-Null 
        }
        
        Set-ItemProperty -Path $uxPath -Name "PauseUpdatesStartTime" -Value $now -Force
        Set-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesStartTime" -Value $now -Force
        Set-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesStartTime" -Value $now -Force
        
        Set-ItemProperty -Path $uxPath -Name "PauseUpdatesExpiryTime" -Value $future -Force
        Set-ItemProperty -Path $uxPath -Name "PauseFeatureUpdatesEndTime" -Value $future -Force
        Set-ItemProperty -Path $uxPath -Name "PauseQualityUpdatesEndTime" -Value $future -Force

        # Eksekusi Registry UpdatePolicy (Kebijakan sistem)
        $upPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
        
        if (-not (Test-Path $upPath)) { 
            New-Item -Path $upPath -Force | Out-Null 
        }
        
        # Angka 1 (DWord) berarti "Aktifkan status Pause"
        Set-ItemProperty -Path $upPath -Name "PausedFeatureStatus" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $upPath -Name "PausedQualityStatus" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $upPath -Name "PausedFeatureDate" -Value $now -Force
        Set-ItemProperty -Path $upPath -Name "PausedQualityDate" -Value $now -Force

        # Kembalikan kursor ke bentuk semula (Panah)
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        
        Write-Log "Success: Windows Update and its services have been forcibly disabled until 2075."
        [System.Windows.Forms.MessageBox]::Show("Windows Update beserta layanannya berhasil dimatikan secara paksa hingga tahun 2075!", "Sukses", "OK", "Information")
    } catch {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        Write-Log "Failed: Unable to disable Windows Update. Error Details: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Gagal mematikan Windows Update.`nDetail: $($_.Exception.Message)", "Error", "OK", "Error")
    }
}

# -------------------------------------------------------------------------
# FUNGSI 2: MENGHIDUPKAN KEMBALI WINDOWS UPDATE (ENABLE TO DEFAULT)
# -------------------------------------------------------------------------
function Action-UpdateEnable {
    Write-Log "Process Started: Enabling Windows Update..."
    try {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor

        # 1. Aktifkan dan Start ulang semua servis ke pengaturan Automatic
        $autoServices = @("wuauserv", "bits", "dosvc", "UsoSvc")
        foreach ($svc in $autoServices) {
            Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svc -ErrorAction SilentlyContinue
        }
        
        # WaaSMedicSvc harus diatur ke Manual sesuai standar pabrik Windows
        Set-Service -Name "WaaSMedicSvc" -StartupType Manual -ErrorAction SilentlyContinue
        Start-Service -Name "WaaSMedicSvc" -ErrorAction SilentlyContinue

        # 2. Hapus Kunci Jeda (Pause) dari Registry UX Settings
        $uxPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
        
        if (Test-Path $uxPath) {
            $props = @(
                "PauseUpdatesStartTime", "PauseFeatureUpdatesStartTime", "PauseQualityUpdatesStartTime", 
                "PauseUpdatesExpiryTime", "PauseFeatureUpdatesEndTime", "PauseQualityUpdatesEndTime"
            )
            foreach ($prop in $props) { 
                Remove-ItemProperty -Path $uxPath -Name $prop -ErrorAction SilentlyContinue 
            }
        }

        # 3. Hapus Folder Registry Policy (Kembali ke bawaan Windows)
        $polAU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        if (Test-Path $polAU) { 
            Remove-Item -Path $polAU -Recurse -Force -ErrorAction SilentlyContinue 
        }
        
        $upPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings"
        if (Test-Path $upPath) { 
            Remove-Item -Path $upPath -Recurse -Force -ErrorAction SilentlyContinue 
        }

        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        
        Write-Log "Success: Windows Update has been successfully restored to factory defaults."
        [System.Windows.Forms.MessageBox]::Show("Windows Update berhasil diaktifkan kembali ke standar pabrik.", "Sukses", "OK", "Information")
    } catch {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        Write-Log "Failed: Unable to enable Windows Update. Error Details: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Gagal mengaktifkan Windows Update.`nDetail: $($_.Exception.Message)", "Error", "OK", "Error")
    }
}

# -------------------------------------------------------------------------
# FUNGSI 3: MEMPERBAIKI WINDOWS UPDATE ERROR (RESET COMPONENTS)
# -------------------------------------------------------------------------
function Action-UpdateReset {
    Write-Log "Action Triggered: Opening Reset Mode dialog..."
    
    # --- A. PEMBUATAN JENDELA POP-UP PILIHAN RESET ---
    $frmReset = New-Object System.Windows.Forms.Form
    $frmReset.Text = "Pilih Mode Reset"
    $frmReset.Size = New-Object System.Drawing.Size(400, 260)
    $frmReset.StartPosition = "CenterScreen"
    $frmReset.FormBorderStyle = "FixedToolWindow"
    $frmReset.TopMost = $true
    $frmReset.BackColor = [System.Drawing.Color]::White

    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "Pilih tingkat perbaikan komponen Windows Update:"
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $lblInfo.AutoSize = $true
    $lblInfo.Location = New-Object System.Drawing.Point(20, 20)
    $frmReset.Controls.Add($lblInfo)

    # 1. Tombol: Standard Reset
    $btnStd = New-Object System.Windows.Forms.Button
    $btnStd.Text = "Standard Reset (Disarankan)"
    $btnStd.Location = New-Object System.Drawing.Point(20, 60)
    $btnStd.Size = New-Object System.Drawing.Size(345, 40)
    $btnStd.BackColor = [System.Drawing.Color]::DodgerBlue
    $btnStd.ForeColor = [System.Drawing.Color]::White
    $btnStd.FlatStyle = "Flat"
    $btnStd.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnStd.Cursor = "Hand"
    
    $btnStd.Add_Click({
        $frmReset.Tag = "Standard"
        $frmReset.DialogResult = "OK"
    })
    $frmReset.Controls.Add($btnStd)

    $lblStd = New-Object System.Windows.Forms.Label
    $lblStd.Text = "Aman. Menghapus Cache dan Network tanpa merusak UAC."
    $lblStd.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblStd.ForeColor = [System.Drawing.Color]::Gray
    $lblStd.AutoSize = $true
    $lblStd.Location = New-Object System.Drawing.Point(20, 105)
    $frmReset.Controls.Add($lblStd)

    # 2. Tombol: Deep Reset
    $btnDeep = New-Object System.Windows.Forms.Button
    $btnDeep.Text = "Deep Reset (Tingkat Lanjut)"
    $btnDeep.Location = New-Object System.Drawing.Point(20, 140)
    $btnDeep.Size = New-Object System.Drawing.Size(345, 40)
    $btnDeep.BackColor = [System.Drawing.Color]::Crimson
    $btnDeep.ForeColor = [System.Drawing.Color]::White
    $btnDeep.FlatStyle = "Flat"
    $btnDeep.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnDeep.Cursor = "Hand"
    
    $btnDeep.Add_Click({
        $confirm = [System.Windows.Forms.MessageBox]::Show("Mode ini akan mendaftarkan ulang seluruh DLL inti Windows.`n`nEfek samping: Pengaturan UAC Anda mungkin akan ter-reset ke Default (Always Notify).`n`nGunakan hanya jika Standard Reset gagal.`nLanjutkan?", "Peringatan Deep Reset", 4, 48)
        
        if ($confirm -eq 'Yes') {
            $frmReset.Tag = "Deep"
            $frmReset.DialogResult = "OK"
        }
    })
    $frmReset.Controls.Add($btnDeep)

    $lblDeep = New-Object System.Windows.Forms.Label
    $lblDeep.Text = "Hanya jika gagal. Registrasi ulang DLL penuh (Beresiko mereset UAC)."
    $lblDeep.Font = New-Object System.Drawing.Font("Segoe UI", 8)
    $lblDeep.ForeColor = [System.Drawing.Color]::Gray
    $lblDeep.AutoSize = $true
    $lblDeep.Location = New-Object System.Drawing.Point(20, 185)
    $frmReset.Controls.Add($lblDeep)

    # --- B. LOGIKA EKSEKUSI (Berdasarkan pilihan user di pop-up tadi) ---
    if ($frmReset.ShowDialog() -eq "OK") {
        $mode = $frmReset.Tag
        Write-Log "Process Started: Resetting Windows Update Components (Mode: $mode)..."
        
        try {
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
            
            # Langkah 1: Matikan services terkait (wajib)
            $services = @("wuauserv", "cryptSvc", "bits", "msiserver")
            foreach ($svc in $services) {
                Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            }

            # Langkah 2: Hapus data antrean unduhan (qmgr)
            $qmgrPath = "$env:ALLUSERSPROFILE\Application Data\Microsoft\Network\Downloader\qmgr*.dat"
            Remove-Item -Path $qmgrPath -Force -ErrorAction SilentlyContinue

            # Langkah 3: Mengamankan Cache lama (SoftwareDistribution & catroot2) dengan merename menjadi .old
            $sdPath = "$env:windir\SoftwareDistribution"
            if (Test-Path "$sdPath.old") { 
                Remove-Item -Path "$sdPath.old" -Recurse -Force -ErrorAction SilentlyContinue 
            }
            if (Test-Path $sdPath) { 
                Rename-Item -Path $sdPath -NewName "SoftwareDistribution.old" -ErrorAction SilentlyContinue 
            }

            $crPath = "$env:windir\System32\catroot2"
            if (Test-Path "$crPath.old") { 
                Remove-Item -Path "$crPath.old" -Recurse -Force -ErrorAction SilentlyContinue 
            }
            if (Test-Path $crPath) { 
                Rename-Item -Path $crPath -NewName "catroot2.old" -ErrorAction SilentlyContinue 
            }

            # --- EKSEKUSI KHUSUS MODE DEEP RESET ---
            if ($mode -eq "Deep") {
                Write-Log "Deep Reset: Re-registering System DLLs and Security Descriptors..."
                
                # Menggunakan Command Prompt (& sc.exe) agar terhindar dari Error parsing PowerShell
                & sc.exe sdset bits "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)" | Out-Null
                & sc.exe sdset wuauserv "D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)" | Out-Null

                # Mendaftarkan ulang seluruh Pustaka Dynamic Link Library (DLL) milik Windows
                $dlls = @(
                    "atl.dll", "urlmon.dll", "mshtml.dll", "shdocvw.dll", "browseui.dll", "jscript.dll", "vbscript.dll", 
                    "scrrun.dll", "msxml.dll", "msxml3.dll", "msxml6.dll", "actxprxy.dll", "softpub.dll", "wintrust.dll", 
                    "dssenh.dll", "rsaenh.dll", "gpkcsp.dll", "sccbase.dll", "slbcsp.dll", "cryptdlg.dll", "oleaut32.dll", 
                    "ole32.dll", "shell32.dll", "initpki.dll", "wuapi.dll", "wuaueng.dll", "wuaueng1.dll", "wucltui.dll", 
                    "wups.dll", "wups2.dll", "wuweb.dll", "qmgr.dll", "qmgrprxy.dll", "wucltux.dll", "muweb.dll", "wuwebv.dll"
                )
                
                $currentLocation = Get-Location
                Set-Location "$env:windir\System32"
                
                # Menjalankan pendaftaran DLL satu per satu tanpa memunculkan jendela pop-up (Silently)
                foreach ($dll in $dlls) {
                    Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $dll" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue
                }
                Set-Location $currentLocation
            }

            # Langkah 4: Reset koneksi jaringan inti (Winsock & WinHTTP Proxy)
            & netsh winsock reset | Out-Null
            & netsh winhttp reset proxy | Out-Null

            # Langkah 5: Nyalakan kembali semua services yang dimatikan di awal
            foreach ($svc in $services) {
                Start-Service -Name $svc -ErrorAction SilentlyContinue
            }
            
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
            Write-Log "Success: Fully reset Windows Update components ($mode Mode)."
            [System.Windows.Forms.MessageBox]::Show("Reset Windows Update ($mode Mode) berhasil!`n`nSangat disarankan untuk RESTART PC setelah pesan ini ditutup.", "Sukses", "OK", "Information")
        } catch {
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
            Write-Log "Failed: An error occurred while resetting components. Error Details: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan saat mereset komponen.`nDetail: $($_.Exception.Message)", "Error", "OK", "Error")
        }
    } else {
        Write-Log "Process Cancelled: User closed the Reset Mode dialog."
    }
}

# -------------------------------------------------------------------------
# FUNGSI 4: MENUNDA UPDATE SAMPAI TANGGAL TERTENTU (CUSTOM PAUSE)
# -------------------------------------------------------------------------
function Action-UpdatePauseCustom {
    Write-Log "Action Triggered: Opening Custom Date Picker dialog..."
    
    # --- Membuat Jendela Kalender (Date Picker UI) ---
    $formDate = New-Object System.Windows.Forms.Form
    $formDate.Text = "Pilih Tanggal Pause"
    $formDate.Size = New-Object System.Drawing.Size(350, 200)
    $formDate.StartPosition = "CenterScreen"
    $formDate.FormBorderStyle = "FixedToolWindow"
    $formDate.TopMost = $true
    $formDate.BackColor = [System.Drawing.Color]::White

    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.Text = "Tentukan tanggal kapan Update akan dilanjutkan:"
    $lblInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $lblInfo.AutoSize = $true
    $lblInfo.Location = New-Object System.Drawing.Point(20, 20)
    $formDate.Controls.Add($lblInfo)

    # Memanggil elemen kalender bawaan Windows
    $dtPicker = New-Object System.Windows.Forms.DateTimePicker
    $dtPicker.Location = New-Object System.Drawing.Point(20, 55)
    $dtPicker.Size = New-Object System.Drawing.Size(290, 30)
    $dtPicker.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $dtPicker.Format = [System.Windows.Forms.DateTimePickerFormat]::Long
    
    # Mencegah user memilih tanggal di masa lalu
    $dtPicker.MinDate = [DateTime]::Now 
    $formDate.Controls.Add($dtPicker)

    $btnSave = New-Object System.Windows.Forms.Button
    $btnSave.Text = "Simpan"
    $btnSave.Location = New-Object System.Drawing.Point(235, 110)
    $btnSave.Size = New-Object System.Drawing.Size(75, 30)
    $btnSave.BackColor = [System.Drawing.Color]::MediumPurple
    $btnSave.ForeColor = [System.Drawing.Color]::White
    $btnSave.FlatStyle = "Flat"
    $btnSave.Cursor = "Hand"
    $btnSave.DialogResult = "OK"
    $formDate.Controls.Add($btnSave)

    # Agar user bisa langsung menekan tombol 'Enter' di keyboard untuk menyimpan
    $formDate.AcceptButton = $btnSave

    # --- Logika Eksekusi Jika Tombol Simpan Ditekan ---
    if ($formDate.ShowDialog() -eq "OK") {
        try {
            Write-Log "Applying custom pause update date..."
            
            # Format waktu diubah ke UTC (Standar GMT 0) karena Registry Windows menolak zona waktu lokal
            $selectedDate = $dtPicker.Value.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
            $now = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
            
            $regPath = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            
            if (-not (Test-Path $regPath)) { 
                New-Item -Path $regPath -Force | Out-Null 
            }

            Set-ItemProperty -Path $regPath -Name "PauseUpdatesStartTime" -Value $now -Force
            Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesStartTime" -Value $now -Force
            Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesStartTime" -Value $now -Force
            
            Set-ItemProperty -Path $regPath -Name "PauseUpdatesExpiryTime" -Value $selectedDate -Force
            Set-ItemProperty -Path $regPath -Name "PauseFeatureUpdatesEndTime" -Value $selectedDate -Force
            Set-ItemProperty -Path $regPath -Name "PauseQualityUpdatesEndTime" -Value $selectedDate -Force

            # Merestart layanan Update agar perubahan tanggal langsung muncul di aplikasi Settings Windows
            Restart-Service -Name wuauserv -Force -ErrorAction SilentlyContinue

            $tglIndo = $dtPicker.Value.ToString("dd MMMM yyyy")
            Write-Log "Success: Windows Update paused until $($selectedDate) (UTC)."
            [System.Windows.Forms.MessageBox]::Show("Windows Update berhasil ditunda hingga $tglIndo.", "Sukses", "OK", "Information")
        } catch {
            Write-Log "Failed: Error applying custom pause date. Error Details: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Gagal menyimpan pengaturan tanggal.`nDetail: $($_.Exception.Message)", "Error", "OK", "Error")
        }
    } else {
        Write-Log "Process Cancelled: User closed the Custom Date Picker dialog."
    }
}

# -------------------------------------------------------------------------
# FUNGSI 5: MENYEMBUNYIKAN UPDATE BERMASALAH (HIDE SPECIFIC UPDATE)
# -------------------------------------------------------------------------
function Action-UpdateHide {
    Write-Log "Process Started: Downloading Windows Update Hide Tool (wushowhide.diagcab)..."
    
    # URL resmi dari Server Pusat Microsoft untuk mendownload perangkat diagnostik
    $url = "http://download.microsoft.com/download/f/2/2/f22d5fdb-59cd-4275-8c95-1be17bf70b21/wushowhide.diagcab"
    $dest = "$env:TEMP\wushowhide.diagcab"

    try {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor

        # Mengunduh file dari internet dan menyimpannya ke folder Temp
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -ErrorAction Stop
        
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default

        # Memastikan file berhasil diunduh, lalu mengeksekusinya
        if (Test-Path $dest) {
            Write-Log "Success: Successfully launched wushowhide.diagcab."
            Start-Process -FilePath $dest
        } else {
            Write-Log "Failed: The file was not found after downloading."
            [System.Windows.Forms.MessageBox]::Show("File wushowhide.diagcab gagal ditemukan setelah diunduh.", "Error", "OK", "Error")
        }
    } catch {
        [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
        Write-Log "Failed: Unable to download wushowhide tool from Microsoft server. Error Details: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Gagal mengunduh tool dari Microsoft.`nPastikan internet Anda aktif.`n`nDetail: $($_.Exception.Message)", "Download Error", "OK", "Error")
    }
}

# =========================================================================
# FASE 15: RENDER ANTARMUKA (UI) WINDOWS UPDATE MANAGER
# =========================================================================

function Render-WindowsUpdates {
    # Bersihkan panel utama sebelum me-render elemen baru
    $contentPanel.Controls.Clear()
    
    # Deteksi tema aktif (Dark Mode / Light Mode)
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    # ---------------------------------------------------------------------
    # HELPER: FUNGSI PEMBUAT SUDUT MELENGKUNG (ROUNDED CORNERS)
    # ---------------------------------------------------------------------
    $SetRounded = {
        param($ctrl, $r)
        
        # Cegah error jika elemen belum memiliki dimensi
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { 
            return 
        }
        
        $D = $r * 2
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        
        # Menggambar 4 sudut melengkung
        $p.AddArc(0, 0, $D, $D, 180, 90)
        $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
        $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
        $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
        $p.CloseAllFigures()
        
        # Terapkan region/bentuk baru ke kontrol UI
        $ctrl.Region = New-Object System.Drawing.Region($p)
    }

    # ---------------------------------------------------------------------
    # WADAH UTAMA (MAIN SCROLL PANEL)
    # ---------------------------------------------------------------------
    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true

    # ---------------------------------------------------------------------
    # 1. HEADER BANNER (KARTU JUDUL)
    # ---------------------------------------------------------------------
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Windows Update Manager"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Ambil alih kendali pembaruan otomatis Windows, atur jadwal pause, atau kunci versi OS."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)
    
    # Force pembuatan Handle UI (wajib di WinForms sebelum manipulasi Region), lalu eksekusi border melengkung
    $null = $bannerCard.Handle
    &$SetRounded $bannerCard 20

    # ---------------------------------------------------------------------
    # 2. FLOW LAYOUT PANEL (GRID SISTEM UNTUK KARTU MENU)
    # ---------------------------------------------------------------------
    $flowGrid = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowGrid.Location = New-Object System.Drawing.Point(30, 150)
    $flowGrid.Width = 735 # Set lebar konstan agar sama dengan banner
    $flowGrid.AutoSize = $true
    $flowGrid.AutoSizeMode = "GrowAndShrink"
    
    # Memaksa elemen di dalamnya turun ke baris baru jika melebihi lebar 735
    $flowGrid.MaximumSize = New-Object System.Drawing.Size(735, 0) 
    $flowGrid.WrapContents = $true
    $flowGrid.AutoScroll = $false 
    $flowGrid.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 40)
    $pnlMain.Controls.Add($flowGrid)

    # ---------------------------------------------------------------------
    # HELPER FUNGSI: PEMBUAT KARTU TOMBOL (ACTION CARDS)
    # ---------------------------------------------------------------------
    function Add-UpdateCard ($Title, $Desc, $IconCode, $IconColor, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(352, 105)
        $card.Margin = New-Object System.Windows.Forms.Padding(0, 10, 15, 10)
        $card.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White}
        $card.Cursor = "Hand"

        # Ikon Kartu
        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(15, 30)
        
        try { 
            $ico.ForeColor = [System.Drawing.Color]::FromName($IconColor) 
        } catch { 
            $ico.ForeColor = [System.Drawing.Color]::FromArgb(0, 102, 204) 
        }
        $card.Controls.Add($ico)

        # Judul Kartu
        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::FromArgb(40, 40, 40)}
        $lTitle.Location = New-Object System.Drawing.Point(65, 18)
        $lTitle.Width = $card.Width - 80
        $card.Controls.Add($lTitle)

        # Deskripsi Kartu
        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(67, 48)
        $lSub.Size = New-Object System.Drawing.Size(($card.Width - 85), 45)
        $card.Controls.Add($lSub)

        # Mendaftarkan event Click ke seluruh area kartu (Background, Ikon, Judul, dan Deskripsi)
        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)
        
        # Animasi Hover (Berubah warna saat mouse di atas kartu)
        $card.Add_MouseEnter({ 
            $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(60, 60, 65)} else {[System.Drawing.Color]::FromArgb(235, 245, 255)} 
        })
        $card.Add_MouseLeave({ 
            $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White} 
        })

        $flowGrid.Controls.Add($card)
        
        $null = $card.Handle
        &$SetRounded $card 12
    }

    # ---------------------------------------------------------------------
    # 3. MENYUSUN DAFTAR KARTU KE DALAM GRID
    # ---------------------------------------------------------------------
    Add-UpdateCard "Disable Windows Update" "Hentikan paksa pembaruan otomatis hingga tahun 2075." 0xE71A "Red" { Action-UpdateDisable }
    Add-UpdateCard "Custom Pause Date" "Pilih sendiri tanggal kapan Windows Update akan dilanjutkan." 0xE787 "MediumPurple" { Action-UpdatePauseCustom }
    Add-UpdateCard "Enable Windows Update" "Kembalikan pengaturan pembaruan otomatis ke standar pabrik." 0xE898 "LimeGreen" { Action-UpdateEnable }
    Add-UpdateCard "Reset Update Components" "Perbaiki error download dengan mereset servis & folder cache." 0xE823 "Orange" { Action-UpdateReset }
    Add-UpdateCard "Hide/Show Updates" "Alat resmi Microsoft untuk sembunyikan update bermasalah." 0xE890 "DeepSkyBlue" { Action-UpdateHide }

    # ---------------------------------------------------------------------
    # 4. KARTU SPESIAL (FULL WIDTH): LOCK TARGET VERSION
    # ---------------------------------------------------------------------
    $lockCard = New-Object System.Windows.Forms.Panel
    $lockCard.Size = New-Object System.Drawing.Size(719, 105) # Memakan 2 kolom penuh
    $lockCard.Margin = New-Object System.Windows.Forms.Padding(0, 10, 15, 10)
    $lockCard.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White}
    
    $icoLock = New-Object System.Windows.Forms.Label
    $icoLock.Text = [char]0xE72E 
    $icoLock.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
    $icoLock.AutoSize = $true
    $icoLock.Location = New-Object System.Drawing.Point(15, 30)
    $icoLock.ForeColor = [System.Drawing.Color]::Gold
    $lockCard.Controls.Add($icoLock)

    $lTitleLock = New-Object System.Windows.Forms.Label
    $lTitleLock.Text = "Lock Target Version"
    $lTitleLock.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $lTitleLock.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::FromArgb(40, 40, 40)}
    $lTitleLock.Location = New-Object System.Drawing.Point(65, 18)
    $lTitleLock.AutoSize = $true
    $lockCard.Controls.Add($lTitleLock)

    $lSubLock = New-Object System.Windows.Forms.Label
    $lSubLock.Text = "Kunci OS untuk mencegah update paksa ke versi lain."
    $lSubLock.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $lSubLock.ForeColor = [System.Drawing.Color]::Gray
    $lSubLock.Location = New-Object System.Drawing.Point(67, 48)
    $lSubLock.Size = New-Object System.Drawing.Size(300, 40)
    $lockCard.Controls.Add($lSubLock)

    # --- Dropdown Menu Pilihan OS ---
    $cbOS = New-Object System.Windows.Forms.ComboBox
    $cbOS.Name = "ComboOS"
    $cbOS.Items.AddRange(@("Windows 10", "Windows 11"))
    $cbOS.SelectedIndex = 1 
    $cbOS.Size = New-Object System.Drawing.Size(105, 30)
    $cbOS.Location = New-Object System.Drawing.Point(375, 38)
    $cbOS.DropDownStyle = "DropDownList"
    $lockCard.Controls.Add($cbOS)

    # --- Dropdown Menu Pilihan Versi Rilis ---
    $cbVer = New-Object System.Windows.Forms.ComboBox
    $cbVer.Name = "ComboVer"
    $cbVer.Size = New-Object System.Drawing.Size(65, 30)
    $cbVer.Location = New-Object System.Drawing.Point(490, 38)
    $cbVer.DropDownStyle = "DropDownList"
    $cbVer.Items.AddRange(@("21H2", "22H2", "23H2", "24H2", "25H2"))
    $cbVer.SelectedIndex = 2 
    $lockCard.Controls.Add($cbVer)

    # Logika Cerdas: Ubah daftar versi otomatis berdasarkan OS yang dipilih
    $cbOS.Add_SelectedIndexChanged({
        $cVer = $this.Parent.Controls["ComboVer"]
        
        if ($cVer) {
            $cVer.Items.Clear()
            
            if ($this.SelectedItem.ToString() -eq "Windows 10") {
                # Windows 10 secara resmi hanya rilis mentok sampai 22H2
                $cVer.Items.AddRange(@("21H2", "22H2"))
                $cVer.SelectedIndex = 1 
            } else {
                # Windows 11 lanjut terus ke 23H2, 24H2, dst.
                $cVer.Items.AddRange(@("21H2", "22H2", "23H2", "24H2", "25H2"))
                $cVer.SelectedIndex = 2 
            }
        }
    })
    
    # --- Tombol Eksekusi: LOCK ---
    $btnLock = New-Object System.Windows.Forms.Button
    $btnLock.Text = "Lock"
    $btnLock.BackColor = $cP.Header
    $btnLock.ForeColor = [System.Drawing.Color]::White
    $btnLock.FlatStyle = "Flat"
    $btnLock.Size = New-Object System.Drawing.Size(60, 28)
    $btnLock.Location = New-Object System.Drawing.Point(565, 37)
    $btnLock.Cursor = "Hand"
    
    $btnLock.Add_Click({
        $cOS = $this.Parent.Controls["ComboOS"]
        $cVer = $this.Parent.Controls["ComboVer"]
        
        # Format string kunci Registry tidak boleh ada spasi (ex: "Windows10")
        $prod = $cOS.SelectedItem.ToString().Replace(" ", "")
        $ver = $cVer.SelectedItem.ToString()
        
        try {
            $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            if (-not (Test-Path $Path)) { 
                New-Item -Path $Path -Force | Out-Null 
            }
            
            Set-ItemProperty -Path $Path -Name "ProductVersion" -Value $prod -Force
            Set-ItemProperty -Path $Path -Name "TargetReleaseVersion" -Value 1 -Type DWord -Force
            Set-ItemProperty -Path $Path -Name "TargetReleaseVersionInfo" -Value $ver -Force
            
            [System.Windows.Forms.MessageBox]::Show("Berhasil dikunci!`nSistem tidak akan melewati versi $prod $ver.`nSilakan Restart PC untuk menerapkan.", "Success", "OK", "Information")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Gagal mengunci versi. Pastikan Anda menjalankan aplikasi sebagai Administrator.", "Error", "OK", "Error")
        }
    })
    $lockCard.Controls.Add($btnLock)

    # --- Tombol Eksekusi: CLEAR ---
    $btnClear = New-Object System.Windows.Forms.Button
    $btnClear.Text = "Clear"
    $btnClear.BackColor = [System.Drawing.Color]::Crimson
    $btnClear.ForeColor = [System.Drawing.Color]::White
    $btnClear.FlatStyle = "Flat"
    $btnClear.Size = New-Object System.Drawing.Size(60, 28)
    $btnClear.Location = New-Object System.Drawing.Point(635, 37)
    $btnClear.Cursor = "Hand"
    
    $btnClear.Add_Click({
        try {
            $Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            Remove-ItemProperty -Path $Path -Name "ProductVersion" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $Path -Name "TargetReleaseVersion" -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $Path -Name "TargetReleaseVersionInfo" -ErrorAction SilentlyContinue
            
            [System.Windows.Forms.MessageBox]::Show("Kunci Versi OS berhasil dihapus! Sistem akan menerima update otomatis kembali.", "Success", "OK", "Information")
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Gagal menghapus kunci versi.", "Error", "OK", "Error")
        }
    })
    $lockCard.Controls.Add($btnClear)

    $flowGrid.Controls.Add($lockCard)
    
    $null = $lockCard.Handle
    &$SetRounded $lockCard 12

    # Memasukkan semua konstruksi panel utama ke antarmuka aplikasi
    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER WINDOWS UPDATES
# ========================================================

# =========================================================================
# FASE 16: MODUL UPGRADE LISENSI & AKTIVASI
# =========================================================================

# -------------------------------------------------------------------------
# FUNGSI AKSI: UPGRADE & HAPUS LISENSI
# -------------------------------------------------------------------------
function Action-LicHome {
    Write-Log "Action Triggered: Changing Windows edition to Home..."
    $result = [System.Windows.Forms.MessageBox]::Show("Ganti ke Windows Home?", "Konfirmasi", "YesNo", "Question")
    
    if ($result -eq "Yes") { 
        Write-Log "Executing: changepk.exe /productkey YTMG3-N6DKC-DKB77-7M9GH-8HVX7"
        Start-Process "changepk.exe" -ArgumentList "/productkey YTMG3-N6DKC-DKB77-7M9GH-8HVX7" 
    } else {
        Write-Log "Process Cancelled: User aborted Windows Home edition upgrade."
    }
}

function Action-LicPro {
    Write-Log "Action Triggered: Changing Windows edition to Pro..."
    $result = [System.Windows.Forms.MessageBox]::Show("Ganti ke Windows Pro?", "Konfirmasi", "YesNo", "Question")
    
    if ($result -eq "Yes") { 
        Write-Log "Executing: changepk.exe /productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T"
        Start-Process "changepk.exe" -ArgumentList "/productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T" 
    } else {
        Write-Log "Process Cancelled: User aborted Windows Pro edition upgrade."
    }
}

function Action-LicEnt {
    Write-Log "Action Triggered: Changing Windows edition to Enterprise..."
    $result = [System.Windows.Forms.MessageBox]::Show("Ganti ke Windows Enterprise?", "Konfirmasi", "YesNo", "Question")
    
    if ($result -eq "Yes") { 
        Write-Log "Executing: changepk.exe /productkey NPPR9-FWDCX-D2C8J-H872K-2YT43"
        Start-Process "changepk.exe" -ArgumentList "/productkey NPPR9-FWDCX-D2C8J-H872K-2YT43" 
    } else {
        Write-Log "Process Cancelled: User aborted Windows Enterprise edition upgrade."
    }
}

function Action-LicRemove {
    Write-Log "Action Triggered: Removing Windows Product Key..."
    $confirm = [System.Windows.Forms.MessageBox]::Show("Ini akan menghapus Product Key dari sistem. Yakin?", "Warning", "YesNo", "Warning")
    
    if ($confirm -eq "Yes") {
        try {
            # Ubah kursor menjadi mode loading
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
            
            # Eksekusi penghapusan lisensi secara *silent* (tanpa popup)
            cscript //B "$env:SystemRoot\System32\slmgr.vbs" /upk | Out-Null
            cscript //B "$env:SystemRoot\System32\slmgr.vbs" /cpky | Out-Null
            cscript //B "$env:SystemRoot\System32\slmgr.vbs" /ckms | Out-Null
            
            # Kembalikan kursor ke normal
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
            Write-Log "Success: Windows Product Key and KMS configurations have been successfully removed."
            [System.Windows.Forms.MessageBox]::Show("Lisensi berhasil dihapus!", "Sukses", "OK", "Information")
        } catch { 
            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
            Write-Log "Failed: An error occurred while removing Windows license. Error Details: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Gagal menghapus lisensi.", "Error", "OK", "Error") 
        }
    } else {
        Write-Log "Process Cancelled: User aborted license removal."
    }
}

# -------------------------------------------------------------------------
# FUNGSI AKSI: MAS ACTIVATION & CEK STATUS
# -------------------------------------------------------------------------
function Action-RunMAS {
    $confirm = [System.Windows.Forms.MessageBox]::Show("Buka Microsoft Activation Scripts (MAS)?`nPastikan Anda terhubung ke Internet.", "Konfirmasi Aktivasi", "YesNo", "Information")
    if ($confirm -eq "Yes") {
        # Menjalankan command MAS di jendela PowerShell baru sebagai Administrator
        $psCommand = "irm https://get.activated.win | iex"
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$psCommand`"" -Verb RunAs
    }
}

function Action-CheckStatus {
    Write-Log "Process Started: Launching Activation Status Checker (Windows & Office)..."
    
    # Cek status langsung di terminal PowerShell baru tanpa membuat file .bat sementara
    $psCommand = @"
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host '          CEK STATUS AKTIVASI WINDOWS            ' -ForegroundColor Cyan
Write-Host '=================================================' -ForegroundColor Cyan
Write-Host ''
cscript //nologo `"$env:SystemRoot\System32\slmgr.vbs`" /xpr
cscript //nologo `"$env:SystemRoot\System32\slmgr.vbs`" /dli
Write-Host ''
Write-Host '=================================================' -ForegroundColor Magenta
Write-Host '          CEK STATUS AKTIVASI OFFICE             ' -ForegroundColor Magenta
Write-Host '=================================================' -ForegroundColor Magenta
Write-Host ''

`$office64 = Join-Path `$env:ProgramFiles 'Microsoft Office\Office16\ospp.vbs'
`$office32 = Join-Path `"`${env:ProgramFiles(x86)}`" 'Microsoft Office\Office16\ospp.vbs'

if (Test-Path `$office64) {
    Write-Host 'Mendeteksi instalasi Office 64-bit...' -ForegroundColor Gray
    cscript //nologo `"`$office64`" /dstatus
} elseif (Test-Path `$office32) {
    Write-Host 'Mendeteksi instalasi Office 32-bit...' -ForegroundColor Gray
    cscript //nologo `"`$office32`" /dstatus
} else {
    Write-Host '[X] Microsoft Office tidak terinstal atau file lisensi (ospp.vbs) tidak ditemukan di PC ini.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=================================================' -ForegroundColor Cyan
Read-Host 'Tekan ENTER untuk menutup jendela ini...'
"@
    
    try {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$psCommand`""
        Write-Log "Success: Activation Status Checker terminal successfully launched."
    } catch {
        Write-Log "Failed: Unable to launch Activation Checker terminal. Error Details: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Gagal membuka terminal untuk pengecekan status.", "Error", "OK", "Error")
    }
}

# -------------------------------------------------------------------------
# FUNGSI RENDER UI: LISENSI & AKTIVASI
# -------------------------------------------------------------------------
function Render-UpgradeLicense {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    # --- HELPER: PEMBUAT SUDUT KARTU MELENGKUNG ---
    $SetRounded = {
        param($ctrl, $r)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { return }
        
        $D = $r * 2
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p.AddArc(0, 0, $D, $D, 180, 90)
        $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
        $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
        $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
        $p.CloseAllFigures()
        
        $ctrl.Region = New-Object System.Drawing.Region($p)
    }

    # --- WADAH UTAMA (SCROLL PANEL) ---
    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true

    # --- 1. BANNER 1: UPGRADE EDITION ---
    $banner1 = New-Object System.Windows.Forms.Panel
    $banner1.Size = New-Object System.Drawing.Size(735, 90)
    $banner1.Location = New-Object System.Drawing.Point(30, 30)
    $banner1.BackColor = $cP.Header 

    $lblT1 = New-Object System.Windows.Forms.Label
    $lblT1.Text = "Upgrade Windows Edition"
    $lblT1.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblT1.ForeColor = [System.Drawing.Color]::White
    $lblT1.AutoSize = $true
    $lblT1.Location = New-Object System.Drawing.Point(25, 20)
    $banner1.Controls.Add($lblT1)
    
    $lblS1 = New-Object System.Windows.Forms.Label
    $lblS1.Text = "Ganti edisi Windows Anda dengan Generic Key resmi."
    $lblS1.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblS1.ForeColor = [System.Drawing.Color]::LightGray
    $lblS1.AutoSize = $true
    $lblS1.Location = New-Object System.Drawing.Point(28, 52)
    $banner1.Controls.Add($lblS1)
    
    $null = $banner1.Handle
    &$SetRounded $banner1 20
    $pnlMain.Controls.Add($banner1)

    # --- 2. GRID 1: ACTION CARDS UPGRADE ---
    $flowGrid1 = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowGrid1.Location = New-Object System.Drawing.Point(30, 140)
    $flowGrid1.Size = New-Object System.Drawing.Size(735, 230) # Tinggi cukup untuk 2 baris
    $flowGrid1.Padding = New-Object System.Windows.Forms.Padding(0)
    $pnlMain.Controls.Add($flowGrid1)

    # --- 3. BANNER 2: ACTIVATION TOOLS ---
    $banner2 = New-Object System.Windows.Forms.Panel
    $banner2.Size = New-Object System.Drawing.Size(735, 90)
    $banner2.Location = New-Object System.Drawing.Point(30, 380)
    $banner2.BackColor = [System.Drawing.Color]::MediumSeaGreen

    $lblT2 = New-Object System.Windows.Forms.Label
    $lblT2.Text = "Windows & Office Activation"
    $lblT2.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblT2.ForeColor = [System.Drawing.Color]::White
    $lblT2.AutoSize = $true
    $lblT2.Location = New-Object System.Drawing.Point(25, 20)
    $banner2.Controls.Add($lblT2)
    
    $lblS2 = New-Object System.Windows.Forms.Label
    $lblS2.Text = "Aktivasi permanen untuk sistem Windows dan Microsoft Office Anda."
    $lblS2.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblS2.ForeColor = [System.Drawing.Color]::LightGreen
    $lblS2.AutoSize = $true
    $lblS2.Location = New-Object System.Drawing.Point(28, 52)
    $banner2.Controls.Add($lblS2)
    
    $null = $banner2.Handle
    &$SetRounded $banner2 20
    $pnlMain.Controls.Add($banner2)

    # --- 4. GRID 2: ACTION CARDS ACTIVATION ---
    $flowGrid2 = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowGrid2.Location = New-Object System.Drawing.Point(30, 490)
    $flowGrid2.Size = New-Object System.Drawing.Size(735, 130) # Tinggi cukup untuk 1 baris
    $flowGrid2.Padding = New-Object System.Windows.Forms.Padding(0)
    $pnlMain.Controls.Add($flowGrid2)

    # --- HELPER FUNGSI: PEMBUAT KARTU KE DALAM GRID ---
    function Add-LicenseCard ($GridTarget, $Title, $Desc, $IconCode, $IconColor, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        # Menghitung lebar presisi agar pas menjadi 2 kolom dikurangi margin
        $cardWidth = [math]::Floor($GridTarget.Width / 2) - 35
        $card.Size = New-Object System.Drawing.Size($cardWidth, 95)
        $card.Margin = New-Object System.Windows.Forms.Padding(10)
        $card.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White}
        $card.Cursor = "Hand"

        # Ikon Kartu
        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(15, 25)
        try { 
            $ico.ForeColor = [System.Drawing.Color]::FromName($IconColor) 
        } catch { 
            $ico.ForeColor = [System.Drawing.Color]::DodgerBlue 
        }
        $card.Controls.Add($ico)

        # Judul Kartu
        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::FromArgb(40, 40, 40)}
        $lTitle.Location = New-Object System.Drawing.Point(65, 15)
        $lTitle.Width = $card.Width - 80
        $lTitle.AutoEllipsis = $true
        $card.Controls.Add($lTitle)

        # Deskripsi Kartu
        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(67, 42)
        $lSub.Size = New-Object System.Drawing.Size(($card.Width - 85), 45)
        $card.Controls.Add($lSub)

        # Registrasi Event Handler (Click)
        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)
        
        # Registrasi Animasi Hover (Warna latar berubah)
        $card.Add_MouseEnter({ 
            $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(60, 60, 65) } else { [System.Drawing.Color]::FromArgb(235, 245, 255) } 
        })
        $card.Add_MouseLeave({ 
            $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 50) } else { [System.Drawing.Color]::White } 
        })

        $GridTarget.Controls.Add($card)
        
        $null = $card.Handle
        &$SetRounded $card 12
    }

    # --- MENGISI KARTU KE GRID 1 (UPGRADE EDITION) ---
    Add-LicenseCard $flowGrid1 "Switch to Windows Home" "Downgrade atau pindah edisi ke Windows Home." 0xE80F "DeepSkyBlue" { Action-LicHome }
    Add-LicenseCard $flowGrid1 "Switch to Windows Pro" "Upgrade edisi Windows ke versi Professional." 0xE7F4 "MediumOrchid" { Action-LicPro }
    Add-LicenseCard $flowGrid1 "Switch to Enterprise" "Upgrade edisi Windows ke versi Enterprise." 0xE719 "Gold" { Action-LicEnt }
    Add-LicenseCard $flowGrid1 "Remove License" "Hapus Product Key dari sistem (Un-activate)." 0xE74D "Crimson" { Action-LicRemove }

    # --- MENGISI KARTU KE GRID 2 (ACTIVATION TOOLS) ---
    Add-LicenseCard $flowGrid2 "Run MAS Activation" "Buka tool aktivasi AIO (HWID, KMS) dari internet." 0xE73E "LimeGreen" { Action-RunMAS }
    Add-LicenseCard $flowGrid2 "Check Status" "Periksa status lisensi & aktivasi saat ini (slmgr)." 0xE9F5 "DodgerBlue" { Action-CheckStatus }

    # --- RUANG KOSONG DI BAWAH (BOTTOM SPACER) ---
    # Memastikan pengguna bisa men-scroll konten hingga ke bagian paling ujung
    $spacer = New-Object System.Windows.Forms.Panel
    $spacer.Size = New-Object System.Drawing.Size(10, 40)
    $spacer.Location = New-Object System.Drawing.Point(30, 630)
    $pnlMain.Controls.Add($spacer)

    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER WINDOWS DEFENDER
# ========================================================

# =========================================================================
# FASE 17: MODUL DOWNLOAD WINDOWS ISO & OFFICE
# =========================================================================

# -------------------------------------------------------------------------
# FUNGSI AKSI: MEMBUKA URL KE BROWSER
# -------------------------------------------------------------------------
function Action-OpenUrl ($Url) {
    if ($Url -match "^http") {
        Start-Process $Url
    } else {
        [System.Windows.Forms.MessageBox]::Show("Link belum tersedia. Silakan update script dengan URL yang benar.", "Info", "OK", "Information")
    }
}

# -------------------------------------------------------------------------
# FUNGSI RENDER UI: HALAMAN DOWNLOAD WINDOWS & OFFICE
# -------------------------------------------------------------------------
function Render-DownloadOS { 
    $contentPanel.Controls.Clear() 
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light } 

    # --- WADAH UTAMA (FLOW LAYOUT PANEL) ---
    $pnlMain = New-Object System.Windows.Forms.FlowLayoutPanel 
    $pnlMain.Dock = "Fill" 
    $pnlMain.BackColor = $cP.Bg 
    $pnlMain.AutoScroll = $true 
    
    # Alur Kiri ke Kanan dan izinkan elemen turun baris (Wrap) untuk bentuk Grid
    $pnlMain.FlowDirection = "LeftToRight" 
    $pnlMain.WrapContents = $true 

    # --- HELPER FUNGSI: MEMBUAT KARTU TOMBOL DOWNLOAD ---
    function Create-DownloadCard ($Title, $Desc, $IconCode, $ColorName, $ActionScript) { 
        $card = New-Object System.Windows.Forms.Panel 
        $card.Size = New-Object System.Drawing.Size(345, 140)  
        $card.Margin = New-Object System.Windows.Forms.Padding(15, 5, 10, 15) 
        $card.BackColor = $cP.Card 
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand 

        # Membuat sudut melengkung pada kartu
        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath 
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90) 
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90) 
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path) 

        # Ikon Kartu
        $ico = New-Object System.Windows.Forms.Label 
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24) 
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(15, 45) 
        try { 
            $ico.ForeColor = [System.Drawing.Color]::FromName($ColorName) 
        } catch { 
            $ico.ForeColor = $cP.Accent 
        } 
        
        # Judul Kartu
        $lTitle = New-Object System.Windows.Forms.Label 
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold) 
        $lTitle.ForeColor = $cP.Text
        $lTitle.Location = New-Object System.Drawing.Point(75, 15)
        $lTitle.AutoSize = $true 
        
        # Deskripsi Kartu
        $lSub = New-Object System.Windows.Forms.Label 
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular) 
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(75, 42) 
        $lSub.Size = New-Object System.Drawing.Size(250, 85)  
        $lSub.AutoSize = $false
        $lSub.AutoEllipsis = $true 

        # Warna animasi Hover
        $hover = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } 
        $normal = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } 

        # Event Handler untuk animasi Hover
        $card.Add_MouseEnter({ $this.BackColor = $hover }.GetNewClosure())
        $card.Add_MouseLeave({ $this.BackColor = $normal }.GetNewClosure()) 
        $ico.Add_MouseEnter({ $this.Parent.BackColor = $hover }.GetNewClosure())
        $ico.Add_MouseLeave({ $this.Parent.BackColor = $normal }.GetNewClosure()) 
        $lTitle.Add_MouseEnter({ $this.Parent.BackColor = $hover }.GetNewClosure())
        $lTitle.Add_MouseLeave({ $this.Parent.BackColor = $normal }.GetNewClosure()) 
        $lSub.Add_MouseEnter({ $this.Parent.BackColor = $hover }.GetNewClosure())
        $lSub.Add_MouseLeave({ $this.Parent.BackColor = $normal }.GetNewClosure()) 

        # Menambahkan komponen dan aksi klik
        $card.Controls.Add($ico)
        $card.Controls.Add($lTitle)
        $card.Controls.Add($lSub) 
        
        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript) 
        
        return $card 
    } 

    $radBanner = 20 

    # ========================================================= 
    # 1. BANNER 1: WINDOWS DOWNLOAD 
    # ========================================================= 
    $banner1 = New-Object System.Windows.Forms.Panel 
    $banner1.Size = New-Object System.Drawing.Size(715, 90)
    $banner1.Margin = New-Object System.Windows.Forms.Padding(15, 25, 15, 15) 
    $banner1.BackColor = $cP.Header  
    
    $pathB1 = New-Object System.Drawing.Drawing2D.GraphicsPath 
    $pathB1.AddArc(0, 0, $radBanner, $radBanner, 180, 90)
    $pathB1.AddArc($banner1.Width - $radBanner, 0, $radBanner, $radBanner, 270, 90) 
    $pathB1.AddArc($banner1.Width - $radBanner, $banner1.Height - $radBanner, $radBanner, $radBanner, 0, 90)
    $pathB1.AddArc(0, $banner1.Height - $radBanner, $radBanner, $radBanner, 90, 90) 
    $pathB1.CloseAllFigures()
    $banner1.Region = New-Object System.Drawing.Region($pathB1) 

    $lblT1 = New-Object System.Windows.Forms.Label
    $lblT1.Text = "Download Windows ISO"
    $lblT1.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold) 
    $lblT1.ForeColor = [System.Drawing.Color]::White
    $lblT1.AutoSize = $true
    $lblT1.Location = New-Object System.Drawing.Point(25, 20) 
    
    $lblS1 = New-Object System.Windows.Forms.Label
    $lblS1.Text = "Unduh file instalasi resmi Windows 10, Windows 11, dan versi ARM."
    $lblS1.Font = New-Object System.Drawing.Font("Segoe UI", 10) 
    $lblS1.ForeColor = [System.Drawing.Color]::LightGray
    $lblS1.AutoSize = $true
    $lblS1.Location = New-Object System.Drawing.Point(28, 52) 
    
    $banner1.Controls.Add($lblT1)
    $banner1.Controls.Add($lblS1)
    $pnlMain.Controls.Add($banner1) 

    # --- ACTION CARDS WINDOWS ---
    $pnlMain.Controls.Add((Create-DownloadCard "Windows 10" "Unduh file ISO Windows 10 (Multi-edition)." 0xE8A4 "DeepSkyBlue" { Action-OpenUrl "https://www.microsoft.com/en-us/software-download/windows10" })) 
    $pnlMain.Controls.Add((Create-DownloadCard "Windows 11" "Unduh file ISO Windows 11 terbaru." 0xE8A4 "MediumSlateBlue" { Action-OpenUrl "https://www.microsoft.com/en-us/software-download/windows11" })) 
    $pnlMain.Controls.Add((Create-DownloadCard "Windows ARM" "Unduh file instalasi Windows untuk perangkat berarsitektur ARM (Snapdragon, dll)." 0xE8A4 "Orange" { Action-OpenUrl "https://www.microsoft.com/en-us/software-download/windows11arm64" })) 

    # ========================================================= 
    # 2. BANNER 2: OFFICE DOWNLOAD 
    # ========================================================= 
    $banner2 = New-Object System.Windows.Forms.Panel 
    $banner2.Size = New-Object System.Drawing.Size(715, 90)
    $banner2.Margin = New-Object System.Windows.Forms.Padding(15, 10, 15, 15) 
    $banner2.BackColor = [System.Drawing.Color]::Tomato 
    
    $pathB2 = New-Object System.Drawing.Drawing2D.GraphicsPath 
    $pathB2.AddArc(0, 0, $radBanner, $radBanner, 180, 90)
    $pathB2.AddArc($banner2.Width - $radBanner, 0, $radBanner, $radBanner, 270, 90) 
    $pathB2.AddArc($banner2.Width - $radBanner, $banner2.Height - $radBanner, $radBanner, $radBanner, 0, 90)
    $pathB2.AddArc(0, $banner2.Height - $radBanner, $radBanner, $radBanner, 90, 90) 
    $pathB2.CloseAllFigures()
    $banner2.Region = New-Object System.Drawing.Region($pathB2) 

    $lblT2 = New-Object System.Windows.Forms.Label
    $lblT2.Text = "Download Microsoft Office"
    $lblT2.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold) 
    $lblT2.ForeColor = [System.Drawing.Color]::White
    $lblT2.AutoSize = $true
    $lblT2.Location = New-Object System.Drawing.Point(25, 20) 
    
    $lblS2 = New-Object System.Windows.Forms.Label
    $lblS2.Text = "Pilih versi Office Anda (Mendukung Online & Offline Installer)."
    $lblS2.Font = New-Object System.Drawing.Font("Segoe UI", 10) 
    $lblS2.ForeColor = [System.Drawing.Color]::MistyRose
    $lblS2.AutoSize = $true
    $lblS2.Location = New-Object System.Drawing.Point(28, 52) 
    
    $banner2.Controls.Add($lblT2)
    $banner2.Controls.Add($lblS2)
    $pnlMain.Controls.Add($banner2) 

    # --- MENU POP-UP: M365 --- 
    $global:menuM365 = New-Object System.Windows.Forms.ContextMenuStrip
    $global:menuM365.Cursor = [System.Windows.Forms.Cursors]::Hand 
    $global:menuM365.Items.Add("[Online] Installer - English").Add_Click({ 
        Write-Log "Executing URL: Microsoft 365 [Online] Installer (EN)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365ProPlusRetail&platform=x64&language=en-us&version=O16GA" 
    }) 
    $global:menuM365.Items.Add("[Online] Installer - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Microsoft 365 [Online] Installer (ID)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365ProPlusRetail&platform=x64&language=id-id&version=O16GA" 
    }) 
    $global:menuM365.Items.Add("-") # Separator 
    $global:menuM365.Items.Add("[Offline] Installer (IMG/ISO) - English").Add_Click({ 
        Write-Log "Executing URL: Microsoft 365 [Offline/IMG] Installer (EN)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/O365ProPlusRetail.img" 
    }) 
    $global:menuM365.Items.Add("[Offline] Installer (IMG/ISO) - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Microsoft 365 [Offline/IMG] Installer (ID)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/id-id/O365ProPlusRetail.img" 
    }) 

    # --- MENU POP-UP: OFFICE 2024 HOME --- 
    $global:menu24Home = New-Object System.Windows.Forms.ContextMenuStrip
    $global:menu24Home.Cursor = [System.Windows.Forms.Cursors]::Hand 
    $global:menu24Home.Items.Add("[Online] Installer - English").Add_Click({ 
        Write-Log "Executing URL: Office 2024 Home [Online] Installer (EN)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=Home2024Retail&platform=x64&language=en-us&version=O16GA" 
    }) 
    $global:menu24Home.Items.Add("[Online] Installer - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Office 2024 Home [Online] Installer (ID)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=Home2024Retail&platform=x64&language=id-id&version=O16GA" 
    }) 
    $global:menu24Home.Items.Add("-") # Separator 
    $global:menu24Home.Items.Add("[Offline] Installer (IMG/ISO) - English").Add_Click({ 
        Write-Log "Executing URL: Office 2024 Home [Offline/IMG] Installer (EN)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/Home2024Retail.img" 
    }) 
    $global:menu24Home.Items.Add("[Offline] Installer (IMG/ISO) - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Office 2024 Home [Offline/IMG] Installer (ID)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/id-id/Home2024Retail.img" 
    }) 

    # --- MENU POP-UP: OFFICE 2024 PROPLUS --- 
    $global:menu24Pro = New-Object System.Windows.Forms.ContextMenuStrip
    $global:menu24Pro.Cursor = [System.Windows.Forms.Cursors]::Hand 
    $global:menu24Pro.Items.Add("[Online] Installer - English").Add_Click({ 
        Write-Log "Executing URL: Office 2024 ProPlus [Online] Installer (EN)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=en-us&version=O16GA" 
    }) 
    $global:menu24Pro.Items.Add("[Online] Installer - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Office 2024 ProPlus [Online] Installer (ID)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=ProPlus2024Retail&platform=x64&language=id-id&version=O16GA" 
    }) 
    $global:menu24Pro.Items.Add("-") # Separator 
    $global:menu24Pro.Items.Add("[Offline] Installer (IMG/ISO) - English").Add_Click({ 
        Write-Log "Executing URL: Office 2024 ProPlus [Offline/IMG] Installer (EN)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/ProPlus2024Retail.img" 
    }) 
    $global:menu24Pro.Items.Add("[Offline] Installer (IMG/ISO) - Indonesia").Add_Click({ 
        Write-Log "Executing URL: Office 2024 ProPlus [Offline/IMG] Installer (ID)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/id-id/ProPlus2024Retail.img" 
    }) 

    # --- MENU POP-UP: VISIO PRO --- 
    $global:menuVisioPro = New-Object System.Windows.Forms.ContextMenuStrip
    $global:menuVisioPro.Cursor = [System.Windows.Forms.Cursors]::Hand 
    $global:menuVisioPro.Items.Add("[Online] Installer - English").Add_Click({ 
        Write-Log "Executing URL: Visio Pro 2024 [Online] Installer (EN)"
        Action-OpenUrl "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=VisioPro2024Retail&platform=x64&language=en-us&version=O16GA" 
    }) 
    $global:menuVisioPro.Items.Add("-") # Separator 
    $global:menuVisioPro.Items.Add("[Offline] Installer (IMG/ISO) - English").Add_Click({ 
        Write-Log "Executing URL: Visio Pro 2024 [Offline/IMG] Installer (EN)"
        Action-OpenUrl "https://officecdn.microsoft.com/db/492350f6-3a01-4f97-b9c0-c7c6ddf67d60/media/en-us/VisioPro2024Retail.img" 
    }) 

    # --- ACTION CARDS OFFICE --- 
    $btnM365 = Create-DownloadCard "Microsoft 365 ProPlus" "Apps: Access, Excel, Lync, OneNote, Outlook, PowerPoint, Publisher, Word, OneDrive.`nKlik untuk memilih mode download (Online/Offline) dan Bahasa." 0xEB41 "Crimson" {  
        Write-Log "Action Triggered: User opened Microsoft 365 ProPlus download menu."
        $global:menuM365.Show([System.Windows.Forms.Cursor]::Position)  
    } 
    $pnlMain.Controls.Add($btnM365) 

    $btn24Home = Create-DownloadCard "Office 2024 Home" "Apps: Excel, OneNote, PowerPoint, Word, OneDrive.`nKlik untuk memilih mode download (Online/Offline) dan Bahasa." 0xE8A5 "Coral" {  
        Write-Log "Action Triggered: User opened Office 2024 Home download menu."
        $global:menu24Home.Show([System.Windows.Forms.Cursor]::Position)  
    } 
    $pnlMain.Controls.Add($btn24Home) 

    $btn24Pro = Create-DownloadCard "Office 2024 ProPlus" "Apps: Access, Excel, OneNote, Outlook, PowerPoint, Word, OneDrive.`nKlik untuk memilih mode download (Online/Offline) dan Bahasa." 0xE8A5 "OrangeRed" { 
        Write-Log "Action Triggered: User opened Office 2024 ProPlus download menu."
        $global:menu24Pro.Show([System.Windows.Forms.Cursor]::Position)  
    } 
    $pnlMain.Controls.Add($btn24Pro) 

    $btnVisioPro = Create-DownloadCard "Visio Professional" "Aplikasi standar industri untuk membuat diagram, flowchart, dan denah.`nKlik untuk memilih mode download (Online/Offline) dan Bahasa." 0xE8A5 "DarkOrchid" {  
        Write-Log "Action Triggered: User opened Visio Professional download menu."
        $global:menuVisioPro.Show([System.Windows.Forms.Cursor]::Position)  
    } 
    $pnlMain.Controls.Add($btnVisioPro) 

    # ========================================================= 
    # 3. BANNER 3: OFFICE UNINSTALLER (SELECTIVE EXTRACTION)
    # ========================================================= 
    $banner3 = New-Object System.Windows.Forms.Panel
    $banner3.Size = New-Object System.Drawing.Size(715, 90)
    $banner3.Margin = New-Object System.Windows.Forms.Padding(15, 10, 15, 15)
    $banner3.BackColor = [System.Drawing.Color]::MediumVioletRed
    
    $pathB3 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pathB3.AddArc(0, 0, $radBanner, $radBanner, 180, 90)
    $pathB3.AddArc($banner3.Width - $radBanner, 0, $radBanner, $radBanner, 270, 90)
    $pathB3.AddArc($banner3.Width - $radBanner, $banner3.Height - $radBanner, $radBanner, $radBanner, 0, 90)
    $pathB3.AddArc(0, $banner3.Height - $radBanner, $radBanner, $radBanner, 90, 90)
    $pathB3.CloseAllFigures()
    $banner3.Region = New-Object System.Drawing.Region($pathB3)

    $lblT3 = New-Object System.Windows.Forms.Label
    $lblT3.Text = "Office Uninstaller Tool"
    $lblT3.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
    $lblT3.ForeColor = [System.Drawing.Color]::White
    $lblT3.AutoSize = $true
    $lblT3.Location = New-Object System.Drawing.Point(25, 20)
    
    $lblS3 = New-Object System.Windows.Forms.Label
    $lblS3.Text = "Hapus bersih instalasi Microsoft Office hingga ke registry (Cloud-Fetched)."
    $lblS3.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $lblS3.ForeColor = [System.Drawing.Color]::LavenderBlush
    $lblS3.AutoSize = $true
    $lblS3.Location = New-Object System.Drawing.Point(28, 52)
    
    $banner3.Controls.Add($lblT3)
    $banner3.Controls.Add($lblS3)
    $pnlMain.Controls.Add($banner3)

    # --- ACTION CARD: UNINSTALL OFFICE ---
    $btnUninstall = Create-DownloadCard "Uninstall Office" "Otomatis memuat dan menjalankan Office Scrubber." 0xE74D "Crimson" {
        Write-Log "Action Triggered: Office Uninstaller Tool card clicked."
        
        $confirm = [System.Windows.Forms.MessageBox]::Show(
            "Waroeng Tools akan memuat Office Scrubber.`n`nPastikan koneksi internet Anda stabil. Lanjutkan?", 
            "Konfirmasi Unduhan", 
            [System.Windows.Forms.MessageBoxButtons]::YesNo, 
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        if ($confirm -eq 'Yes') {
            Write-Log "Process Started: User confirmed Office Uninstaller operation."
            try {
                # Ubah kursor menjadi loading
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
                
                $tempDir = $env:TEMP
                $zipPath = Join-Path $tempDir "BatUtil_Temp.zip"
                $scrubDir = Join-Path $tempDir "Waroeng_OfficeScrubber"
                $scrubCmd = Join-Path $scrubDir "OfficeScrubber.cmd"

                # Hapus folder penampungan jika sebelumnya ada (Clean Slate)
                if (Test-Path $scrubDir) { 
                    Remove-Item -Path $scrubDir -Recurse -Force -ErrorAction SilentlyContinue 
                }
                New-Item -ItemType Directory -Path $scrubDir -Force | Out-Null

                # Unduh ZIP utama dari repositori GitHub
                $url = "https://github.com/abbodi1406/BatUtil/archive/refs/heads/master.zip"
                Write-Log "Executing: Downloading BatUtil master repository from GitHub..."
                Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
                
                # --- PROSES EKSTRAKSI SELEKTIF (.NET FRAMEWORK) ---
                Write-Log "Success: Download complete. Starting selective extraction of OfficeScrubber components..."
                Add-Type -AssemblyName System.IO.Compression.FileSystem
                $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
                
                foreach ($entry in $zip.Entries) {
                    # Filter Regex: Hanya ekstrak file/folder di dalam folder "OfficeScrubber"
                    if ($entry.FullName -match "^BatUtil-master/OfficeScrubber/(.+)") {
                        $relativePath = $matches[1]
                        $targetPath = Join-Path $scrubDir $relativePath
                        
                        # Jika entry adalah Folder
                        if ($entry.FullName.EndsWith("/")) {
                            if (-not (Test-Path $targetPath)) { 
                                New-Item -ItemType Directory -Path $targetPath -Force | Out-Null 
                            }
                        } 
                        # Jika entry adalah File
                        else {
                            $parentDir = Split-Path $targetPath -Parent
                            if (-not (Test-Path $parentDir)) { 
                                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null 
                            }
                            [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetPath, $true)
                        }
                    }
                }
                
                # Bebaskan resource ZIP dari memori
                $zip.Dispose()
                
                # Langsung HAPUS file ZIP master-nya
                Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
                Write-Log "Success: Extraction complete. Master ZIP deleted."

                # Kembalikan kursor ke normal
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default

                # Jalankan skrip OfficeScrubber
                if (Test-Path $scrubCmd) {
                    Write-Log "Executing: Launching OfficeScrubber.cmd via cmd.exe..."
                    # Buka terminal CMD dan tunggu pengguna selesai menggunakannya (-Wait)
                    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$scrubCmd`"" -Wait
                    
                    # PROSES PEMBERSIHAN OTOMATIS (ZERO-FOOTPRINT)
                    Write-Log "Process Completed: OfficeScrubber session ended. Executing zero-footprint cleanup..."
                    Remove-Item -Path $scrubDir -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "Success: All temporary OfficeScrubber files have been cleanly removed."
                } else {
                    Write-Log "Failed: OfficeScrubber.cmd could not be found after extraction."
                    [System.Windows.Forms.MessageBox]::Show("Gagal menemukan file OfficeScrubber.cmd setelah ekstraksi.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }

            } catch {
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
                Write-Log "Failed: An error occurred during Office Uninstaller process. Error Details: $($_.Exception.Message)"
                [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan teknis saat memuat:`n$($_.Exception.Message)", "Gagal", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
        } else {
            Write-Log "Process Cancelled: User aborted Office Uninstaller operation."
        }
    }
    
    $pnlMain.Controls.Add($btnUninstall)

    # --- RUANG KOSONG DI BAWAH (SPACER) --- 
    $spacer = New-Object System.Windows.Forms.Panel
    $spacer.Size = New-Object System.Drawing.Size(715, 40)
    $pnlMain.Controls.Add($spacer) 
    
    $contentPanel.Controls.Add($pnlMain) 
}

# ========================================================
# SELESAI RENDER DOWNLOAD ISO
# ========================================================

# ========================================================
# MODUL: WINDOWS TWEAKS RENDERER
# ========================================================

# ---------------------------------------------------------
# [BLOK 1] DATABASE WINDOWS TWEAKS
# ---------------------------------------------------------
$global:TweakCategories = @(
    [PSCustomObject]@{ 
        ID = "T1"
        Name = "Privacy Cleanup"
        Info = "Membersihkan seluruh log jejak aktivitas lokal pada sistem operasi untuk menjaga privasi Anda dari pengguna lain di komputer yang sama.

Detail Tindakan:
- Menghapus riwayat pencarian berkas dan perintah pada Windows Explorer, Run, Regedit, WordPad, dan Paint.
- Membersihkan riwayat koneksi Map Network Drive yang sudah tidak digunakan.
- Menghapus tumpukan cache berkas sementara (Temporary Files), cache Thumbnail gambar, Java, dan Adobe Flash.
- Membersihkan berkas log instalasi sistem lama (setupapi.log) untuk membebaskan ruang penyimpanan.

[INFO KEAMANAN]: Fitur ini hanya membersihkan berkas sampah dan log riwayat aktivitas sistem. Dokumen pribadi Anda (seperti Foto, Video, Musik, atau Berkas Kerja) sama sekali TIDAK AKAN disentuh atau dihapus." 
    }
    [PSCustomObject]@{ 
        ID = "T2"
        Name = "Disable OS Data Collection"
        Info = "Menghentikan sistem Windows agar tidak mengumpulkan dan mengirimkan data penggunaan perangkat serta aktivitas harian Anda ke server Microsoft secara diam-diam.

Detail Tindakan:
- Mematikan fitur Telemetri OS (CEIP / Customer Experience Improvement Program) dan Diagnostic Data.
- Menonaktifkan Windows Error Reporting (WER) sehingga log sistem tidak dikirim ke luar secara otomatis saat aplikasi crash.
- Mematikan fungsi pelacakan otomatis dari Microsoft SpyNet dan cloud pertahanan MAPS.
- Menghentikan perekaman pola pengetikan keyboard dan pengenalan tinta digital (Ink & Typing Recognition).
- Menonaktifkan fitur perekaman kronologi aktivitas latar belakang (Activity Feed / Timeline).

[INFO KEAMANAN]: Mematikan pengiriman data latar belakang ini justru akan menghemat kuota internet Anda, meningkatkan privasi total, dan mengurangi beban kerja CPU." 
    }
    [PSCustomObject]@{ 
        ID = "T3"
        Name = "Configure Programs"
        Info = "Menonaktifkan modul telemetri, iklan, dan pelacakan internal tersembunyi yang tertanam di dalam aplikasi bawaan Windows maupun aplikasi pihak ketiga.

Detail Tindakan:
- Mematikan pelacakan aktivitas pencarian pada peramban Microsoft Edge dan asisten virtual Cortana.
- Menonaktifkan fitur pengiriman sampel berkas otomatis dari Windows Defender ke server eksternal.
- Mematikan fitur pelacakan dan sinkronisasi konstan pada komponen gaming bawaan (Xbox Live & Xbox Game Bar).
- Memblokir pengumpulan log data otomatis pada program produktivitas kerja (Microsoft Office, Visual Studio).
- Mematikan fungsi pelacakan iklan (Ad-tracking) on aplikasi utilitas pihak ketiga seperti CCleaner.

[INFO KEAMANAN]: Semua aplikasi di atas akan tetap berfungsi dengan normal dan stabil. Skrip ini hanya menutup jalur 'mata-mata' dan pengiriman data analitik di dalam aplikasi tersebut." 
    }
    [PSCustomObject]@{ 
        ID = "T4"
        Name = "Security Improvements"
        Info = "Memperketat keamanan sistem Windows dengan menutup celah-celah kritis yang sering dieksploitasi oleh malware, ransomware, maupun peretas jarak jauh.

Detail Tindakan:
- Mengaktifkan protokol enkripsi jaringan modern terbaru (TLS 1.3 dan DTLS 1.2) serta memaksa aplikasi berbasis .NET menggunakannya.
- Mematikan fitur Cloud Clipboard History untuk mencegah kebocoran teks sensitif (seperti password atau nomor rekening yang tidak sengaja tersalin).
- Mengaktifkan perlindungan memori tingkat lanjut (DEP & Exception Chain Validation/SEHOP) guna menangkal injeksi kode berbahaya ke RAM.
- Mencegah serangan Downgrade dengan mencabut fitur usang PowerShell 2.0 yang kerap dimanfaatkan hacker untuk menembus antivirus.
- Mematikan fitur rentan Windows Connect Now (WCN) yang memiliki celah eksploitasi tinggi pada jaringan nirkabel.

[INFO KEAMANAN]: Tweak ini murni berfokus pada penguatan dinding pertahanan OS. Tidak ada fitur harian yang terganggu, dan koneksi internet Anda akan tetap berjalan normal dengan perlindungan yang jauh lebih kuat." 
    }
    [PSCustomObject]@{ 
        ID = "T5"
        Name = "Block Tracking Hosts"
        Info = "Membangun sistem pemblokiran jaringan dua lapis yang tegas untuk memastikan komputer Anda tidak dapat terhubung ke server pelacak, iklan, maupun telemetri.

Detail Tindakan:
- Menyuntikkan daftar blokir (Blocklist) berisi ratusan domain pelacak (seperti telemetri Windows, Dropbox, Spotify, MSN Ads) langsung ke file Hosts lokal (dialihkan ke IP kosong 0.0.0.0).
- Membuat aturan otomatis (Rule) pada Windows Firewall untuk memblokir rentang IP/Subnet server telemetri Microsoft yang dikenal agresif.

[INFO KEAMANAN]: Metode ini bekerja secara pasif di tingkat sistem jaringan tanpa menggunakan aplikasi pihak ketiga yang berat. Proses ini juga dapat membuat loading internet terasa sedikit lebih cepat karena iklan dan tracker langsung dibendung sebelum terunduh." 
    }
    [PSCustomObject]@{ 
        ID = "T7"
        Name = "UI For Privacy"
        Info = "Merapikan tampilan antarmuka (UI) Windows sekaligus melindungi privasi visual Anda agar aktivitas kerja tidak mudah diintip atau dilihat oleh orang di sekitar Anda.

Detail Tindakan:
- Menyembunyikan daftar berkas dan folder yang baru saja dibuka (Recent Files) pada menu Quick Access di File Explorer.
- Menonaktifkan rekomendasi atau saran aplikasi yang sering dibuka pada Start Menu.
- Mematikan riwayat pencarian otomatis (Search History) pada kolom pencarian utama Windows Taskbar.
- Menghilangkan tayangan iklan promosi, tips Windows, dan saran Timeline yang mengganggu di layar kunci (Lock Screen).

[INFO KEAMANAN]: Perubahan ini murni bersifat kosmetik/visual pada sistem. Tidak ada data riwayat yang dihapus secara permanen dari komputer, sistem hanya menyembunyikannya dari layar agar lingkungan kerja Anda terlihat bersih dan privat." 
    }
    [PSCustomObject]@{ 
        ID = "T8"
        Name = "Remove Bloatware"
        Info = "Mencabut paksa aplikasi bawaan sistem (Bloatware) yang tidak penting, jarang digunakan, memenuhi kapasitas penyimpanan, serta sering berjalan diam-diam di latar belakang.

Detail Tindakan:
- Mencabut paksa aplikasi pihak ketiga dan game sponsor bawaan pabrik (seperti Candy Crush, Spotify, Duolingo, Shazam).
- Menghapus bersih aplikasi UWP Microsoft yang memakan ruang (Xbox Apps, 3D Viewer, Solitaire Collection, MSN News, Weather, Sports, Maps).
- Membongkar OneDrive beserta seluruh layanannya secara tuntas hingga ke akar sistem (sangat efektif mengatasi masalah Disk Usage 100%).
- Menonaktifkan fitur berat yang tidak semua orang pakai seperti Windows Copilot dan menu Meet Now di Taskbar.
- Mematikan layanan latar belakang (Background Services) yang tidak penting untuk menghemat konsumsi RAM.

[INFO KEAMANAN]: Aplikasi vital inti Windows (seperti Microsoft Store / App Store) TIDAK AKAN DIHAPUS. Dengan begitu, Anda tetap bisa mengunduh aplikasi lain kapan saja, kapasitas penyimpanan menjadi lebih lega, dan RAM komputer akan menjadi jauh lebih hemat." 
    }
)

# ==========================================
# [BLOK 2] RENDER MENU TWEAKS (APPLY & REVERT)
# ==========================================
function Render-WindowsTweaks { 
    $contentPanel.Controls.Clear() 
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $false 

    $script:twk_toolTip = New-Object System.Windows.Forms.ToolTip
    $script:twk_toolTip.IsBalloon = $true

    $script:CatCheckboxes = @()

    # --- HELPER: Fungsi Pembuat Sudut Bulat ---
    # --- HELPER: Fungsi Pembuat Sudut Bulat ---
    function Set-RoundedElement {
        param(
            [System.Windows.Forms.Control]$ctrl, 
            [int]$radius
        )
        $D = $radius * 2
        
        # Eksekusi instan saat elemen dibuat
        if ($ctrl.Width -gt $D -and $ctrl.Height -gt $D) {
            $p = New-Object System.Drawing.Drawing2D.GraphicsPath
            $p.AddArc(0, 0, $D, $D, 180, 90)
            $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
            $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
            $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
            $p.CloseAllFigures()
            $ctrl.Region = New-Object System.Drawing.Region($p)
        }

        # Event Resize otomatis (DIPERBAIKI DENGAN GetNewClosure)
        $ctrl.Add_SizeChanged({
            $D = $radius * 2
            if ($this.Width -gt $D -and $this.Height -gt $D) {
                $p = New-Object System.Drawing.Drawing2D.GraphicsPath
                $p.AddArc(0, 0, $D, $D, 180, 90)
                $p.AddArc($this.Width - $D, 0, $D, $D, 270, 90)
                $p.AddArc($this.Width - $D, $this.Height - $D, $D, $D, 0, 90)
                $p.AddArc(0, $this.Height - $D, $D, $D, 90, 90)
                $p.CloseAllFigures()
                $this.Region = New-Object System.Drawing.Region($p)
            }
        }.GetNewClosure()) # <--- INI KUNCI PERBAIKANNYA (Baris 4060 di kodemu)
    }

    # ----------------------------------------------------
    # PANEL ATAS: QUICK PRESETS
    # ----------------------------------------------------
    $pnlPresets = New-Object System.Windows.Forms.Panel
    $pnlPresets.Dock = "Top"
    $pnlPresets.Height = 85
    $pnlPresets.BackColor = $cP.Header
    $pnlMain.Controls.Add($pnlPresets)

    Set-RoundedElement -ctrl $pnlPresets -radius 15

    $lblPreset = New-Object System.Windows.Forms.Label
    $lblPreset.Text = "Quick Presets :"
    $lblPreset.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lblPreset.ForeColor = [System.Drawing.Color]::White
    $lblPreset.AutoSize = $true
    $lblPreset.Location = New-Object System.Drawing.Point(25, 32)
    $pnlPresets.Controls.Add($lblPreset)

    # Helper: Pembuat Tombol Preset
    function Create-PresetButton([string]$Text, [int]$X, [System.Drawing.Color]$Color, $TargetCats) {
        $btn = New-Object System.Windows.Forms.Button
        $btn.Text = $Text
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
        $btn.Size = New-Object System.Drawing.Size(180, 40)
        $btn.Location = New-Object System.Drawing.Point($X, 22)
        $btn.BackColor = $Color
        $btn.ForeColor = [System.Drawing.Color]::White
        $btn.FlatStyle = "Flat"
        $btn.FlatAppearance.BorderSize = 0
        $btn.Cursor = "Hand"
        
        Set-RoundedElement -ctrl $btn -radius 15
        $btn.Tag = $TargetCats

        $btn.Add_Click({
            $targets = $this.Tag
            foreach ($chk in $script:CatCheckboxes) {
                if ($targets -eq "ALL") {
                    $chk.Checked = $true
                } 
                elseif ($targets -contains $chk.Name) {
                    $chk.Checked = $true
                } 
                else {
                    $chk.Checked = $false
                }
            }
        })
        return $btn
    }

    $pnlPresets.Controls.Add((Create-PresetButton -Text "ESSENTIAL" -X 160 -Color ([System.Drawing.Color]::SeaGreen) -TargetCats @("Privacy Cleanup", "Remove Bloatware")))
    $pnlPresets.Controls.Add((Create-PresetButton -Text "OPTIMAL" -X 355 -Color ([System.Drawing.Color]::SteelBlue) -TargetCats @("Privacy Cleanup", "Disable OS Data Collection", "Configure Programs", "UI For Privacy", "Remove Bloatware")))
    $pnlPresets.Controls.Add((Create-PresetButton -Text "ULTIMATE" -X 550 -Color ([System.Drawing.Color]::Crimson) -TargetCats "ALL"))

    # ----------------------------------------------------
    # PANEL BAWAH: EXECUTE & RESET
    # ----------------------------------------------------
    $pnlBot = New-Object System.Windows.Forms.Panel
    $pnlBot.Dock = "Bottom"
    $pnlBot.Height = 75
    $pnlBot.BackColor = $cP.Header
    $pnlMain.Controls.Add($pnlBot)

    Set-RoundedElement -ctrl $pnlBot -radius 15

    # Tombol Execute
    $btnApplyMain = New-Object System.Windows.Forms.Button
    $btnApplyMain.Text = "EXECUTE SELECTED CATEGORIES"
    $btnApplyMain.Size = New-Object System.Drawing.Size(320, 45)
    $btnApplyMain.Location = New-Object System.Drawing.Point(25, 15)
    $btnApplyMain.BackColor = [System.Drawing.Color]::Teal
    $btnApplyMain.ForeColor = [System.Drawing.Color]::White
    $btnApplyMain.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $btnApplyMain.FlatStyle = "Flat"
    $btnApplyMain.FlatAppearance.BorderSize = 0
    $btnApplyMain.Cursor = "Hand"
    Set-RoundedElement -ctrl $btnApplyMain -radius 18 
    $pnlBot.Controls.Add($btnApplyMain)

    # Tombol Reset
    $btnClearMain = New-Object System.Windows.Forms.Button
    $btnClearMain.Text = "RESET"
    $btnClearMain.Size = New-Object System.Drawing.Size(120, 45)
    $btnClearMain.Location = New-Object System.Drawing.Point(360, 15)
    $btnClearMain.BackColor = [System.Drawing.Color]::Firebrick
    $btnClearMain.ForeColor = [System.Drawing.Color]::White
    $btnClearMain.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $btnClearMain.FlatStyle = "Flat"
    $btnClearMain.FlatAppearance.BorderSize = 0
    $btnClearMain.Cursor = "Hand"
    Set-RoundedElement -ctrl $btnClearMain -radius 18 
    
    $btnClearMain.Add_Click({
        foreach ($cb in $script:CatCheckboxes) { 
            $cb.Checked = $false 
        }
    })
    $pnlBot.Controls.Add($btnClearMain)

    # ----------------------------------------------------
    # LOGIKA EKSEKUSI (SWITCH BLOCK & RUNNER)
    # ----------------------------------------------------

    $btnApplyMain.Add_Click({
        Write-Log "Action Triggered: User initiated 'Execute Selected Categories'."
        
        $selectedCats = @()
        foreach ($cb in $script:CatCheckboxes) {
            if ($cb.Checked) { 
                $selectedCats += $cb.Name 
            }
        }
        
        if ($selectedCats.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Harap centang minimal 1 kategori!", "Peringatan", "OK", "Warning")
            return
        }
        
        $msg = "Anda akan mengeksekusi $($selectedCats.Count) Kategori Tweak di tab baru.`nLanjutkan?"
        if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi", "YesNo", "Question") -eq "No") { 
            return 
        }

        # --- MEMBUAT SCRIPT POWERSHELL (.ps1) ---
        $masterScript = @'
# Mengubah ukuran jendela terminal agar terlihat rapi
$Host.UI.RawUI.WindowTitle = "Waroeng Tools - Applying Tweaks"
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "       APPLYING SELECTED WINDOWS TWEAKS          " -ForegroundColor Cyan
Write-Host "=================================================`n" -ForegroundColor Cyan
'@

        foreach ($catName in $selectedCats) {
            Write-Log "-> Selected Tweak to Apply: $catName"
            
            # --- DESAIN BOX PEMBATAS UNTUK SETIAP TWEAK (BARU) ---
            $masterScript += @"
`nWrite-Host "=================================================" -ForegroundColor Yellow
Write-Host " -> MEMPROSES KATEGORI: $catName" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow`n
"@
            
            switch ($catName) {
                "Privacy Cleanup" {
                    $masterScript += @'
# =====================================================================
# SCRIPT PRIVACY CLEANUP (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan tool ini sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU)
# ---------------------------------------------------------------------

# Fungsi untuk membersihkan value di dalam Registry Key (Mendukung rekursif)
function Clear-RegistryKeyValues {
    param(
        [string]$RegistryPath, 
        [switch]$Recurse
    )
    try {
        if (-Not (Test-Path -LiteralPath $RegistryPath)) {
            Write-Host "   [Dilewati] Kunci Registry tidak ditemukan: '$RegistryPath'" -ForegroundColor DarkGray
            return
        }
        
        # Hapus value langsung di dalam key
        $directValueNames = (Get-Item -LiteralPath $RegistryPath -ErrorAction Stop).Property
        if ($directValueNames) {
            foreach ($valueName in $directValueNames) {
                if ($valueName -ne "(default)") {
                    Remove-ItemProperty -LiteralPath $RegistryPath -Name $valueName -ErrorAction SilentlyContinue
                }
            }
            Write-Host "   [Selesai] Membersihkan nilai di '$RegistryPath'" -ForegroundColor Green
        }

        # Jika butuh hapus subkey (rekursif)
        if ($Recurse) {
            $subKeys = Get-ChildItem -LiteralPath $RegistryPath -ErrorAction SilentlyContinue
            foreach ($subKey in $subKeys) {
                Clear-RegistryKeyValues -RegistryPath $subKey.PSPath -Recurse
            }
        }
    } catch {
        Write-Warning "Gagal membersihkan nilai registry di '$RegistryPath'. Error: $_"
    }
}

# Fungsi untuk membersihkan isi direktori
function Clear-DirectoryContents {
    param([string]$DirectoryGlob)
    try {
        $expandedPath = [System.Environment]::ExpandEnvironmentVariables($DirectoryGlob)
        Get-ChildItem -Path $expandedPath -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "   [Selesai] Membersihkan isi dari: '$expandedPath'" -ForegroundColor Green
    } catch {
        Write-Warning "Gagal membersihkan direktori '$DirectoryGlob': $_"
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI CLEANUP
# ---------------------------------------------------------------------
Write-Host "=== Memulai Pembersihan Privasi (Privacy Cleanup) ===" -ForegroundColor Magenta

# 1. Clear Windows Registry last-accessed key
Write-Host "-> 1. Membersihkan kunci riwayat akses terakhir di Windows Registry" -ForegroundColor Cyan
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit" -Name "LastKey" -ErrorAction SilentlyContinue

# 2. Clear Windows Registry favorite locations
Write-Host "-> 2. Membersihkan lokasi favorit di Regedit" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites"

# 3. Clear recent application history
Write-Host "-> 3. Membersihkan riwayat aplikasi yang baru saja dibuka" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedMRU"
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU"
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy"

# 4. Clear Adobe recent file history
Write-Host "-> 4. Membersihkan riwayat berkas Adobe yang baru dibuka" -ForegroundColor Cyan
Remove-Item -Path "HKCU:\Software\Adobe\MediaBrowser\MRU" -Force -Recurse -ErrorAction SilentlyContinue

# 5. Clear Microsoft Paint recent files history
Write-Host "-> 5. Membersihkan riwayat berkas Microsoft Paint yang baru dibuka" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List"

# 6. Clear WordPad recent file history
Write-Host "-> 6. Membersihkan riwayat berkas WordPad yang baru dibuka" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List"

# 7. Clear network drive mapping history
Write-Host "-> 7. Membersihkan riwayat pemetaan network drive (Map Network Drive)" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU"

# 8. Clear Windows Search history
Write-Host "-> 8. Membersihkan riwayat Pencarian Windows (Windows Search)" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Search Assistant\ACMru" -Recurse
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery"
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\SearchHistory" -Recurse
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\Windows\ConnectedSearch\History\*"

# 9. Clear recent files and folders history
Write-Host "-> 9. Membersihkan riwayat berkas dan folder yang baru dibuka" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" -Recurse
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU" -Recurse
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU" -Recurse
Clear-DirectoryContents "%APPDATA%\Microsoft\Windows\Recent Items\*"

# 10. Clear Windows Media Player & MPC recent activity history
Write-Host "-> 10. Membersihkan riwayat aktivitas Media Player & MPC" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\MediaPlayer\Player\RecentFileList"
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\MediaPlayer\Player\RecentURLList"
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Gabest\Media Player Classic\Recent File List"

# 11. Clear DirectX recent application history
Write-Host "-> 11. Membersihkan riwayat aplikasi DirectX yang baru dibuka" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Direct3D\MostRecentApplication"

# 12. Clear Windows Run command history
Write-Host "-> 12. Membersihkan riwayat perintah Windows Run" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"

# 13. Clear File Explorer address bar history
Write-Host "-> 13. Membersihkan riwayat address bar di File Explorer" -ForegroundColor Cyan
Clear-RegistryKeyValues -RegistryPath "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"

# 14. Clear privacy.sexy script history and logs
Write-Host "-> 14. Membersihkan riwayat dan log skrip privacy.sexy" -ForegroundColor Cyan
Clear-DirectoryContents "%APPDATA%\privacy.sexy\runs\*"
Clear-DirectoryContents "%APPDATA%\privacy.sexy\logs\*"

# 15. Clear Steam dumps, traces, and cache
Write-Host "-> 15. Membersihkan file dump, jejak, dan cache Steam" -ForegroundColor Cyan
Clear-DirectoryContents "%PROGRAMFILES(X86)%\Steam\Dumps\*"
Clear-DirectoryContents "%PROGRAMFILES(X86)%\Steam\Traces\*"
Clear-DirectoryContents "%ProgramFiles(x86)%\Steam\appcache\*"

# 16. Clear offline Visual Studio usage telemetry & App Insights
Write-Host "-> 16. Membersihkan telemetri offline Visual Studio & Application Insights" -ForegroundColor Cyan
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSCommon\14.0\SQM\*"
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSCommon\15.0\SQM\*"
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSCommon\16.0\SQM\*"
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSCommon\17.0\SQM\*"
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSApplicationInsights\*"

# 17. Clear Visual Studio Application Insights logs
Write-Host "-> 17. Membersihkan log Application Insights Visual Studio" -ForegroundColor Cyan
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\VSApplicationInsights\*"
Clear-DirectoryContents "%PROGRAMDATA%\Microsoft\VSApplicationInsights\*"
Clear-DirectoryContents "%TEMP%\Microsoft\VSApplicationInsights\*"

# 18. Clear Visual Studio telemetry data
Write-Host "-> 18. Membersihkan data telemetri Visual Studio" -ForegroundColor Cyan
Clear-DirectoryContents "%APPDATA%\vstelemetry\*"
Clear-DirectoryContents "%PROGRAMDATA%\vstelemetry\*"

# 19. Clear Visual Studio temporary telemetry and log data
Write-Host "-> 19. Membersihkan data sementara telemetri dan log Visual Studio" -ForegroundColor Cyan
Clear-DirectoryContents "%TEMP%\VSFaultInfo\*"
Clear-DirectoryContents "%TEMP%\VSFeedbackPerfWatsonData\*"
Clear-DirectoryContents "%TEMP%\VSFeedbackVSRTCLogs\*"
Clear-DirectoryContents "%TEMP%\VSFeedbackIntelliCodeLogs\*"
Clear-DirectoryContents "%TEMP%\VSRemoteControl\*"
Clear-DirectoryContents "%TEMP%\Microsoft\VSFeedbackCollector\*"
Clear-DirectoryContents "%TEMP%\VSTelem\*"
Clear-DirectoryContents "%TEMP%\VSTelem.Out\*"

# 20. Clear Visual Studio 2010 license
Write-Host "-> 20. Membersihkan lisensi Visual Studio 2010" -ForegroundColor Cyan
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\77550D6B-6352-4E77-9DA3-537419DF564B" -Force -Recurse -ErrorAction SilentlyContinue

# 21. Clear Visual Studio 2013 - 2022 licenses
Write-Host "-> 21. Membersihkan lisensi Visual Studio 2013-2022" -ForegroundColor Cyan
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\E79B3F9C-6543-4897-BBA5-5BFB0A02BB5C" -Force -Recurse -ErrorAction SilentlyContinue # VS 2013
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\4D8CFBCB-2F6A-4AD2-BABF-10E28F6F2C8F" -Force -Recurse -ErrorAction SilentlyContinue # VS 2015
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\5C505A59-E312-4B89-9508-E162F8150517" -Force -Recurse -ErrorAction SilentlyContinue # VS 2017
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA" -Force -Recurse -ErrorAction SilentlyContinue # VS 2019
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\B16F0CF0-8AD1-4A5B-87BC-CB0DBE9C48FC" -Force -Recurse -ErrorAction SilentlyContinue # VS 2022
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\10D17DBA-761D-4CD8-A627-984E75A58700" -Force -Recurse -ErrorAction SilentlyContinue # VS 2022
Remove-Item -Path "HKLM:\SOFTWARE\Classes\Licenses\1299B4B9-DFCC-476D-98F0-F65A2B46C96D" -Force -Recurse -ErrorAction SilentlyContinue # VS 2022

# 22. Clear Application Caches and Traces (Listary, Java, Flash, Dotnet)
Write-Host "-> 22. Membersihkan cache aplikasi (Listary, Java, Flash, Dotnet CLI)" -ForegroundColor Cyan
Clear-DirectoryContents "%APPDATA%\Listary\UserData\*"
Clear-DirectoryContents "%APPDATA%\Sun\Java\Deployment\cache\*"
Clear-DirectoryContents "%APPDATA%\Macromedia\Flash Player\*"
Clear-DirectoryContents "%USERPROFILE%\.dotnet\TelemetryStorageService\*"

# 23. Clear System and User Temporary Folders
Write-Host "-> 23. Membersihkan Folder Temp (Sementara) Sistem dan Pengguna" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Temp\*"
Clear-DirectoryContents "%TEMP%\*"

# 24. Clear Prefetch
Write-Host "-> 24. Membersihkan folder Prefetch" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Prefetch\*"

# 25. Clear Windows Update and Diagnostics Logs
Write-Host "-> 25. Membersihkan log pembaruan Windows dan scan SFC" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Temp\CBS\*"
Clear-DirectoryContents "%SYSTEMROOT%\Logs\waasmedic\*"

# 26. Clear "Cryptographic Services" diagnostic traces
Write-Host "-> 26. Membersihkan jejak diagnostik Cryptographic Services" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\System32\catroot2\dberr.txt" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\System32\catroot2.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\System32\catroot2.jrs" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\System32\catroot2.edb" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\System32\catroot2.chk" -Force -ErrorAction SilentlyContinue

# 27. Clear Server-initiated Healing Events system logs
Write-Host "-> 27. Membersihkan log sistem Server-initiated Healing Events (SIH)" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Logs\SIH\*"

# 28. Clear Windows Update Traces logs
Write-Host "-> 28. Membersihkan log jejak Windows Update" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Traces\WindowsUpdate\*"

# 29. Clear System Root Logs (COM+, DTC, File Rename, Windows Update Installation)
Write-Host "-> 29. Membersihkan log Komponen Opsional, DTC, File Rename, dan Setup" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\comsetup.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\DtcInstall.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\PFRO.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\setupact.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\setuperr.log" -Force -ErrorAction SilentlyContinue

# 30. Clear Windows Setup Logs & Panther directory
Write-Host "-> 30. Membersihkan log Windows Setup dan direktori Panther" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\setupapi.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\inf\setupapi.app.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\inf\setupapi.dev.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\inf\setupapi.offline.log" -Force -ErrorAction SilentlyContinue
Clear-DirectoryContents "%SYSTEMROOT%\Panther\*"

# 31. Clear Windows System Assessment Tool (WinSAT) logs
Write-Host "-> 31. Membersihkan log Windows System Assessment Tool (WinSAT)" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\Performance\WinSAT\winsat.log" -Force -ErrorAction SilentlyContinue

# 32. Clear Password Change Events log
Write-Host "-> 32. Membersihkan log kejadian perubahan kata sandi" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\debug\PASSWD.LOG" -Force -ErrorAction SilentlyContinue

# 33. Clear User Web Cache database
Write-Host "-> 33. Membersihkan database Web Cache Pengguna" -ForegroundColor Cyan
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\Windows\WebCache\*"

# 34. Clear System Temp Folder (LocalService)
Write-Host "-> 34. Membersihkan Folder Temp Sistem (LocalService)" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\ServiceProfiles\LocalService\AppData\Local\Temp\*"

# 35. Clear DISM and CBS System logs
Write-Host "-> 35. Membersihkan log DISM dan CBS" -ForegroundColor Cyan
Remove-Item -Path "$env:SYSTEMROOT\Logs\CBS\CBS.log" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SYSTEMROOT\Logs\DISM\DISM.log" -Force -ErrorAction SilentlyContinue

# 36. Clear Windows Update files (SoftwareDistribution)
Write-Host "-> 36. Membersihkan cache Windows Update (SoftwareDistribution)" -ForegroundColor Cyan
try {
    $wuService = Get-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    if ($wuService -and $wuService.Status -eq 'Running') {
        Write-Host "   Menghentikan Layanan Windows Update (wuauserv)..." -ForegroundColor Yellow
        Stop-Service -Name "wuauserv" -Force -ErrorAction Stop
        $wuService.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(15))
    }
    
    # Hapus file cache update
    Clear-DirectoryContents "%SYSTEMROOT%\SoftwareDistribution\*"
    
    if ($wuService) {
        Write-Host "   Memulai ulang Layanan Windows Update (wuauserv)..." -ForegroundColor Yellow
        Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Gagal membersihkan folder SoftwareDistribution. Layanan Windows Update mungkin terkunci: $_"
}

# 37. Clear Common Language Runtime (CLR) logs
Write-Host "-> 37. Membersihkan log Common Language Runtime (CLR)" -ForegroundColor Cyan
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\CLR_v4.0\UsageTraces\*"
Clear-DirectoryContents "%LOCALAPPDATA%\Microsoft\CLR_v4.0_32\UsageTraces\*"

# 38. Clear Network Setup Service & Disk Cleanup logs
Write-Host "-> 38. Membersihkan log Pengaturan Jaringan dan Disk Cleanup" -ForegroundColor Cyan
Clear-DirectoryContents "%SYSTEMROOT%\Logs\NetSetup\*"
Clear-DirectoryContents "%SYSTEMROOT%\System32\LogFiles\setupcln\*"

# 39. Clear Thumbnail Cache
Write-Host "-> 39. Membersihkan cache Thumbnail Explorer" -ForegroundColor Cyan
Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.db" -Force -ErrorAction SilentlyContinue

# 40. Clear Diagnostics tracking logs (DiagTrack/Telemetri)
Write-Host "-> 40. Membersihkan log pelacakan Diagnostik (DiagTrack/Telemetri)" -ForegroundColor Cyan
try {
    $diagService = Get-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    if ($diagService -and $diagService.Status -eq 'Running') {
        Write-Host "   Menghentikan layanan Telemetri (DiagTrack)..." -ForegroundColor Yellow
        Stop-Service -Name "DiagTrack" -Force -ErrorAction Stop
        $diagService.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(10))
    }
    
    # Hapus file .etl secara paksa (Abaikan takeown/icacls CMD yang lambat)
    $diagPaths = @(
        "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl",
        "$env:PROGRAMDATA\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\AutoLogger-Diagtrack-Listener.etl"
    )
    foreach ($etlPath in $diagPaths) {
        if (Test-Path $etlPath) {
            Remove-Item -Path $etlPath -Force -ErrorAction SilentlyContinue
        }
    }
    
    if ($diagService) {
        Write-Host "   Memulai ulang layanan DiagTrack..." -ForegroundColor Yellow
        Start-Service -Name "DiagTrack" -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Gagal membersihkan log ETL DiagTrack: $_"
}

# 41. Clear ALL event logs in Event Viewer
Write-Host "-> 41. Membersihkan SEMUA Log Event Viewer (Ini mungkin memakan waktu)..." -ForegroundColor Cyan
try {
    # Fix permission bug on LiveId/Operational first (dari script aslinya)
    & wevtutil sl Microsoft-Windows-LiveId/Operational /ca:O:BAG:SYD:`(A`;`;0x1`;`;`;SY`)`(A`;`;0x5`;`;`;BA`)`(A`;`;0x1`;`;`;LA`) *>&1 | Out-Null
    
    # Dapatkan semua nama log dan bersihkan
    $logs = Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LogName
    $clearedCount = 0
    foreach ($log in $logs) {
        & wevtutil cl $log *>&1 | Out-Null
        $clearedCount++
    }
    Write-Host "   Berhasil membersihkan $clearedCount Log Event." -ForegroundColor Green
} catch {
    Write-Warning "Gagal membersihkan beberapa log Event Viewer: $_"
}

# 42. Clear Defender scan (protection) history
Write-Host "-> 42. Membersihkan riwayat pemindaian Windows Defender" -ForegroundColor Cyan
Clear-DirectoryContents "%ProgramData%\Microsoft\Windows Defender\Scans\History\*"

# 43. Empty Recycle Bin
Write-Host "-> 43. Mengosongkan Recycle Bin" -ForegroundColor Cyan
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# 44. Clear previous Windows installations (Windows.old)
Write-Host "-> 44. Membersihkan instalasi Windows sebelumnya (Windows.old)" -ForegroundColor Cyan
if (Test-Path "$env:SystemDrive\Windows.old") {
    Write-Host "   Ditemukan Windows.old! Mengambil alih hak akses dan menghapus (ini mungkin memakan waktu)..." -ForegroundColor Yellow
    # Memaksa ambil alih hak akses folder Windows.old (agar tidak Access Denied)
    & takeown /f "$env:SystemDrive\Windows.old" /a /r /d y *>&1 | Out-Null
    & icacls "$env:SystemDrive\Windows.old" /grant "*S-1-5-32-544:F" /t /c /q *>&1 | Out-Null
    
    # Hapus folder secara paksa setelah hak akses diberikan
    Remove-Item -Path "$env:SystemDrive\Windows.old" -Force -Recurse -ErrorAction SilentlyContinue
}

Write-Host "=== Pembersihan Privasi (Privacy Cleanup) Selesai ===" -ForegroundColor Magenta
'@
                }
                "Disable OS Data Collection" {
                $masterScript += @'
# =====================================================================
# SCRIPT DISABLE OS DATA COLLECTION (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan tool ini sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU)
# ---------------------------------------------------------------------

# Fungsi untuk menonaktifkan Scheduled Task
function Disable-TweakTask {
    param([string]$TaskPath, [string]$TaskName)
    try {
        $task = Get-ScheduledTask -TaskPath $TaskPath -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            if ($task.State -ne 'Disabled') {
                $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null
                Write-Host "   [Selesai] Menonaktifkan Task: $TaskName" -ForegroundColor Green
            }
        }
    } catch {
        Write-Warning "Gagal menonaktifkan task '$TaskName': $_"
    }
}

# Fungsi untuk mengatur Registry Key
function Set-TweakRegistry {
    param([string]$Path, [string]$Name, [int]$Value, [string]$Type="DWord")
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
        Write-Host "   [Selesai] Mengatur Registry: $Path\$Name = $Value" -ForegroundColor Green
    } catch {
        Write-Warning "Gagal mengatur registry '$Path\$Name': $_"
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI TWEAK
# ---------------------------------------------------------------------
Write-Host "=== Memulai Penonaktifan Pengumpulan Data OS (Disable OS Data Collection) ===" -ForegroundColor Magenta

# 1. Disable Server Customer Experience Improvement Program (CEIP)
Write-Host "-> 1. Menonaktifkan task Server CEIP (Customer Experience Improvement Program)" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -TaskName "ServerCeipAssistant"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -TaskName "ServerRoleCollector"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -TaskName "ServerRoleUsageCollector"

# 2. Disable Software Quality Metrics (SQM) & Kernel CEIP
Write-Host "-> 2. Menonaktifkan SQM Proxy & Kernel CEIP" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Autochk\" -TaskName "Proxy"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "KernelCeipTask"

# 3. Disable Bluetooth & Disk Diagnostic Data Collection
Write-Host "-> 3. Menonaktifkan telemetri Diagnostik Bluetooth & Disk" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "BthSQM"
Disable-TweakTask -TaskPath "\Microsoft\Windows\DiskDiagnostic\" -TaskName "Microsoft-Windows-DiskDiagnosticDataCollector"
Disable-TweakTask -TaskPath "\Microsoft\Windows\DiskDiagnostic\" -TaskName "Microsoft-Windows-DiskDiagnosticResolver"

# 4. Disable USB & General CEIP Data Consolidation/Uploads
Write-Host "-> 4. Menonaktifkan task USB, Consolidator, dan Uploader" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Consolidator"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Customer Experience Improvement Program\" -TaskName "Uploader"

# 5. Disable CEIP via Registry Policies
Write-Host "-> 5. Menonaktifkan metrik CEIP via Registry" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\SQMClient" -Name "UploadDisableFlag" -Value 0

# 6. Disable daily compatibility data collection (Microsoft Compatibility Appraiser)
Write-Host "-> 6. Menonaktifkan Microsoft Compatibility Appraiser (Pengumpul data kompatibilitas harian)" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "Microsoft Compatibility Appraiser"

# 7. Disable telemetry collector and sender process (CompatTelRunner.exe)
Write-Host "-> 7. Menonaktifkan CompatTelRunner.exe (Pengumpul Telemetri)" -ForegroundColor Cyan
$processName = "CompatTelRunner"

# 7.a Kill process if running
$runningProc = Get-Process -Name $processName -ErrorAction SilentlyContinue
if ($runningProc) {
    Write-Host "   CompatTelRunner sedang berjalan. Menghentikan proses..." -ForegroundColor Yellow
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
}

# 7.b Configure termination immediately upon its startup (IFEO Debugger injection)
Write-Host "   Menginjeksikan Debugger Dummy via IFEO..." -ForegroundColor Yellow
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe"
Set-TweakRegistry -Path $ifeoPath -Name "Debugger" -Value "$env:SYSTEMROOT\System32\taskkill.exe" -Type "String"

# 7.c Add a rule to prevent running via File Explorer (DisallowRun)
Write-Host "   Memblokir eksekusi via Kebijakan Explorer..." -ForegroundColor Yellow
$disallowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$disallowRunPath = "$disallowPath\DisallowRun"

# Enable DisallowRun policy
Set-TweakRegistry -Path $disallowPath -Name "DisallowRun" -Value 1 -Type "DWord"

# Add CompatTelRunner to the blocked list
try {
    if (-not (Test-Path $disallowRunPath)) {
        New-Item -Path $disallowRunPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    # Check if already exists to prevent duplicate entries
    $existingEntries = Get-ItemProperty -Path $disallowRunPath -ErrorAction SilentlyContinue
    $alreadyBlocked = $false
    
    if ($existingEntries) {
        foreach ($prop in $existingEntries.psobject.properties) {
            if ($prop.Value -eq "CompatTelRunner.exe") {
                $alreadyBlocked = $true
                break
            }
        }
    }
    
    if (-not $alreadyBlocked) {
        $nextIndex = 1
        while ($existingEntries.psobject.properties.Name -contains [string]$nextIndex) {
            $nextIndex++
        }
        Set-ItemProperty -Path $disallowRunPath -Name [string]$nextIndex -Value "CompatTelRunner.exe" -Type "String" -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Gagal mengatur DisallowRun untuk CompatTelRunner: $_"
}

# 7.d Soft delete file (Rename to .OLD)
Write-Host "   Menghapus secara halus (soft delete) CompatTelRunner.exe..." -ForegroundColor Yellow
$compatPath = "$env:SYSTEMROOT\System32\CompatTelRunner.exe"
if (Test-Path $compatPath) {
    try {
        # Ambil alih paksa dari TrustedInstaller menggunakan native tools (Lebih aman dari inject C# on the fly)
        & takeown /f $compatPath /a *>&1 | Out-Null
        & icacls $compatPath /grant "*S-1-5-32-544:F" /c /q *>&1 | Out-Null
        
        Move-Item -Path $compatPath -Destination "$compatPath.OLD" -Force -ErrorAction Stop
        Write-Host "   Berhasil mengubah nama menjadi CompatTelRunner.exe.OLD" -ForegroundColor Green
    } catch {
        Write-Warning "   Gagal mengubah nama $compatPath. File mungkin sedang dikunci oleh sistem."
    }
} else {
    Write-Host "   CompatTelRunner.exe tidak ditemukan atau sudah diubah namanya." -ForegroundColor DarkGray
}

# 8. Disable Application Experience & Program Compatibility Assistant (PCA) Tasks
Write-Host "-> 8. Menonaktifkan task Application Experience dan Program Compatibility Assistant (PCA)" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "ProgramDataUpdater"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "AitAgent"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "StartupAppTask"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "PcaPatchDbTask"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "SdbinstMergeDbTask"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Application Experience\" -TaskName "MareBackup"

# 9. Disable PCA Service and Telemetry via Registry
Write-Host "-> 9. Menonaktifkan fitur Program Compatibility Assistant via Registry" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisablePCA" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "AITEnable" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableEngine" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisablePropPage" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableUAR" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" -Name "DisableInventory" -Value 1

# 10. Disable Telemetry and Diagnostics Services
Write-Host "-> 10. Menonaktifkan Layanan Diagnostik & Telemetri" -ForegroundColor Cyan
$servicesToDisable = @(
    "PcaSvc",                                  # Program Compatibility Assistant Service
    "DiagTrack",                               # Connected User Experiences and Telemetry
    "dmwappushservice",                        # WAP Push Message Routing Service
    "diagnosticshub.standardcollector.service",# Diagnostics Hub Standard Collector
    "diagsvc"                                  # Diagnostic Execution Service
)
foreach ($svcName in $servicesToDisable) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq 'Running') {
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   Menonaktifkan Layanan: $svcName" -ForegroundColor Green
        }
    } catch {
        Write-Warning "   Gagal menonaktifkan layanan: $svcName"
    }
}

# 11. Disable Device Information Tasks
Write-Host "-> 11. Menonaktifkan task Informasi Perangkat (Device Information)" -ForegroundColor Cyan
Disable-TweakTask -TaskPath "\Microsoft\Windows\Device Information\" -TaskName "Device"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Device Information\" -TaskName "Device User"

# 12. Disable Device Census Data Collection (DeviceCensus.exe)
Write-Host "-> 12. Menonaktifkan DeviceCensus.exe (Pengumpul Data)" -ForegroundColor Cyan
$processName = "DeviceCensus"

# 12.a Kill process if running
$runningProc = Get-Process -Name $processName -ErrorAction SilentlyContinue
if ($runningProc) {
    Write-Host "   DeviceCensus sedang berjalan. Menghentikan proses..." -ForegroundColor Yellow
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
}

# 12.b Configure termination immediately upon its startup (IFEO Debugger injection)
Write-Host "   Menginjeksikan Debugger Dummy via IFEO untuk DeviceCensus..." -ForegroundColor Yellow
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe"
Set-TweakRegistry -Path $ifeoPath -Name "Debugger" -Value "$env:SYSTEMROOT\System32\taskkill.exe" -Type "String"

# 12.c Add a rule to prevent running via File Explorer (DisallowRun)
Write-Host "   Memblokir eksekusi via Kebijakan Explorer untuk DeviceCensus..." -ForegroundColor Yellow
$disallowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$disallowRunPath = "$disallowPath\DisallowRun"

try {
    # Ensure DisallowRun is active
    Set-TweakRegistry -Path $disallowPath -Name "DisallowRun" -Value 1 -Type "DWord"

    if (-not (Test-Path $disallowRunPath)) {
        New-Item -Path $disallowRunPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    $existingEntries = Get-ItemProperty -Path $disallowRunPath -ErrorAction SilentlyContinue
    $alreadyBlocked = $false
    
    if ($existingEntries) {
        foreach ($prop in $existingEntries.psobject.properties) {
            if ($prop.Value -eq "DeviceCensus.exe") {
                $alreadyBlocked = $true
                break
            }
        }
    }
    
    if (-not $alreadyBlocked) {
        $nextIndex = 1
        while ($existingEntries.psobject.properties.Name -contains [string]$nextIndex) {
            $nextIndex++
        }
        Set-ItemProperty -Path $disallowRunPath -Name [string]$nextIndex -Value "DeviceCensus.exe" -Type "String" -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-Warning "Gagal mengatur DisallowRun untuk DeviceCensus: $_"
}

# 13. Disable Desktop Analytics & Diagnostic Data Processing
Write-Host "-> 13. Menonaktifkan Pemrosesan Desktop Analytics & Data Diagnostik" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDesktopAnalyticsProcessing" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowDeviceNameInTelemetry" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "MicrosoftEdgeDataOptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowWUfBCloudProcessing" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowUpdateComplianceProcessing" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowCommercialDataPipeline" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "DisableOneSettingsDownloads" -Value 1

# 14. Disable License Telemetry
Write-Host "-> 14. Menonaktifkan Telemetri Lisensi" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" -Name "NoGenTicket" -Value 1

# 15. Disable Windows Error Reporting (WER)
Write-Host "-> 15. Menonaktifkan Windows Error Reporting (WER) dan Scheduled Tasks terkait" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name "Disabled" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent" -Name "DefaultConsent" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting\Consent" -Name "DefaultOverrideBehavior" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting" -Name "DontSendAdditionalData" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting" -Name "LoggingDisabled" -Value 1

Disable-TweakTask -TaskPath "\Microsoft\Windows\ErrorDetails\" -TaskName "EnableErrorDetailsUpdate"
Disable-TweakTask -TaskPath "\Microsoft\Windows\Windows Error Reporting\" -TaskName "QueueReporting"

# Matikan Service WER
$werServices = @("wersvc", "wercplsupport")
foreach ($svcName in $werServices) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq 'Running') {
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Gagal menonaktifkan layanan WER: $svcName"
    }
}

# 16. Completely Disable Cortana
Write-Host "-> 16. Menonaktifkan Cortana & Akses Cloud Pencarian" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "HistoryViewEnabled" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "DeviceHistoryEnabled" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" -Name "VoiceActivationOn" -Value 0
Set-TweakRegistry -Path "HKLM:\Software\Microsoft\Speech_OneCore\Preferences" -Name "VoiceActivationDefaultOn" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "VoiceShortcut" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" -Name "VoiceActivationEnableAboveLockscreen" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" -Name "ModelDownloadAllowed" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" -Name "DisableVoice" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana" -Name "value" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCloudSearch" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaConsent" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "CanCortanaBeEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaEnabled" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCortanaButton" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "CortanaInAmbientMode" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowIndexingEncryptedStoresOrItems" -Value 0

# Flag to remind restarting Explorer at the end of the script
$global:RequireExplorerRestart = $true

# 17. Disable Web Search (Bing) & Cloud Content in Windows Search
Write-Host "-> 17. Menonaktifkan Pencarian Web (Bing) & Saran Pencarian" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AlwaysUseAutoLangDetection" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "PreventRemoteQueries" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "PreventUnwantedAddIns" -Value "" -Type "String"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "DisableSearchBoxSuggestions" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "DisableWebSearch" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWeb" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchUseWebOverMeteredConnections" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "EnableDynamicContentInWSB" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDynamicSearchBoxEnabled" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowSearchToUseLocation" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "AllowSearchToUseLocation" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchHistory" -Value 1
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsDeviceSearchHistoryEnabled" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "ConnectedSearchPrivacy" -Value 3
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsMSACloudSearchEnabled" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings" -Name "IsAADCloudSearchEnabled" -Value 0

# Display Explorer Restart Notice (if required by earlier tweaks)
if ($global:RequireExplorerRestart) {
    Write-Host ""
    Write-Host "CATATAN: Beberapa perubahan pencarian & taskbar memerlukan restart Windows Explorer agar efeknya terlihat." -ForegroundColor Cyan
    Write-Host "Anda dapat merestartnya melalui Task Manager atau dengan merestart komputer Anda." -ForegroundColor Cyan
}

# 18. Disable Windows Tips, Spotlight, and Consumer Experience (Bloatware)
Write-Host "-> 18. Menonaktifkan Tips Windows, Iklan, dan Windows Spotlight" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableSoftLanding" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsSpotlightFeatures" -Value 1
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\Windows\CloudContent" -Name "DisableWindowsConsumerFeatures" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353694Enabled" -Value 0
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-353696Enabled" -Value 0

# 19. Disable Setting Sync (Microsoft Account Synchronization)
Write-Host "-> 19. Menonaktifkan Sinkronisasi Akun (Setting Sync)" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableSyncOnPaidNetwork" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "SyncPolicy" -Value 5
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableApplicationSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableApplicationSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableAppSyncSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableAppSyncSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableCredentialsSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableCredentialsSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Credentials" -Name "Enabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableDesktopThemeSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableDesktopThemeSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisablePersonalizationSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisablePersonalizationSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableStartLayoutSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableStartLayoutSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableWebBrowserSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableWebBrowserSettingSyncUserOverride" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableWindowsSettingSync" -Value 2
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\SettingSync" -Name "DisableWindowsSettingSyncUserOverride" -Value 1

# Display Explorer Restart Notice (if required by earlier tweaks)
if ($global:RequireExplorerRestart) {
    Write-Host ""
    Write-Host "CATATAN: Beberapa perubahan pencarian & taskbar memerlukan restart Windows Explorer agar efeknya terlihat." -ForegroundColor Cyan
    Write-Host "Anda dapat merestartnya melalui Task Manager atau dengan merestart komputer Anda." -ForegroundColor Cyan
}

# 20. Disable Language Setting Sync
Write-Host "-> 20. Menonaktifkan Sinkronisasi Pengaturan Bahasa" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SettingSync\Groups\Language" -Name "Enabled" -Value 0

# 21. Disable Windows Insider Service (wisvc)
Write-Host "-> 21. Menonaktifkan Windows Insider Service (wisvc)" -ForegroundColor Cyan
try {
    $wisvc = Get-Service -Name "wisvc" -ErrorAction SilentlyContinue
    if ($wisvc) {
        if ($wisvc.Status -eq 'Running') { Stop-Service -Name "wisvc" -Force -ErrorAction SilentlyContinue }
        Set-Service -Name "wisvc" -StartupType Disabled -ErrorAction SilentlyContinue
    }
} catch { Write-Warning "Gagal menonaktifkan wisvc" }

# 22. Disable Windows Insider, Feature Trials & Preview Builds
Write-Host "-> 22. Menonaktifkan Windows Insider, Uji Coba Fitur, dan Preview Builds" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "EnableExperimentation" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "EnableConfigFlighting" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation" -Name "value" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds" -Name "AllowBuildPreview" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility" -Name "HideInsiderPage" -Value 1

# 23. Disable AI Recall & Cloud Speech Privacy
Write-Host "-> 23. Menonaktifkan Copilot AI Recall dan Pengenalan Suara Berbasis Cloud" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "DisableAIDataAnalysis" -Value 1
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 0

# 24. Disable Windows Feedback Collection (SIUF)
Write-Host "-> 24. Menonaktifkan Pengumpulan Umpan Balik Windows (Feedback Collection)" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod" -Value 0
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "PeriodInNanoSeconds" -ErrorAction SilentlyContinue
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1

# 25. Disable Text, Handwriting, & Typing Data Collection
Write-Host "-> 25. Menonaktifkan Pengumpulan Data Teks, Tulisan Tangan, & Pengetikan" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitInkCollection" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "RestrictImplicitTextCollection" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports" -Name "PreventHandwritingErrorReports" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC" -Name "PreventHandwritingDataSharing" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization" -Name "AllowInputPersonalization" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value 0

# 26. Disable App Launch Tracking & Activity Feed
Write-Host "-> 26. Menonaktifkan Pelacakan Peluncuran Aplikasi dan Activity Feed" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Start_TrackProgs" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed" -Value 0

# 27. Disable Website Language List & Auto Map Downloads
Write-Host "-> 27. Menonaktifkan Akses Daftar Bahasa Situs Web dan Unduhan Peta Otomatis" -ForegroundColor Cyan
Set-TweakRegistry -Path "HKCU:\Control Panel\International\User Profile" -Name "HttpAcceptLanguageOptOut" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AllowUntriggeredNetworkTrafficOnSettingsPage" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Maps" -Name "AutoDownloadAndUpdateMapData" -Value 0

# Display Explorer Restart Notice (if required by earlier tweaks)
if ($global:RequireExplorerRestart) {
    Write-Host ""
    Write-Host "CATATAN: Beberapa perubahan pencarian & taskbar memerlukan restart Windows Explorer agar efeknya terlihat." -ForegroundColor Cyan
    Write-Host "Anda dapat merestartnya melalui Task Manager atau dengan merestart komputer Anda." -ForegroundColor Cyan
}

Write-Host "=== Penonaktifan Pengumpulan Data OS Selesai ===" -ForegroundColor Magenta
'@
            } # Tutup switch case "Disable OS Data Collection"
                "Configure Programs" {
                $masterScript += @'
# =====================================================================
# SCRIPT CONFIGURE PROGRAMS (NATIVE POWERSHELL)
# =====================================================================

# 1. Pastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan aplikasi sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# FUNGSI PEMBANTU (HELPER FUNCTIONS)
# ---------------------------------------------------------------------

# Fungsi untuk mengatur nilai Registry
function Set-TweakRegistry {
    param([string]$Path, [string]$Name, $Value, [string]$Type="DWord")
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
        Write-Host "Set Registry: $Path\$Name = $Value"
    } catch {
        Write-Warning "Gagal mengatur registry '$Path\$Name': $_"
    }
}

# Fungsi untuk menghapus nilai Registry
function Remove-TweakRegistry {
    param([string]$Path, [string]$Name)
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "Menghapus Registry: $Path\$Name"
        }
    } catch {
        Write-Warning "Gagal menghapus registry '$Path\$Name': $_"
    }
}

# Fungsi untuk mengatur setting pada VS Code (settings.json)
function Set-VSCodeSetting {
    param([string]$Key, $Value)
    $jsonFilePath = "$env:APPDATA\Code\User\settings.json"
    
    if (-not (Test-Path $jsonFilePath)) {
        Write-Host "Melewati pengaturan '$Key': VS Code tidak terinstall atau settings.json tidak ditemukan."
        return
    }

    try {
        $content = Get-Content -Path $jsonFilePath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($content)) { $content = "{}" }
        
        $jsonObj = $content | ConvertFrom-Json
        
        # Mengecek apakah nilainya sudah sama
        $existingValue = $jsonObj.$Key
        if ($existingValue -ne $null -and $existingValue -eq $Value) {
            Write-Host "Pengaturan VS Code '$Key' sudah di-set ke '$Value'. Dilewati."
            return
        }

        # Menambahkan atau memperbarui kunci json
        if ($jsonObj -is [PSCustomObject]) {
            $jsonObj | Add-Member -MemberType NoteProperty -Name $Key -Value $Value -Force
        }
        
        $jsonObj | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonFilePath -Encoding UTF8
        Write-Host "Berhasil menerapkan '$Key' = '$Value' ke VS Code."
    } catch {
        Write-Warning "Gagal memodifikasi konfigurasi VS Code: $_"
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI PENGATURAN PROGRAM
# ---------------------------------------------------------------------
Write-Host "=== Memulai Konfigurasi Program ==="

# 1. Mematikan Visual Studio CEIP (Customer Experience Improvement Program) & Telemetri
Write-Host "-> Mematikan Telemetri dan CEIP Visual Studio"
Set-TweakRegistry -Path "HKLM:\Software\Policies\Microsoft\VisualStudio\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\VSCommon\14.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\VSCommon\15.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\VSCommon\16.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM" -Name "OptIn" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM" -Name "OptIn" -Value 0

Set-TweakRegistry -Path "HKCU:\Software\Microsoft\VisualStudio\Telemetry" -Name "TurnOffSwitch" -Value 1

# 2. Mematikan fitur Feedback & Layanan Log Visual Studio
Write-Host "-> Mematikan Feedback dan Logging Visual Studio"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableFeedbackDialog" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableEmailInput" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableScreenshotCapture" -Value 1
Remove-TweakRegistry -Path "HKLM:\Software\Microsoft\VisualStudio\DiagnosticsHub" -Name "LogLevel"

Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode" -Name "DisableRemoteAnalysis" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode" -Name "DisableRemoteAnalysis" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode" -Name "DisableRemoteAnalysis" -Value 1

# Matikan service VSStandardCollectorService150
try {
    $vsSvc = Get-Service -Name "VSStandardCollectorService150" -ErrorAction SilentlyContinue
    if ($vsSvc) {
        if ($vsSvc.Status -eq 'Running') { Stop-Service -Name "VSStandardCollectorService150" -Force -ErrorAction SilentlyContinue }
        Set-Service -Name "VSStandardCollectorService150" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Berhasil mematikan VS Standard Collector Service."
    }
} catch { Write-Warning "Gagal mematikan VSStandardCollectorService150." }

# 3. Konfigurasi Keamanan dan Privasi Visual Studio Code
Write-Host "-> Menerapkan pengaturan privasi untuk Visual Studio Code"
Set-VSCodeSetting -Key "telemetry.enableTelemetry" -Value $false
Set-VSCodeSetting -Key "telemetry.enableCrashReporter" -Value $false
Set-VSCodeSetting -Key "workbench.enableExperiments" -Value $false
Set-VSCodeSetting -Key "update.mode" -Value "manual"
Set-VSCodeSetting -Key "update.showReleaseNotes" -Value $false
Set-VSCodeSetting -Key "extensions.autoCheckUpdates" -Value $false
Set-VSCodeSetting -Key "extensions.showRecommendationsOnlyOnDemand" -Value $true
Set-VSCodeSetting -Key "git.autofetch" -Value $false
Set-VSCodeSetting -Key "npm.fetchOnlinePackageInfo" -Value $false

# 4. Mematikan Logging dan Telemetri Microsoft Office
Write-Host "-> Mematikan Logging dan Telemetri Microsoft Office"
$officePaths = @("15.0", "16.0")

foreach ($ver in $officePaths) {
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Outlook\Options\Mail" -Name "EnableLogging" -Value 0
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Outlook\Options\Calendar" -Name "EnableCalendarLogging" -Value 0
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Word\Options" -Name "EnableLogging" -Value 0
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\OSM" -Name "EnableLogging" -Value 0
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\OSM" -Name "EnableUpload" -Value 0
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Common\ClientTelemetry" -Name "DisableTelemetry" -Value 1
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Common\ClientTelemetry" -Name "VerboseLogging" -Value 0
    Set-TweakRegistry -Path "HKCU:\Software\Policies\Microsoft\Office\$ver\Common" -Name "QMEnable" -Value 0
}

Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" -Name "DisableTelemetry" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\Common\ClientTelemetry" -Name "VerboseLogging" -Value 0

# 5. Mematikan Feedback dan Tasks Telemetri Microsoft Office
Write-Host "-> Mematikan Feedback dan Tasks Telemetri Microsoft Office"
$officePaths = @("15.0", "16.0")
foreach ($ver in $officePaths) {
    Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Common\Feedback" -Name "Enabled" -Value 0
}

$officeTasks = @(
    "OfficeTelemetryAgentFallBack", 
    "OfficeTelemetryAgentFallBack2016", 
    "OfficeTelemetryAgentLogOn", 
    "OfficeTelemetryAgentLogOn2016", 
    "Office 15 Subscription Heartbeat"
)
foreach ($taskName in $officeTasks) {
    Disable-TweakTask -TaskPath "\Microsoft\Office\" -TaskName $taskName
}

# 6. Mematikan Telemetri, Metrik, dan Feedback Microsoft Edge
Write-Host "-> Mematikan Telemetri, Metrik, dan Feedback Microsoft Edge"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "DiagnosticData" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "MetricsReportingEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SendSiteInfoToImproveServices" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "UserFeedbackAllowed" -Value 0

# 7. Mematikan Auto-Install Microsoft Edge & WebView2
Write-Host "-> Mencegah instalasi otomatis Edge & WebView2"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate" -Name "DoNotUpdateToEdgeWithChromium" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "InstallDefault" -Value 0

$edgeGuids = @(
    "{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}",
    "{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}",
    "{65C35B14-6C1D-4122-AC46-7148CC9D6497}",
    "{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}",
    "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" # WebView & WebView2
)
foreach ($guid in $edgeGuids) {
    Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate" -Name "Install$guid" -Value 0
}

# 8. Mematikan Services dan Tasks Microsoft Edge Update
Write-Host "-> Mematikan Services dan Scheduled Tasks Microsoft Edge Update"
$edgeServices = @("edgeupdate", "edgeupdatem")
foreach ($svcName in $edgeServices) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq 'Running') { Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   Service dimatikan: $svcName"
        }
    } catch { Write-Warning "   Gagal mematikan service $svcName." }
}

# Menghentikan task dengan wildcard (MicrosoftEdgeUpdateTaskMachineCore & UA)
try {
    $edgeTasks = Get-ScheduledTask -TaskName "MicrosoftEdgeUpdateTask*" -ErrorAction SilentlyContinue
    if ($edgeTasks) {
        $edgeTasks | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
        Write-Host "   Berhasil mematikan Scheduled Tasks untuk Edge Update."
    }
} catch { Write-Warning "   Gagal mematikan Scheduled Tasks Edge Update." }

# 9. Melumpuhkan Executable Microsoft Edge Update (MicrosoftEdgeUpdate.exe)
Write-Host "-> Melumpuhkan file eksekusi MicrosoftEdgeUpdate.exe"
$processName = "MicrosoftEdgeUpdate"

# 9.a Hentikan proses jika sedang berjalan
$runningProc = Get-Process -Name $processName -ErrorAction SilentlyContinue
if ($runningProc) {
    Write-Host "   Menghentikan proses $processName yang sedang berjalan..."
    Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue
}

# 9.b Suntikkan Dummy Debugger via IFEO (Mencegah aplikasi terbuka)
Write-Host "   Menyuntikkan Dummy Debugger (IFEO) untuk Edge Update..."
$ifeoPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MicrosoftEdgeUpdate.exe"
Set-TweakRegistry -Path $ifeoPath -Name "Debugger" -Value "$env:SYSTEMROOT\System32\taskkill.exe" -Type "String"

# 9.c Blokir eksekusi via Explorer Policies (DisallowRun)
Write-Host "   Memblokir eksekusi Edge Update melalui Explorer Policies..."
$disallowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$disallowRunPath = "$disallowPath\DisallowRun"

try {
    Set-TweakRegistry -Path $disallowPath -Name "DisallowRun" -Value 1 -Type "DWord"
    if (-not (Test-Path $disallowRunPath)) { New-Item -Path $disallowRunPath -Force -ErrorAction SilentlyContinue | Out-Null }
    
    $existingEntries = Get-ItemProperty -Path $disallowRunPath -ErrorAction SilentlyContinue
    $alreadyBlocked = $false
    
    if ($existingEntries) {
        foreach ($prop in $existingEntries.psobject.properties) {
            if ($prop.Value -eq "MicrosoftEdgeUpdate.exe") {
                $alreadyBlocked = $true
                break
            }
        }
    }
    
    if (-not $alreadyBlocked) {
        $nextIndex = 1
        while ($existingEntries.psobject.properties.Name -contains [string]$nextIndex) { $nextIndex++ }
        Set-ItemProperty -Path $disallowRunPath -Name [string]$nextIndex -Value "MicrosoftEdgeUpdate.exe" -Type "String" -Force -ErrorAction SilentlyContinue
    }
} catch { Write-Warning "Gagal mengatur DisallowRun untuk Edge Update: $_" }

# 9.d Ganti nama file eksekusi menjadi .OLD (Soft Delete)
Write-Host "   Melakukan soft-delete (rename ke .OLD) pada MicrosoftEdgeUpdate.exe..."
$edgeUpdateGlobs = @(
    "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe",
    "${env:ProgramFiles(x86)}\Microsoft\EdgeUpdate\*\MicrosoftEdgeUpdate.exe"
)

foreach ($glob in $edgeUpdateGlobs) {
    # Ambil file sesuai pattern (mendukung folder dengan versi angka)
    Get-Item -Path $glob -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not $_.Name.EndsWith('.OLD')) {
            try {
                Move-Item -LiteralPath $_.FullName -Destination "$($_.FullName).OLD" -Force -ErrorAction Stop
                Write-Host "   Berhasil mengubah nama file: $($_.FullName)"
            } catch {
                Write-Warning "   Gagal mengubah nama $($_.FullName) (Mungkin sedang digunakan sistem)."
            }
        }
    }
}

# 10. Konfigurasi Pembaruan Microsoft Edge (Edge Update)
Write-Host "-> Mematikan Pembaruan Otomatis Microsoft Edge"
$edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
Set-TweakRegistry -Path $edgeUpdatePath -Name "UpdateDefault" -Value 0
Set-TweakRegistry -Path $edgeUpdatePath -Name "AutoUpdateCheckPeriodMinutes" -Value 0
Set-TweakRegistry -Path $edgeUpdatePath -Name "UpdatesSuppressedDurationMin" -Value 1440
Set-TweakRegistry -Path $edgeUpdatePath -Name "UpdatesSuppressedStartHour" -Value 0
Set-TweakRegistry -Path $edgeUpdatePath -Name "UpdatesSuppressedStartMin" -Value 0

$edgeUpdateGuids = @(
    "{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}",
    "{2CD8A007-E189-409D-A2C8-9AF4EF3C72AA}",
    "{65C35B14-6C1D-4122-AC46-7148CC9D6497}",
    "{0D50BFEC-CD6A-4F9A-964C-C7416E3ACB10}",
    "{F3C4FE00-EFD5-403B-9569-398A20F1BA4A}",
    "{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" # WebView & WebView2
)
foreach ($guid in $edgeUpdateGuids) {
    Set-TweakRegistry -Path $edgeUpdatePath -Name "Update$guid" -Value 0
}

# 11. Konfigurasi Privasi dan Telemetri Microsoft Edge
Write-Host "-> Menerapkan Kebijakan Privasi Microsoft Edge (Mematikan Telemetri, Iklan, Bing, Copilot)"
$edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

# Copilot & Hubs Sidebar
Set-TweakRegistry -Path $edgePolicyPath -Name "HubsSidebarEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "StandaloneHubsSidebarEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "DiscoverPageContextEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "CopilotPageContext" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "CopilotCDPPageContext" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "NewTabPageBingChatEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "EdgeDiscoverEnabled" -Value 0

# Ads, Suggestions, and Promotions
Set-TweakRegistry -Path $edgePolicyPath -Name "SpotlightExperiencesAndRecommendationsEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "ShowRecommendationsEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "BingAdsSuppression" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "PromotionalTabsEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "PersonalizationReportingEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "MicrosoftEdgeInsiderPromotionEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "ShowAcrobatSubscriptionButton" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "EdgeShoppingAssistantEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "AddressBarMicrosoftSearchInBingProviderEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "RelatedMatchesCloudServiceEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "SignInCtaOnNtpEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "SearchSuggestEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "EdgeEnhanceImagesEnabled" -Value 0

# New Tab Page (NTP)
Set-TweakRegistry -Path $edgePolicyPath -Name "NewTabPageHideDefaultTopSites" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "NewTabPageQuickLinksEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "NewTabPageAllowedBackgroundTypes" -Value 1

# Privacy & Tracking
Set-TweakRegistry -Path $edgePolicyPath -Name "TrackingPrevention" -Value 3
Set-TweakRegistry -Path $edgePolicyPath -Name "BlockThirdPartyCookies" -Value 1
Set-TweakRegistry -Path $edgePolicyPath -Name "ConfigureDoNotTrack" -Value 1
Set-TweakRegistry -Path $edgePolicyPath -Name "EdgeFollowEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "AlternateErrorPagesEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "AutofillCreditCardEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "AutofillAddressEnabled" -Value 0

# UI/UX & Miscellenous Features
Set-TweakRegistry -Path $edgePolicyPath -Name "WebWidgetAllowed" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "WebWidgetIsEnabledOnStartup" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "SearchbarAllowed" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "SearchbarIsEnabledOnStartup" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "ShowMicrosoftRewards" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "EdgeCollectionsEnabled" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "AllowGamesMenu" -Value 0
Set-TweakRegistry -Path $edgePolicyPath -Name "InAppSupportEnabled" -Value 0

# Set flag untuk notifikasi restart aplikasi pada akhir script
$global:RequireEdgeRestart = $true

# 10. Konfigurasi Internet Explorer (IE) & Edge Legacy
Write-Host "-> Mematikan Telemetri & Geolocation Internet Explorer dan Edge Legacy"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ExperimentationAndConfigurationServiceControl" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "StartupBoostEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ResolveNavigationErrorsUseWebService" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "FamilySafetySettingsEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SiteSafetyServicesEnabled" -Value 0

Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Name "PreventLiveTileDataCollection" -Value 1
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\Main" -Name "PreventLiveTileDataCollection" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\SearchScopes" -Name "ShowSearchSuggestionsGlobal" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\SearchScopes" -Name "ShowSearchSuggestionsGlobal" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\BooksLibrary" -Name "EnableExtendedBooksTelemetry" -Value 0
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\BooksLibrary" -Name "EnableExtendedBooksTelemetry" -Value 0

Set-TweakRegistry -Path "HKCU:\Software\Policies\Microsoft\Internet Explorer\Geolocation" -Name "PolicyDisableGeolocation" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Safety\PrivacIE" -Name "DisableLogging" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\SQM" -Name "DisableCustomerImprovementProgram" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "CallLegacyWCMPolicies" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "EnableSSL3Fallback" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name "PreventIgnoreCertErrors" -Value 1

# 11. Konfigurasi Google Chrome (Telemetri & Software Reporter Tool)
Write-Host "-> Menerapkan Kebijakan Privasi Google Chrome"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "ChromeCleanupReportingEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "ChromeCleanupEnabled" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name "MetricsReportingEnabled" -Value 0

# Melumpuhkan Software Reporter Tool (Chrome)
Write-Host "   Melumpuhkan Chrome Software Reporter Tool..."
$chromeSrtProcess = "software_reporter_tool"
if (Get-Process -Name $chromeSrtProcess -ErrorAction SilentlyContinue) {
    Stop-Process -Name $chromeSrtProcess -Force -ErrorAction SilentlyContinue
}
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\software_reporter_tool.exe" -Name "Debugger" -Value "$env:SYSTEMROOT\System32\taskkill.exe" -Type "String"

try {
    $disallowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    $disallowRunPath = "$disallowPath\DisallowRun"
    Set-TweakRegistry -Path $disallowPath -Name "DisallowRun" -Value 1 -Type "DWord"
    if (-not (Test-Path $disallowRunPath)) { New-Item -Path $disallowRunPath -Force -ErrorAction SilentlyContinue | Out-Null }
    
    $existingEntries = Get-ItemProperty -Path $disallowRunPath -ErrorAction SilentlyContinue
    $alreadyBlocked = $false
    
    if ($existingEntries) {
        foreach ($prop in $existingEntries.psobject.properties) {
            if ($prop.Value -eq "software_reporter_tool.exe") {
                $alreadyBlocked = $true; break
            }
        }
    }
    
    if (-not $alreadyBlocked) {
        $nextIndex = 1
        while ($existingEntries.psobject.properties.Name -contains [string]$nextIndex) { $nextIndex++ }
        Set-ItemProperty -Path $disallowRunPath -Name [string]$nextIndex -Value "software_reporter_tool.exe" -Type "String" -Force -ErrorAction SilentlyContinue
    }
} catch { Write-Warning "Gagal mengatur DisallowRun untuk Chrome SRT: $_" }


# 12. Konfigurasi Mozilla Firefox
Write-Host "-> Menerapkan Kebijakan Privasi Mozilla Firefox"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox" -Name "DisableDefaultBrowserAgent" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Mozilla\Firefox" -Name "DisableTelemetry" -Value 1

Disable-TweakTask -TaskPath "\Mozilla\" -TaskName "Firefox Default Browser Agent 308046B0AF4A39CB"
Disable-TweakTask -TaskPath "\Mozilla\" -TaskName "Firefox Default Browser Agent D2CEEC440E2074BD"


# 13. Konfigurasi Dropbox Update Service
Write-Host "-> Mematikan Telemetri dan Auto-Update Dropbox"
$dropboxServices = @("dbupdate", "dbupdatem")
foreach ($svcName in $dropboxServices) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq 'Running') { Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   Service dimatikan: $svcName"
        }
    } catch { Write-Warning "   Gagal mematikan service Dropbox: $svcName." }
}

Disable-TweakTask -TaskPath "\" -TaskName "DropboxUpdateTaskMachineUA"
Disable-TweakTask -TaskPath "\" -TaskName "DropboxUpdateTaskMachineCore"


# 14. Konfigurasi Windows Media Player
Write-Host "-> Mematikan Telemetri Windows Media Player"
Set-TweakRegistry -Path "HKCU:\SOFTWARE\Microsoft\MediaPlayer\Preferences" -Name "UsageTracking" -Value 0

# 15. Mematikan Pencarian Metadata & Telemetri Windows Media Player
Write-Host "-> Mematikan Pencarian Metadata dan Sharing Service Windows Media Player"
$wmpPolicyPath = "HKCU:\Software\Policies\Microsoft\WindowsMediaPlayer"
Set-TweakRegistry -Path $wmpPolicyPath -Name "PreventCDDVDMetadataRetrieval" -Value 1
Set-TweakRegistry -Path $wmpPolicyPath -Name "PreventMusicFileMetadataRetrieval" -Value 1
Set-TweakRegistry -Path $wmpPolicyPath -Name "PreventRadioPresetsRetrieval" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\WMDRM" -Name "DisableOnline" -Value 1

try {
    $wmpSvc = Get-Service -Name "WMPNetworkSvc" -ErrorAction SilentlyContinue
    if ($wmpSvc) {
        if ($wmpSvc.Status -eq 'Running') { Stop-Service -Name "WMPNetworkSvc" -Force -ErrorAction SilentlyContinue }
        Set-Service -Name "WMPNetworkSvc" -StartupType Disabled -ErrorAction SilentlyContinue
    }
} catch { Write-Warning "Gagal mematikan Windows Media Player Network Sharing Service." }


# 16. Mematikan Telemetri .NET Core CLI dan PowerShell (Environment Variables)
Write-Host "-> Mematikan Telemetri .NET Core CLI dan PowerShell"
[System.Environment]::SetEnvironmentVariable('DOTNET_CLI_TELEMETRY_OPTOUT', '1', [System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('POWERSHELL_TELEMETRY_OPTOUT', '1', [System.EnvironmentVariableTarget]::Machine)


# 17. Mematikan Service Pelacakan Pihak Ketiga (Razer & Logitech)
Write-Host "-> Mematikan Service Pelacakan Razer dan Logitech"
$gamingServices = @("Razer Game Scanner Service", "LogiRegistryService")
foreach ($svcName in $gamingServices) {
    try {
        $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -eq 'Running') { Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue }
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "   Service dimatikan: $svcName"
        }
    } catch { Write-Warning "   Gagal mematikan service gaming: $svcName" }
}


# 18. Konfigurasi CCleaner (Mematikan Iklan, Telemetri, dan Update Otomatis)
Write-Host "-> Menerapkan Kebijakan Privasi dan mematikan Iklan CCleaner"
$ccleanerPath = "HKCU:\Software\Piriform\CCleaner"
Set-TweakRegistry -Path $ccleanerPath -Name "Monitoring" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "HelpImproveCCleaner" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "SystemMonitoring" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "UpdateAuto" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "UpdateCheck" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "UpdateBackground" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "CheckTrialOffer" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)HealthCheck" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)QuickClean" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)QuickCleanIpm" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)GetIpmForTrial" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)SoftwareUpdater" -Value 0
Set-TweakRegistry -Path $ccleanerPath -Name "(Cfg)SoftwareUpdaterIpm" -Value 0


# Display Explorer/Browser Restart Notice
if ($global:RequireEdgeRestart) {
    Write-Host ""
    Write-Host "CATATAN: Beberapa pengaturan memerlukan restart pada aplikasi Google Chrome, Mozilla Firefox, atau Microsoft Edge agar berfungsi penuh." -ForegroundColor Cyan
}

Write-Host "=== Konfigurasi Program Selesai ==="
'@
            } # Tutup switch case "Configure Programs"
            "Security Improvements" {
            $masterScript += @'
# =====================================================================
# SCRIPT SECURITY IMPROVEMENTS (NATIVE POWERSHELL)
# =====================================================================

# 1. Pastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan aplikasi sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# FUNGSI PEMBANTU (HELPER FUNCTIONS)
# ---------------------------------------------------------------------

# Fungsi untuk mengatur nilai Registry
function Set-TweakRegistry {
    param([string]$Path, [string]$Name, $Value, [string]$Type="DWord")
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
        }
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
        Write-Host "Set Registry: $Path\$Name = $Value"
    } catch {
        Write-Warning "Gagal mengatur registry '$Path\$Name': $_"
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI PENINGKATAN KEAMANAN (SECURITY IMPROVEMENTS)
# ---------------------------------------------------------------------
Write-Host "=== Memulai Konfigurasi Peningkatan Keamanan ==="

# 1. Mengaktifkan Protokol Keamanan Jaringan Modern (DTLS 1.2 & TLS 1.3)
Write-Host "-> Menerapkan protokol jaringan aman (TLS 1.3 dan DTLS 1.2)"
$schannelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

# DTLS 1.2
Set-TweakRegistry -Path "$schannelPath\DTLS 1.2\Server" -Name "Enabled" -Value 1
Set-TweakRegistry -Path "$schannelPath\DTLS 1.2\Server" -Name "DisabledByDefault" -Value 0
Set-TweakRegistry -Path "$schannelPath\DTLS 1.2\Client" -Name "Enabled" -Value 1
Set-TweakRegistry -Path "$schannelPath\DTLS 1.2\Client" -Name "DisabledByDefault" -Value 0

# TLS 1.3 (Didukung secara default sejak Windows 11)
Set-TweakRegistry -Path "$schannelPath\TLS 1.3\Server" -Name "Enabled" -Value 1
Set-TweakRegistry -Path "$schannelPath\TLS 1.3\Server" -Name "DisabledByDefault" -Value 0
Set-TweakRegistry -Path "$schannelPath\TLS 1.3\Client" -Name "Enabled" -Value 1
Set-TweakRegistry -Path "$schannelPath\TLS 1.3\Client" -Name "DisabledByDefault" -Value 0

# Mewajibkan versi TLS modern untuk aplikasi .NET lama
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727" -Name "SystemDefaultTlsVersions" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727" -Name "SystemDefaultTlsVersions" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value 1
Set-TweakRegistry -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value 1


# 2. Mematikan Riwayat Cloud Clipboard (Mencegah Pencurian Data)
Write-Host "-> Mematikan Sinkronisasi dan Riwayat Clipboard (Mencegah pencurian password tersalin)"
Set-TweakRegistry -Path "HKCU:\Software\Microsoft\Clipboard" -Name "CloudClipboardAutomaticUpload" -Value 0

# 3. Mengaktifkan Perlindungan Memori Eksekusi (DEP & SEHOP)
Write-Host "-> Mengaktifkan perlindungan memori tingkat lanjut (DEP & SEHOP)"
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoDataExecutionPrevention" -Value 0
Set-TweakRegistry -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableHHDEP" -Value 0
Set-TweakRegistry -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Value 0


# 4. Mencegah Downgrade Attack pada PowerShell 2.0
Write-Host "-> Mencabut fitur usang PowerShell 2.0 (Mencegah Serangan Downgrade)"
$ps2Features = @("MicrosoftWindowsPowerShellV2", "MicrosoftWindowsPowerShellV2Root")
foreach ($featureName in $ps2Features) {
    try {
        $feature = Get-WindowsOptionalFeature -FeatureName $featureName -Online -ErrorAction SilentlyContinue
        if ($feature -and $feature.State -ne 'Disabled') {
            Disable-WindowsOptionalFeature -FeatureName $featureName -Online -NoRestart -ErrorAction Stop | Out-Null
            Write-Host "   Berhasil mencabut fitur $featureName."
        } else {
            Write-Host "   Fitur $featureName sudah dicabut."
        }
    } catch {
        Write-Warning "   Gagal mencabut fitur ${featureName}: $_"
    }
}


# 5. Mematikan Windows Connect Now (WCN) yang rentan eksploitasi
Write-Host "-> Mematikan fitur rentan Windows Connect Now (WCN)"
$wcnPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN"
Set-TweakRegistry -Path "$wcnPath\UI" -Name "DisableWcnUi" -Value 1
Set-TweakRegistry -Path "$wcnPath\Registrars" -Name "DisableFlashConfigRegistrar" -Value 0
Set-TweakRegistry -Path "$wcnPath\Registrars" -Name "DisableInBand802DOT11Registrar" -Value 0
Set-TweakRegistry -Path "$wcnPath\Registrars" -Name "DisableUPnPRegistrar" -Value 0
Set-TweakRegistry -Path "$wcnPath\Registrars" -Name "DisableWPDRegistrar" -Value 0
Set-TweakRegistry -Path "$wcnPath\Registrars" -Name "EnableRegistrars" -Value 0

Write-Host "=== Security Improvements Selesai ==="
'@
        }
                "Block Tracking Hosts" {
                $masterScript += @'
# =====================================================================
# SCRIPT BLOCK TRACKING HOSTS (NATIVE POWERSHELL)
# =====================================================================

# 1. Pastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan aplikasi sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# FUNGSI PEMBANTU (HELPER FUNCTIONS)
# ---------------------------------------------------------------------

# Fungsi untuk menambahkan entri blokir ke file Hosts Windows
function Add-BlockHost {
    param([string[]]$Domains)
    $hostsPath = "$env:SYSTEMROOT\System32\drivers\etc\hosts"
    $comment = "managed by privacy.sexy"
    
    # Buat file hosts jika belum ada
    if (-not (Test-Path $hostsPath)) {
        New-Item -Path $hostsPath -ItemType File -Force -ErrorAction SilentlyContinue | Out-Null
    }
    
    # Baca isi file hosts saat ini
    $hostsContent = Get-Content $hostsPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $hostsContent) { $hostsContent = "" }
    
    $linesToAdd = @()
    foreach ($domain in $Domains) {
        $ipv4 = "0.0.0.0`t$domain"
        $ipv6 = "::1`t$domain"
        
        # Tambahkan IPv4 jika belum ada
        if (-not $hostsContent.Contains($ipv4)) {
            $linesToAdd += "$ipv4 # $comment"
        }
        # Tambahkan IPv6 jika belum ada
        if (-not $hostsContent.Contains($ipv6)) {
            $linesToAdd += "$ipv6 # $comment"
        }
    }
    
    # Tulis ke file hosts jika ada entri baru
    if ($linesToAdd.Count -gt 0) {
        try {
            Add-Content -Path $hostsPath -Value $linesToAdd -Encoding UTF8 -ErrorAction Stop
            Write-Host "   Berhasil menambahkan $($Domains.Count) host(s) ke daftar blokir."
        } catch {
            Write-Warning "   Gagal menulis ke file hosts. Pastikan anti-virus tidak memblokir modifikasi file hosts: $_"
        }
    } else {
        Write-Host "   Semua host tersebut sudah terblokir. Dilewati."
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI PEMBLOKIRAN HOSTS
# ---------------------------------------------------------------------
Write-Host "=== Memulai Pemblokiran Tracking Hosts ==="

# 1. Memblokir Telemetri Dropbox
Write-Host "-> Memblokir host telemetri Dropbox..."
Add-BlockHost -Domains @(
    "telemetry.dropbox.com",
    "telemetry.v.dropbox.com"
)

# 2. Memblokir Host Spotify Live Tile
Write-Host "-> Memblokir host Spotify Live Tile..."
Add-BlockHost -Domains @(
    "spclient.wg.spotify.com"
)

# 3. Memblokir Host Laporan Crash & Telemetri Windows
Write-Host "-> Memblokir host Windows Crash Report & Telemetry..."
Add-BlockHost -Domains @(
    "oca.telemetry.microsoft.com",
    "oca.microsoft.com",
    "kmwatsonc.events.data.microsoft.com"
)

# 4. Memblokir Host Windows Error Reporting (Watson & Blob Storage)
Write-Host "-> Memblokir host Windows Error Reporting (Watson & Diagnostic Logs)..."
Add-BlockHost -Domains @(
    "watson.telemetry.microsoft.com",
    "umwatsonc.events.data.microsoft.com",
    "ceuswatcab01.blob.core.windows.net",
    "ceuswatcab02.blob.core.windows.net",
    "eaus2watcab01.blob.core.windows.net",
    "eaus2watcab02.blob.core.windows.net",
    "weus2watcab01.blob.core.windows.net",
    "weus2watcab02.blob.core.windows.net",
    "co4.telecommand.telemetry.microsoft.com",
    "cs11.wpc.v0cdn.net",
    "cs1137.wpc.gammacdn.net",
    "modern.watson.data.microsoft.com"
)

# 5. Memblokir Host Telemetri & User Experience (UX)
Write-Host "-> Memblokir host Telemetri dan User Experience..."
Add-BlockHost -Domains @(
    "functional.events.data.microsoft.com",
    "browser.events.data.msn.com",
    "self.events.data.microsoft.com",
    "v10.events.data.microsoft.com",
    "v10c.events.data.microsoft.com",
    "us-v10c.events.data.microsoft.com",
    "eu-v10c.events.data.microsoft.com",
    "v10.vortex-win.data.microsoft.com",
    "vortex-win.data.microsoft.com",
    "telecommand.telemetry.microsoft.com",
    "www.telecommandsvc.microsoft.com",
    "umwatson.events.data.microsoft.com",
    "watsonc.events.data.microsoft.com",
    "eu-watsonc.events.data.microsoft.com"
)

# 6. Memblokir Host Sinkronisasi Konfigurasi Jarak Jauh (Remote Sync)
Write-Host "-> Memblokir host Remote Configuration Sync..."
Add-BlockHost -Domains @(
    "settings-win.data.microsoft.com",
    "settings.data.microsoft.com"
)

# 7. Memblokir Host Pembaruan & Data Peta (Maps Data)
Write-Host "-> Memblokir host Maps Data & Updates..."
Add-BlockHost -Domains @(
    "maps.windows.com",
    "ecn.dev.virtualearth.net",
    "ecn-us.dev.virtualearth.net",
    "weathermapdata.blob.core.windows.net"
)

# 8. Memblokir Iklan Spotlight, Widget, & Saran MSN
Write-Host "-> Memblokir host Spotlight Ads & Suggestions..."
Add-BlockHost -Domains @(
    "arc.msn.com",
    "ris.api.iris.microsoft.com",
    "api.msn.com",
    "assets.msn.com",
    "c.msn.com",
    "g.msn.com",
    "ntp.msn.com",
    "srtb.msn.com",
    "www.msn.com",
    "fd.api.iris.microsoft.com",
    "staticview.msn.com",
    "mucp.api.account.microsoft.com",
    "query.prod.cms.rt.microsoft.com"
)

# 9. Memblokir Cortana, Live Tiles, & Azure Edge CDN Services
Write-Host "-> Memblokir host Cortana, Live Tiles, dan Widget Services..."
Add-BlockHost -Domains @(
    "business.bing.com",
    "c.bing.com",
    "th.bing.com",
    "edgeassetservice.azureedge.net",
    "c-ring.msedge.net",
    "fp.msedge.net",
    "I-ring.msedge.net",
    "s-ring.msedge.net",
    "dual-s-ring.msedge.net",
    "creativecdn.com",
    "a-ring-fallback.msedge.net",
    "fp-afd-nocache-ccp.azureedge.net",
    "prod-azurecdn-akamai-iris.azureedge.net",
    "widgetcdn.azureedge.net",
    "widgetservice.azurefd.net",
    "fp-vs.azureedge.net",
    "ln-ring.msedge.net",
    "t-ring.msedge.net",
    "t-ring-fdv2.msedge.net",
    "tse1.mm.bing.net",
    "config.edge.skype.com",
    "evoke-windowsservices-tas.msedge.net",
    "cdn.onenote.net",
    "tile-service.weather.microsoft.com"
)

Write-Host "=== Block Tracking Host Selesai ==="
'@
            }
                "UI For Privacy" {
                    $masterScript += @'
# =====================================================================
# UI FOR PRIVACY - KONFIGURASI ANTARMUKA & PENGATURAN PRIVASI WINDOWS
# =====================================================================

Write-Host "-> Menerapkan pengaturan UI For Privacy..." -ForegroundColor Cyan

# 1. Fungsi Pembantu untuk Mempercepat Modifikasi Registri
function Set-PrivacyReg {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -Type $Type -ErrorAction SilentlyContinue
}

# 2. Menonaktifkan Tips Online, Notifikasi Aplikasi, & Live Tiles
Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "AllowOnlineTips" 0
Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "DisableLockScreenAppNotifications" 1
Set-PrivacyReg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" "NoTileApplicationNotification" 1

# 3. Menonaktifkan Telemetri UI (Recent Apps, Usage Tracking, Backtracking)
Set-PrivacyReg "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" "DisableMFUTracking" 1
Set-PrivacyReg "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" "DisableRecentApps" 1
Set-PrivacyReg "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" "TurnOffBackstack" 1

# 4. Membersihkan Windows Explorer (Riwayat, Wizard, Sinkronisasi Iklan)
$expPolicies = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
Set-PrivacyReg $expPolicies "NoInternetOpenWith" 1
Set-PrivacyReg $expPolicies "NoOnlinePrintsWizard" 1
Set-PrivacyReg $expPolicies "NoPublishingWizard" 1
Set-PrivacyReg $expPolicies "NoWebServices" 1
Set-PrivacyReg $expPolicies "NoRecentDocsHistory" 1
Set-PrivacyReg $expPolicies "NoPhysicalCameraLED" 1

Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "ClearRecentDocsOnExit" 1
Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSyncProviderNotifications" 0
Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "ShowRecent" 0

# 5. Menyembunyikan Folder "3D Objects" dari This PC
$3dObj1 = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag"
$3dObj2 = "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag"
Set-PrivacyReg $3dObj1 "ThisPCPolicy" "Hide" "String"
Set-PrivacyReg $3dObj2 "ThisPCPolicy" "Hide" "String"
Set-PrivacyReg "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideMyComputerIcons" "{31C0DD25-9439-4F12-BF41-7FF4EDA38722}" 1

# Menghapus Namespace 3D Objects lama (Untuk Windows 10 & 11)
$namespace3D = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
if (Test-Path $namespace3D) {
    Remove-Item -Path $namespace3D -Force -Recurse -ErrorAction SilentlyContinue
}
Set-PrivacyReg $namespace3D "HiddenByDefault" 1
Set-PrivacyReg $namespace3D "HideIfEnabled" 36354489 # 0x22ab9b9

# 6. Menghapus File yang Baru Digunakan dari Quick Access
$delegateFolders = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}"
)
foreach ($folder in $delegateFolders) {
    if (Test-Path $folder) {
        Remove-ItemProperty -Path $folder -Name "(default)" -ErrorAction SilentlyContinue
    }
}

# 7. Menonaktifkan Hibernation (Mempercepat Startup & Keamanan Data)
Write-Host "-> Mematikan Hibernation..." -ForegroundColor Cyan
Invoke-Expression "powercfg -h off"

Write-Host "-> Pengaturan UI For Privacy selesai diterapkan!" -ForegroundColor Green
Write-Host "   (Restart explorer.exe atau komputer kamu agar efek UI terlihat)" -ForegroundColor Yellow

Write-Host "=== UI For Privacy Selesai ==="
'@
                }
                "Remove Bloatware" {
            $masterScript += @'
# =====================================================================
# SCRIPT REMOVE BLOATWARE (NATIVE POWERSHELL)
# =====================================================================

# 1. Pastikan script berjalan sebagai Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Memerlukan hak akses Administrator. Harap jalankan aplikasi sebagai Administrator."
    Exit 1
}

# ---------------------------------------------------------------------
# FUNGSI PEMBANTU (HELPER FUNCTIONS)
# ---------------------------------------------------------------------

# A. Fungsi Helper untuk memanipulasi Registry secara aman
function Set-PrivacyReg {
    param ([string]$Path, [string]$Name, $Value, [string]$Type = "DWORD")
    $psPath = $Path -replace "HKLM:", "Registry::HKLM" -replace "HKCU:", "Registry::HKCU"
    if (-not (Test-Path $psPath)) {
        New-Item -Path $psPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $psPath -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
}

# B. Injeksi WIN32 API untuk mendapatkan hak akses TrustedInstaller
$PrivilegeCode = @"
using System;
using System.Runtime.InteropServices;
public class Privileges {
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
    [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
    [DllImport("advapi32.dll", SetLastError = true)]
    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
    [StructLayout(LayoutKind.Sequential, Pack = 1)]
    internal struct TokPriv1Luid {
        public int Count;
        public long Luid;
        public int Attr;
    }
    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
    internal const int TOKEN_QUERY = 0x00000008;
    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
    public static bool AddPrivilege(string privilege) {
        try {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = GetCurrentProcess();
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1; tp.Luid = 0; tp.Attr = SE_PRIVILEGE_ENABLED;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        } catch { return false; }
    }
    public static bool RemovePrivilege(string privilege) {
        try {
            bool retVal;
            TokPriv1Luid tp;
            IntPtr hproc = GetCurrentProcess();
            IntPtr htok = IntPtr.Zero;
            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
            tp.Count = 1; tp.Luid = 0; tp.Attr = 0;
            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
            return retVal;
        } catch { return false; }
    }
    [DllImport("kernel32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr GetCurrentProcess();
}
"@

if (-not ([Object].Assembly.GetType("Privileges"))) {
    Add-Type -TypeDefinition $PrivilegeCode
}

# C. Fungsi Soft Delete (Mengganti nama folder bandel menjadi .OLD)
function Invoke-SoftDelete ($TargetGlob) {
    $expandedPath = [System.Environment]::ExpandEnvironmentVariables($TargetGlob)
    $items = Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Ignore
    
    if (-not $items) { return }

    $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'
    $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount])
    $adminAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($adminAccount, "FullControl", "Allow")

    foreach ($item in $items) {
        if ($item.PSIsContainer -or $item.Name.EndsWith(".OLD")) { continue }
        
        $filePath = $item.FullName
        try {
            $acl = Get-Acl -Path $filePath
            $acl.SetOwner($adminAccount)
            $acl.AddAccessRule($adminAccessRule)
            Set-Acl -Path $filePath -AclObject $acl -ErrorAction SilentlyContinue

            $oldPath = "$filePath.OLD"
            Move-Item -LiteralPath $filePath -Destination $oldPath -Force -ErrorAction SilentlyContinue
            Write-Host "   [Soft-Deleted] $filePath" -ForegroundColor DarkGray
        } catch {
            Write-Warning "   Gagal memproses berkas: $filePath"
        }
    }
}

# ---------------------------------------------------------------------
# EKSEKUSI REMOVE BLOATWARE
# ---------------------------------------------------------------------
Write-Host "=== Memulai Pembersihan Bloatware Secara Menyeluruh ===" -ForegroundColor Magenta

$userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# 2. Menghapus Aplikasi Bawaan (Standard UWP Apps)
Write-Host "-> Menghapus & Deprovisioning Aplikasi Bawaan (UWP)..." -ForegroundColor Cyan

$bloatwareApps = @(
    "Microsoft.MicrosoftOfficeHub_8wekyb3d8bbwe",          # Office 365 App
    "Microsoft.Office.OneNote_8wekyb3d8bbwe",              # OneNote
    "Microsoft.Office.Sway_8wekyb3d8bbwe",                 # Sway
    "Microsoft.WindowsPhone_8wekyb3d8bbwe",                # Phone Companion
    "Microsoft.CommsPhone_8wekyb3d8bbwe",                  # Microsoft Phone
    "Microsoft.YourPhone_8wekyb3d8bbwe",                   # Phone Link
    "king.com.CandyCrushSaga_kgqvnymyfvs32",               # Candy Crush Saga
    "king.com.CandyCrushSodaSaga_kgqvnymyfvs32",           # Candy Crush Soda Saga
    "ShazamEntertainmentLtd.Shazam_pqbynwjfrbcg4",         # Shazam
    "Flipboard.Flipboard_3f5azkryzdbc4",                   # Flipboard
    "9E2F88E3.Twitter_wgeqdkkx372wm",                      # Twitter
    "ClearChannelRadioDigital.iHeartRadio_a76a11dkgb644",  # iHeartRadio
    "D5EA27B7.Duolingo-LearnLanguagesforFree_yx6k7tf7xvsea",# Duolingo
    "AdobeSystemsIncorporated.AdobePhotoshopExpress_ynb6jyjzte8ga", # PS Express
    "PandoraMediaInc.29680B314EFC2_n619g4d5j0fnw",         # Pandora
    "46928bounde.EclipseManager_a5h4egax66k6y",            # Eclipse Manager
    "ActiproSoftwareLLC.562882FEEB491_24pqs290vpjk0",      # Code Writer
    "SpotifyAB.SpotifyMusic_zpdnekdrzrea0",                # Spotify
    "Microsoft.549981C3F5F10_8wekyb3d8bbwe",               # Cortana
    "Microsoft.Getstarted_8wekyb3d8bbwe",                  # Microsoft Tips
    "Microsoft.Messaging_8wekyb3d8bbwe",                   # Microsoft Messaging
    "Microsoft.MixedReality.Portal_8wekyb3d8bbwe",         # Mixed Reality Portal
    "Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe",          # Feedback Hub
    "Microsoft.MSPaint_8wekyb3d8bbwe",                     # Paint 3D
    "Microsoft.WindowsMaps_8wekyb3d8bbwe",                 # Windows Maps
    "Microsoft.MinecraftUWP_8wekyb3d8bbwe",                # Minecraft for Windows
    "Microsoft.People_8wekyb3d8bbwe",                      # Microsoft People
    "Microsoft.Wallet_8wekyb3d8bbwe",                      # Microsoft Pay
    "Microsoft.OneConnect_8wekyb3d8bbwe",                  # Mobile Plans
    "Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe",# Solitaire Collection
    "Microsoft.SkypeApp_kzf8qxf38zg5c",                    # Skype
    "Microsoft.GroupMe10_kzf8qxf38zg5c",                   # GroupMe
    "Microsoft.RemoteDesktop_8wekyb3d8bbwe",               # Microsoft Remote Desktop
    "Microsoft.NetworkSpeedTest_8wekyb3d8bbwe",            # Network Speed Test
    "Microsoft.Todos_8wekyb3d8bbwe",                       # Microsoft To Do
    "Microsoft.BingWeather_8wekyb3d8bbwe",                 # MSN Weather
    "Microsoft.BingSports_8wekyb3d8bbwe",                  # MSN Sports
    "Microsoft.BingNews_8wekyb3d8bbwe",                    # MSN News
    "Microsoft.BingFinance_8wekyb3d8bbwe",                 # MSN Money
    "Windows.Print3D_cw5n1h2txyewy",                       # Print 3D
    "Microsoft.3DBuilder_8wekyb3d8bbwe",                   # 3D Builder
    "Microsoft.Microsoft3DViewer_8wekyb3d8bbwe",           # 3D Viewer
    "Microsoft.XboxApp_8wekyb3d8bbwe",                     # Xbox Console Companion
    "Microsoft.Xbox.TCUI_8wekyb3d8bbwe",                   # Xbox Live in-game experience
    "Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe",     # Xbox Speech To Text Overlay
    "Microsoft.XboxIdentityProvider_8wekyb3d8bbwe",        # Xbox Identity Provider
    "Microsoft.GamingApp_8wekyb3d8bbwe",                   # Xbox App
    "Microsoft.XboxGamingOverlay_8wekyb3d8bbwe",           # Game Bar Overlay
    "Microsoft.XboxGameOverlay_8wekyb3d8bbwe"              # Xbox Game Overlay
)

foreach ($appFamily in $bloatwareApps) {
    $appName = $appFamily.Split('_')[0]
    Write-Host "   Menghapus: $appName..." -ForegroundColor Yellow
    Get-AppxPackage -Name $appName -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    $deprovisionPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$appFamily"
    if (-not (Test-Path $deprovisionPath)) {
        New-Item -Path $deprovisionPath -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

# 3. Menghapus System Apps Lanjutan (Menggunakan EndOfLife Bypass)
Write-Host "-> Menghapus System Apps (Callable UI, People, Take a Test, dll)..." -ForegroundColor Cyan

# Aktifkan hak restorasi dan pengambilalihan kepemilikan berkas dilindungi
[Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null
[Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null

$advancedSystemApps = @(
    "Microsoft.Windows.CallingShellApp_cw5n1h2txyewy",
    "Microsoft.XboxGameCallableUI_cw5n1h2txyewy",
    "Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy",
    "Microsoft.Windows.SecureAssessmentBrowser_cw5n1h2txyewy",
    "Microsoft.WindowsFeedback_cw5n1h2txyewy",
    "NarratorQuickStart_8wekyb3d8bbwe",
    "MicrosoftWindows.UndockedDevKit_cw5n1h2txyewy"
)

foreach ($appFamily in $advancedSystemApps) {
    $appName = $appFamily.Split('_')[0]
    Write-Host "   Bypass & Menghapus: $appName..." -ForegroundColor Yellow
    
    $eolPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$userSid\$appFamily"
    $deprovPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\$appFamily"
    
    if (-not (Test-Path $eolPath)) { New-Item -Path $eolPath -Force -ErrorAction SilentlyContinue | Out-Null }
    
    Get-AppxPackage -Name $appName -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    
    if (-not (Test-Path $deprovPath)) { New-Item -Path $deprovPath -Force -ErrorAction SilentlyContinue | Out-Null }
    if (Test-Path $eolPath) { Remove-Item -Path $eolPath -Force -ErrorAction SilentlyContinue | Out-Null }
}

# 4. Cleanup Sisa Folder SystemApps & WindowsApps (Soft-Delete)
Write-Host "-> Membersihkan Sisa Direktori SystemApps & Cache..." -ForegroundColor Cyan

$softDeletePaths = @(
    "%SYSTEMROOT%\SystemApps\Microsoft.XboxGameCallableUI_cw5n1h2txyewy\*",
    "%SYSTEMROOT%\XboxGameCallableUI\*",
    "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.XboxGameCallableUI_*_cw5n1h2txyewy\*",
    "%LOCALAPPDATA%\Packages\Microsoft.XboxGameCallableUI_cw5n1h2txyewy\*",
    "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.XboxGameCallableUI_*_cw5n1h2txyewy\*",
    
    "%SYSTEMROOT%\SystemApps\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*",
    "%SYSTEMROOT%\PeopleExperienceHost\*",
    "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*",
    "%LOCALAPPDATA%\Packages\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*",
    "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*",
    
    "%SYSTEMROOT%\SystemApps\Microsoft.Windows.SecureAssessmentBrowser_cw5n1h2txyewy\*",
    "%SYSTEMROOT%\SecureAssessmentBrowser\*",
    "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.Windows.SecureAssessmentBrowser_*_cw5n1h2txyewy\*",
    "%LOCALAPPDATA%\Packages\Microsoft.Windows.SecureAssessmentBrowser_cw5n1h2txyewy\*",
    "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.Windows.SecureAssessmentBrowser_*_cw5n1h2txyewy\*",
    
    "%SYSTEMROOT%\SystemApps\Microsoft.WindowsFeedback_cw5n1h2txyewy\*",
    "%SYSTEMROOT%\WindowsFeedback\*",
    "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*",
    "%LOCALAPPDATA%\Packages\Microsoft.WindowsFeedback_cw5n1h2txyewy\*",
    "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*",
    
    "%SYSTEMROOT%\SystemApps\Windows.Print3D_cw5n1h2txyewy\*",
    "%LOCALAPPDATA%\Packages\Windows.Print3D_cw5n1h2txyewy\*",
    "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Windows.Print3D_*cw5n1h2txyewy*",
    "%SYSTEMDRIVE%\Program Files\WindowsApps\Windows.Print3D_*cw5n1h2txyewy*"
)

foreach ($path in $softDeletePaths) {
    Invoke-SoftDelete $path
}

# Matikan hak akses khusus kembali ke mode normal (Keamanan Sistem)
[Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null
[Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null


# 5. Membersihkan OneDrive Secara Menyeluruh
Write-Host "-> Mematikan dan Menghapus OneDrive..." -ForegroundColor Cyan

Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDriveSetup" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "OneDrive" -ErrorAction SilentlyContinue

$odSetup32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
$odSetup64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
if (Test-Path $odSetup32) {
    Start-Process -FilePath $odSetup32 -ArgumentList "/uninstall" -Wait -NoNewWindow
} elseif (Test-Path $odSetup64) {
    Start-Process -FilePath $odSetup64 -ArgumentList "/uninstall" -Wait -NoNewWindow
}

# Evaluasi Direktori Shell OS
$userShellPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
$userShellEntries = Get-ItemProperty -Path $userShellPath
$isRedirected = $false
foreach ($prop in $userShellEntries.PSObject.Properties) {
    if ($prop.Value -like "*\OneDrive*") { $isRedirected = $true; break }
}

if (-not $isRedirected) {
    $oneDriveFolder = "$env:USERPROFILE\OneDrive"
    if (Test-Path $oneDriveFolder) {
        Remove-Item -Path "$oneDriveFolder\*" -Force -Recurse -ErrorAction SilentlyContinue
        if (-not (Get-ChildItem -Path $oneDriveFolder -Recurse -ErrorAction SilentlyContinue)) {
            Remove-Item -Path $oneDriveFolder -Force -ErrorAction SilentlyContinue
        }
    }
}

$cachePaths = @("$env:LOCALAPPDATA\Microsoft\OneDrive", "$env:PROGRAMDATA\Microsoft OneDrive", "$env:SystemDrive\OneDriveTemp")
foreach ($path in $cachePaths) {
    if (Test-Path $path) {
        cmd /c "takeown /f `"$path`" /a /r /d Y 2>&1" | Out-Null
        cmd /c "icacls `"$path`" /grant Administrators:F /t 2>&1" | Out-Null
        Remove-Item -Path $path -Force -Recurse -ErrorAction SilentlyContinue
    }
}

$shortcuts = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk",
    "$env:USERPROFILE\Links\OneDrive.lnk",
    "$env:SYSTEMROOT\ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk",
    "$env:SYSTEMROOT\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
)
foreach ($lnk in $shortcuts) { if (Test-Path $lnk) { Remove-Item -Path $lnk -Force -ErrorAction SilentlyContinue } }

Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" 1
Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSync" 1
Set-PrivacyReg "HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
Set-PrivacyReg "HKCU:\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" "System.IsPinnedToNameSpaceTree" 0
Remove-ItemProperty -Path "HKCU:\Environment" -Name "OneDrive" -ErrorAction SilentlyContinue

$tasks = @("OneDrive Reporting Task-*", "OneDrive Standalone Update Task-*", "OneDrive Per-Machine Standalone Update")
foreach ($taskName in $tasks) {
    Get-ScheduledTask -TaskName $taskName -ErrorAction Ignore | Disable-ScheduledTask -ErrorAction SilentlyContinue
}

# 6. Menonaktifkan Windows Copilot & Meet Now
Write-Host "-> Menonaktifkan Windows Copilot & Meet Now..." -ForegroundColor Yellow

Set-PrivacyReg "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-PrivacyReg "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1
Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat" "IsUserEligible" 0
Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "AutoOpenCopilotLargeScreens" 0
Set-PrivacyReg "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" 0
Set-PrivacyReg "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" "HideSCAMeetNow" 1
Set-PrivacyReg "HKCU:\Software\Microsoft\Narrator\QuickStart" "SkipQuickStart" 1

# 7. Mematikan Layanan Tidak Penting (Services)
Write-Host "-> Mematikan Background Services (Xbox, Maps, Messaging, UserData)..." -ForegroundColor Yellow

$ServicesToDisable = @(
    'XblGameSave', 'XboxNetApiSvc', 'XblAuthManager', 
    'MapsBroker', 'RetailDemo'
)

foreach ($svcName in $ServicesToDisable) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc) {
        if ($svc.Status -eq 'Running') { Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue }
        Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
    }
}

Get-Service -Name "UserDataSvc*" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name
    if ($_.Status -eq 'Running') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
    Set-PrivacyReg "HKLM:\SYSTEM\CurrentControlSet\Services\$name" "Start" 4
}

Get-Service -Name "MessagingService*" -ErrorAction SilentlyContinue | ForEach-Object {
    $name = $_.Name
    if ($_.Status -eq 'Running') { Stop-Service -Name $name -Force -ErrorAction SilentlyContinue }
    Set-PrivacyReg "HKLM:\SYSTEM\CurrentControlSet\Services\$name" "Start" 4
}

# ---------------------------------------------------------------------
# STATUS AKHIR & PENUTUP
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " DEBLOAT WINDOWS SELESAI!" -ForegroundColor Green
Write-Host " Semua bloatware dan telemetri telah dibersihkan." -ForegroundColor Green
Write-Host " Silakan RESTART komputer Anda agar perubahan Registry & Service aktif." -ForegroundColor Yellow
Write-Host "=======================================================================\n" -ForegroundColor Green

Write-Host "=== Remove Bloatware Selesai ==="
'@
                }
            }
        }

        # Penutup Script (DIUBAH MENJADI PAUSE MANUAL / TEKAN ENTER)
        $masterScript += @'

Write-Host "`n=================================================" -ForegroundColor Green
Write-Host " PROSES SELESAI!" -ForegroundColor Green
Write-Host " Tekan ENTER untuk keluar dari jendela ini..." -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Green
[void](Read-Host)
'@

        # --- RUNNER: MENJALANKAN SCRIPT DI JENDELA POWERSHELL BARU ---
        if (![string]::IsNullOrWhiteSpace($masterScript)) {
            try {
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
                
                # Simpan script sebagai file .ps1 (Bukan .bat lagi)
                $tempPs1 = Join-Path $env:TEMP "WaroengTweak_Apply.ps1"
                $masterScript | Out-File -FilePath $tempPs1 -Encoding utf8
                
                # Buka PowerShell baru (TIDAK HIDDEN agar user bisa melihat prosesnya)
                # Parameter -Wait membuat aplikasi Waroeng Tools menahan diri sampai jendela biru tertutup
                $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`""
                Start-Process "powershell.exe" -ArgumentList $psArgs -Wait
                
                # Hapus jejak
                Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
                
                Write-Log "Success: Execution completed."
                [System.Windows.Forms.MessageBox]::Show("Semua kategori terpilih selesai dieksekusi!", "Sukses", 0, 64)
            } 
            catch {
                [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
                [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan!`n$($_.Exception.Message)", "Error", 0, 16)
            }
        }
    })

    # ----------------------------------------------------
    # PANEL TENGAH: GRID KARTU KATEGORI
    # ----------------------------------------------------
    $flpGrid = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpGrid.Dock = "Fill"
    $flpGrid.AutoScroll = $true
    $flpGrid.WrapContents = $true
    $flpGrid.Padding = New-Object System.Windows.Forms.Padding(25, 20, 0, 20)

    $pnlMain.Controls.Add($flpGrid)
    $flpGrid.BringToFront() 

    # ---------------------------------------------------------
    # [BLOK 4] FUNGSI PEMBUAT KARTU TWEAK
    # ---------------------------------------------------------
    function Create-TweakCard {
        param ($Title, $InfoText)

        # Konfigurasi Dimensi Kartu
        $cardW = 310
        $cardH = 150
        $radius = 20
        $arcX = $cardW - $radius
        $arcY = $cardH - $radius
        $infoX = $cardW - 45
        $chkY = $cardH - 45
        $revX = $cardW - 100
        $revY = $cardH - 50

        # Kontainer Kartu
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size($cardW, $cardH)
        $card.Margin = New-Object System.Windows.Forms.Padding(15, 15, 10, 10)
        $card.BackColor = $cP.Card

        # Membuat Sudut Bulat Kartu
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $radius, $radius, 180, 90)
        $path.AddArc($arcX, 0, $radius, $radius, 270, 90)
        $path.AddArc($arcX, $arcY, $radius, $radius, 0, 90)
        $path.AddArc(0, $arcY, $radius, $radius, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        # Judul Tweak
        $lblTitle = New-Object System.Windows.Forms.Label
        $lblTitle.Text = $Title
        $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lblTitle.ForeColor = $cP.Accent
        $lblTitle.Location = New-Object System.Drawing.Point(20, 20)
        $lblTitle.Size = New-Object System.Drawing.Size(230, 50) 
        $card.Controls.Add($lblTitle)

        # Tombol Info (Lingkaran kecil 'i')
        $btnInfo = New-Object System.Windows.Forms.Label
        $btnInfo.Text = "i"
        $btnInfo.Font = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
        $btnInfo.Size = New-Object System.Drawing.Size(30, 30)
        $btnInfo.Location = New-Object System.Drawing.Point($infoX, 18)
        $btnInfo.TextAlign = "MiddleCenter"
        $btnInfo.BackColor = [System.Drawing.Color]::SteelBlue
        $btnInfo.ForeColor = [System.Drawing.Color]::White
        $btnInfo.Cursor = "Hand"
        
        $pathInfo = New-Object System.Drawing.Drawing2D.GraphicsPath
        $pathInfo.AddEllipse(0, 0, 29, 29)
        $btnInfo.Region = New-Object System.Drawing.Region($pathInfo)
        
        $btnInfo.Tag = $InfoText
        $btnInfo.Add_Click({ 
            [System.Windows.Forms.MessageBox]::Show($this.Tag, "Informasi Kategori", "OK", "Information") 
        })
        $card.Controls.Add($btnInfo)

        # Checkbox untuk Memilih
        $chkSelect = New-Object System.Windows.Forms.CheckBox
        $chkSelect.Text = "Apply Tweak"
        $chkSelect.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
        $chkSelect.ForeColor = $cP.Text
        $chkSelect.AutoSize = $true
        $chkSelect.Location = New-Object System.Drawing.Point(20, $chkY)
        $chkSelect.Cursor = "Hand"
        $chkSelect.Name = $Title 
        
        $card.Controls.Add($chkSelect)
        $script:CatCheckboxes += $chkSelect

        # ==========================================================
        # LOGIKA TOMBOL REVERT (HANYA JIKA BUKAN PRIVACY CLEANUP)
        # ==========================================================
        if ($Title -ne "Privacy Cleanup") {
            $btnRevert = New-Object System.Windows.Forms.Button
            $btnRevert.Text = "Revert"
            $btnRevert.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
            $btnRevert.Size = New-Object System.Drawing.Size(80, 32)
            $btnRevert.Location = New-Object System.Drawing.Point($revX, $revY)
            $btnRevert.BackColor = [System.Drawing.Color]::Firebrick
            $btnRevert.ForeColor = [System.Drawing.Color]::White
            $btnRevert.FlatStyle = "Flat"
            $btnRevert.FlatAppearance.BorderSize = 0
            $btnRevert.Cursor = "Hand"
            
            Set-RoundedElement -ctrl $btnRevert -radius 10
            $btnRevert.Tag = $Title

            $btnRevert.Add_Click({
                $catName = $this.Tag
                Write-Log "Action: User clicked Revert for '$catName'."
                
                $msg = "Kembalikan pengaturan asli untuk kategori:`n`n$catName?"
                if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Revert", "YesNo", "Warning") -eq "Yes") {
                    
                    # --- MEMBUAT SCRIPT POWERSHELL (.ps1) UNTUK REVERT ---
                    $revertScript = @'
$Host.UI.RawUI.WindowTitle = "Waroeng Tools - Reverting Tweak"
Write-Host "=================================================" -ForegroundColor Magenta
Write-Host "       REVERTING WINDOWS TWEAKS                  " -ForegroundColor Magenta
Write-Host "=================================================`n" -ForegroundColor Magenta
'@
                    
                    # --- DESAIN BOX PEMBATAS UNTUK REVERT (BARU) ---
                    $revertScript += @"
`nWrite-Host "=================================================" -ForegroundColor Yellow
Write-Host " -> REVERTING KATEGORI: $catName" -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Yellow`n
"@

                    switch ($catName) {
                        "Disable OS Data Collection" {
                            $revertScript += @'
# =====================================================================
# SCRIPT REVERT: DISABLE OS DATA COLLECTION (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) OS Data Collection & Telemetri..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU UNTUK OPTIMALISASI PERFORMA)
# ---------------------------------------------------------------------

# Fungsi untuk menghapus nilai registry dengan aman
function Remove-RegValue {
    param(
        [string]$Path,
        [string]$Name
    )
    if (Test-Path -Path $Path) {
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) -ne $null) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Menghapus nilai registry: $Name dari $Path" -ForegroundColor DarkGray
        }
    }
}

# Fungsi untuk mengatur/membuat nilai registry baru dengan aman
function Set-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        $Value,
        [string]$Type = "DWord"
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Mengatur nilai registry: $Name di $Path -> $Value" -ForegroundColor DarkGray
}

# Fungsi untuk memulihkan Tugas Terjadwal (Scheduled Tasks)
function Restore-Task {
    param(
        [string]$Path,
        [string]$Name,
        [bool]$Disable = $false
    )
    $task = Get-ScheduledTask -TaskPath $Path -TaskName $Name -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "   [LEWATI] Tugas tidak ditemukan: $Path$Name" -ForegroundColor Yellow
        return
    }
    try {
        if ($Disable) {
            if ($task.State -ne 'Disabled') {
                $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null
                Write-Host "   [OK] Menonaktifkan tugas: $Name" -ForegroundColor DarkGray
            } else {
                Write-Host "   [LEWATI] Tugas $Name sudah dalam kondisi tidak aktif." -ForegroundColor DarkGray
            }
        } else {
            if ($task.State -eq 'Disabled' -or $task.State -eq 'Unknown') {
                $task | Enable-ScheduledTask -ErrorAction Stop | Out-Null
                Write-Host "   [OK] Mengaktifkan kembali tugas: $Name" -ForegroundColor DarkGray
            } else {
                Write-Host "   [LEWATI] Tugas $Name sudah dalam kondisi aktif." -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Warning "   [GAGAL] Gagal memulihkan tugas $Name: $($_.Exception.Message)"
    }
}

# Fungsi untuk memulihkan Layanan Windows (Services)
function Restore-Service {
    param(
        [string]$Name,
        [string]$StartupType,
        [bool]$Start = $false
    )
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service) {
        Write-Host "   [LEWATI] Layanan tidak ditemukan: $Name" -ForegroundColor Yellow
        return
    }
    try {
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        Write-Host "   [OK] Mengubah tipe startup layanan $Name menjadi $StartupType" -ForegroundColor DarkGray
        if ($Start -and $service.Status -ne 'Running') {
            Start-Service -Name $Name -ErrorAction Stop
            Write-Host "   [OK] Memulai kembali layanan: $Name" -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "   [GAGAL] Gagal memulihkan layanan $Name: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# PROSES REVERT 1: PENGATURAN REGISTRY PRIVASI & TELEMETRI
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Pengaturan Registry..." -ForegroundColor Cyan

# CEIP Data Collection & Uploads
Remove-RegValue -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name "CEIPEnable"
Set-RegValue -Path "HKLM:\Software\Microsoft\SQMClient\Windows" -Name "CEIPEnable" -Value 0
Remove-RegValue -Path "HKLM:\Software\Microsoft\SQMClient" -Name "UploadDisableFlag"

# OneSettings, Lisensi Telemetri, & Cortana Above Lock
Remove-RegValue -Path "HKLM:\Software\Policies\Microsoft\Windows\DataCollection" -Name "DisableOneSettingsDownloads"
Remove-RegValue -Path "HKLM:\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform" -Name "NoGenTicket"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortanaAboveLock"

# Aktivasi Suara & Privasi Speech
Remove-RegValue -Path "HKCU:\Software\Microsoft\Speech_OneCore\Preferences" -Name "VoiceActivationOn"
Remove-RegValue -Path "HKLM:\Software\Microsoft\Speech_OneCore\Preferences" -Name "VoiceActivationDefaultOn"
Remove-RegValue -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted"

# Persetujuan Privasi & Feedback Windows
Set-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Personalization\Settings" -Name "AcceptedPrivacyPolicy" -Value 1
Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Siuf\Rules" -Name "NumberOfSIUFInPeriod"
Set-RegValue -Path "HKCU:\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore" -Name "HarvestContacts" -Value 1

# Feedback Pengetikan (Typing Feedback) & Activity Feed
Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value 1
Set-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Input\TIPC" -Name "Enabled" -Value 1
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "EnableActivityFeed"


# ---------------------------------------------------------------------
# PROSES REVERT 2: PEMULIHAN COMPATTELRUNNER.EXE (TELEMETRI SENDER)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Eksekusi CompatTelRunner.exe..." -ForegroundColor Cyan

# Hapus dari Image File Execution Options (IFEO)
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe" -Name "Debugger"

# Hapus dari Kebijakan DisallowRun jika ada
$disallowPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun"
if (Test-Path $disallowPath) {
    $props = Get-ItemProperty -Path $disallowPath -ErrorAction SilentlyContinue
    if ($props) {
        foreach ($prop in $props.PSObject.Properties) {
            if ($prop.Value -eq "CompatTelRunner.exe") {
                Remove-ItemProperty -Path $disallowPath -Name $prop.Name -Force -ErrorAction SilentlyContinue
                Write-Host "   [OK] Menghapus aturan pembatasan DisallowRun untuk CompatTelRunner.exe" -ForegroundColor DarkGray
            }
        }
    }
    # Jika subkey DisallowRun sekarang kosong, bersihkan flag utamanya
    $remaining = Get-ItemProperty -Path $disallowPath -ErrorAction SilentlyContinue
    $hasRules = $false
    if ($remaining) {
        foreach ($p in $remaining.PSObject.Properties) {
            if ($p.Name -notmatch "PSPath|PSParentPath|PSChildName|PSDrive|Provider|PSProvider") { $hasRules = $true }
        }
    }
    if (-not $hasRules) {
        Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisallowRun" -Force -ErrorAction SilentlyContinue
    }
}

# Kembalikan file asli dari isolasi (.OLD)
$compatTelPath = "$env:SystemRoot\System32\CompatTelRunner.exe"
$compatTelOldPath = "$compatTelPath.OLD"
if (Test-Path $compatTelOldPath) {
    try {
        Rename-Item -Path $compatTelOldPath -NewName "CompatTelRunner.exe" -Force -ErrorAction Stop
        Write-Host "   [OK] Berhasil mengembalikan berkas CompatTelRunner.exe dari backup (.OLD)" -ForegroundColor DarkGray
    } catch {
        Write-Warning "   [SKIPPED] Berkas cadangan (.OLD) ditemukan tetapi gagal diubah namanya. Kemungkinan masalah hak akses sistem."
    }
}


# ---------------------------------------------------------------------
# PROSES REVERT 3: TUGAS TERJADWAL (SCHEDULED TASKS)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Tugas Terjadwal (Scheduled Tasks)..." -ForegroundColor Cyan

Restore-Task -Path "\Microsoft\Windows\Autochk\" -Name "Proxy" [cite: 1697, 1698]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -Name "KernelCeipTask" [cite: 1707, 1708]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -Name "BthSQM" [cite: 1717, 1718]
Restore-Task -Path "\Microsoft\Windows\DiskDiagnostic\" -Name "Microsoft-Windows-DiskDiagnosticDataCollector" [cite: 1727, 1728]
Restore-Task -Path "\Microsoft\Windows\DiskDiagnostic\" -Name "Microsoft-Windows-DiskDiagnosticResolver" -Disable $true [cite: 1737, 1738]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -Name "Consolidator" [cite: 1747, 1748]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\" -Name "Uploader" [cite: 1757, 1758]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -Name "ServerCeipAssistant" [cite: 1767, 1768]
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -Name "ServerRoleCollector"
Restore-Task -Path "\Microsoft\Windows\Customer Experience Improvement Program\Server\" -Name "ServerRoleUsageCollector"
Restore-Task -Path "\Microsoft\Windows\Application Experience\" -Name "Microsoft Compatibility Appraiser"


# ---------------------------------------------------------------------
# PROSES REVERT 4: LAYANAN WINDOWS (SERVICES)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Layanan Telemetri (Services)..." -ForegroundColor Cyan

# Mengembalikan DiagTrack (Connected User Experiences and Telemetry) ke Automatic dan dijalankan
Restore-Service -Name "DiagTrack" -StartupType "Automatic" -Start $true [cite: 1492]

# Mengembalikan dmwappushservice ke Manual (Default Windows)
Restore-Service -Name "dmwappushservice" -StartupType "Manual" [cite: 1536]


# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT OS DATA COLLECTION SELESAI!" -ForegroundColor Green
Write-Host " Semua pengaturan telemetri bawaan OS telah dipulihkan ke default." -ForegroundColor Green
Write-Host " Silakan RESTART komputer Anda agar perubahan berjalan optimal." -ForegroundColor Yellow
Write-Host "=======================================================================\n" -ForegroundColor Green
'@
                }
                        "Configure Programs" {
                            $revertScript += @'
# =====================================================================
# SCRIPT REVERT: CONFIGURE PROGRAMS (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) Pengaturan Program Pihak Ketiga..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU UNTUK OPTIMALISASI PERFORMA)
# ---------------------------------------------------------------------

# Fungsi untuk menghapus nilai registry dengan aman
function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path -Path $Path) {
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) -ne $null) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Menghapus nilai registry: $Name dari $Path" -ForegroundColor DarkGray
        }
    }
}

# Fungsi untuk mengatur nilai registry dengan aman
function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Mengatur nilai registry: $Name di $Path -> $Value" -ForegroundColor DarkGray
}

# Fungsi untuk memulihkan Layanan Windows (Services)
function Restore-Service {
    param([string]$Name, [string]$StartupType)
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if (-not $service) { return }
    try {
        Set-Service -Name $Name -StartupType $StartupType -ErrorAction Stop
        Write-Host "   [OK] Mengubah tipe startup layanan $Name menjadi $StartupType" -ForegroundColor DarkGray
    } catch {
        Write-Warning "   [GAGAL] Gagal memulihkan layanan $Name: $($_.Exception.Message)"
    }
}

# Fungsi cerdas untuk menghapus kunci spesifik di dalam file JSON (VS Code)
function Remove-JsonSetting {
    param([string]$JsonFilePath, [string]$SettingKey)
    if (-not (Test-Path $JsonFilePath -PathType Leaf)) { return }
    try {
        $fileContent = Get-Content $JsonFilePath -Raw -ErrorAction Stop
        if ([string]::IsNullOrWhiteSpace($fileContent)) { return }
        
        $json = ConvertFrom-Json -InputObject $fileContent -ErrorAction Stop
        if ($null -ne $json.PSObject.Properties[$SettingKey]) {
            $json.PSObject.Properties.Remove($SettingKey)
            $json | ConvertTo-Json -Depth 10 | Set-Content $JsonFilePath -ErrorAction Stop
            Write-Host "   [OK] Memulihkan pengaturan '$SettingKey' di VS Code" -ForegroundColor DarkGray
        }
    } catch {
        Write-Warning "   [GAGAL] Gagal memodifikasi VS Code settings ($SettingKey): $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# PROSES REVERT 1: VISUAL STUDIO TELEMETRY & FEEDBACK
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Telemetri & Feedback Visual Studio..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\Software\Policies\Microsoft\VisualStudio\SQM" -Name "OptIn"
Remove-RegValue -Path "HKCU:\Software\Microsoft\VisualStudio\Telemetry" -Name "TurnOffSwitch"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableFeedbackDialog"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableEmailInput"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback" -Name "DisableScreenshotCapture"
Remove-RegValue -Path "HKLM:\Software\Microsoft\VisualStudio\DiagnosticsHub" -Name "LogLevel"

# Memulihkan Telemetri IntelliCode
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode" -Name "DisableRemoteAnalysis"
Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode" -Name "DisableRemoteAnalysis"
Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode" -Name "DisableRemoteAnalysis"

# Mengaktifkan kembali VSCommon SQM (OptIn ke 1) dengan Array
$vsVersions = @("14.0", "15.0", "16.0", "17.0")
foreach ($ver in $vsVersions) {
    Set-RegValue -Path "HKLM:\SOFTWARE\Microsoft\VSCommon\$ver\SQM" -Name "OptIn" -Value 1
    Set-RegValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\VSCommon\$ver\SQM" -Name "OptIn" -Value 1
}

# Memulihkan Layanan Standar Visual Studio (Collector Service)
Restore-Service -Name "VSStandardCollectorService150" -StartupType "Manual"

# ---------------------------------------------------------------------
# PROSES REVERT 2: VISUAL STUDIO CODE (PENGATURAN JSON)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Pengaturan Visual Studio Code..." -ForegroundColor Cyan
$vscodeSettingsPath = "$env:APPDATA\Code\User\settings.json"

if (Test-Path $vscodeSettingsPath) {
    $vscodeKeys = @(
        "telemetry.enableTelemetry",
        "telemetry.enableCrashReporter",
        "workbench.enableExperiments",
        "update.mode",
        "update.showReleaseNotes",
        "extensions.autoCheckUpdates",
        "extensions.showRecommendationsOnlyOnDemand",
        "git.autofetch",
        "npm.fetchOnlinePackageInfo"
    )
    foreach ($key in $vscodeKeys) {
        Remove-JsonSetting -JsonFilePath $vscodeSettingsPath -SettingKey $key
    }
} else {
    Write-Host "   [LEWATI] File pengaturan VS Code tidak ditemukan (User belum menginstalnya)." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# PROSES REVERT 3: MICROSOFT OFFICE LOGGING
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Pencatatan Log (Logging) Microsoft Office..." -ForegroundColor Cyan

$officeVersions = @("15.0", "16.0")
foreach ($ver in $officeVersions) {
    Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Outlook\Options\Mail" -Name "EnableLogging"
    Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Outlook\Options\Calendar" -Name "EnableCalendarLogging"
    Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Office\$ver\Word\Options" -Name "EnableLogging"
    Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\OSM" -Name "EnableLogging"
    Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\OSM" -Name "EnableUpload"
    Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Office\$ver\OSM" -Name "EnableFileObfuscation"
}

# ---------------------------------------------------------------------
# PROSES REVERT 4: CCLEANER TELEMETRY
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Konfigurasi Telemetri CCleaner..." -ForegroundColor Cyan

$ccleanerPath = "HKCU:\Software\Piriform\CCleaner"
$ccleanerKeys = @(
    "(Cfg)HealthCheck",
    "(Cfg)QuickClean",
    "(Cfg)QuickCleanIpm",
    "(Cfg)GetIpmForTrial",
    "(Cfg)SoftwareUpdater",
    "(Cfg)SoftwareUpdaterIpm"
)
foreach ($key in $ccleanerKeys) {
    Remove-RegValue -Path $ccleanerPath -Name $key
}

# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT 'CONFIGURE PROGRAMS' SELESAI!" -ForegroundColor Green
Write-Host " Pengaturan Telemetri pada VS Code, Office, dan aplikasi lain telah dipulihkan." -ForegroundColor Green
Write-Host "=======================================================================\n" -ForegroundColor Green
'@
                }
                        "Security Improvements" {
                            $revertScript += @'
# =====================================================================
# SCRIPT REVERT: SECURITY IMPROVEMENTS (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) Security Improvements..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU UNTUK OPTIMALISASI PERFORMA)
# ---------------------------------------------------------------------

# Fungsi untuk menghapus nilai registry dengan aman
function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path -Path $Path) {
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) -ne $null) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Menghapus nilai registry: $Name dari $Path" -ForegroundColor DarkGray
        }
    }
}

# Fungsi untuk mengatur nilai registry dengan aman
function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Mengatur nilai registry: $Name di $Path -> $Value" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# PROSES REVERT 1: SEHOP & DATA EXECUTION PREVENTION (DEP)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan pengaturan SEHOP dan DEP..." -ForegroundColor Cyan

Set-RegValue -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" -Name "DisableExceptionChainValidation" -Value 0
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "NoDataExecutionPrevention"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableHHDEP"


# ---------------------------------------------------------------------
# PROSES REVERT 2: POWERSHELL 2.0 (DIPERBAIKI)
# ---------------------------------------------------------------------
Write-Host "`n-> Mengaktifkan kembali fitur lawas PowerShell 2.0..." -ForegroundColor Cyan

$ps2Features = @("MicrosoftWindowsPowerShellV2", "MicrosoftWindowsPowerShellV2Root")
foreach ($featureName in $ps2Features) {
    try {
        $feature = Get-WindowsOptionalFeature -FeatureName $featureName -Online -ErrorAction SilentlyContinue
        if ($feature -and $feature.State -ne 'Enabled') {
            Enable-WindowsOptionalFeature -FeatureName $featureName -All -Online -NoRestart -WarningAction SilentlyContinue -ErrorAction Stop | Out-Null
            Write-Host "   [OK] Berhasil mengaktifkan kembali fitur: $featureName" -ForegroundColor DarkGray
        } else {
            Write-Host "   [LEWATI] Fitur $featureName sudah aktif." -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "   [GAGAL] Gagal mengaktifkan fitur $featureName: $($_.Exception.Message)"
    }
}


# ---------------------------------------------------------------------
# PROSES REVERT 3: WINDOWS CONNECT NOW (WCN)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan pengaturan Windows Connect Now (WCN)..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\Software\Policies\Microsoft\Windows\WCN\UI" -Name "DisableWcnUi"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "DisableFlashConfigRegistrar"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "DisableInBand802DOT11Registrar"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "DisableUPnPRegistrar"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "DisableWPDRegistrar"
Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WCN\Registrars" -Name "EnableRegistrars"


# ---------------------------------------------------------------------
# PROSES REVERT 4: CLOUD CLIPBOARD SINKRONISASI
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Pengaturan Sinkronisasi Cloud Clipboard..." -ForegroundColor Cyan

# Hanya memulihkan pengaturan upload cloud (karena service dan riwayat lokal tidak lagi dimatikan)
Remove-RegValue -Path "HKCU:\Software\Microsoft\Clipboard" -Name "CloudClipboardAutomaticUpload"


# ---------------------------------------------------------------------
# PROSES REVERT 5: PROTOKOL KEAMANAN JARINGAN (DTLS & TLS)
# ---------------------------------------------------------------------
Write-Host "`n-> Mengembalikan pengaturan default protokol TLS 1.3 dan DTLS 1.2..." -ForegroundColor Cyan

$protocols = @("DTLS 1.2", "TLS 1.3")
$roles = @("Server", "Client")
$schannelPath = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols"

foreach ($proto in $protocols) {
    foreach ($role in $roles) {
        Remove-RegValue -Path "$schannelPath\$proto\$role" -Name "Enabled"
        Remove-RegValue -Path "$schannelPath\$proto\$role" -Name "DisabledByDefault"
    }
}

# Memulihkan konfigurasi koneksi aman untuk aplikasi .NET lama
$dotnetPaths = @(
    "HKLM:\SOFTWARE\Microsoft\.NETFramework\v2.0.50727",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v2.0.50727",
    "HKLM:\SOFTWARE\Microsoft\.NETFramework\v4.0.30319",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\.NETFramework\v4.0.30319"
)
foreach ($path in $dotnetPaths) {
    Remove-RegValue -Path $path -Name "SystemDefaultTlsVersions"
}


# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT 'SECURITY IMPROVEMENTS' SELESAI!" -ForegroundColor Green
Write-Host " Pengaturan keamanan OS telah dipulihkan ke setelan bawaan Windows." -ForegroundColor Green
Write-Host "=======================================================================\n" -ForegroundColor Green
'@
                }
                        "Block Tracking Hosts" {
                            $revertScript += @'
# =====================================================================
# SCRIPT REVERT: BLOCK TRACKING HOSTS (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) Block Tracking Hosts..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# PROSES REVERT 1: MEMBERSIHKAN FILE HOSTS
# ---------------------------------------------------------------------
$hostsFilePath = "$env:SYSTEMROOT\System32\drivers\etc\hosts"
$marker = "# managed by privacy.sexy"

if (Test-Path $hostsFilePath) {
    try {
        # Membaca seluruh isi file Hosts
        $hostsContent = Get-Content -Path $hostsFilePath -ErrorAction Stop
        
        # Menyaring dan membuang semua baris yang mengandung marker dari privacy.sexy
        $newContent = $hostsContent | Where-Object { $_ -notmatch [regex]::Escape($marker) }
        
        # Mengecek apakah ada baris yang berhasil dihapus
        if ($hostsContent.Count -ne $newContent.Count) {
            $removedCount = $hostsContent.Count - $newContent.Count
            
            # Menulis ulang file Hosts yang sudah bersih
            Set-Content -Path $hostsFilePath -Value $newContent -Force -ErrorAction Stop
            Write-Host "   [OK] Berhasil menghapus $removedCount baris domain pelacak dari file Hosts." -ForegroundColor DarkGray
        } else {
            Write-Host "   [LEWATI] Tidak ditemukan entri blokir '$marker' di dalam file Hosts." -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "   [GAGAL] Gagal memulihkan atau menyimpan perubahan pada file Hosts: $($_.Exception.Message)"
    }
} else {
    Write-Host "   [LEWATI] File Hosts tidak ditemukan di sistem ($hostsFilePath)." -ForegroundColor Yellow
}

# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT 'BLOCK TRACKING HOSTS' SELESAI!" -ForegroundColor Green
Write-Host " File Hosts OS Windows Anda telah dipulihkan dan dibersihkan dari blokir." -ForegroundColor Green
Write-Host "=======================================================================\n" -ForegroundColor Green
'@
                }
                "UI For Privacy" {
                    $revertScript += @'
# =====================================================================
# SCRIPT REVERT: UI FOR PRIVACY (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) UI For Privacy..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# HELPER FUNCTIONS
# ---------------------------------------------------------------------

# Fungsi untuk menghapus nilai registry dengan aman
function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path -Path $Path) {
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) -ne $null) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
            Write-Host "   [OK] Memulihkan (menghapus): $Name dari $Path" -ForegroundColor DarkGray
        }
    }
}

# Fungsi untuk mengatur nilai registry dengan aman
function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = "DWord")
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -Force -ErrorAction SilentlyContinue | Out-Null
    }
    Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -Force -ErrorAction SilentlyContinue
    Write-Host "   [OK] Mengatur nilai: $Name di $Path -> $Value" -ForegroundColor DarkGray
}

# ---------------------------------------------------------------------
# PROSES REVERT 1: EXPLORER & QUICK ACCESS
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan fitur File Explorer dan Quick Access..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoRecentDocsHistory"
Remove-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "ClearRecentDocsOnExit"
Remove-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" -Name "ShowRecent"
Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSyncProviderNotifications"

# Mengembalikan folder "Recent Files" ke delegate Explorer
$recentPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}",
    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}"
)
foreach ($path in $recentPaths) {
    Set-RegValue -Path $path -Name "(Default)" -Value "Recent Files Folder" -Type "String"
}

# ---------------------------------------------------------------------
# PROSES REVERT 2: 3D OBJECTS FOLDER (This PC)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan folder '3D Objects' di This PC..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" -Name "ThisPCPolicy"
Remove-RegValue -Path "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{31C0DD25-9439-4F12-BF41-7FF4EDA38722}\PropertyBag" -Name "ThisPCPolicy"
Remove-RegValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideMyComputerIcons" -Name "{31C0DD25-9439-4F12-BF41-7FF4EDA38722}"

# Membuat ulang Namespace untuk 3D Objects
$namespacePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}"
if (-not (Test-Path $namespacePath)) {
    New-Item -Path $namespacePath -Force -ErrorAction SilentlyContinue | Out-Null
}
Remove-RegValue -Path $namespacePath -Name "HiddenByDefault"
Remove-RegValue -Path $namespacePath -Name "HideIfEnabled"


# ---------------------------------------------------------------------
# PROSES REVERT 3: TIPS ONLINE & WIZARDS
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Tips Online dan layanan web bawaan..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "AllowOnlineTips"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoInternetOpenWith"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoOnlinePrintsWizard"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoPublishingWizard"
Remove-RegValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoWebServices"


# ---------------------------------------------------------------------
# PROSES REVERT 4: NOTIFIKASI & PELACAKAN APLIKASI
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Notifikasi Lock Screen dan riwayat penggunaan aplikasi..." -ForegroundColor Cyan

Remove-RegValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Name "DisableLockScreenAppNotifications"
Remove-RegValue -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "NoTileApplicationNotification"
Remove-RegValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoPhysicalCameraLED"
Remove-RegValue -Path "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" -Name "DisableMFUTracking"
Remove-RegValue -Path "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" -Name "DisableRecentApps"
Remove-RegValue -Path "HKCU:\Software\Policies\Microsoft\Windows\EdgeUI" -Name "TurnOffBackstack"

# Memulihkan Icon "Meet Now" di Taskbar
Remove-RegValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow"


# ---------------------------------------------------------------------
# PROSES REVERT 5: SISTEM POWER (HIBERNASI)
# ---------------------------------------------------------------------
Write-Host "`n-> Mengaktifkan kembali fitur Hibernasi..." -ForegroundColor Cyan
try {
    & powercfg -h on *>&1 | Out-Null
    Write-Host "   [OK] Perintah powercfg -h on berhasil dieksekusi." -ForegroundColor DarkGray
} catch {
    Write-Warning "   [GAGAL] Gagal mengaktifkan hibernasi."
}


# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT 'UI FOR PRIVACY' SELESAI!" -ForegroundColor Green
Write-Host " Antarmuka Windows Anda telah dikembalikan ke setelan bawaan." -ForegroundColor Green
Write-Host "=======================================================================\n" -ForegroundColor Green

Write-Host "Mulai ulang (Restarting) Windows Explorer agar UI langsung diperbarui..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe
'@
                }
                        "Remove Bloatware" {
                            $revertScript += @'
# =====================================================================
# SCRIPT REVERT: REMOVE BLOATWARE (NATIVE POWERSHELL)
# =====================================================================

# 1. Memastikan skrip berjalan dengan hak akses Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Hak akses Administrator diperlukan. Silakan jalankan alat ini sebagai Administrator."
    Exit 1
}

Write-Host "-> Memulai proses pemulihan (Revert) Aplikasi Bawaan (Bloatware)..." -ForegroundColor Cyan

# ---------------------------------------------------------------------
# HELPER FUNCTIONS (FUNGSI PEMBANTU)
# ---------------------------------------------------------------------

# Fungsi untuk menghapus nilai registry dengan aman
function Remove-RegValue {
    param([string]$Path, [string]$Name)
    if (Test-Path -Path $Path) {
        if ((Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue) -ne $null) {
            Remove-ItemProperty -Path $Path -Name $Name -Force -ErrorAction SilentlyContinue
        }
    }
}

# Fungsi untuk memulihkan layanan Windows
function Restore-Service {
    param([string]$Name, [string]$StartupType)
    $service = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($service) {
        try {
            Set-Service -Name $Name -StartupType $StartupType -ErrorAction SilentlyContinue
            Write-Host "   [OK] Memulihkan layanan: $Name ($StartupType)" -ForegroundColor DarkGray
        } catch {}
    }
}

# Fungsi cerdas untuk menginstal ulang aplikasi UWP (Appx) yang sebelumnya dihapus
function Restore-UWPApp {
    param([string]$PackageName)
    
    # 1. Hapus dari daftar Deprovisioned (agar sistem mengizinkan instalasi lagi)
    $deprovPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned"
    $deprovKeys = Get-ChildItem -Path $deprovPath -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match $PackageName }
    foreach ($key in $deprovKeys) {
        Remove-Item -Path $key.PSPath -Force -Recurse -ErrorAction SilentlyContinue
    }

    # 2. Re-register dari file manifest sistem jika aplikasinya masih tersimpan di cache OS
    try {
        $app = Get-AppxPackage -AllUsers -Name "*$PackageName*" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($app -and $app.InstallLocation) {
            $manifest = Join-Path $app.InstallLocation "AppxManifest.xml"
            if (Test-Path $manifest) {
                Add-AppxPackage -Register $manifest -DisableDevelopmentMode -ErrorAction SilentlyContinue
                Write-Host "   [OK] Berhasil merestorasi aplikasi: $PackageName" -ForegroundColor DarkGray
                return
            }
        }
    } catch {}
    Write-Host "   [LEWATI] Aplikasi $PackageName tidak tersedia di cache (Bisa diunduh manual di MS Store)." -ForegroundColor Yellow
}

# Fungsi untuk mengembalikan nama folder sistem/aplikasi terkunci dari .OLD
function Restore-SoftDeletedFolder {
    param([string]$Directory)
    if (Test-Path $Directory) {
        $oldFolders = Get-ChildItem -Path $Directory -Filter "*.OLD" -Directory -ErrorAction SilentlyContinue
        foreach ($folder in $oldFolders) {
            $newName = $folder.Name.Replace(".OLD", "")
            try {
                # Ambil alih hak akses penuh terlebih dahulu
                & takeown /f $folder.FullName /r /d y *>&1 | Out-Null
                & icacls $folder.FullName /grant "*S-1-5-32-544:F" /t /c /q *>&1 | Out-Null
                Rename-Item -Path $folder.FullName -NewName $newName -Force -ErrorAction SilentlyContinue
                Write-Host "   [OK] Memulihkan folder sistem terkunci: $newName" -ForegroundColor DarkGray
            } catch {}
        }
    }
}

# ---------------------------------------------------------------------
# PROSES REVERT 1: MENGINSTAL ULANG UWP BLOATWARE & APLIKASI SISTEM
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan Aplikasi Bawaan (UWP Apps)..." -ForegroundColor Cyan

# Daftar aplikasi bloatware & sistem yang akan direstorasi
$uwpApps = @(
    "Microsoft.YourPhone",
    "Microsoft.Windows.PeopleExperienceHost",
    "Microsoft.Windows.SecureAssessmentBrowser",
    "NarratorQuickStart",
    "Microsoft.WindowsFeedback",
    "Microsoft.BingWeather",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.WindowsMaps",
    "Microsoft.XboxApp",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneVideo",
    "Microsoft.ZuneMusic",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.GetHelp",
    "Microsoft.Getstarted",
    "Microsoft.WindowsFeedbackHub",
    "SpotifyAB.SpotifyMusic",
    "king.com.CandyCrushSaga",
    "Microsoft.MinecraftUWP"
)

foreach ($app in $uwpApps) {
    Restore-UWPApp -PackageName $app
}

# ---------------------------------------------------------------------
# PROSES REVERT 2: MEMULIHKAN FOLDER SISTEM TERKUNCI (.OLD)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan folder sistem yang disembunyikan (Soft-delete)..." -ForegroundColor Cyan
Restore-SoftDeletedFolder -Directory "$env:windir\SystemApps"

# ---------------------------------------------------------------------
# PROSES REVERT 3: MEMULIHKAN LAYANAN (SERVICES)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan layanan latar belakang (Background Services)..." -ForegroundColor Cyan

Restore-Service -Name "MapsBroker" -StartupType "Automatic"
Restore-Service -Name "RetailDemo" -StartupType "Manual"
Restore-Service -Name "UserDataSvc" -StartupType "Automatic"

# ---------------------------------------------------------------------
# PROSES REVERT 4: TASKBAR ICONS (COPILOT & MEET NOW)
# ---------------------------------------------------------------------
Write-Host "`n-> Memulihkan icon Copilot & Meet Now di Taskbar..." -ForegroundColor Cyan

Remove-RegValue -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton"
Remove-RegValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAMeetNow"

# ---------------------------------------------------------------------
# SELESAI
# ---------------------------------------------------------------------
Write-Host "`n=======================================================================" -ForegroundColor Green
Write-Host " PROSES REVERT 'REMOVE BLOATWARE' SELESAI!" -ForegroundColor Green
Write-Host " Catatan: Jika ada aplikasi (seperti Spotify/Candy Crush) yang tidak kembali," -ForegroundColor Green
Write-Host " itu karena cache OS telah dibersihkan. Anda bisa mengunduhnya di MS Store." -ForegroundColor Green
Write-Host "=======================================================================\n" -ForegroundColor Green

Write-Host "Mulai ulang (Restarting) Windows Explorer..." -ForegroundColor Yellow
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process explorer.exe
'@
}
    }
                    # Penutup Script Revert (DIUBAH MENJADI PAUSE MANUAL / TEKAN ENTER)
                    $revertScript += @'

Write-Host "`n=================================================" -ForegroundColor Green
Write-Host " PROSES REVERT SELESAI!" -ForegroundColor Green
Write-Host " Tekan ENTER untuk keluar dari jendela ini..." -ForegroundColor Yellow
Write-Host "=================================================" -ForegroundColor Green
[void](Read-Host)
'@
                
                    # --- RUNNER REVERT (VIA POWERSHELL TAB BARU) ---
                    if (![string]::IsNullOrWhiteSpace($revertScript)) {
                        try {
                            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
                            
                            # Simpan menggunakan format .ps1 (Bukan .bat lagi)
                            $tempPs1 = Join-Path $env:TEMP "WaroengTweak_Revert.ps1"
                            $revertScript | Out-File -FilePath $tempPs1 -Encoding utf8
                            
                            # Menjalankan PowerShell secara TERBUKA (Tidak Hidden)
                            $psArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`""
                            Start-Process "powershell.exe" -ArgumentList $psArgs -Wait
                            
                            # Pembersihan file temporary
                            Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
                            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
                            
                            Write-Log "Success: Revert process completed for $catName."
                            [System.Windows.Forms.MessageBox]::Show("Proses Revert untuk $catName berhasil!", "Sukses", 0, 64)
                        } 
                        catch {
                            [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
                            Write-Log "Failed: Error during Revert. Details: $($_.Exception.Message)"
                            [System.Windows.Forms.MessageBox]::Show("Gagal melakukan Revert!`n$($_.Exception.Message)", "Error", 0, 16)
                        }
                    }
                } 
                else {
                    Write-Log "Process Cancelled: User aborted Revert for $catName."
                }
            })
            $card.Controls.Add($btnRevert)
        }
        
        return $card
    }

    # ----------------------------------------------------
    # RENDER SEMUA KARTU KE DALAM GRID
    # ----------------------------------------------------
    if ($global:TweakCategories) {
        foreach ($cat in $global:TweakCategories) {
            # Membuat kartu baru berdasarkan database
            $card = Create-TweakCard -Title $cat.Name -InfoText $cat.Info
            
            # Memasukkan kartu ke dalam FlowLayoutPanel (Grid)
            $flpGrid.Controls.Add($card)
        }
    }

    # Menambahkan panel utama yang sudah jadi ke container aplikasi
    $contentPanel.Controls.Add($pnlMain)
    
    Write-Log "UI Rendered: Windows Tweaks menu is now visible."
}

# ========================================================
# SELESAI RENDER WINDOWS TWEAKS
# ========================================================

# ========================================================
# MULAI RENDER SYSTEM REPAIR
# ========================================================
function Action-RepStandard {
    Write-Log "Action Triggered: User initiated Standard System Repair."
    
    $msg = "Proses ini akan menjalankan SFC dan DISM secara berurutan.`n`nWaktu estimasi: 20-45 Menit.`nJendela PowerShell akan terbuka untuk menampilkan progres.`n`nLanjutkan proses perbaikan?"
    $result = [System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi", "OKCancel", "Question")

    if ($result -eq "OK") {
        Write-Log "Process Started: Standard System Repair confirmed. Launching PowerShell sequence..."
        
        # Menggunakan titik koma (;) untuk menyambung perintah di PowerShell
        # Menggunakan Write-Host untuk memberi warna pada teks info
        $cmds = "Write-Host '(1/6) Running SFC Scan (1st Pass)...' -ForegroundColor Cyan; sfc /scannow; " +
                "Write-Host '(2/6) DISM ScanHealth...' -ForegroundColor Cyan; dism /online /cleanup-image /scanhealth; " +
                "Write-Host '(3/6) DISM CheckHealth...' -ForegroundColor Cyan; dism /online /cleanup-image /checkhealth; " +
                "Write-Host '(4/6) DISM RestoreHealth (Online)...' -ForegroundColor Cyan; dism /online /cleanup-image /restorehealth; " +
                "Write-Host '(5/6) DISM ComponentCleanup...' -ForegroundColor Cyan; dism.exe /online /cleanup-image /startcomponentcleanup; " +
                "Write-Host '(6/6) Running SFC Scan (Final Pass)...' -ForegroundColor Cyan; sfc /scannow; " +
                "Write-Host '`nALL TASKS COMPLETED!' -ForegroundColor Green; Read-Host 'Press Enter to close this window'"

        # Menjalankan PowerShell baru sebagai Administrator
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Normal -Command `"$cmds`"" -Verb RunAs
    } else {
        Write-Log "Process Cancelled: User aborted Standard System Repair."
    }
}

function Action-RepChkdsk {
    Write-Log "Action Triggered: User initiated Check Disk (CHKDSK) scheduling."
    $msg = "CHKDSK biasanya perlu restart komputer jika memeriksa drive C:.`n`nApakah Anda ingin menjadwalkan CHKDSK saat Restart nanti?"
    
    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi", "YesNo", "Question") -eq "Yes") {
        Write-Log "Success: CHKDSK scheduled for the next system reboot."
        Start-Process cmd -ArgumentList "/k  y | chkdsk /f" -Verb RunAs
        [System.Windows.Forms.MessageBox]::Show("CHKDSK telah dijadwalkan.`nSilakan Restart komputer Anda untuk memulai perbaikan disk.", "Info", "OK", "Information")
    } else {
        Write-Log "Process Cancelled: User aborted CHKDSK scheduling."
    }
}

function Action-RepSource {
    Write-Log "Action Triggered: User initiated Repair with Custom Source (WIM)."
    
    $intro = "Fitur ini memperbaiki Windows menggunakan file asli (install.wim) sebagai sumbernya.`n`n" +
             "CARA MENDAPATKAN FILE INSTALL.WIM:`n" +
             "1. Download file ISO Windows (sesuai versi OS kamu).`n" +
             "2. Klik kanan file ISO -> Mount.`n" +
             "3. Buka drive hasil mount, masuk ke folder 'sources'.`n" +
             "4. Cari file bernama 'install.wim'.`n`n" +
             "Klik OK untuk mencari file tersebut di komputer Anda."
    
    $res = [System.Windows.Forms.MessageBox]::Show($intro, "Panduan", "OKCancel", "Information")
    if ($res -eq "Cancel") { 
        Write-Log "Process Cancelled: User closed the instruction prompt for Custom Source Repair."
        return 
    }

    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Title = "Pilih file install.wim dari folder 'sources' Windows ISO"
    $dlg.Filter = "Windows Image File (install.wim)|install.wim|All Files (*.*)|*.*"
    
    if ($dlg.ShowDialog() -eq "OK") {
        $wimPath = $dlg.FileName
        Write-Log "Action: User selected custom source file: $wimPath"

        if ([System.Windows.Forms.MessageBox]::Show("Sumber dipilih: $wimPath`n`nMulai perbaikan sekarang?", "Konfirmasi", "YesNo", "Question") -eq "Yes") {
            Write-Log "Process Started: Executing DISM Repair using local source..."
            
            $cmd = "dism /Online /Cleanup-Image /RestoreHealth /Source:wim:`"$wimPath`":1 /limitaccess & " +
                   "echo. & echo REPAIR WITH SOURCE COMPLETED! & pause"
            
            Start-Process cmd -ArgumentList "/c title Waroeng Tools - Repair with Source && $cmd" -Verb RunAs
        } else {
            Write-Log "Process Cancelled: User aborted Custom Source Repair at final confirmation."
        }
    } else {
        Write-Log "Process Cancelled: User aborted WIM file selection."
    }
}

function Render-SystemRepair {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true # SCROLL UTAMA HALAMAN

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "System Repair Tools"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Perbaiki file sistem Windows yang korup, error disk, atau kerusakan komponen (SFC & DISM)."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. GRID UNTUK ACTION CARDS ---
    $flpCards = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpCards.Location = New-Object System.Drawing.Point(25, 160)
    $flpCards.Size = New-Object System.Drawing.Size(770, 0)
    $flpCards.AutoSize = $true
    $flpCards.AutoSizeMode = "GrowAndShrink"
    $flpCards.AutoScroll = $false 
    $flpCards.FlowDirection = "TopDown"
    $flpCards.WrapContents = $false

    # --- HELPER FUNCTION UNTUK KARTU TOMBOL (ANTI-ERROR HOVER) ---
    function Create-ActionCard ($Title, $Desc, $IconCode, $ColorName, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(735, 90)
        $card.Margin = New-Object System.Windows.Forms.Padding(5, 5, 15, 10)
        $card.BackColor = $cP.Card
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand

        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(20, 25)
        try { $ico.ForeColor = [System.Drawing.Color]::FromName($ColorName) } catch { $ico.ForeColor = $cP.Accent }
        $card.Controls.Add($ico)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = $cP.Text
        $lTitle.Location = New-Object System.Drawing.Point(80, 20)
        $lTitle.AutoSize = $true
        $card.Controls.Add($lTitle)

        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(80, 48)
        $lSub.Size = New-Object System.Drawing.Size(630, 20)
        $lSub.AutoSize = $false
        $lSub.AutoEllipsis = $true
        $card.Controls.Add($lSub)

        # Efek Hover (Dievaluasi Real-Time agar bebas error)
        $card.Add_MouseEnter({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $card.Add_MouseLeave({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $ico.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $ico.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lTitle.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lTitle.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lSub.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lSub.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)

        return $card
    }

    # --- 3. MEMASUKKAN TOMBOL ACTION ---
    $flpCards.Controls.Add((Create-ActionCard "Standard System Repair" "Jalankan SFC /Scannow & DISM Online Repair secara berurutan. (Rekomendasi Utama)" 0xE90F "DeepSkyBlue" { Action-RepStandard }))
    $flpCards.Controls.Add((Create-ActionCard "Check Disk (CHKDSK)" "Periksa drive sistem (C:) dari error filesystem. Membutuhkan Restart PC." 0xE7F1 "Orange" { Action-RepChkdsk }))
    $flpCards.Controls.Add((Create-ActionCard "Repair with Custom Source" "Jalankan DISM menggunakan file 'install.wim' lokal. Gunakan jika Standard Repair gagal." 0xE88E "MediumOrchid" { Action-RepSource }))

    $pnlMain.Controls.Add($flpCards)
    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER SYSTEM REPAIR
# ========================================================

# ========================================================
# MULAI RENDER SYSTEM REPORT
# ========================================================
function Action-ReportNFO {
    Write-Log "Action Triggered: User initiated NFO System Report export."
    
    $msg = "Proses ini akan mengumpulkan informasi detail Hardware & Software via MSINFO32.`n`n" +
           "WAKTU ESTIMASI: 1 - 2 Menit.`n" +
           "Aplikasi mungkin akan terlihat diam (Not Responding) saat proses scan.`n`n" +
           "Lanjutkan?"
           
    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Export", "YesNo", "Information") -eq "Yes") {
        Write-Log "Process Started: NFO Export confirmed. Initiating MSINFO32 scan..."
        
        # 1. Tentukan Lokasi File (Desktop)
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $fileName = "System_Info_Report.nfo"
        $fullPath = Join-Path $desktopPath $fileName
        
        # 2. Ubah Kursor jadi Loading
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        try {
            # 3. Jalankan MSINFO32
            Start-Process "msinfo32.exe" -ArgumentList "/nfo `"$fullPath`"" -Wait -WindowStyle Hidden
            
            # 4. Kembalikan Kursor
            $form.Cursor = [System.Windows.Forms.Cursors]::Default

            # 5. Cek apakah file berhasil dibuat
            if (Test-Path $fullPath) {
                Write-Log "Success: NFO System Report saved successfully to $fullPath"
                $ask = [System.Windows.Forms.MessageBox]::Show("Laporan berhasil disimpan di Desktop!`nPath: $fullPath`n`nBuka file sekarang?", "Sukses", "YesNo", "Information")
                if ($ask -eq "Yes") {
                    Write-Log "Action: User chose to open the generated NFO report."
                    Invoke-Item $fullPath
                }
            } else {
                Write-Log "Failed: NFO file was not created after MSINFO32 execution."
                [System.Windows.Forms.MessageBox]::Show("Gagal membuat file laporan.", "Error", "OK", "Error")
            }
        } catch {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            Write-Log "Failed: Error occurred during NFO export. Details: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan sistem.", "Error", "OK", "Error")
        }
    } else {
        Write-Log "Process Cancelled: User aborted NFO Export."
    }
}

function Action-ReportDxDiag {
    Write-Log "Action Triggered: User launched DirectX Diagnostic Tool (DxDiag)."
    [System.Windows.Forms.MessageBox]::Show("Akan membuka DxDiag.`nSilakan klik tombol 'Save All Information' di aplikasi tersebut jika ingin menyimpannya.", "Info", "OK", "Information")
    Start-Process "dxdiag.exe"
}

function Render-SystemReport {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true # SCROLL UTAMA HALAMAN

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "System Information Report"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Ekspor laporan mendetail mengenai komponen Hardware dan Software (MSINFO & DxDiag)."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. GRID UNTUK ACTION CARDS ---
    $flpCards = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpCards.Location = New-Object System.Drawing.Point(25, 160)
    $flpCards.Size = New-Object System.Drawing.Size(770, 0)
    $flpCards.AutoSize = $true
    $flpCards.AutoSizeMode = "GrowAndShrink"
    $flpCards.AutoScroll = $false 
    $flpCards.FlowDirection = "TopDown"
    $flpCards.WrapContents = $false

    # --- HELPER FUNCTION UNTUK KARTU TOMBOL (ANTI-ERROR HOVER) ---
    function Create-ActionCard ($Title, $Desc, $IconCode, $ColorName, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(735, 90)
        $card.Margin = New-Object System.Windows.Forms.Padding(5, 5, 15, 10)
        $card.BackColor = $cP.Card
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand

        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(20, 25)
        try { $ico.ForeColor = [System.Drawing.Color]::FromName($ColorName) } catch { $ico.ForeColor = $cP.Accent }
        $card.Controls.Add($ico)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = $cP.Text
        $lTitle.Location = New-Object System.Drawing.Point(80, 20)
        $lTitle.AutoSize = $true
        $card.Controls.Add($lTitle)

        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(80, 48)
        $lSub.Size = New-Object System.Drawing.Size(630, 20)
        $lSub.AutoSize = $false
        $lSub.AutoEllipsis = $true
        $card.Controls.Add($lSub)

        # Efek Hover (Dievaluasi Real-Time agar bebas error)
        $card.Add_MouseEnter({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $card.Add_MouseLeave({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $ico.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $ico.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lTitle.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lTitle.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lSub.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lSub.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)

        return $card
    }

    # --- 3. MEMASUKKAN TOMBOL ACTION ---
    $flpCards.Controls.Add((Create-ActionCard "Export Full System Report (.NFO)" "Generate laporan mendetail tentang Hardware & Software via MSINFO32 ke Desktop." 0xF0E3 "Teal" { Action-ReportNFO }))
    $flpCards.Controls.Add((Create-ActionCard "Open DirectX Diagnostic (DxDiag)" "Membuka alat DxDiag untuk melihat driver Grafis, Suara, dan Input." 0xE968 "CornflowerBlue" { Action-ReportDxDiag }))

    $pnlMain.Controls.Add($flpCards)
    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER SYSTEM REPORT
# ========================================================

# ========================================================
# MULAI RENDER BACKUP / RESTORE
# ========================================================
# --- Helper untuk Memilih Folder ---
function Get-UserSelectedPath ($Description) {
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = $Description
    $dlg.ShowNewFolderButton = $true
    if ($dlg.ShowDialog() -eq "OK") {
        return $dlg.SelectedPath
    }
    return $null
}

function Action-BackupData {
    Write-Log "Action Triggered: User initiated Backup Personal Data."
    
    # 1. DISCLAIMER
    $folders = " - Downloads`n - Documents`n - Pictures`n - Music`n - Videos"
    $msg = "PERHATIAN SEBELUM BACKUP:`n`n" +
           "Script ini akan MENYALIN (Copy) seluruh data dari folder:`n$folders`n`n" +
           "File asli TIDAK akan dihapus.`n" +
           "Anda akan diminta memilih lokasi penyimpanan backup.`n`n" +
           "Lanjutkan?"

    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Backup", "YesNo", "Warning") -eq "Yes") {
        Write-Log "Action: Backup confirmed. Prompting user to select destination folder..."
        
        # 2. Pilih Lokasi
        $destRoot = Get-UserSelectedPath "Pilih folder tujuan untuk menyimpan Backup"
        if ([string]::IsNullOrWhiteSpace($destRoot)) { 
            Write-Log "Process Cancelled: User aborted backup destination selection."
            return 
        }

        # 3. Buat Sub-folder dengan Tanggal & Jam (Supaya rapi)
        $dateStr = Get-Date -Format "yyyy-MM-dd_HH-mm"
        $backupDir = Join-Path $destRoot "WaroengBackup_$dateStr"
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        
        Write-Log "Process Started: Initiating Robocopy backup to $backupDir..."
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        # 4. Proses Robocopy
        $userProfile = $env:USERPROFILE
        $targetFolders = @("Downloads", "Documents", "Pictures", "Music", "Videos")
        
        foreach ($folder in $targetFolders) {
            $source = Join-Path $userProfile $folder
            $destination = Join-Path $backupDir $folder
            
            # Cek jika folder sumber ada
            if (Test-Path $source) {
                Write-Log "-> Copying folder: $folder"
                # Robocopy flags: /E (Recurse) /NFL /NDL (No log names) /NJH (No header) -> Supaya bersih
                # Kita gunakan Start-Process agar CMD window tidak muncul mengganggu, tapi user harus tunggu kursor loading
                $proc = Start-Process "robocopy" -ArgumentList "`"$source`" `"$destination`" /E /NFL /NDL /NJH /NJS /R:0 /W:0" -NoNewWindow -PassThru -Wait
            }
        }

        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        Write-Log "Success: Personal Data Backup completed successfully."
        [System.Windows.Forms.MessageBox]::Show("Backup Selesai!`n`nData tersimpan di:`n$backupDir", "Sukses", "OK", "Information")
        
        # Buka folder hasil backup
        Invoke-Item $backupDir
    } else {
        Write-Log "Process Cancelled: User aborted Backup Personal Data."
    }
}

function Action-RestoreData {
    Write-Log "Action Triggered: User initiated Restore Personal Data."
    
    # 1. DISCLAIMER
    $folders = " - Downloads`n - Documents`n - Pictures`n - Music`n - Videos"
    $msg = "PERHATIAN SEBELUM RESTORE:`n`n" +
           "Script ini akan MENGEMBALIKAN data ke folder:`n$folders`n`n" +
           "Pastikan Anda memilih folder backup yang benar (contoh: 'WaroengBackup_...').`n`n" +
           "Lanjutkan?"

    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Restore", "YesNo", "Warning") -eq "Yes") {
        Write-Log "Action: Restore confirmed. Prompting user to select source folder..."
        
        # 2. Pilih Folder Sumber Backup
        $sourceRoot = Get-UserSelectedPath "Pilih Folder 'WaroengBackup_...' yang ingin dikembalikan"
        if ([string]::IsNullOrWhiteSpace($sourceRoot)) { 
            Write-Log "Process Cancelled: User aborted restore source selection."
            return 
        }

        # Validasi sederhana: Cek apakah di dalamnya ada folder Documents/Downloads?
        $isValid = (Test-Path "$sourceRoot\Documents") -or (Test-Path "$sourceRoot\Downloads")
        if (-not $isValid) {
            Write-Log "Failed: Selected directory is not a valid WaroengTools backup folder."
            [System.Windows.Forms.MessageBox]::Show("Folder yang dipilih sepertinya bukan folder Backup yang valid.`nPastikan memilih folder yang berisi subfolder Documents, Downloads, dll.", "Error", "OK", "Error")
            return
        }

        Write-Log "Process Started: Initiating Restore from $sourceRoot..."
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        # 3. Proses Restore (Robocopy Balik)
        $userProfile = $env:USERPROFILE
        $targetFolders = @("Downloads", "Documents", "Pictures", "Music", "Videos")

        foreach ($folder in $targetFolders) {
            $source = Join-Path $sourceRoot $folder
            $destination = Join-Path $userProfile $folder
            
            if (Test-Path $source) {
                Write-Log "-> Restoring folder: $folder"
                Start-Process "robocopy" -ArgumentList "`"$source`" `"$destination`" /E /NFL /NDL /NJH /NJS /R:0 /W:0" -NoNewWindow -PassThru -Wait
            }
        }

        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        Write-Log "Success: Personal Data Restore completed successfully."
        [System.Windows.Forms.MessageBox]::Show("Restore Selesai!`nData telah dikembalikan ke folder User Anda.", "Sukses", "OK", "Information")
    } else {
        Write-Log "Process Cancelled: User aborted Restore Personal Data."
    }
}

function Action-BackupDriver {
    Write-Log "Action Triggered: User initiated Backup System Drivers."
    
    # 1. DISCLAIMER
    $msg = "PERHATIAN BACKUP DRIVER:`n`n" +
           "Script ini akan menyalin seluruh Driver Windows yang terinstall.`n" +
           "File asli tidak akan dihapus.`n`n" +
           "Pilih folder tujuan yang memiliki ruang penyimpanan cukup.`n" +
           "Lanjutkan?"

    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Driver Backup", "YesNo", "Warning") -eq "Yes") {
        Write-Log "Action: Driver Backup confirmed. Prompting user to select destination folder..."
        
        # 2. Pilih Lokasi
        $destRoot = Get-UserSelectedPath "Pilih folder tujuan untuk Backup Driver"
        if ([string]::IsNullOrWhiteSpace($destRoot)) { 
            Write-Log "Process Cancelled: User aborted driver backup destination selection."
            return 
        }

        $backupDir = Join-Path $destRoot "WaroengDrivers"
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        
        Write-Log "Process Started: Exporting drivers via Native PowerShell to $backupDir..."
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        try {
            # 3. Export Driver (Native PowerShell)
            Export-WindowsDriver -Online -Destination $backupDir -ErrorAction Stop
            
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            Write-Log "Success: System Driver Backup completed successfully."
            [System.Windows.Forms.MessageBox]::Show("Backup Driver Selesai!`nTersimpan di: $backupDir", "Sukses", "OK", "Information")
            Invoke-Item $backupDir
        } catch {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            Write-Log "Failed: Error occurred during Driver Backup. Details: $($_.Exception.Message)"
            [System.Windows.Forms.MessageBox]::Show("Gagal Backup Driver. Pastikan aplikasi dijalankan sebagai Administrator.", "Error", "OK", "Error")
        }
    } else {
        Write-Log "Process Cancelled: User aborted Backup System Drivers."
    }
}

function Render-BackupRestore {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true # SCROLL UTAMA HALAMAN

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Backup / Restore Center"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Amankan data personal dan ekspor driver sistem sebelum melakukan install ulang Windows."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. GRID UNTUK ACTION CARDS ---
    $flpCards = New-Object System.Windows.Forms.FlowLayoutPanel
    $flpCards.Location = New-Object System.Drawing.Point(25, 160)
    $flpCards.Size = New-Object System.Drawing.Size(770, 0)
    $flpCards.AutoSize = $true
    $flpCards.AutoSizeMode = "GrowAndShrink"
    $flpCards.AutoScroll = $false 
    $flpCards.FlowDirection = "TopDown"
    $flpCards.WrapContents = $false

    # --- HELPER FUNCTION UNTUK KARTU TOMBOL (ANTI-ERROR HOVER) ---
    function Create-ActionCard ($Title, $Desc, $IconCode, $ColorName, $ActionScript) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(735, 90)
        $card.Margin = New-Object System.Windows.Forms.Padding(5, 5, 15, 10)
        $card.BackColor = $cP.Card
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand

        $rad = 15
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $path.AddArc(0, 0, $rad, $rad, 180, 90)
        $path.AddArc($card.Width - $rad, 0, $rad, $rad, 270, 90)
        $path.AddArc($card.Width - $rad, $card.Height - $rad, $rad, $rad, 0, 90)
        $path.AddArc(0, $card.Height - $rad, $rad, $rad, 90, 90)
        $path.CloseAllFigures()
        $card.Region = New-Object System.Drawing.Region($path)

        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        $ico.AutoSize = $true
        $ico.Location = New-Object System.Drawing.Point(20, 25)
        try { $ico.ForeColor = [System.Drawing.Color]::FromName($ColorName) } catch { $ico.ForeColor = $cP.Accent }
        $card.Controls.Add($ico)

        $lTitle = New-Object System.Windows.Forms.Label
        $lTitle.Text = $Title
        $lTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $lTitle.ForeColor = $cP.Text
        $lTitle.Location = New-Object System.Drawing.Point(80, 20)
        $lTitle.AutoSize = $true
        $card.Controls.Add($lTitle)

        $lSub = New-Object System.Windows.Forms.Label
        $lSub.Text = $Desc
        $lSub.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
        $lSub.ForeColor = [System.Drawing.Color]::Gray
        $lSub.Location = New-Object System.Drawing.Point(80, 48)
        $lSub.Size = New-Object System.Drawing.Size(630, 20)
        $lSub.AutoSize = $false
        $lSub.AutoEllipsis = $true
        $card.Controls.Add($lSub)

        # Efek Hover (Dievaluasi Real-Time agar bebas error)
        $card.Add_MouseEnter({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $card.Add_MouseLeave({ $this.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $ico.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $ico.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lTitle.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lTitle.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $lSub.Add_MouseEnter({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(45, 45, 55) } else { [System.Drawing.Color]::FromArgb(235, 235, 235) } })
        $lSub.Add_MouseLeave({ $this.Parent.BackColor = if ($global:IsDarkMode) { [System.Drawing.Color]::FromArgb(30, 30, 35) } else { [System.Drawing.Color]::White } })

        $card.Add_Click($ActionScript)
        $ico.Add_Click($ActionScript)
        $lTitle.Add_Click($ActionScript)
        $lSub.Add_Click($ActionScript)

        return $card
    }

    # --- 3. MEMASUKKAN TOMBOL ACTION ---
    $flpCards.Controls.Add((Create-ActionCard "Backup Personal Data" "Menyalin file Documents, Downloads, Pictures, dsb. ke folder tujuan yang aman." 0xE74E "DeepSkyBlue" { Action-BackupData }))
    $flpCards.Controls.Add((Create-ActionCard "Restore Personal Data" "Mengembalikan file dari folder backup (WaroengBackup_...) ke profil User Anda saat ini." 0xE7A7 "LimeGreen" { Action-RestoreData }))
    $flpCards.Controls.Add((Create-ActionCard "Backup System Drivers" "Mengekspor semua driver yang terinstall agar bisa digunakan ulang nanti." 0xE772 "Orange" { Action-BackupDriver }))

    $pnlMain.Controls.Add($flpCards)
    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER BACKUP / RESTORE
# ========================================================

# ========================================================
# MULAI RENDER TECHNICAL GUIDES
# ========================================================
# --- Helper: Menampilkan Jendela Catatan ---
function Show-NoteWindow ($Title, $Content) {
    # Setup Form
    $frmNote = New-Object System.Windows.Forms.Form
    $frmNote.Text = $Title
    $frmNote.Size = New-Object System.Drawing.Size(700, 500)
    $frmNote.StartPosition = "CenterParent"
    $frmNote.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(30,30,35)} else {[System.Drawing.Color]::White}
    $frmNote.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::Black}
    
    # Text Box (Read Only)
    $txt = New-Object System.Windows.Forms.TextBox
    $txt.Multiline = $true
    $txt.ScrollBars = "Vertical"
    $txt.ReadOnly = $true
    $txt.BorderStyle = "None"
    $txt.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(30,30,35)} else {[System.Drawing.Color]::White}
    $txt.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::Gainsboro} else {[System.Drawing.Color]::Black}
    $txt.Font = New-Object System.Drawing.Font("Consolas", 10) # Font Monospace biar rapi
    $txt.Dock = "Fill"
    $txt.Text = $Content
    $txt.SelectionStart = 0
    $txt.SelectionLength = 0
    
    # Padding biar teks gak nempel pinggir
    $pnlPad = New-Object System.Windows.Forms.Panel
    $pnlPad.Dock = "Fill"
    $pnlPad.Padding = New-Object System.Windows.Forms.Padding(20)
    $pnlPad.Controls.Add($txt)
    
    $frmNote.Controls.Add($pnlPad)
    
    # Tombol Close di bawah
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = "Tutup Catatan"
    $btnClose.Dock = "Bottom"
    $btnClose.Height = 40
    $btnClose.FlatStyle = "Flat"
    $btnClose.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
    $btnClose.ForeColor = [System.Drawing.Color]::White
    $btnClose.Add_Click({ $frmNote.Close() })
    $frmNote.Controls.Add($btnClose)

    $frmNote.ShowDialog()
}

# --- ISI KONTEN CATATAN (DATABASE TEKS) ---

function Get-Note-Error709 {
    return @"
=====================================================
  Additional Printer Settings (Error 0x00000709)
=====================================================

Masalah ini biasanya terjadi karena Policy RPC pada Windows 11/10 terbaru.
Silakan buka 'Local Group Policy Editor' (gpedit.msc) dan atur manual:

[1] Configure RPC connection settings
    - Lokasi        : Computer Configuration \ Administrative Templates \ Printers
    - Setting Name  : Configure RPC connection settings
    - Status        : Enabled
    - Protocol used : RPC over named pipes

[2] Configure RPC listener settings
    - Lokasi        : Computer Configuration \ Administrative Templates \ Printers
    - Setting Name  : Configure RPC listener settings
    - Status        : Enabled
    - Protocol used : RPC over named pipes and TCP

[3] Configure RPC over TCP port
    - Lokasi        : Computer Configuration \ Administrative Templates \ Printers
    - Setting Name  : Configure RPC over TCP port
    - Status        : Enabled

CATATAN:
- Restart komputer setelah mengubah Group Policy.
- Atau gunakan fitur "Printer Sharing Fix" di menu Other Tools
"@
}

function Get-Note-Error3e3 {
    return @"
=====================================================
  Additional Printer Settings (Error 0x000003e3)
=====================================================

Lakukan langkah manual via Registry Editor:

[1] Tekan tombol Logo Windows + R -> Ketik: REGEDIT -> Enter.

[2] Arahkan ke lokasi berikut:
    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3\Merk_Tipe_Printer_Kamu

    *Catatan: Ganti 'Merk_Tipe_Printer_Kamu' dengan nama folder driver printer yang bermasalah.

[3] Cari key bernama "PrinterDriverAttributes"

[4] Klik dua kali, ubah nilainya menjadi: 1

[5] Klik OK dan tutup Registry Editor.

[6] Restart komputer jika diperlukan.
"@
}

function Get-Note-RST {
    return @"
=====================================================
       SSD TIDAK MUNCUL SAAT INSTAL WINDOWS
              (Intel RST Issue)
=====================================================

KONTEKS:
Saat instalasi Windows (terutama laptop Intel Gen 10/11/12/13), SSD NVMe tidak terdeteksi.

SOLUSI: Load Driver Intel RST (Rapid Storage Technology) manual.

[1] Solusi: Extract Driver RST dengan SetupRST.exe
    - Download SetupRST dari situs resmi Intel:
    - Simpan file SetupRST.exe ke root drive D: (Contoh lokasi: D:\SetupRST.exe)  

[2] Langkah Ekstraksi Driver
    - Ketik cmd, klik kanan Command Prompt lalu pilih Run as Administrator.
    - Jalankan perintah berikut: "D:\SetupRST.exe -extractdrivers RST"
    - Setelah proses selesai, driver akan diekstrak ke: (D:\RST)

[3] Gunakan Driver Saat Instalasi Windows
    - Buat USB installer Windows seperti biasa.
    - Salin folder hasil ekstrak (D:\RST) ke dalam USB installer Windows.
      Bisa ke folder Drivers, atau langsung di root USB.
    - Saat instalasi Windows dan SSD tidak terdeteksi, klik:
      Load driver / Browse / Pilih folder Intel RST yang kamu salin tadi / pilih file dengan format .inf
    - Windows akan memuat driver, dan SSD akan muncul.

[4] Catatan Tambahan:
    - Pastikan BIOS Mode menggunakan RAID atau RST, bukan AHCI.
    - Jika BIOS menggunakan AHCI, SSD seharusnya langsung terdeteksi tanpa driver tambahan.
    - Download SetupRST.exe sesuai dengan Gen Intel kamu
"@
}

function Get-Note-LOQ {
    return @"
=====================================================
      SETTING SETUP UNDERVOLT LENOVO LOQ
=====================================================

--- BAGIAN 1: THROTTLESTOP ---

[1] Aktifkan Pengaturan BIOS
    - Masuk BIOS (F2/Del).
    - Cari & Aktifkan: 'Legion Optimization' / 'Unlock Overclocking'.
    - Save & Exit.

[2] Konfigurasi FIVR (Voltage)
    - Buka ThrottleStop (Run as Admin).
    - Klik tombol 'FIVR'.
    - Pastikan judulnya 'FIVR Control' (Bukan 'Locked').
      Jika tertulis Unlocked atau Undervolt Protection, berarti ada pengaturan BIOS lain yang belum diaktifkan.

    Lakukan pada (CPU Core), (CPU P Cache), dan (CPU E Cache):
      -> Centang 'Unlock Adjustable Voltage'
      -> Range: Pilih '250 mV'
      -> Offset Voltage: Set ke '-135.7 mV' (atau sesuaikan stabilitas)
    
    - Pilih 'OK - Save voltage after ThrottleStop exits'.
    - Klik Apply -> OK.

[3] Atur Power Limits (TPL)
    - Klik tombol 'TPL'.
    - Uncheck 'Disable Controls'.
    - Di bagian Clamp, ubah angka jadi 45.
    - Apply -> OK.

--- BAGIAN 2: MSI AFTERBURNER (GPU) ---

[1] Curve Editor
    - Buka MSI Afterburner -> Settings.
    - Tab General -> Uncheck 'Unlock voltage control'.
    - Kembali ke menu utama -> Tekan 'Ctrl + F' (Curve Editor).
    - Cari titik Voltage di '925 mV' atau '900 mV' (beda orang beda racikan).
    - Tekan Shift lalu klik titik voltage nya lalu tarik titik tersebut naik (Frequency) sekitar '+229 MHz'.
    - Kalau sudah tekan Shift dan klik Enter 2x 
    - Jangan lupa untuk Save Profile.
"@
}

function Get-Note-Credential {
    return @"
=====================================================
  Printer Sharing: Windows Credential Issues
=====================================================

Jika saat connect ke printer sharing diminta Username/Password,
Gunakan kredensial komputer HOST (Komputer yang dicolok kabel USB printer).

[1] Username: 
    Nama User yang ada di komputer Host.
    (Cek dengan ketik 'whoami' di CMD komputer host).

[2] Password: 
    Password login komputer Host.
    
    *Jika komputer Host tidak ada password, buat password dulu atau 
     matikan 'Password Protected Sharing' di Network and Sharing Center.
"@
}

function Get-Note-Bypass {
    return @"
=====================================================
                Setting Local Windows 
=====================================================

Gunakan perintah ini saat instalasi Windows 11 memaksa koneksi internet/akun Microsoft.

[1] Buka CMD
    Tekan tombol: Shift + F10  (atau Fn + Shift + F10).

[2] Perintah Bypass (Pilih Salah Satu):

    A. Metode OOBE (Restart Setup)
       Ketik: oobe\bypassnro
       (Laptop akan restart dan menu 'I dont have internet' akan muncul).

    B. Metode Registry (Manual)
       reg add HKLM\software\microsoft\windows\CurrentVersion\oobe /v BypassNRO /t REG_DWORD /d 1 /f

    C. Metode Kill Process
       taskkill /F /IM oobenetworkconnectionflow.exe

    D. Metode Akun Lokal
        start ms-cxh:localonly

[3] Jika Keyboard tidak muncul?
    Aktifkan On-Screen Keyboard: Ctrl + Windows + O
"@
}

function Render-AddSettings {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    # --- HELPER: PELENGKUNG SUDUT CARD ---
    $SetRounded = {
        param($ctrl, $r)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { return }
        $D = $r * 2
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p.AddArc(0, 0, $D, $D, 180, 90)
        $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
        $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
        $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
        $p.CloseAllFigures()
        $ctrl.Region = New-Object System.Drawing.Region($p)
    }

    # PANEL UTAMA
    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true # SCROLL UTAMA HALAMAN

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Technical Guides (Manual Fix)"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Kumpulan panduan teknis dan perbaikan sistem Windows secara manual."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. CONTAINER FLOW (Untuk isi menunya nanti) ---
    $flowGrid = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowGrid.Location = New-Object System.Drawing.Point(30, 160)
    $flowGrid.Size = New-Object System.Drawing.Size(735, 400) # Bisa disesuaikan
    $flowGrid.Anchor = "Top, Bottom, Left, Right"
    $flowGrid.AutoScroll = $true
    $flowGrid.Padding = New-Object System.Windows.Forms.Padding(0)
    $pnlMain.Controls.Add($flowGrid)

    # --- FUNCTION HELPER: CREATE GUIDE CARD ---
    function Add-GuideCard ($Title, $Desc, $IconCode, $IconColor, $Action) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(($flowGrid.Width / 2 - 25), 105)
        $card.Margin = New-Object System.Windows.Forms.Padding(10)
        $card.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White}
        $card.Cursor = "Hand"

        # Icon Label dengan Warna Kustom
        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        try { $ico.ForeColor = [System.Drawing.Color]::FromName($IconColor) } catch { $ico.ForeColor = [System.Drawing.Color]::FromArgb(0, 102, 204) }
        $ico.Location = New-Object System.Drawing.Point(15, 30)
        $ico.AutoSize = $true
        $card.Controls.Add($ico)

        # Title
        $head = New-Object System.Windows.Forms.Label
        $head.Text = $Title
        $head.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $head.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::FromArgb(40, 40, 40)}
        $head.Location = New-Object System.Drawing.Point(65, 18)
        $head.Width = $card.Width - 80
        $card.Controls.Add($head)

        # Description
        $sub = New-Object System.Windows.Forms.Label
        $sub.Text = $Desc
        $sub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $sub.ForeColor = [System.Drawing.Color]::Gray
        $sub.Location = New-Object System.Drawing.Point(67, 48)
        $sub.Size = New-Object System.Drawing.Size(($card.Width - 85), 45)
        $card.Controls.Add($sub)

        # Click Events
        $card.Add_Click($Action); $ico.Add_Click($Action); $head.Add_Click($Action); $sub.Add_Click($Action)

        # Hover Effect
        $card.Add_MouseEnter({ $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(60, 60, 65)} else {[System.Drawing.Color]::FromArgb(235, 245, 255)} })
        $card.Add_MouseLeave({ $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White} })

        $flowGrid.Controls.Add($card)
        $null = $card.Handle; &$SetRounded $card 12
    }

    # --- MENAMBAHKAN GUIDES DENGAN WARNA IKON ---
    Add-GuideCard "Fix Printer Error 709" "Panduan manual Group Policy untuk memperbaiki koneksi RPC Printer." 0xE749 "Teal" { Show-NoteWindow "Error 709 Guide" (Get-Note-Error709) }
    Add-GuideCard "Fix Printer Error 3e3" "Langkah registrasi driver untuk masalah environment version printer." 0xE95F "SteelBlue" { Show-NoteWindow "Error 3e3 Guide" (Get-Note-Error3e3) }
    Add-GuideCard "Intel RST / SSD Missing" "Cara load driver Intel Rapid Storage saat instalasi Windows." 0xE88E "DarkOrange" { Show-NoteWindow "Intel RST Guide" (Get-Note-RST) }
    Add-GuideCard "Lenovo LOQ Undervolt" "Panduan ThrottleStop & Afterburner untuk suhu laptop lebih dingin." 0xE945 "Tomato" { Show-NoteWindow "Undervolt Guide" (Get-Note-LOQ) }
    Add-GuideCard "Printer Credentials" "Username & Password yang benar untuk akses printer sharing." 0xE8D7 "Goldenrod" { Show-NoteWindow "Credential Guide" (Get-Note-Credential) }
    Add-GuideCard "Bypass Windows Setup" "Cara melewati kewajiban akun Microsoft saat instalasi Windows 11." 0xE775 "RoyalBlue" { Show-NoteWindow "Bypass Guide" (Get-Note-Bypass) }
    
    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER TECHNICAL GUIDES
# ========================================================

# ========================================================
# MULAI RENDER OTHER TOOLS
# ========================================================
function Action-ToolTemp {
    Write-Log "Cleaning Temp Files..."
    if ([System.Windows.Forms.MessageBox]::Show("Script akan menghapus file sampah di C:\Windows\Temp dan %TEMP% User.`n`nLanjutkan?", "Konfirmasi", "Warning", "YesNo") -eq "Yes") {
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        # 1. Hapus System Temp
        Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        # 2. Hapus User Temp
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        [System.Windows.Forms.MessageBox]::Show("Temporary Files berhasil dibersihkan!", "Sukses", "OK", "Information")
    }
}

function Action-ToolNetReset {
    Write-Log "Starting Network Reset..."
    $msg = "RESET JARINGAN AKAN MELAKUKAN:`n" +
           "- Flush DNS & Reset Winsock`n" +
           "- Restart Adapter Network (WiFi/LAN akan putus sebentar)`n" +
           "- Restart Windows Explorer`n`n" +
           "Lanjutkan?"

    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi Reset Network", "YesNo", "Warning") -eq "Yes") {
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        cmd /c "netsh winsock reset"
        cmd /c "netsh int ip reset"
        cmd /c "ipconfig /flushdns"
        cmd /c "ipconfig /release"
        cmd /c "ipconfig /renew"

        cmd /c "nbtstat -R"
        cmd /c "nbtstat -RR"

        Get-NetAdapter | Where-Object Status -eq "Up" | Restart-NetAdapter -ErrorAction SilentlyContinue

        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 1
        
        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        [System.Windows.Forms.MessageBox]::Show("Network Reset Selesai!", "Sukses", "OK", "Information")
    }
}

function Action-ToolPrinter {
    Write-Log "Fixing Printer & Enabling SMB1..."
    if ([System.Windows.Forms.MessageBox]::Show("Proses ini akan mengaktifkan SMB 1.0 dan mengubah konfigurasi RPC Printer.`nKomputer perlu Restart setelah ini.`n`nLanjutkan?", "Konfirmasi", "YesNo", "Question") -eq "Yes") {
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        
        $features = "SMB1Protocol", "Printing-Foundation-LPRPortMonitor", "Printing-Foundation-LPDPrintService"
        foreach ($feat in $features) {
            Start-Process "dism.exe" -ArgumentList "/online /enable-feature /featurename:$feat /all /quiet /norestart" -Wait -NoNewWindow
        }

        $regRPC = "HKLM:\Software\Policies\Microsoft\Windows NT\Printers\RPC"
        if (-not (Test-Path $regRPC)) { New-Item -Path $regRPC -Force | Out-Null }
        
        Set-ItemProperty -Path $regRPC -Name "RpcOverNamedPipes" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $regRPC -Name "RpcOverTcp" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $regRPC -Name "RpcUseNamedPipeProtocol" -Value 1 -Type DWord -Force

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Print" -Name "RpcAuthnLevelPrivacyEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "AllowInsecureGuestAuth" -Value 1 -Type DWord -Force

        Restart-Service -Name spooler -Force -ErrorAction SilentlyContinue

        $form.Cursor = [System.Windows.Forms.Cursors]::Default
        [System.Windows.Forms.MessageBox]::Show("Konfigurasi Printer & SMB selesai.`nSilakan Restart komputer.", "Info", "OK", "Information")
    }
}

function Action-ToolChrome {
    Write-Log "Applying Chrome Extension Fix..."
    $path = "HKCU:\Software\Policies\Google\Chrome"
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    
    Set-ItemProperty -Path $path -Name "ExtensionManifestV2Availability" -Value 2 -Type DWord -Force
    [System.Windows.Forms.MessageBox]::Show("Fix applied!`nSilakan Restart Google Chrome.", "Sukses", "OK", "Information")
}

function Action-ToolGpEdit {
    Write-Log "Enabling Group Policy Editor..."
    $msg = "Proses ini akan menginstall GPEdit.msc (untuk Windows Home Edition).`n" +
           "Waktu estimasi: 2-5 Menit.`n" +
           "Jendela CMD akan terbuka untuk menampilkan progres instalasi.`n`n" +
           "Lanjutkan?"

    if ([System.Windows.Forms.MessageBox]::Show($msg, "Konfirmasi", "YesNo", "Question") -eq "Yes") {
        $script = '
            $list = Get-ChildItem "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum", "$env:SystemRoot\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum"
            Write-Host "Ditemukan $($list.Count) paket GPEdit. Mulai menginstall..." -ForegroundColor Cyan
            foreach ($i in $list) {
                Write-Host "Installing: $($i.Name)"
                dism /online /norestart /add-package:"$($i.FullName)"
            }
            Write-Host "`nSELESAI! Silakan coba ketik gpedit.msc di Run." -ForegroundColor Green
            Read-Host "Tekan Enter untuk keluar..."
        '
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($script)
        $encoded = [Convert]::ToBase64String($bytes)
        Start-Process powershell -ArgumentList "-NoProfile -EncodedCommand $encoded" -Verb RunAs
    }
}

function Action-ToolDiagnostic {
    Write-Log "Opening Device Diagnostic..."
    Start-Process "msdt.exe" -ArgumentList "/id DeviceDiagnostic"
}

function Action-HyperVEnable {
    Write-Log "Mengeksekusi bcdedit untuk mengaktifkan Hyper-V (Auto)..."
    try {
        $p = Start-Process bcdedit -ArgumentList "/set hypervisorlaunchtype auto" -Wait -NoNewWindow -PassThru
        if ($p.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Hyper-V Launch Type berhasil diatur ke [Auto].`n`nPERINGATAN: Anda harus me-restart komputer Anda agar efek perubahan ini aktif!", "Sukses", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Gagal mengeksekusi bcdedit. Pastikan aplikasi dijalankan sebagai Administrator.", "Akses Ditolak", "OK", "Error")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan: $_", "Error", "OK", "Error")
    }
}

function Action-HyperVDisable {
    Write-Log "Mengeksekusi bcdedit untuk menonaktifkan Hyper-V (Off)..."
    try {
        $p = Start-Process bcdedit -ArgumentList "/set hypervisorlaunchtype off" -Wait -NoNewWindow -PassThru
        if ($p.ExitCode -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Hyper-V Launch Type berhasil diatur ke [Off].`n`nPERINGATAN: Anda harus me-restart komputer Anda agar efek perubahan ini aktif (Optimal untuk Game & Emulator)!", "Sukses", "OK", "Information")
        } else {
            [System.Windows.Forms.MessageBox]::Show("Gagal mengeksekusi bcdedit. Pastikan aplikasi dijalankan sebagai Administrator.", "Akses Ditolak", "OK", "Error")
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Terjadi kesalahan: $_", "Error", "OK", "Error")
    }
}

function Action-CreateRestorePoint {
    Write-Log "Memulai proses pembuatan System Restore Point..."
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "WaroengTools_AutoBackup" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("System Restore Point 'WaroengTools_AutoBackup' BERHASIL dibuat!`nSistem Anda sekarang aman sebelum melakukan tweaking.", "Restore Point Sukses", "OK", "Information")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Gagal membuat Restore Point.`n`nKemungkinan penyebab:`n1. System Restore dimatikan permanen di Windows.`n2. Batasan Windows (Hanya boleh membuat 1 restore point dalam 24 jam).`n`nDetail Error: $_", "Gagal", "OK", "Warning")
    }
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::Default
}

function Render-OtherTools {
    $contentPanel.Controls.Clear()
    $cP = if ($global:IsDarkMode) { $ThemePalettes.Dark } else { $ThemePalettes.Light }

    # --- HELPER: PELENGKUNG SUDUT CARD ---
    $SetRounded = {
        param($ctrl, $r)
        if ($ctrl.Width -le 0 -or $ctrl.Height -le 0) { return }
        $D = $r * 2
        $p = New-Object System.Drawing.Drawing2D.GraphicsPath
        $p.AddArc(0, 0, $D, $D, 180, 90)
        $p.AddArc($ctrl.Width - $D, 0, $D, $D, 270, 90)
        $p.AddArc($ctrl.Width - $D, $ctrl.Height - $D, $D, $D, 0, 90)
        $p.AddArc(0, $ctrl.Height - $D, $D, $D, 90, 90)
        $p.CloseAllFigures()
        $ctrl.Region = New-Object System.Drawing.Region($p)
    }

    # PANEL UTAMA (Scroll vertical dikunci di sini)
    $pnlMain = New-Object System.Windows.Forms.Panel
    $pnlMain.Dock = "Fill"
    $pnlMain.BackColor = $cP.Bg
    $pnlMain.AutoScroll = $true  

    # --- 1. HEADER BANNER ---
    $bannerCard = New-Object System.Windows.Forms.Panel
    $bannerCard.Size = New-Object System.Drawing.Size(735, 110)
    $bannerCard.Location = New-Object System.Drawing.Point(30, 30)
    $bannerCard.BackColor = $cP.Header 
    
    $banRadius = 20
    $banPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $banPath.AddArc(0, 0, $banRadius, $banRadius, 180, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, 0, $banRadius, $banRadius, 270, 90)
    $banPath.AddArc($bannerCard.Width - $banRadius, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 0, 90)
    $banPath.AddArc(0, $bannerCard.Height - $banRadius, $banRadius, $banRadius, 90, 90)
    $banPath.CloseAllFigures()
    $bannerCard.Region = New-Object System.Drawing.Region($banPath)

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Text = "Other Utility Tools"
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
    $lblTitle.ForeColor = [System.Drawing.Color]::White
    $lblTitle.AutoSize = $true
    $lblTitle.Location = New-Object System.Drawing.Point(25, 20)
    $bannerCard.Controls.Add($lblTitle)

    $lblSubTitle = New-Object System.Windows.Forms.Label
    $lblSubTitle.Text = "Kumpulan alat utilitas tambahan untuk manajemen, proteksi, dan optimasi OS."
    $lblSubTitle.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $lblSubTitle.ForeColor = [System.Drawing.Color]::LightGray
    $lblSubTitle.AutoSize = $true
    $lblSubTitle.Location = New-Object System.Drawing.Point(28, 60)
    $bannerCard.Controls.Add($lblSubTitle)

    $pnlMain.Controls.Add($bannerCard)

    # --- 2. CONTAINER FLOW (KUNCI PERBAIKAN DI SINI) ---
    $flowGrid = New-Object System.Windows.Forms.FlowLayoutPanel
    $flowGrid.Location = New-Object System.Drawing.Point(30, 160)
    $flowGrid.Width = 735
    # Trik Utama: Kunci lebar maksimal di 735 agar kartu otomatis membungkus (wrap) ke bawah
    $flowGrid.MaximumSize = New-Object System.Drawing.Size(735, 0) 
    $flowGrid.WrapContents = $true       # Memastikan fitur bungkus baris aktif
    $flowGrid.AutoSize = $true           # Biar memanjang ke bawah mengikuti jumlah baris kartu
    $flowGrid.AutoSizeMode = "GrowAndShrink"
    $flowGrid.AutoScroll = $false        # Matikan scroll internal biar tidak bentrok
    $flowGrid.Padding = New-Object System.Windows.Forms.Padding(0, 0, 0, 40) # Spasi extra di bawah agar tidak kepotong
    $pnlMain.Controls.Add($flowGrid)

    # --- FUNCTION HELPER: CREATE CARD ---
    function Add-ToolCard ($Title, $Desc, $IconCode, $IconColor, $Action) {
        $card = New-Object System.Windows.Forms.Panel
        $card.Size = New-Object System.Drawing.Size(345, 100) 
        $card.Margin = New-Object System.Windows.Forms.Padding(0, 10, 20, 10) # Jarak antar kartu yang presisi
        $card.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White}
        $card.Cursor = "Hand"

        # Icon Label
        $ico = New-Object System.Windows.Forms.Label
        $ico.Text = [char]$IconCode
        $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 24)
        try { $ico.ForeColor = [System.Drawing.Color]::FromName($IconColor) } catch { $ico.ForeColor = [System.Drawing.Color]::FromArgb(0, 102, 204) }
        $ico.Location = New-Object System.Drawing.Point(15, 25)
        $ico.AutoSize = $true
        $card.Controls.Add($ico)

        # Title Label
        $head = New-Object System.Windows.Forms.Label
        $head.Text = $Title
        $head.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
        $head.ForeColor = if ($global:IsDarkMode) {[System.Drawing.Color]::White} else {[System.Drawing.Color]::FromArgb(40, 40, 40)}
        $head.Location = New-Object System.Drawing.Point(65, 18)
        $head.Width = $card.Width - 80
        $head.AutoEllipsis = $true
        $card.Controls.Add($head)

        # Description Label
        $sub = New-Object System.Windows.Forms.Label
        $sub.Text = $Desc
        $sub.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $sub.ForeColor = [System.Drawing.Color]::Gray
        $sub.Location = New-Object System.Drawing.Point(67, 45)
        $sub.Size = New-Object System.Drawing.Size(($card.Width - 85), 45)
        $card.Controls.Add($sub)

        # Click Event
        $card.Add_Click($Action); $ico.Add_Click($Action); $head.Add_Click($Action); $sub.Add_Click($Action)

        # Hover Effect
        $card.Add_MouseEnter({ $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(60, 60, 65)} else {[System.Drawing.Color]::FromArgb(235, 245, 255)} })
        $card.Add_MouseLeave({ $this.BackColor = if ($global:IsDarkMode) {[System.Drawing.Color]::FromArgb(45, 45, 50)} else {[System.Drawing.Color]::White} })

        $flowGrid.Controls.Add($card)
        
        $null = $card.Handle
        &$SetRounded $card 12
    }

    # --- MENAMBAHKAN TOOLS BAWAAN ---
    Add-ToolCard "Delete Temp Files" "Bersihkan file sampah di C:\Windows\Temp dan %TEMP% user." 0xE74D "Crimson" { Action-ToolTemp } 
    Add-ToolCard "Reset Network Stack" "Flush DNS, Reset Winsock, & Restart Adapter (Fix Internet)." 0xE909 "DodgerBlue" { Action-ToolNetReset } 
    Add-ToolCard "Printer Sharing Fix" "Aktifkan SMB1.0, Fix RPC 11b, & Restart Print Spooler." 0xE749 "Teal" { Action-ToolPrinter } 
    Add-ToolCard "Chrome Ext. Fix" "Paksa aktifkan Manifest V2 extensions via Registry Policy." 0xE774 "Goldenrod" { Action-ToolChrome } 
    Add-ToolCard "Enable GPEdit" "Install Group Policy Editor khusus untuk Windows Home Edition." 0xE7EF "MediumPurple" { Action-ToolGpEdit } 
    Add-ToolCard "Hardware Diagnostic" "Jalankan Windows MSDT untuk cek masalah perangkat keras." 0xE9D9 "MediumSeaGreen" { Action-ToolDiagnostic } 

    # --- MENAMBAHKAN KARTU HYPER-V & RESTORE POINT BARU ---
    Add-ToolCard "Disable Hyper-V (Off)" "Matikan Hypervisor via bcdedit agar Game & Emulator berjalan lancar." 0xEE3F "OrangeRed" { Action-HyperVDisable }
    Add-ToolCard "Enable Hyper-V (Auto)" "Aktifkan kembali mesin virtualisasi bcdedit untuk WSL, Docker, / VM." 0xEE3F "LimeGreen" { Action-HyperVEnable }
    Add-ToolCard "Create Restore Point" "Buat titik keamanan sistem (Safety Guard) saat ini sebelum tweaks ekstrem." 0xE73E "DodgerBlue" { Action-CreateRestorePoint }

    # SINKRONISASI RENDER LAYOUT
    $flowGrid.ResumeLayout()
    $pnlMain.ResumeLayout()

    $contentPanel.Controls.Add($pnlMain)
}

# ========================================================
# SELESAI RENDER OTHER TOOLS
# ========================================================

function Navigate-To ($MenuName) {
    # 1. Bersihkan Halaman Lama
    $contentPanel.Controls.Clear()
    
    # Update Judul Halaman (Opsional, agar user tahu ada di menu apa)
    if ($lblPageTitle) { $lblPageTitle.Text = $MenuName }

    # 2. Cek Menu Apa yang Dipilih
    switch ($MenuName) {
        "Dashboard" { 
            Render-Dashboard 
        }
	    "Software Center" {
            Render-SoftwareCenter
        }
        "Windows Defender" { 
            Render-WindowsDefender
        }
        "Windows Updates" { 
            Render-WindowsUpdates 
        }
        "Upgrade License" {
            Render-UpgradeLicense
        }
        "Windows Tweaks" {
            Render-WindowsTweaks
        }
        "System Repair" {
            Render-SystemRepair
        }
        "System Report" {
            Render-SystemReport
        }
        "Backup / Restore" {
            Render-BackupRestore
        }
        "Download ISO" {
            Render-DownloadOS
        }
        "Technical Guides" {
            Render-AddSettings
        }
        "Other Tools" {
            Render-OtherTools
        }

        # Jika menu tidak dikenali
        default { 
            $msg = New-Object System.Windows.Forms.Label
            $msg.Text = "Halaman '$MenuName' sedang dalam pengembangan."
            $msg.AutoSize = $true
            $msg.Font = New-Object System.Drawing.Font("Segoe UI", 12)
            $msg.ForeColor = [System.Drawing.Color]::Gray
            $msg.Location = New-Object System.Drawing.Point(50, 100)
            $contentPanel.Controls.Add($msg)
        }
    }
}

# --- SIDEBAR MENU ---
$menuList = @(
    @{Title="Dashboard";        Icon=0xE80F},
    @{Title="Software Center";  Icon=0xE718},
    @{Title="Windows Defender"; Icon=0xE83D},
    @{Title="Windows Updates";  Icon=0xE895},
    @{Title="Upgrade License";  Icon=0xE8D1},
    @{Title="Download ISO";     Icon=0xE896},
    @{Title="Windows Tweaks";   Icon=0xE82D},
    @{Title="System Repair";    Icon=0xE90F},
    @{Title="System Report";    Icon=0xF167},
    @{Title="Backup / Restore"; Icon=0xE753},
    @{Title="Technical Guides"; Icon=0xE713},
    @{Title="Other Tools";      Icon=0xE712},
    @{Title="Exit Application"; Icon=0xE7E8}
)

$currentY = 130 

foreach ($m in $menuList) {
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = "      $($m.Title)"
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $btn.Width = 270
    $btn.Height = 45
    
    # --- LOGIC POSISI BARU ---
    # Jika tombol adalah "Exit Application", tempel ke BAWAH (Dock Bottom)
    if ($m.Title -eq "Exit Application") {
        $btn.Dock = "Bottom"
        # Tambahkan sedikit border atas supaya tidak terlalu mepet konten
        $btn.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(40,40,40)
        $btn.FlatAppearance.BorderSize = 0
    } 
    # Jika bukan Exit, susun dari ATAS seperti biasa
    else {
        $btn.Location = New-Object System.Drawing.Point(0, $currentY)
        $currentY += 45
    }
    # -------------------------

    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.TextAlign = "MiddleLeft"
    $btn.Padding = New-Object System.Windows.Forms.Padding(35,0,0,0)
    $btn.Cursor = "Hand"
    $btn.BackColor = $ThemePalettes.Dark.Side
    $btn.ForeColor = [System.Drawing.Color]::LightGray
    
    # Icon
    $ico = New-Object System.Windows.Forms.Label
    $ico.Text = [char]$m.Icon
    $ico.Font = New-Object System.Drawing.Font("Segoe MDL2 Assets", 12)
    $ico.ForeColor = [System.Drawing.Color]::White
    $ico.AutoSize = $true
    $ico.Location = New-Object System.Drawing.Point(25, 14)
    $ico.BackColor = "Transparent"
    
    # Marker (Garis Indikator Aktif)
    $marker = New-Object System.Windows.Forms.Panel
    $marker.Width = 4
    $marker.Height = 45
    $marker.Dock = "Left"
    $marker.BackColor = $ThemePalettes.Dark.Header
    $marker.Visible = $false
    
    $btn.Controls.Add($ico)
    $btn.Controls.Add($marker)

    # Hover Effects
    $btn.Add_MouseEnter({ 
        if ($this.Tag -ne "Active") { 
            $this.BackColor = [System.Drawing.Color]::FromArgb(40,44,52)
            $this.ForeColor = [System.Drawing.Color]::White 
        } 
    })
    $btn.Add_MouseLeave({ 
        if ($this.Tag -ne "Active") { 
            $this.BackColor = $ThemePalettes.Dark.Side
            $this.ForeColor = [System.Drawing.Color]::LightGray 
        } 
    })

    # Click Logic
    $btn.Add_Click({ 
        # Reset warna tombol lain
        foreach ($c in $sidebar.Controls) { 
            if ($c -is [System.Windows.Forms.Button]) { 
                $c.BackColor = $ThemePalettes.Dark.Side
                $c.ForeColor = [System.Drawing.Color]::LightGray
                $c.Tag = $null
                $c.Controls[1].Visible = $false 
            } 
        }
        
        # Set tombol aktif
        $this.BackColor = [System.Drawing.Color]::FromArgb(20,20,20)
        $this.ForeColor = $ThemePalettes.Dark.Header
        $this.Tag = "Active"
        $marker.Visible = $true
        
        if ($this.Text.Contains("Exit")) { 
            $form.Close() 
        } else { 
            Navigate-To $this.Text.Trim()
            Write-Log "Navigated to: $($this.Text.Trim())" 
        }
    })
    
    $ico.Add_Click({ $btn.PerformClick() })
    $sidebar.Controls.Add($btn)
}

# --- START ---
Navigate-To "Dashboard"
$sidebar.Controls | Where-Object {$_.Text -match "Dashboard"} | ForEach-Object { $_.PerformClick() }
$form.TopMost = $true; $form.Add_Shown({ $form.Activate(); $form.TopMost = $false }); [void]$form.ShowDialog()
