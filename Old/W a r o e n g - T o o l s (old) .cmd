@echo off
:: ==========================================
:: Waroeng Tools - Windows Utility Suite
:: By: Linaris | Version: 4.1.5
:: ==========================================

:: Check for Administrator privileges
NET SESSION >NUL 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:main_menu
title W a r o e n g   T o o l s
@echo off
chcp 65001 >nul
color 0B

:: Ganti ukuran CMD: 80 kolom x 30 baris
mode con: cols=118 lines=55

:: Variables
set "repo_version=4.0.0"
set "repo_author=Linaris"
set "repo_url=https://github.com/loqdev/waroeng-tools"

:: Get OS info
set "computername=%COMPUTERNAME%"
for /f "tokens=2 delims==" %%i in ('"wmic os get Caption /value"') do set "osname=%%i"
for /f "tokens=2 delims==" %%i in ('"wmic os get OSArchitecture /value"') do set "osarch=%%i"
for /f "tokens=2 delims==" %%i in ('"wmic os get Version /value"') do set "osversion=%%i"

:: Ambil DisplayVersion (misal 23H2, 22H2)
for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v DisplayVersion 2^>nul') do set "DisplayVersion=%%a %%b"

:: Fallback: Jika DisplayVersion kosong, coba ambil ReleaseId
if not defined DisplayVersion (
    for /f "tokens=3*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ReleaseId 2^>nul') do set "DisplayVersion=%%a %%b"
)

::System Manufacturer & Model
for /f "tokens=2 delims==" %%i in ('"wmic computersystem get manufacturer /value"') do set "sysmaker=%%i"
for /f "tokens=2 delims==" %%i in ('"wmic computersystem get model /value"') do set "sysmodel=%%i"

::Processor Name
for /f "tokens=2 delims==" %%i in ('"wmic cpu get name /value"') do set "cpu=%%i"

::GPU Name
for /f "tokens=2 delims==" %%i in ('"wmic path win32_VideoController get Name /value"') do set "gpu=%%i"

:: Ambil total kapasitas RAM (GB)
for /f "delims=" %%A in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB"') do (
    set "ram=%%A"
)

:: Ambil Total RAM Slots
for /f %%a in ('powershell -command "(Get-CimInstance Win32_PhysicalMemoryArray).MemoryDevices"') do (
    set "ram_total=%%a"
)

:: Ambil RAM yang Terpakai
for /f %%a in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory | Measure-Object).Count"') do (
    set "ram_used=%%a"
)

:: Ambil kapasitas dan speed slot 0 (slot pertama)
for /f "delims=" %%C in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory)[0].Capacity / 1GB"') do set "slot0_cap=%%C"
for /f "delims=" %%D in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory)[0].Speed"') do set "slot0_speed=%%D"

:: Ambil kapasitas dan speed slot 1 (slot kedua)
if %ram_total% LSS 2 (
    set "slot1_cap=Not Available"
    set "slot1_speed=Not Available"
) else (
    if %ram_used% LSS 2 (
        set "slot1_cap=Not Installed"
        set "slot1_speed=Not Installed"
    ) else (
        for /f "delims=" %%E in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory)[1].Capacity / 1GB"') do set "slot1_cap=%%E"
        for /f "delims=" %%F in ('powershell -command "(Get-CimInstance Win32_PhysicalMemory)[1].Speed"') do set "slot1_speed=%%F"
    )
)

:: Hitung jumlah disk yang terdeteksi
for /f %%i in ('powershell -Command "(Get-PhysicalDisk).Count"') do set DiskCount=%%i

:: Estimasi slot maksimum (tidak selalu tersedia di semua sistem)
for /f %%i in ('powershell -Command "(Get-PhysicalDisk | Measure-Object SlotNumber -Maximum).Maximum + 1"') do set MaxSlot=%%i

:: Cek apakah antivirus aktif dan nama antivirus
setlocal

:: Dapatkan status Real-Time Protection
for /f "delims=" %%a in ('powershell -Command "(Get-MpPreference).DisableRealtimeMonitoring"') do (
    set "rtp=%%a"
)

:: Interpretasi hasil
if "%rtp%"=="True" (
    set "av_status=Disabled"
) else (
    set "av_status=Enabled"
)

:: Nama default (bisa kamu sesuaikan jika ada antivirus lain)
set "av_name=Windows Defender"


:: Welcome Banner
cls
echo.
echo.
echo     Waroeng Tools v%repo_version%                         Windows Utility Suite                           Author : %repo_author%
echo.
echo     ██╗    ██╗ █████╗ ██████╗  ██████╗ ███████╗███╗   ██╗ ██████╗      ████████╗ ██████╗  ██████╗ ██╗     ███████╗
echo     ██║    ██║██╔══██╗██╔══██╗██╔═══██╗██╔════╝████╗  ██║██╔════╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
echo     ██║ █╗ ██║███████║██████╔╝██║   ██║█████╗  ██╔██╗ ██║██║  ███╗        ██║   ██║   ██║██║   ██║██║     ███████╗
echo     ██║███╗██║██╔══██║██╔══██╗██║   ██║██╔══╝  ██║╚██╗██║██║   ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
echo     ╚███╔███╔╝██║  ██║██║  ██║╚██████╔╝███████╗██║ ╚████║╚██████╔╝        ██║   ╚██████╔╝╚██████╔╝███████╗███████║
echo      ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
echo.
echo    ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
echo.
echo     OS VERSION          : %osname% (%DisplayVersion%/ %osversion% / %osarch%)
echo.
echo     MODEL / USER        : %sysmaker% %sysmodel% (%username% / %computername%)
echo.
echo     CPU                 : %cpu%
echo.
echo     GPU                 : %gpu%
echo.
echo     RAM / SLOT / USED / : %ram% GB (%ram_total% / %ram_used%)
echo     RAM SPEED           : (SLOT 1: %slot0_cap% GB %slot0_speed% MHz / SLOT 2: %slot1_cap% GB %slot1_speed% MHz)
echo.
powershell -NoProfile -Command "Get-PhysicalDisk | ForEach-Object { $sizeGB = [math]::Round($_.Size / 1GB, 2); Write-Host ('    STORAGE             : ' + $_.FriendlyName + ' / ' + $sizeGB + ' GB / ' + $_.MediaType) }"
echo.
echo     ANTIVIRUS / STATUS  : %av_name% (%av_status%)
echo.
echo.   ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
echo:
echo:			    
echo:      [1] WINDOWS DEFENDER                    [6] SYSTEM INFO REPORT
echo.
echo.
echo:      [2] WINDOWS UPDATES                     [7] ADDITIONAL SETTINGS MANUALLY
echo.
echo.
echo:      [3] UPGRADE WINDOWS LECENSE             [8] Other
echo.
echo.
echo:      [4] WINDOWS UTILITY
echo.
echo.
echo:      [5] WINDOWS SYSTEM REPAIR
echo.
echo.
echo.
echo:      [0] Exit
echo.
echo.
set /p choice=Enter your choice: 

if "%choice%"=="0" exit
if "%choice%" geq "1" if "%choice%" leq "8" goto confirm_action

echo Invalid choice! Try again.
pause
goto main_menu

:confirm_action
cls
echo.
echo.
echo     Waroeng Tools v%repo_version%                         Windows Utility Suite                           Author  : %repo_author%
echo.
echo     ██╗    ██╗ █████╗ ██████╗  ██████╗ ███████╗███╗   ██╗ ██████╗      ████████╗ ██████╗  ██████╗ ██╗     ███████╗
echo     ██║    ██║██╔══██╗██╔══██╗██╔═══██╗██╔════╝████╗  ██║██╔════╝      ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██╔════╝
echo     ██║ █╗ ██║███████║██████╔╝██║   ██║█████╗  ██╔██╗ ██║██║  ███╗        ██║   ██║   ██║██║   ██║██║     ███████╗
echo     ██║███╗██║██╔══██║██╔══██╗██║   ██║██╔══╝  ██║╚██╗██║██║   ██║        ██║   ██║   ██║██║   ██║██║     ╚════██║
echo     ╚███╔███╔╝██║  ██║██║  ██║╚██████╔╝███████╗██║ ╚████║╚██████╔╝        ██║   ╚██████╔╝╚██████╔╝███████╗███████║
echo      ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝         ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚══════╝
echo.
echo    ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
echo.
echo    ────────────────────────────────────────────────────────────────────────────────────────────────────────────────
echo.
echo.			      
if "%choice%"=="1" echo:     [1] ENABLE WINDOWS DEFENDER
if "%choice%"=="1" echo.
if "%choice%"=="1" echo.
if "%choice%"=="1" echo:     [2] DISABLE WINDOWS DEFENDER
if "%choice%"=="1" echo.
if "%choice%"=="1" echo.
if "%choice%"=="1" echo:     [3] ENABLE WINDOWS DEFENDER
if "%choice%"=="1" echo:         [For IT Limit Only]
if "%choice%"=="2" echo:     [1] ENABLE WINDOWS UPDATE              [6] EX-PAUSE WINDOWS UPDATE
if "%choice%"=="2" echo.
if "%choice%"=="2" echo.
if "%choice%"=="2" echo:     [2] DISABLE WINDOWS UPDATE
if "%choice%"=="2" echo.
if "%choice%"=="2" echo.
if "%choice%"=="2" echo:     [3] HIDE/SHOW WINDOWS UPDATE
if "%choice%"=="2" echo.
if "%choice%"=="2" echo.
if "%choice%"=="2" echo:     [4] LOCK WINDOWS UPDATE
if "%choice%"=="2" echo.
if "%choice%"=="2" echo.
if "%choice%"=="2" echo:     [5] RESET WINDOWS UPDATE
if "%choice%"=="3" echo:     [1] WINDOWS HOME
if "%choice%"=="3" echo.
if "%choice%"=="3" echo.
if "%choice%"=="3" echo:     [2] WINDOWS PRO
if "%choice%"=="3" echo.
if "%choice%"=="3" echo.
if "%choice%"=="3" echo:     [3] WINDOWS ENTERPRISE
if "%choice%"=="3" echo.
if "%choice%"=="3" echo.
if "%choice%"=="3" echo:     [4] REMOVE LICENSE
if "%choice%"=="4" echo:     [1] ACTIVATE WINDOWS / OFFICE (Internet Require)
if "%choice%"=="4" echo.
if "%choice%"=="4" echo.
if "%choice%"=="4" echo:     [2] WINDOWS UTILITY (Internet Require)
if "%choice%"=="4" echo.
if "%choice%"=="4" echo.
if "%choice%"=="4" echo:     [3] WINDOWS TWEAKER
if "%choice%"=="5" goto system_repair
if "%choice%"=="6" goto view_sysinfo
if "%choice%"=="7" echo:     [1] ADDITIONAL PRINTER SETTINGS (Error 0x00000709)
if "%choice%"=="7" echo.
if "%choice%"=="7" echo.
if "%choice%"=="7" echo:     [2] ADDITIONAL PRINTER SETTINGS (Error 0x000003e3)
if "%choice%"=="7" echo.
if "%choice%"=="7" echo.
if "%choice%"=="7" echo:     [3] SSD TIDAK MUNCUL SAAT INSTAL WINDOWS
if "%choice%"=="7" echo.
if "%choice%"=="7" echo.
if "%choice%"=="7" echo:     [4] SETTING SETUP UNDERVOLT LENOVO LOQ
if "%choice%"=="8" echo:     [1] CLEAR TEMP FILES                   [6] FIX EXTENSION CHROME TURN OFF
if "%choice%"=="8" echo.
if "%choice%"=="8" echo.
if "%choice%"=="8" echo:     [2] RESET NETWORK SETTINGS             [7] BYPASS WINDOWS 11 INSTALLATION
if "%choice%"=="8" echo.
if "%choice%"=="8" echo.
if "%choice%"=="8" echo:     [3] ENABLE GPEDIT                      [8] FORM PERMINTAAN BANTUAN IT   
if "%choice%"=="8" echo.
if "%choice%"=="8" echo.
if "%choice%"=="8" echo:     [4] DEVICE DIAGNOSTIC
if "%choice%"=="8" echo.
if "%choice%"=="8" echo.
if "%choice%"=="8" echo:     [5] TROUBLESHOOT PRINTERS
echo:
echo:  
echo:
echo:     [0] Go Back
echo:
echo:
set /p confirm=Enter your choice: 

if "%confirm%"=="0" goto main_menu
if "%choice%"=="1" if "%confirm%"=="1" goto win_def_enable
if "%choice%"=="1" if "%confirm%"=="2" goto win_def_disable
if "%choice%"=="1" if "%confirm%"=="3" goto it_win_def_enable
if "%choice%"=="2" if "%confirm%"=="1" goto enable_update
if "%choice%"=="2" if "%confirm%"=="2" goto disable_update
if "%choice%"=="2" if "%confirm%"=="3" goto hideshow
if "%choice%"=="2" if "%confirm%"=="4" goto lock_update
if "%choice%"=="2" if "%confirm%"=="5" goto reset_update
if "%choice%"=="2" if "%confirm%"=="6" goto pause_update
if "%choice%"=="3" if "%confirm%"=="1" goto win_home
if "%choice%"=="3" if "%confirm%"=="2" goto win_pro
if "%choice%"=="3" if "%confirm%"=="3" goto win_enterprise
if "%choice%"=="3" if "%confirm%"=="4" goto win_remover
if "%choice%"=="4" if "%confirm%"=="1" goto activation
if "%choice%"=="4" if "%confirm%"=="2" goto tweaks
if "%choice%"=="4" if "%confirm%"=="3" goto optimize_win
if "%choice%"=="7" if "%confirm%"=="1" goto error709
if "%choice%"=="7" if "%confirm%"=="2" goto error3e3
if "%choice%"=="7" if "%confirm%"=="3" goto rstintel
if "%choice%"=="7" if "%confirm%"=="4" goto undervoltloq
if "%choice%"=="8" if "%confirm%"=="1" goto del_temp
if "%choice%"=="8" if "%confirm%"=="2" goto reset_net
if "%choice%"=="8" if "%confirm%"=="3" goto enable_gpedit
if "%choice%"=="8" if "%confirm%"=="4" goto diagnostic 
if "%choice%"=="8" if "%confirm%"=="5" goto service_printer
if "%choice%"=="8" if "%confirm%"=="6" goto extension_off
if "%choice%"=="8" if "%confirm%"=="7" goto bypasswin11
if "%choice%"=="8" if "%confirm%"=="8" goto form_it
echo Invalid choice! Try again.
pause
goto confirm_action

:it_win_def_enable
cls
    @echo off
    echo:
    echo: ======================================
    echo:   Enabling Windows Defender. . .(IT)
    echo: ======================================
    echo:

    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies" /f
    reg delete "HKCU\Software\Microsoft\WindowsSelfHost" /f
    reg delete "HKCU\Software\Policies" /f
    reg delete "HKLM\Software\Microsoft\Policies" /f
    reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies" /f
    reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /f
    reg delete "HKLM\Software\Microsoft\WindowsSelfHost" /f
    reg delete "HKLM\Software\Policies" /f
    reg delete "HKLM\Software\WOW6432Node\Microsoft\Policies" /f
    reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Policies" /f
    reg delete "HKLM\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\WindowsStore\WindowsUpdate" /f
    echo:
    echo: ======================================
    echo:  Enabling Windows Defender Completed!
    echo: ======================================
    echo:
pause
goto main_menu

:win_def_disable
cls
    @echo off
    echo:
    echo: ======================================
    echo:     Disabling Windows Defender...
    echo: ======================================
    echo:

    echo Disabling Windows Defender entirely
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 0 /f

    echo Disable Windows Defender real-time protection
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 1 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f

    echo Disable automatic signature updates
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 0 /f

    echo Disable the block feature based on Spynet reputation
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f

:: Registry policy disables
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v "MpEnablePus" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v "MpEngineRunTime" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /v "DisableEnhancedNotifications" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "SubmitSamplesConsent" /t REG_DWORD /d 2 /f >nul

:: Stop and disable services
sc stop WinDefend >nul 2>&1
sc stop Sense >nul 2>&1
sc config WinDefend start= disabled >nul
sc config Sense start= disabled >nul

    echo:
    echo: ======================================
    echo:   Windows Defender has been disabled
    echo: ======================================
    echo: 
pause
goto main_menu

:win_def_enable
cls
    @echo off
    echo:
    echo: ======================================
    echo:      Enable Windows Defender...
    echo: ======================================
    echo:

    rem Reactivate Windows Defender in its entirety
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableSpecialRunningModes" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "ServiceKeepAlive" /t REG_DWORD /d 1 /f

    rem Reactivate Windows Defender real-time protection
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScanOnRealtimeEnable" /t REG_DWORD /d 0 /f
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 0 /f

    rem Reactivate automatic signature updates
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /v "ForceUpdateFromMU" /t REG_DWORD /d 1 /f

    rem Reactivate Re-enable the block feature based on Spynet reputation
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 0 /f

:: Remove Defender registry policies
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting" /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /f >nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Signature Updates" /f >nul

:: Enable and start services
sc config WinDefend start= auto >nul
sc config Sense start= auto >nul
sc start WinDefend >nul 2>&1
sc start Sense >nul 2>&1


    echo:
    echo: ======================================
    echo: Windows Defender has been reactivated
    echo: ======================================
    echo:
pause
goto main_menu

:enable_gpedit
cls
    @echo off
    echo:
    echo: ======================================
    echo:          Enabling GPEdit...
    echo: ======================================
    echo:
 
    pushd "%~dp0" 
 
    dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientExtensions-Package~3*.mum >List.txt 
    dir /b %SystemRoot%\servicing\Packages\Microsoft-Windows-GroupPolicy-ClientTools-Package~3*.mum >>List.txt 
 
    for /f %%i in ('findstr /i . List.txt 2^>nul') do dism /online /norestart /add-package:"%SystemRoot%\servicing\Packages\%%i" 
pause
goto main_menu

:diagnostic
cls
    @echo off
    echo:
    echo: ======================================
    echo:      Running Device Diagnostic...
    echo: ======================================
    echo:
    msdt.exe /id DeviceDiagnostic
pause
goto main_menu

:enable_update
cls
@echo off
setlocal EnableDelayedExpansion

echo:
echo: =====================================
echo:     Enabling Windows Update...
echo: =====================================
echo:

:: Mengubah layanan menjadi otomatis
sc config wuauserv start= auto
sc config bits start= auto
sc config dosvc start= auto
sc config UsoSvc start= auto

:: Memulai ulang layanan
net start wuauserv
net start bits
net start dosvc
net start UsoSvc

sc config WaaSMedicSvc start= demand > nul 2>&1
net start WaaSMedicSvc > nul 2>&1

:: Bersihkan registry pause/tweak block
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /f > nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /f > nul 2>&1

echo:
echo: =====================================
echo:  Windows Update Successfully Enabled
echo: =====================================
echo:
pause
goto main_menu


:disable_update
cls
@echo off
setlocal EnableDelayedExpansion

echo:
echo: =====================================
echo:     Disabling Windows Update...
echo: =====================================
echo:

echo Menghentikan layanan Windows Update
net stop wuauserv
net stop bits
net stop dosvc
net stop UsoSvc

echo Menonaktifkan layanan agar tidak berjalan otomatis
sc config wuauserv start= disabled
sc config bits start= disabled
sc config dosvc start= disabled
sc config UsoSvc start= disabled

:: WaaSMedicSvc
sc stop WaaSMedicSvc > nul 2>&1
sc config WaaSMedicSvc start= disabled > nul 2>&1

echo Pausing Windows Updates until the year 2075...

set "StartDate=2025-01-01T00:00:00Z"
set "EndDate=2075-01-01T00:00:00Z"

:: UX\Settings keys
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "%EndDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "%EndDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "%EndDate%" /f >nul

:: Optional additional registry flags
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "%StartDate%" /f >nul

echo Windows Update paused until: %EndDate%

echo:
echo: ======================================
echo:        Windows Update Disabled
echo: ======================================
echo:
pause
goto main_menu

:hideshow
@echo off
cls
title Windows Update Show/Hide Tool

:: Cek apakah file sudah ada
if exist "%~dp0wushowhide.diagcab" (
    echo Menjalankan wushowhide...
    start "" "%~dp0wushowhide.diagcab"
    exit /b
)

:: Jika belum ada, download dari Microsoft
echo File wushowhide.diagcab tidak ditemukan.
echo Mendownload dari Microsoft...

powershell -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/f/2/2/f22d5fdb-59cd-4275-8c95-1be17bf70b21/wushowhide.diagcab' -OutFile 'wushowhide.diagcab'"

if exist "wushowhide.diagcab" (
    echo Download selesai. Menjalankan wushowhide...
    start "" "wushowhide.diagcab"
) else (
    echo Gagal mendownload wushowhide.diagcab. Silakan cek koneksi internet Anda.
)

pause
goto main_menu

:lock_update
title Lock Windows Update
cls
echo.
echo ============================================================
echo.
echo   - Fungsi Script:
echo   Script ini digunakan untuk menetapkan versi Windows
echo   tertentu sebagai "target", agar sistem tidak otomatis
echo   upgrade ke versi di atasnya.
echo.
echo   - Contoh:
echo   Jika kamu di Windows 11 23H2 dan ingin tetap di versi itu
echo   tanpa upgrade ke 24H2 atau lebih, gunakan script ini.
echo.
echo ============================================================
echo.
echo   [1] Atur Versi Target Windows (Kunci Versi)
echo.
echo   [2] Hapus Pengaturan Target (Kembali Default)
echo.
echo.
echo   [0] Keluar
echo.
set /p menu=Pilihan Anda: 

if "%menu%"=="1" goto set_target
if "%menu%"=="2" goto reset_target
if "%menu%"=="0" goto main_menu

:set_target
echo.
echo ============================================================
echo.
echo   Pilih Windows yang digunakan:
echo.
echo   [1] Windows 11
echo.
echo   [2] Windows 10
echo.
echo.
echo   [0] Batal
echo.
set /p osver=Pilihan OS: 

if "%osver%"=="0" goto lock_update
if "%osver%"=="1" set "product=Windows11"
if "%osver%"=="2" set "product=Windows10"
if not defined product (
    echo   Pilihan tidak valid.
    pause
    goto set_target
)

echo.
echo ============================================================
echo   Masukkan Target Release Version (cth: 22H2, 23H2, 24H2)
echo ============================================================
echo.
set /p targetver=Versi Target: 

if "%targetver%"=="" (
    echo   Versi tidak boleh kosong.
    pause
    goto set_target
)

echo.
echo   Mengatur versi %product% ke %targetver% ...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ProductVersion" /t REG_SZ /d "%product%" /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /t REG_SZ /d "%targetver%" /f >nul

echo.
echo ============================================================
echo   Berhasil dikunci ke: %product% %targetver%
echo   Restart PC untuk menerapkan sepenuhnya.
echo ============================================================
echo.
pause
goto main_menu

:reset_target
echo.
echo   Menghapus semua pengaturan target versi...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ProductVersion" /f >nul 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersion" /f >nul 2>nul
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "TargetReleaseVersionInfo" /f >nul 2>nul

echo.
echo ============================================================
echo   Pengaturan target berhasil dihapus.
echo   Sistem akan kembali mengikuti update default.
echo ============================================================
echo.
pause
goto main_menu

:reset_update
title Reset Windows Update Components
cls
echo.
echo ============================================
echo      RESETTING WINDOWS UPDATE COMPONENTS
echo ============================================
echo.

echo Stopping Windows Update Services...
net stop wuauserv >nul
net stop cryptSvc >nul
net stop bits >nul
net stop msiserver >nul

echo Renaming SoftwareDistribution and Catroot2 folders...
ren %systemroot%\SoftwareDistribution SoftwareDistribution.old >nul 2>&1
ren %systemroot%\System32\catroot2 catroot2.old >nul 2>&1

echo Deleting qmgr*.dat files...
del /s /q /f "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat" >nul 2>&1

echo Resetting BITS and Windows Update services...
sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)

echo Re-registering Windows Update DLLs...
cd /d %windir%\system32
for %%i in (
    atl.dll
    urlmon.dll
    mshtml.dll
    shdocvw.dll
    browseui.dll
    jscript.dll
    vbscript.dll
    scrrun.dll
    msxml.dll
    msxml3.dll
    msxml6.dll
    actxprxy.dll
    softpub.dll
    wintrust.dll
    dssenh.dll
    rsaenh.dll
    gpkcsp.dll
    sccbase.dll
    slbcsp.dll
    cryptdlg.dll
    oleaut32.dll
    ole32.dll
    shell32.dll
    initpki.dll
    wuapi.dll
    wuaueng.dll
    wuaueng1.dll
    wucltui.dll
    wups.dll
    wups2.dll
    wuweb.dll
    qmgr.dll
    qmgrprxy.dll
    wucltux.dll
    muweb.dll
    wuwebv.dll
) do regsvr32 /s %%i

echo Resetting Winsock...
netsh winsock reset >nul

echo Resetting proxy settings...
netsh winhttp reset proxy >nul

echo Starting Windows Update Services...
net start wuauserv >nul
net start cryptSvc >nul
net start bits >nul
net start msiserver >nul

echo.
echo ============================================
echo       RESET COMPLETED SUCCESSFULLY!
echo ============================================
echo.
pause
goto main_menu

:pause_update
cls
title Pause Windows Update
:menu_pause
echo.
echo ============================================
echo          Windows Update Pause Tool
echo ============================================
echo.
echo   [1] Pause until 2075 (preset)
echo.
echo   [2] Pause with custom dates
echo.
echo   [0] Exit
echo.
set /p opt=Select an option: 
echo.

if "%opt%"=="1" goto preset
if "%opt%"=="2" goto custom
if "%opt%"=="0" goto main_menu

echo Invalid option.
pause
goto menu_pause

:preset
set "StartDate=2025-01-01T00:00:00Z"
set "EndDate=2075-01-01T00:00:00Z"
goto apply

:custom
echo.
echo ============================================
set /p StartDate=Enter pause start date (e.g. 2025-01-01T00:00:00Z): 
set /p EndDate=Enter pause end date   (e.g. 2075-01-01T00:00:00Z): 
echo ============================================
goto apply

:apply
echo.
echo Pausing Windows Updates from:
echo.
echo   Start : %StartDate%
echo   End   : %EndDate%
echo.

set /p confirm=Apply these changes? (y/n): 
if /i "%confirm%" NEQ "y" goto menu_pause

:: Apply registry changes
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseFeatureUpdatesEndTime" /t REG_SZ /d "%EndDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseQualityUpdatesEndTime" /t REG_SZ /d "%EndDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesStartTime" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" /v "PauseUpdatesExpiryTime" /t REG_SZ /d "%EndDate%" /f >nul

reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureStatus" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityStatus" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedFeatureDate" /t REG_SZ /d "%StartDate%" /f >nul
reg add "HKLM\SOFTWARE\Microsoft\WindowsUpdate\UpdatePolicy\Settings" /v "PausedQualityDate" /t REG_SZ /d "%StartDate%" /f >nul

echo.
echo  Windows Updates paused successfully!
echo  Until: %EndDate%
echo.
pause
goto main_menu

:win_home
cls
    @echo off
    echo:
    echo: =====================================
    echo:     Switching to Windows Home...
    echo: =====================================
    echo:
    changepk.exe /productkey YTMG3-N6DKC-DKB77-7M9GH-8HVX7
pause
goto main_menu

:win_pro
cls
    @echo off
    echo:
    echo: =====================================
    echo:     Switching to Windows Pro...
    echo: =====================================
    echo:
    changepk.exe /productkey VK7JG-NPHTM-C97JM-9MPGT-3V66T
pause
goto main_menu

:win_enterprise
cls
    @echo off
    echo:
    echo: =====================================
    echo:  Switching to Windows Enterprise...
    echo: =====================================
    echo:
    changepk.exe /productkey NPPR9-FWDCX-D2C8J-H872K-2YT43
pause
goto main_menu

:win_remover
cls
    @echo off
    echo:
    echo: =====================================
    echo:     Removing Windows License...
    echo: =====================================
    echo:
    SLMGR.VBS /UPK
    SLMGR.VBS /CPKY
    SLMGR.VBS /CKMS

    DISM /ONLINE /GET-TARGETEDITIONS

    SC CONFIG LICENSEMANAGER START= AUTO & NET START LICENSEMANAGER
    SC CONFIG WUAUSERV START= AUTO & NET START WUAUSERV
pause
goto main_menu

:activation
cls
    @echo 0ff
    echo Opening PowerShell with administrator privileges...
    powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command irm https://get.activated.win | iex | iex' -Verb RunAs"
pause
goto main_menu

:tweaks
cls
    @echo 0ff
    echo Opening PowerShell with administrator privileges...
    powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command iwr -useb https://christitus.com/win | iex' -Verb RunAs"
pause
goto main_menu

:optimize_win
cls
    @echo off
    echo:
    echo: =====================================
    echo:          Optimize Windows...
    echo: =====================================
    echo:
:: Initialize environment
setlocal EnableExtensions DisableDelayedExpansion


:: ----------------------------------------------------------
:: -------------Clear Quick Access recent files--------------
:: ----------------------------------------------------------
echo --- Clear Quick Access recent files
:: Clear directory contents  : "%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Quick Access pinned items--------------
:: ----------------------------------------------------------
echo --- Clear Quick Access pinned items
:: Clear directory contents  : "%APPDATA%\Microsoft\Windows\Recent\CustomDestinations"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Microsoft\Windows\Recent\CustomDestinations'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Clear Windows Registry last-accessed key---------
:: ----------------------------------------------------------
echo --- Clear Windows Registry last-accessed key
:: Delete the registry value "LastKey" from the key "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit'; $valueName = 'LastKey'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Clear Windows Registry favorite locations---------
:: ----------------------------------------------------------
echo --- Clear Windows Registry favorite locations
:: Clear register values from "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Regedit\Favorites'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear recent application history-------------
:: ----------------------------------------------------------
echo --- Clear recent application history
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedMRU" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedMRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\LastVisitedPidlMRULegacy'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Adobe recent file history--------------
:: ----------------------------------------------------------
echo --- Clear Adobe recent file history
:: Remove the registry key "HKCU\Software\Adobe\MediaBrowser\MRU" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKCU\Software\Adobe\MediaBrowser\MRU'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Clear Microsoft Paint recent files history--------
:: ----------------------------------------------------------
echo --- Clear Microsoft Paint recent files history
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Applets\Paint\Recent File List'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Clear WordPad recent file history-------------
:: ----------------------------------------------------------
echo --- Clear WordPad recent file history
:: Clear register values from "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Applets\Wordpad\Recent File List'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Clear network drive mapping history------------
:: ----------------------------------------------------------
echo --- Clear network drive mapping history
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Map Network Drive MRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Clear Windows Search history---------------
:: ----------------------------------------------------------
echo --- Clear Windows Search history
:: Clear register values from "HKCU\Software\Microsoft\Search Assistant\ACMru" (recursively)
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Search Assistant\ACMru'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Iterating subkeys recursively: `"^""$formattedRegistryKeyPath`"^""."^""; $subKeys = Get-ChildItem -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop; if (!$subKeys) { Write-Output 'Skipping: no subkeys available.'; return; }; foreach ($subKey in $subKeys) { $subkeyName = $($subKey.PSChildName); Write-Output "^""Processing subkey: `"^""$subkeyName`"^"""^""; $subkeyPath = Join-Path -Path $currentRegistryKeyPath -ChildPath $subkeyName; Clear-RegistryKeyValues $subkeyPath; }; Write-Output "^""Successfully cleared all subkeys in `"^""$formattedRegistryKeyPath`"^""."^""; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\SearchHistory" (recursively)
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\SearchHistory'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Iterating subkeys recursively: `"^""$formattedRegistryKeyPath`"^""."^""; $subKeys = Get-ChildItem -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop; if (!$subKeys) { Write-Output 'Skipping: no subkeys available.'; return; }; foreach ($subKey in $subKeys) { $subkeyName = $($subKey.PSChildName); Write-Output "^""Processing subkey: `"^""$subkeyName`"^"""^""; $subkeyPath = Join-Path -Path $currentRegistryKeyPath -ChildPath $subkeyName; Clear-RegistryKeyValues $subkeyPath; }; Write-Output "^""Successfully cleared all subkeys in `"^""$formattedRegistryKeyPath`"^""."^""; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\Windows\ConnectedSearch\History"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\Windows\ConnectedSearch\History'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Clear recent files and folders history----------
:: ----------------------------------------------------------
echo --- Clear recent files and folders history
:: Clear register values from "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs" (recursively)
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Iterating subkeys recursively: `"^""$formattedRegistryKeyPath`"^""."^""; $subKeys = Get-ChildItem -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop; if (!$subKeys) { Write-Output 'Skipping: no subkeys available.'; return; }; foreach ($subKey in $subKeys) { $subkeyName = $($subKey.PSChildName); Write-Output "^""Processing subkey: `"^""$subkeyName`"^"""^""; $subkeyPath = Join-Path -Path $currentRegistryKeyPath -ChildPath $subkeyName; Clear-RegistryKeyValues $subkeyPath; }; Write-Output "^""Successfully cleared all subkeys in `"^""$formattedRegistryKeyPath`"^""."^""; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU" (recursively)
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSaveMRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Iterating subkeys recursively: `"^""$formattedRegistryKeyPath`"^""."^""; $subKeys = Get-ChildItem -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop; if (!$subKeys) { Write-Output 'Skipping: no subkeys available.'; return; }; foreach ($subKey in $subKeys) { $subkeyName = $($subKey.PSChildName); Write-Output "^""Processing subkey: `"^""$subkeyName`"^"""^""; $subkeyPath = Join-Path -Path $currentRegistryKeyPath -ChildPath $subkeyName; Clear-RegistryKeyValues $subkeyPath; }; Write-Output "^""Successfully cleared all subkeys in `"^""$formattedRegistryKeyPath`"^""."^""; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU" (recursively)
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Iterating subkeys recursively: `"^""$formattedRegistryKeyPath`"^""."^""; $subKeys = Get-ChildItem -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop; if (!$subKeys) { Write-Output 'Skipping: no subkeys available.'; return; }; foreach ($subKey in $subKeys) { $subkeyName = $($subKey.PSChildName); Write-Output "^""Processing subkey: `"^""$subkeyName`"^"""^""; $subkeyPath = Join-Path -Path $currentRegistryKeyPath -ChildPath $subkeyName; Clear-RegistryKeyValues $subkeyPath; }; Write-Output "^""Successfully cleared all subkeys in `"^""$formattedRegistryKeyPath`"^""."^""; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear directory contents  : "%APPDATA%\Microsoft\Windows\Recent Items"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Microsoft\Windows\Recent Items'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Clear Windows Media Player recent activity history----
:: ----------------------------------------------------------
echo --- Clear Windows Media Player recent activity history
:: Clear register values from "HKCU\Software\Microsoft\MediaPlayer\Player\RecentFileList" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\MediaPlayer\Player\RecentFileList'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Microsoft\MediaPlayer\Player\RecentURLList" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\MediaPlayer\Player\RecentURLList'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: Clear register values from "HKCU\Software\Gabest\Media Player Classic\Recent File List" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Gabest\Media Player Classic\Recent File List'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Clear DirectX recent application history---------
:: ----------------------------------------------------------
echo --- Clear DirectX recent application history
:: Clear register values from "HKCU\Software\Microsoft\Direct3D\MostRecentApplication" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Direct3D\MostRecentApplication'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Clear Windows Run command history-------------
:: ----------------------------------------------------------
echo --- Clear Windows Run command history
:: Clear register values from "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Clear File Explorer address bar history----------
:: ----------------------------------------------------------
echo --- Clear File Explorer address bar history
:: Clear register values from "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" 
PowerShell -ExecutionPolicy Unrestricted -Command "$rootRegistryKeyPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths'; function Clear-RegistryKeyValues { try { $currentRegistryKeyPath = $args[0]; Write-Output "^""Clearing registry values from `"^""$currentRegistryKeyPath`"^""."^""; $formattedRegistryKeyPath = $currentRegistryKeyPath -replace '^([^\\]+)', '$1:'; if (-Not (Test-Path -LiteralPath $formattedRegistryKeyPath)) { Write-Output "^""Skipping: Registry key not found: `"^""$formattedRegistryKeyPath`"^""."^""; return; }; $directValueNames=(Get-Item -LiteralPath $formattedRegistryKeyPath -ErrorAction Stop | Select-Object -ExpandProperty Property); if (-Not $directValueNames) { Write-Output 'Skipping: Registry key has no direct values.'; } else { foreach ($valueName in $directValueNames) { Remove-ItemProperty -LiteralPath $formattedRegistryKeyPath -Name $valueName -ErrorAction Stop; Write-Output "^""Successfully deleted value: `"^""$valueName`"^"" from `"^""$formattedRegistryKeyPath`"^""."^""; }; Write-Output "^""Successfully cleared all direct values in `"^""$formattedRegistryKeyPath`"^""."^""; }; } catch { Write-Error "^""Failed to clear registry values in `"^""$formattedRegistryKeyPath`"^"". Error: $_"^""; Exit 1; }; }; Clear-RegistryKeyValues $rootRegistryKeyPath"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Clear privacy.sexy script history-------------
:: ----------------------------------------------------------
echo --- Clear privacy.sexy script history
:: Clear directory contents  : "%APPDATA%\privacy.sexy\runs"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\privacy.sexy\runs'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear privacy.sexy activity logs-------------
:: ----------------------------------------------------------
echo --- Clear privacy.sexy activity logs
:: Clear directory contents  : "%APPDATA%\privacy.sexy\logs"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\privacy.sexy\logs'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Clear Steam dumps---------------------
:: ----------------------------------------------------------
echo --- Clear Steam dumps
:: Clear directory contents  : "%PROGRAMFILES(X86)%\Steam\Dumps"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%PROGRAMFILES(X86)%\Steam\Dumps'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Clear Steam traces--------------------
:: ----------------------------------------------------------
echo --- Clear Steam traces
:: Clear directory contents  : "%PROGRAMFILES(X86)%\Steam\Traces"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%PROGRAMFILES(X86)%\Steam\Traces'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Clear Steam cache---------------------
:: ----------------------------------------------------------
echo --- Clear Steam cache
:: Clear directory contents  : "%ProgramFiles(x86)%\Steam\appcache"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%ProgramFiles(x86)%\Steam\appcache'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Clear offline Visual Studio usage telemetry data-----
:: ----------------------------------------------------------
echo --- Clear offline Visual Studio usage telemetry data
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\VSCommon\14.0\SQM"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\VSCommon\14.0\SQM'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\VSCommon\15.0\SQM"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\VSCommon\15.0\SQM'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\VSCommon\16.0\SQM"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\VSCommon\16.0\SQM'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\VSCommon\17.0\SQM"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\VSCommon\17.0\SQM'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------Clear Visual Studio Application Insights logs-------
:: ----------------------------------------------------------
echo --- Clear Visual Studio Application Insights logs
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\VSApplicationInsights"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\VSApplicationInsights'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%PROGRAMDATA%\Microsoft\VSApplicationInsights"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%PROGRAMDATA%\Microsoft\VSApplicationInsights'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\Microsoft\VSApplicationInsights"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\Microsoft\VSApplicationInsights'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Clear Visual Studio telemetry data------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio telemetry data
:: Clear directory contents  : "%APPDATA%\vstelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\vstelemetry'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%PROGRAMDATA%\vstelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%PROGRAMDATA%\vstelemetry'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Clear Visual Studio temporary telemetry and log data---
:: ----------------------------------------------------------
echo --- Clear Visual Studio temporary telemetry and log data
:: Clear directory contents  : "%TEMP%\VSFaultInfo"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSFaultInfo'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSFeedbackPerfWatsonData"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSFeedbackPerfWatsonData'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSFeedbackVSRTCLogs"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSFeedbackVSRTCLogs'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSFeedbackIntelliCodeLogs"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSFeedbackIntelliCodeLogs'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSRemoteControl"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSRemoteControl'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\Microsoft\VSFeedbackCollector"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\Microsoft\VSFeedbackCollector'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSTelem"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSTelem'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%TEMP%\VSTelem.Out"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%\VSTelem.Out'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2010 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2010 license
:: Remove Visual Studio license for product 77550D6B-6352-4E77-9DA3-537419DF564B
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\77550D6B-6352-4E77-9DA3-537419DF564B" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\77550D6B-6352-4E77-9DA3-537419DF564B'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2013 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2013 license
:: Remove Visual Studio license for product E79B3F9C-6543-4897-BBA5-5BFB0A02BB5C
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\E79B3F9C-6543-4897-BBA5-5BFB0A02BB5C" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\E79B3F9C-6543-4897-BBA5-5BFB0A02BB5C'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2015 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2015 license
:: Remove Visual Studio license for product 4D8CFBCB-2F6A-4AD2-BABF-10E28F6F2C8F
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\4D8CFBCB-2F6A-4AD2-BABF-10E28F6F2C8F" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\4D8CFBCB-2F6A-4AD2-BABF-10E28F6F2C8F'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2017 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2017 license
:: Remove Visual Studio license for product 5C505A59-E312-4B89-9508-E162F8150517
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\5C505A59-E312-4B89-9508-E162F8150517" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\5C505A59-E312-4B89-9508-E162F8150517'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2019 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2019 license
:: Remove Visual Studio license for product 41717607-F34E-432C-A138-A3CFD7E25CDA
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\41717607-F34E-432C-A138-A3CFD7E25CDA'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear Visual Studio 2022 license-------------
:: ----------------------------------------------------------
echo --- Clear Visual Studio 2022 license
:: Remove Visual Studio license for product B16F0CF0-8AD1-4A5B-87BC-CB0DBE9C48FC
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\B16F0CF0-8AD1-4A5B-87BC-CB0DBE9C48FC" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\B16F0CF0-8AD1-4A5B-87BC-CB0DBE9C48FC'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove Visual Studio license for product 10D17DBA-761D-4CD8-A627-984E75A58700
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\10D17DBA-761D-4CD8-A627-984E75A58700" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\10D17DBA-761D-4CD8-A627-984E75A58700'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove Visual Studio license for product 1299B4B9-DFCC-476D-98F0-F65A2B46C96D
:: Remove the registry key "HKLM\SOFTWARE\Classes\Licenses\1299B4B9-DFCC-476D-98F0-F65A2B46C96D" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Classes\Licenses\1299B4B9-DFCC-476D-98F0-F65A2B46C96D'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Clear Listary search index----------------
:: ----------------------------------------------------------
echo --- Clear Listary search index
:: Clear directory contents  : "%APPDATA%\Listary\UserData"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Listary\UserData'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------------Clear Java cache---------------------
:: ----------------------------------------------------------
echo --- Clear Java cache
:: Clear directory contents  : "%APPDATA%\Sun\Java\Deployment\cache"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Sun\Java\Deployment\cache'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Clear Flash Player traces-----------------
:: ----------------------------------------------------------
echo --- Clear Flash Player traces
:: Clear directory contents  : "%APPDATA%\Macromedia\Flash Player"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%APPDATA%\Macromedia\Flash Player'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Clear Dotnet CLI telemetry----------------
:: ----------------------------------------------------------
echo --- Clear Dotnet CLI telemetry
:: Clear directory contents  : "%USERPROFILE%\.dotnet\TelemetryStorageService"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%USERPROFILE%\.dotnet\TelemetryStorageService'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Clear temporary system folder---------------
:: ----------------------------------------------------------
echo --- Clear temporary system folder
:: Clear directory contents  : "%SYSTEMROOT%\Temp"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Temp'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Clear temporary user folder----------------
:: ----------------------------------------------------------
echo --- Clear temporary user folder
:: Clear directory contents  : "%TEMP%"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%TEMP%'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Clear prefetch folder-------------------
:: ----------------------------------------------------------
echo --- Clear prefetch folder
:: Clear directory contents  : "%SYSTEMROOT%\Prefetch"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Prefetch'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Clear Windows update and SFC scan logs----------
:: ----------------------------------------------------------
echo --- Clear Windows update and SFC scan logs
:: Clear directory contents  : "%SYSTEMROOT%\Temp\CBS"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Temp\CBS'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Clear Windows Update Medic Service logs----------
:: ----------------------------------------------------------
echo --- Clear Windows Update Medic Service logs
:: Clear directory contents  : "%SYSTEMROOT%\Logs\waasmedic"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Logs\waasmedic'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Clear "Cryptographic Services" diagnostic traces-----
:: ----------------------------------------------------------
echo --- Clear "Cryptographic Services" diagnostic traces
:: Delete files matching pattern: "%SYSTEMROOT%\System32\catroot2\dberr.txt"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\catroot2\dberr.txt"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\System32\catroot2.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\catroot2.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\System32\catroot2.jrs"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\catroot2.jrs"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\System32\catroot2.edb"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\catroot2.edb"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\System32\catroot2.chk"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\catroot2.chk"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Clear Server-initiated Healing Events system logs-----
:: ----------------------------------------------------------
echo --- Clear Server-initiated Healing Events system logs
:: Clear directory contents  : "%SYSTEMROOT%\Logs\SIH"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Logs\SIH'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Clear Windows Update logs-----------------
:: ----------------------------------------------------------
echo --- Clear Windows Update logs
:: Clear directory contents  : "%SYSTEMROOT%\Traces\WindowsUpdate"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Traces\WindowsUpdate'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: Clear Optional Component Manager and COM+ components logs-
:: ----------------------------------------------------------
echo --- Clear Optional Component Manager and COM+ components logs
:: Delete files matching pattern: "%SYSTEMROOT%\comsetup.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\comsetup.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Clear "Distributed Transaction Coordinator (DTC)" logs--
:: ----------------------------------------------------------
echo --- Clear "Distributed Transaction Coordinator (DTC)" logs
:: Delete files matching pattern: "%SYSTEMROOT%\DtcInstall.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\DtcInstall.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: Clear logs for pending/unsuccessful file rename operations
echo --- Clear logs for pending/unsuccessful file rename operations
:: Delete files matching pattern: "%SYSTEMROOT%\PFRO.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\PFRO.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Clear Windows update installation logs----------
:: ----------------------------------------------------------
echo --- Clear Windows update installation logs
:: Delete files matching pattern: "%SYSTEMROOT%\setupact.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\setupact.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\setuperr.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\setuperr.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Clear Windows setup logs-----------------
:: ----------------------------------------------------------
echo --- Clear Windows setup logs
:: Delete files matching pattern: "%SYSTEMROOT%\setupapi.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\setupapi.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\inf\setupapi.app.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\inf\setupapi.app.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\inf\setupapi.dev.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\inf\setupapi.dev.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\inf\setupapi.offline.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\inf\setupapi.offline.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%SYSTEMROOT%\Panther"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Panther'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Clear "Windows System Assessment Tool (`WinSAT`)" logs--
:: ----------------------------------------------------------
echo --- Clear "Windows System Assessment Tool (`WinSAT`)" logs
:: Delete files matching pattern: "%SYSTEMROOT%\Performance\WinSAT\winsat.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\Performance\WinSAT\winsat.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Clear password change events---------------
:: ----------------------------------------------------------
echo --- Clear password change events
:: Delete files matching pattern: "%SYSTEMROOT%\debug\PASSWD.LOG"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\debug\PASSWD.LOG"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Clear user web cache database---------------
:: ----------------------------------------------------------
echo --- Clear user web cache database
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\Windows\WebCache"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\Windows\WebCache'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Clear system temp folder when not logged in--------
:: ----------------------------------------------------------
echo --- Clear system temp folder when not logged in
:: Clear directory contents  : "%SYSTEMROOT%\ServiceProfiles\LocalService\AppData\Local\Temp"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\ServiceProfiles\LocalService\AppData\Local\Temp'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: Clear DISM (Deployment Image Servicing and Management) system logs
echo --- Clear DISM (Deployment Image Servicing and Management) system logs
:: Delete files matching pattern: "%SYSTEMROOT%\Logs\CBS\CBS.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\Logs\CBS\CBS.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%SYSTEMROOT%\Logs\DISM\DISM.log"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\Logs\DISM\DISM.log"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Clear Windows update files----------------
:: ----------------------------------------------------------
echo --- Clear Windows update files
:: Stop service: wuauserv (with state flag) (wait until stopped)
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'wuauserv'; Write-Host "^""Stopping service: `"^""$serviceName`"^""."^""; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if (!$service) { Write-Host "^""Skipping, service `"^""$serviceName`"^"" could not be not found, no need to stop it."^""; exit 0; }; if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""Skipping, `"^""$serviceName`"^"" is not running, no need to stop."^""; exit 0; }; Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { $service | Stop-Service -Force -ErrorAction Stop; $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped); } catch { throw "^""Failed to stop the service `"^""$serviceName`"^"": $_"^""; }; Write-Host "^""Successfully stopped the service: `"^""$serviceName`"^""."^""; $stateFilePath = '%APPDATA%\privacy.sexy-wuauserv'; $expandedStateFilePath = [System.Environment]::ExpandEnvironmentVariables($stateFilePath); if (Test-Path -Path $expandedStateFilePath) { Write-Host "^""Skipping creating a service state file, it already exists: `"^""$expandedStateFilePath`"^""."^""; } else { <# Ensure the directory exists #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedStateFilePath); if (-not (Test-Path $parentDirectory -PathType Container)) { try { New-Item -ItemType Directory -Path $parentDirectory -Force -ErrorAction Stop | Out-Null; }  catch { Write-Warning "^""Failed to create parent directory of service state file `"^""$parentDirectory`"^"": $_"^""; }; }; <# Create the state file #>; try { New-Item -ItemType File -Path $expandedStateFilePath -Force -ErrorAction Stop | Out-Null; Write-Host 'The service will be started again.'; } catch { Write-Warning "^""Failed to create service state file `"^""$expandedStateFilePath`"^"": $_"^""; }; }"
:: Clear directory contents  : "%SYSTEMROOT%\SoftwareDistribution"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\SoftwareDistribution'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Start service: wuauserv (with state flag)
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'wuauserv'; $stateFilePath = '%APPDATA%\privacy.sexy-wuauserv'; $expandedStateFilePath = [System.Environment]::ExpandEnvironmentVariables($stateFilePath); if (-not (Test-Path -Path $expandedStateFilePath)) { Write-Host "^""Skipping starting the service: It was not running before."^""; } else { try { Remove-Item -Path $expandedStateFilePath -Force -ErrorAction Stop; Write-Host 'The service is expected to be started.'; } catch { Write-Warning "^""Failed to delete the service state file `"^""$expandedStateFilePath`"^"": $_"^""; }; }; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if (!$service) { throw "^""Failed to start service `"^""$serviceName`"^"": Service not found."^""; }; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""Skipping, `"^""$serviceName`"^"" is already running, no need to start."^""; exit 0; }; Write-Host "^""`"^""$serviceName`"^"" is not running, starting it."^""; try { $service | Start-Service -ErrorAction Stop; Write-Host "^""Successfully started the service: `"^""$serviceName`"^""."^""; } catch { Write-Warning "^""Failed to start the service: `"^""$serviceName`"^""."^""; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Clear Common Language Runtime system logs---------
:: ----------------------------------------------------------
echo --- Clear Common Language Runtime system logs
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\CLR_v4.0\UsageTraces"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\CLR_v4.0\UsageTraces'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Clear directory contents  : "%LOCALAPPDATA%\Microsoft\CLR_v4.0_32\UsageTraces"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\CLR_v4.0_32\UsageTraces'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------Clear Network Setup Service Events system logs------
:: ----------------------------------------------------------
echo --- Clear Network Setup Service Events system logs
:: Clear directory contents  : "%SYSTEMROOT%\Logs\NetSetup"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\Logs\NetSetup'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: Clear logs generated by Disk Cleanup Tool (`cleanmgr.exe`)
echo --- Clear logs generated by Disk Cleanup Tool (`cleanmgr.exe`)
:: Clear directory contents  : "%SYSTEMROOT%\System32\LogFiles\setupcln"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMROOT%\System32\LogFiles\setupcln'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Clear thumbnail cache-------------------
:: ----------------------------------------------------------
echo --- Clear thumbnail cache
:: Delete files matching pattern: "%LOCALAPPDATA%\Microsoft\Windows\Explorer\*.db"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%LOCALAPPDATA%\Microsoft\Windows\Explorer\*.db"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Clear diagnostics tracking logs--------------
:: ----------------------------------------------------------
echo --- Clear diagnostics tracking logs
:: Stop service: DiagTrack (with state flag) (wait until stopped)
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'DiagTrack'; Write-Host "^""Stopping service: `"^""$serviceName`"^""."^""; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if (!$service) { Write-Host "^""Skipping, service `"^""$serviceName`"^"" could not be not found, no need to stop it."^""; exit 0; }; if ($service.Status -ne [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""Skipping, `"^""$serviceName`"^"" is not running, no need to stop."^""; exit 0; }; Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { $service | Stop-Service -Force -ErrorAction Stop; $service.WaitForStatus([System.ServiceProcess.ServiceControllerStatus]::Stopped); } catch { throw "^""Failed to stop the service `"^""$serviceName`"^"": $_"^""; }; Write-Host "^""Successfully stopped the service: `"^""$serviceName`"^""."^""; $stateFilePath = '%APPDATA%\privacy.sexy-DiagTrack'; $expandedStateFilePath = [System.Environment]::ExpandEnvironmentVariables($stateFilePath); if (Test-Path -Path $expandedStateFilePath) { Write-Host "^""Skipping creating a service state file, it already exists: `"^""$expandedStateFilePath`"^""."^""; } else { <# Ensure the directory exists #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedStateFilePath); if (-not (Test-Path $parentDirectory -PathType Container)) { try { New-Item -ItemType Directory -Path $parentDirectory -Force -ErrorAction Stop | Out-Null; }  catch { Write-Warning "^""Failed to create parent directory of service state file `"^""$parentDirectory`"^"": $_"^""; }; }; <# Create the state file #>; try { New-Item -ItemType File -Path $expandedStateFilePath -Force -ErrorAction Stop | Out-Null; Write-Host 'The service will be started again.'; } catch { Write-Warning "^""Failed to create service state file `"^""$expandedStateFilePath`"^"": $_"^""; }; }"
:: Delete files matching pattern: "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\AutoLogger\AutoLogger-Diagtrack-Listener.etl"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; <# Not using `Get-Acl`/`Set-Acl` to avoid adjusting token privileges #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedPath); $fileName = [System.IO.Path]::GetFileName($expandedPath); if ($parentDirectory -like '*[*?]*') { throw "^""Unable to grant permissions to glob path parent directory: `"^""$parentDirectory`"^"", wildcards in parent directory are not supported by ``takeown`` and ``icacls``."^""; }; if (($fileName -ne '*') -and ($fileName -like '*[*?]*')) { throw "^""Unable to grant permissions to glob path file name: `"^""$fileName`"^"", wildcards in file name is not supported by ``takeown`` and ``icacls``."^""; }; Write-Host "^""Taking ownership of `"^""$expandedPath`"^""."^""; $cmdPath = $expandedPath; if ($cmdPath.EndsWith('\')) { $cmdPath += '\' <# Escape trailing backslash for correct handling in batch commands #>; }; $takeOwnershipCommand = "^""takeown /f `"^""$cmdPath`"^"" /a"^"" <# `icacls /setowner` does not succeed, so use `takeown` instead. #>; if (-not (Test-Path -Path "^""$expandedPath"^"" -PathType Leaf)) { $localizedYes = 'Y' <# Default 'Yes' flag (fallback) #>; try { $choiceOutput = cmd /c "^""choice <nul 2>nul"^""; if ($choiceOutput -and $choiceOutput.Length -ge 2) { $localizedYes = $choiceOutput[1]; } else { Write-Warning "^""Failed to determine localized 'Yes' character. Output: `"^""$choiceOutput`"^"""^""; }; } catch { Write-Warning "^""Failed to determine localized 'Yes' character. Error: $_"^""; }; $takeOwnershipCommand += "^"" /r /d $localizedYes"^""; }; $takeOwnershipOutput = cmd /c "^""$takeOwnershipCommand 2>&1"^"" <# `stderr` message is misleading, e.g. "^""ERROR: The system cannot find the file specified."^"" is not an error. #>; if ($LASTEXITCODE -eq 0) { Write-Host "^""Successfully took ownership of `"^""$expandedPath`"^"" (using ``$takeOwnershipCommand``)."^""; } else { Write-Host "^""Did not take ownership of `"^""$expandedPath`"^"" using ``$takeOwnershipCommand``, status code: $LASTEXITCODE, message: $takeOwnershipOutput."^""; <# Do not write as error or warning, because this can be due to missing path, it's handled in next command. #>; <# `takeown` exits with status code `1`, making it hard to handle missing path here. #>; }; Write-Host "^""Granting permissions for `"^""$expandedPath`"^""."^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminAccountName = $adminAccount.Value; $grantPermissionsCommand = "^""icacls `"^""$cmdPath`"^"" /grant `"^""$($adminAccountName):F`"^"" /t"^""; $icaclsOutput = cmd /c "^""$grantPermissionsCommand"^""; if ($LASTEXITCODE -eq 3) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } elseif ($LASTEXITCODE -ne 0) { Write-Host "^""Take ownership message:`n$takeOwnershipOutput"^""; Write-Host "^""Grant permissions:`n$icaclsOutput"^""; Write-Warning "^""Failed to assign permissions for `"^""$expandedPath`"^"" using ``$grantPermissionsCommand``, status code: $LASTEXITCODE."^""; } else { $fileStats = $icaclsOutput | ForEach-Object { $_ -match '\d+' | Out-Null; $matches[0] } | Where-Object { $_ -ne $null } | ForEach-Object { [int]$_ }; if ($fileStats.Count -gt 0 -and ($fileStats | ForEach-Object { $_ -eq 0 } | Where-Object { $_ -eq $false }).Count -eq 0) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } else { Write-Host "^""Successfully granted permissions for `"^""$expandedPath`"^"" (using ``$grantPermissionsCommand``)."^""; }; }; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete files matching pattern: "%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\AutoLogger-Diagtrack-Listener.etl"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Diagnosis\ETLLogs\ShutdownLogger\AutoLogger-Diagtrack-Listener.etl"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; <# Not using `Get-Acl`/`Set-Acl` to avoid adjusting token privileges #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedPath); $fileName = [System.IO.Path]::GetFileName($expandedPath); if ($parentDirectory -like '*[*?]*') { throw "^""Unable to grant permissions to glob path parent directory: `"^""$parentDirectory`"^"", wildcards in parent directory are not supported by ``takeown`` and ``icacls``."^""; }; if (($fileName -ne '*') -and ($fileName -like '*[*?]*')) { throw "^""Unable to grant permissions to glob path file name: `"^""$fileName`"^"", wildcards in file name is not supported by ``takeown`` and ``icacls``."^""; }; Write-Host "^""Taking ownership of `"^""$expandedPath`"^""."^""; $cmdPath = $expandedPath; if ($cmdPath.EndsWith('\')) { $cmdPath += '\' <# Escape trailing backslash for correct handling in batch commands #>; }; $takeOwnershipCommand = "^""takeown /f `"^""$cmdPath`"^"" /a"^"" <# `icacls /setowner` does not succeed, so use `takeown` instead. #>; if (-not (Test-Path -Path "^""$expandedPath"^"" -PathType Leaf)) { $localizedYes = 'Y' <# Default 'Yes' flag (fallback) #>; try { $choiceOutput = cmd /c "^""choice <nul 2>nul"^""; if ($choiceOutput -and $choiceOutput.Length -ge 2) { $localizedYes = $choiceOutput[1]; } else { Write-Warning "^""Failed to determine localized 'Yes' character. Output: `"^""$choiceOutput`"^"""^""; }; } catch { Write-Warning "^""Failed to determine localized 'Yes' character. Error: $_"^""; }; $takeOwnershipCommand += "^"" /r /d $localizedYes"^""; }; $takeOwnershipOutput = cmd /c "^""$takeOwnershipCommand 2>&1"^"" <# `stderr` message is misleading, e.g. "^""ERROR: The system cannot find the file specified."^"" is not an error. #>; if ($LASTEXITCODE -eq 0) { Write-Host "^""Successfully took ownership of `"^""$expandedPath`"^"" (using ``$takeOwnershipCommand``)."^""; } else { Write-Host "^""Did not take ownership of `"^""$expandedPath`"^"" using ``$takeOwnershipCommand``, status code: $LASTEXITCODE, message: $takeOwnershipOutput."^""; <# Do not write as error or warning, because this can be due to missing path, it's handled in next command. #>; <# `takeown` exits with status code `1`, making it hard to handle missing path here. #>; }; Write-Host "^""Granting permissions for `"^""$expandedPath`"^""."^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminAccountName = $adminAccount.Value; $grantPermissionsCommand = "^""icacls `"^""$cmdPath`"^"" /grant `"^""$($adminAccountName):F`"^"" /t"^""; $icaclsOutput = cmd /c "^""$grantPermissionsCommand"^""; if ($LASTEXITCODE -eq 3) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } elseif ($LASTEXITCODE -ne 0) { Write-Host "^""Take ownership message:`n$takeOwnershipOutput"^""; Write-Host "^""Grant permissions:`n$icaclsOutput"^""; Write-Warning "^""Failed to assign permissions for `"^""$expandedPath`"^"" using ``$grantPermissionsCommand``, status code: $LASTEXITCODE."^""; } else { $fileStats = $icaclsOutput | ForEach-Object { $_ -match '\d+' | Out-Null; $matches[0] } | Where-Object { $_ -ne $null } | ForEach-Object { [int]$_ }; if ($fileStats.Count -gt 0 -and ($fileStats | ForEach-Object { $_ -eq 0 } | Where-Object { $_ -eq $false }).Count -eq 0) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } else { Write-Host "^""Successfully granted permissions for `"^""$expandedPath`"^"" (using ``$grantPermissionsCommand``)."^""; }; }; $deletedCount = 0; $failedCount = 0; $skippedCount = 0; $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping, the path is not a file but a folder: $($path)."^""; $skippedCount++; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; if ($skippedCount -gt 0) { Write-Host "^""Skipped $($skippedCount) items."^""; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Start service: DiagTrack (with state flag)
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'DiagTrack'; $stateFilePath = '%APPDATA%\privacy.sexy-DiagTrack'; $expandedStateFilePath = [System.Environment]::ExpandEnvironmentVariables($stateFilePath); if (-not (Test-Path -Path $expandedStateFilePath)) { Write-Host "^""Skipping starting the service: It was not running before."^""; } else { try { Remove-Item -Path $expandedStateFilePath -Force -ErrorAction Stop; Write-Host 'The service is expected to be started.'; } catch { Write-Warning "^""Failed to delete the service state file `"^""$expandedStateFilePath`"^"": $_"^""; }; }; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if (!$service) { throw "^""Failed to start service `"^""$serviceName`"^"": Service not found."^""; }; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""Skipping, `"^""$serviceName`"^"" is already running, no need to start."^""; exit 0; }; Write-Host "^""`"^""$serviceName`"^"" is not running, starting it."^""; try { $service | Start-Service -ErrorAction Stop; Write-Host "^""Successfully started the service: `"^""$serviceName`"^""."^""; } catch { Write-Warning "^""Failed to start the service: `"^""$serviceName`"^""."^""; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Clear event logs in Event Viewer application-------
:: ----------------------------------------------------------
echo --- Clear event logs in Event Viewer application
REM https://social.technet.microsoft.com/Forums/en-US/f6788f7d-7d04-41f1-a64e-3af9f700e4bd/failed-to-clear-log-microsoftwindowsliveidoperational-access-is-denied?forum=win10itprogeneral
wevtutil sl Microsoft-Windows-LiveId/Operational /ca:O:BAG:SYD:(A;;0x1;;;SY)(A;;0x5;;;BA)(A;;0x1;;;LA)
for /f "tokens=*" %%i in ('wevtutil.exe el') DO (
    echo Deleting event log: "%%i"
    wevtutil.exe cl %1 "%%i"
)
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Clear Defender scan (protection) history---------
:: ----------------------------------------------------------
echo --- Clear Defender scan (protection) history
:: Clear directory contents (with additional permissions) : "%ProgramData%\Microsoft\Windows Defender\Scans\History"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%ProgramData%\Microsoft\Windows Defender\Scans\History'; if ($directoryGlob.EndsWith('\*')) { $directoryGlob } elseif ($directoryGlob.EndsWith('\')) { "^""$($directoryGlob)*"^"" } else { "^""$($directoryGlob)\*"^"" } )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; <# Not using `Get-Acl`/`Set-Acl` to avoid adjusting token privileges #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedPath); $fileName = [System.IO.Path]::GetFileName($expandedPath); if ($parentDirectory -like '*[*?]*') { throw "^""Unable to grant permissions to glob path parent directory: `"^""$parentDirectory`"^"", wildcards in parent directory are not supported by ``takeown`` and ``icacls``."^""; }; if (($fileName -ne '*') -and ($fileName -like '*[*?]*')) { throw "^""Unable to grant permissions to glob path file name: `"^""$fileName`"^"", wildcards in file name is not supported by ``takeown`` and ``icacls``."^""; }; Write-Host "^""Taking ownership of `"^""$expandedPath`"^""."^""; $cmdPath = $expandedPath; if ($cmdPath.EndsWith('\')) { $cmdPath += '\' <# Escape trailing backslash for correct handling in batch commands #>; }; $takeOwnershipCommand = "^""takeown /f `"^""$cmdPath`"^"" /a"^"" <# `icacls /setowner` does not succeed, so use `takeown` instead. #>; if (-not (Test-Path -Path "^""$expandedPath"^"" -PathType Leaf)) { $localizedYes = 'Y' <# Default 'Yes' flag (fallback) #>; try { $choiceOutput = cmd /c "^""choice <nul 2>nul"^""; if ($choiceOutput -and $choiceOutput.Length -ge 2) { $localizedYes = $choiceOutput[1]; } else { Write-Warning "^""Failed to determine localized 'Yes' character. Output: `"^""$choiceOutput`"^"""^""; }; } catch { Write-Warning "^""Failed to determine localized 'Yes' character. Error: $_"^""; }; $takeOwnershipCommand += "^"" /r /d $localizedYes"^""; }; $takeOwnershipOutput = cmd /c "^""$takeOwnershipCommand 2>&1"^"" <# `stderr` message is misleading, e.g. "^""ERROR: The system cannot find the file specified."^"" is not an error. #>; if ($LASTEXITCODE -eq 0) { Write-Host "^""Successfully took ownership of `"^""$expandedPath`"^"" (using ``$takeOwnershipCommand``)."^""; } else { Write-Host "^""Did not take ownership of `"^""$expandedPath`"^"" using ``$takeOwnershipCommand``, status code: $LASTEXITCODE, message: $takeOwnershipOutput."^""; <# Do not write as error or warning, because this can be due to missing path, it's handled in next command. #>; <# `takeown` exits with status code `1`, making it hard to handle missing path here. #>; }; Write-Host "^""Granting permissions for `"^""$expandedPath`"^""."^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminAccountName = $adminAccount.Value; $grantPermissionsCommand = "^""icacls `"^""$cmdPath`"^"" /grant `"^""$($adminAccountName):F`"^"" /t"^""; $icaclsOutput = cmd /c "^""$grantPermissionsCommand"^""; if ($LASTEXITCODE -eq 3) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } elseif ($LASTEXITCODE -ne 0) { Write-Host "^""Take ownership message:`n$takeOwnershipOutput"^""; Write-Host "^""Grant permissions:`n$icaclsOutput"^""; Write-Warning "^""Failed to assign permissions for `"^""$expandedPath`"^"" using ``$grantPermissionsCommand``, status code: $LASTEXITCODE."^""; } else { $fileStats = $icaclsOutput | ForEach-Object { $_ -match '\d+' | Out-Null; $matches[0] } | Where-Object { $_ -ne $null } | ForEach-Object { [int]$_ }; if ($fileStats.Count -gt 0 -and ($fileStats | ForEach-Object { $_ -eq 0 } | Where-Object { $_ -eq $false }).Count -eq 0) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } else { Write-Host "^""Successfully granted permissions for `"^""$expandedPath`"^"" (using ``$grantPermissionsCommand``)."^""; }; }; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Empty trash (Recycle Bin)-----------------
:: ----------------------------------------------------------
echo --- Empty trash (Recycle Bin)
PowerShell -ExecutionPolicy Unrestricted -Command "$bin = (New-Object -ComObject Shell.Application).NameSpace(10); $bin.items() | ForEach { Write-Host "^""Deleting $($_.Name) from Recycle Bin"^""; Remove-Item $_.Path -Recurse -Force; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Clear previous Windows installations-----------
:: ----------------------------------------------------------
echo --- Clear previous Windows installations
:: Delete directory (with additional permissions) : "%SYSTEMDRIVE%\Windows.old"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMDRIVE%\Windows.old'; if (-Not $directoryGlob.EndsWith('\')) { $directoryGlob += '\' }; $directoryGlob )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; <# Not using `Get-Acl`/`Set-Acl` to avoid adjusting token privileges #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedPath); $fileName = [System.IO.Path]::GetFileName($expandedPath); if ($parentDirectory -like '*[*?]*') { throw "^""Unable to grant permissions to glob path parent directory: `"^""$parentDirectory`"^"", wildcards in parent directory are not supported by ``takeown`` and ``icacls``."^""; }; if (($fileName -ne '*') -and ($fileName -like '*[*?]*')) { throw "^""Unable to grant permissions to glob path file name: `"^""$fileName`"^"", wildcards in file name is not supported by ``takeown`` and ``icacls``."^""; }; Write-Host "^""Taking ownership of `"^""$expandedPath`"^""."^""; $cmdPath = $expandedPath; if ($cmdPath.EndsWith('\')) { $cmdPath += '\' <# Escape trailing backslash for correct handling in batch commands #>; }; $takeOwnershipCommand = "^""takeown /f `"^""$cmdPath`"^"" /a"^"" <# `icacls /setowner` does not succeed, so use `takeown` instead. #>; if (-not (Test-Path -Path "^""$expandedPath"^"" -PathType Leaf)) { $localizedYes = 'Y' <# Default 'Yes' flag (fallback) #>; try { $choiceOutput = cmd /c "^""choice <nul 2>nul"^""; if ($choiceOutput -and $choiceOutput.Length -ge 2) { $localizedYes = $choiceOutput[1]; } else { Write-Warning "^""Failed to determine localized 'Yes' character. Output: `"^""$choiceOutput`"^"""^""; }; } catch { Write-Warning "^""Failed to determine localized 'Yes' character. Error: $_"^""; }; $takeOwnershipCommand += "^"" /r /d $localizedYes"^""; }; $takeOwnershipOutput = cmd /c "^""$takeOwnershipCommand 2>&1"^"" <# `stderr` message is misleading, e.g. "^""ERROR: The system cannot find the file specified."^"" is not an error. #>; if ($LASTEXITCODE -eq 0) { Write-Host "^""Successfully took ownership of `"^""$expandedPath`"^"" (using ``$takeOwnershipCommand``)."^""; } else { Write-Host "^""Did not take ownership of `"^""$expandedPath`"^"" using ``$takeOwnershipCommand``, status code: $LASTEXITCODE, message: $takeOwnershipOutput."^""; <# Do not write as error or warning, because this can be due to missing path, it's handled in next command. #>; <# `takeown` exits with status code `1`, making it hard to handle missing path here. #>; }; Write-Host "^""Granting permissions for `"^""$expandedPath`"^""."^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminAccountName = $adminAccount.Value; $grantPermissionsCommand = "^""icacls `"^""$cmdPath`"^"" /grant `"^""$($adminAccountName):F`"^"" /t"^""; $icaclsOutput = cmd /c "^""$grantPermissionsCommand"^""; if ($LASTEXITCODE -eq 3) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } elseif ($LASTEXITCODE -ne 0) { Write-Host "^""Take ownership message:`n$takeOwnershipOutput"^""; Write-Host "^""Grant permissions:`n$icaclsOutput"^""; Write-Warning "^""Failed to assign permissions for `"^""$expandedPath`"^"" using ``$grantPermissionsCommand``, status code: $LASTEXITCODE."^""; } else { $fileStats = $icaclsOutput | ForEach-Object { $_ -match '\d+' | Out-Null; $matches[0] } | Where-Object { $_ -ne $null } | ForEach-Object { [int]$_ }; if ($fileStats.Count -gt 0 -and ($fileStats | ForEach-Object { $_ -eq 0 } | Where-Object { $_ -eq $false }).Count -eq 0) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } else { Write-Host "^""Successfully granted permissions for `"^""$expandedPath`"^"" (using ``$grantPermissionsCommand``)."^""; }; }; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable AutoPlay and AutoRun---------------
:: ----------------------------------------------------------
echo --- Disable AutoPlay and AutoRun
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoDriveTypeAutoRun"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '255'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoDriveTypeAutoRun' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoAutorun"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoAutorun' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer!NoAutoplayfornonVolume"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' /v 'NoAutoplayfornonVolume' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Block telemetry and user experience hosts---------
:: ----------------------------------------------------------
echo --- Block telemetry and user experience hosts
:: Add hosts entries for functional.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='functional.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for browser.events.data.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='browser.events.data.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for self.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='self.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for v10.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='v10.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for v10c.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='v10c.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for us-v10c.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='us-v10c.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for eu-v10c.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='eu-v10c.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for v10.vortex-win.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='v10.vortex-win.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for vortex-win.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='vortex-win.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for telecommand.telemetry.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='telecommand.telemetry.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for www.telecommandsvc.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='www.telecommandsvc.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for umwatson.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='umwatson.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for watsonc.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='watsonc.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for eu-watsonc.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='eu-watsonc.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Block Weather Live Tile hosts---------------
:: ----------------------------------------------------------
echo --- Block Weather Live Tile hosts
:: Add hosts entries for tile-service.weather.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='tile-service.weather.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Block OneNote Live Tile hosts---------------
:: ----------------------------------------------------------
echo --- Block OneNote Live Tile hosts
:: Add hosts entries for cdn.onenote.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='cdn.onenote.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Block Edge experimentation hosts-------------
:: ----------------------------------------------------------
echo --- Block Edge experimentation hosts
:: Add hosts entries for config.edge.skype.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='config.edge.skype.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Block Cortana and Live Tiles hosts------------
:: ----------------------------------------------------------
echo --- Block Cortana and Live Tiles hosts
:: Add hosts entries for business.bing.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='business.bing.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for c.bing.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='c.bing.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for th.bing.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='th.bing.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for edgeassetservice.azureedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='edgeassetservice.azureedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for c-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='c-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for fp.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='fp.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for I-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='I-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for s-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='s-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for dual-s-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='dual-s-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for creativecdn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='creativecdn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for a-ring-fallback.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='a-ring-fallback.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for fp-afd-nocache-ccp.azureedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='fp-afd-nocache-ccp.azureedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for prod-azurecdn-akamai-iris.azureedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='prod-azurecdn-akamai-iris.azureedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for widgetcdn.azureedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='widgetcdn.azureedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for widgetservice.azurefd.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='widgetservice.azurefd.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for fp-vs.azureedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='fp-vs.azureedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ln-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ln-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for t-ring.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='t-ring.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for t-ring-fdv2.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='t-ring-fdv2.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for tse1.mm.bing.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='tse1.mm.bing.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Block Spotlight ads and suggestions hosts---------
:: ----------------------------------------------------------
echo --- Block Spotlight ads and suggestions hosts
:: Add hosts entries for arc.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='arc.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ris.api.iris.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ris.api.iris.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for api.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='api.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for assets.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='assets.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for c.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='c.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for g.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='g.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ntp.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ntp.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for srtb.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='srtb.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for www.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='www.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for fd.api.iris.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='fd.api.iris.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for staticview.msn.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='staticview.msn.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for mucp.api.account.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='mucp.api.account.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for query.prod.cms.rt.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='query.prod.cms.rt.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Block maps data and updates hosts-------------
:: ----------------------------------------------------------
echo --- Block maps data and updates hosts
:: Add hosts entries for maps.windows.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='maps.windows.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ecn.dev.virtualearth.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ecn.dev.virtualearth.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ecn-us.dev.virtualearth.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ecn-us.dev.virtualearth.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for weathermapdata.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='weathermapdata.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Block Photos app sync hosts----------------
:: ----------------------------------------------------------
echo --- Block Photos app sync hosts
:: Add hosts entries for evoke-windowsservices-tas.msedge.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='evoke-windowsservices-tas.msedge.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Block location data sharing hosts-------------
:: ----------------------------------------------------------
echo --- Block location data sharing hosts
:: Add hosts entries for inference.location.live.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='inference.location.live.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for location-inference-westus.cloudapp.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='location-inference-westus.cloudapp.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Block remote configuration sync hosts-----------
:: ----------------------------------------------------------
echo --- Block remote configuration sync hosts
:: Add hosts entries for settings-win.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='settings-win.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for settings.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='settings.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Block Windows error reporting hosts------------
:: ----------------------------------------------------------
echo --- Block Windows error reporting hosts
:: Add hosts entries for watson.telemetry.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='watson.telemetry.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for umwatsonc.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='umwatsonc.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ceuswatcab01.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ceuswatcab01.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for ceuswatcab02.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='ceuswatcab02.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for eaus2watcab01.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='eaus2watcab01.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for eaus2watcab02.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='eaus2watcab02.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for weus2watcab01.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='weus2watcab01.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for weus2watcab02.blob.core.windows.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='weus2watcab02.blob.core.windows.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for co4.telecommand.telemetry.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='co4.telecommand.telemetry.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for cs11.wpc.v0cdn.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='cs11.wpc.v0cdn.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for cs1137.wpc.gammacdn.net
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='cs1137.wpc.gammacdn.net'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for modern.watson.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='modern.watson.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Block Windows crash report hosts-------------
:: ----------------------------------------------------------
echo --- Block Windows crash report hosts
:: Add hosts entries for oca.telemetry.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='oca.telemetry.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for oca.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='oca.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for kmwatsonc.events.data.microsoft.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='kmwatsonc.events.data.microsoft.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Block Dropbox telemetry hosts---------------
:: ----------------------------------------------------------
echo --- Block Dropbox telemetry hosts
:: Add hosts entries for telemetry.dropbox.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='telemetry.dropbox.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: Add hosts entries for telemetry.v.dropbox.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='telemetry.v.dropbox.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Block Spotify Live Tile hosts---------------
:: ----------------------------------------------------------
echo --- Block Spotify Live Tile hosts
:: Add hosts entries for spclient.wg.spotify.com
PowerShell -ExecutionPolicy Unrestricted -Command "$domain ='spclient.wg.spotify.com'; $hostsFilePath = "^""$env:SYSTEMROOT\System32\drivers\etc\hosts"^""; $comment = "^""managed by privacy.sexy"^""; $hostsFileEncoding = [Microsoft.PowerShell.Commands.FileSystemCmdletProviderEncoding]::Utf8; $blockingHostsEntries = @(; @{ AddressType = "^""IPv4"^"";  IPAddress = '0.0.0.0'; }; @{ AddressType = "^""IPv6"^"";  IPAddress = '::1'; }; ); try { $isHostsFilePresent = Test-Path -Path $hostsFilePath -PathType Leaf -ErrorAction Stop; } catch { Write-Error "^""Failed to check hosts file existence. Error: $_"^""; exit 1; }; if (-Not $isHostsFilePresent) { Write-Output "^""Creating a new hosts file at $hostsFilePath."^""; try { New-Item -Path $hostsFilePath -ItemType File -Force -ErrorAction Stop | Out-Null; Write-Output "^""Successfully created the hosts file."^""; } catch { Write-Error "^""Failed to create the hosts file. Error: $_"^""; exit 1; }; }; foreach ($blockingEntry in $blockingHostsEntries) { Write-Output "^""Processing addition for $($blockingEntry.AddressType) entry."^""; try { $hostsFileContents = Get-Content -Path "^""$hostsFilePath"^"" -Raw -Encoding $hostsFileEncoding -ErrorAction Stop; } catch { Write-Error "^""Failed to read the hosts file. Error: $_"^""; continue; }; $hostsEntryLine = "^""$($blockingEntry.IPAddress)`t$domain $([char]35) $comment"^""; if ((-Not [String]::IsNullOrWhiteSpace($hostsFileContents)) -And ($hostsFileContents.Contains($hostsEntryLine))) { Write-Output 'Skipping, entry already exists.'; continue; }; try { Add-Content -Path $hostsFilePath -Value $hostsEntryLine -Encoding $hostsFileEncoding -ErrorAction Stop; Write-Output 'Successfully added the entry.'; } catch { Write-Error "^""Failed to add the entry. Error: $_"^""; continue; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: Disable Defender Antivirus "Block at First Sight" feature-
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus "Block at First Sight" feature
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'DisableBlockAtFirstSeen'; $value = $True; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -DisableBlockAtFirstSeen $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet!DisableBlockAtFirstSeen"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\SpyNet' /v 'DisableBlockAtFirstSeen' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Microsoft\Windows Defender\SpyNet!DisableBlockAtFirstSeen"
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$registryPath = ''HKLM\Software\Microsoft\Windows Defender\SpyNet'''+"^""`r`n"^""+'$data = ''1'''+"^""`r`n"^""+''+"^""`r`n"^""+'reg add ''HKLM\Software\Microsoft\Windows Defender\SpyNet'' `'+"^""`r`n"^""+'    /v ''DisableBlockAtFirstSeen'' `'+"^""`r`n"^""+'    /t ''REG_DWORD'' `'+"^""`r`n"^""+'    /d "^""$data"^"" `'+"^""`r`n"^""+'    /f'; Invoke-AsTrustedInstaller $cmd"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: Disable Defender Antivirus "Extended Cloud Check" feature-
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus "Extended Cloud Check" feature
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'CloudExtendedTimeout'; $value = '50'; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -CloudExtendedTimeout $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine!MpBafsExtendedTimeout"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine'; $data = '50'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine' /v 'MpBafsExtendedTimeout' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine!MpBafsExtendedTimeout"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine'; $data = '50'; reg add 'HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine' /v 'MpBafsExtendedTimeout' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable Defender Antivirus aggressive cloud protection--
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus aggressive cloud protection
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'CloudBlockLevel'; $value = '0'; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -CloudBlockLevel $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine!MpCloudBlockLevel"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\MpEngine' /v 'MpCloudBlockLevel' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine!MpCloudBlockLevel"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine'; $data = '2'; reg add 'HKLM\SOFTWARE\Microsoft\Windows Defender\MpEngine' /v 'MpCloudBlockLevel' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Disable Defender Antivirus cloud-based notifications---
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus cloud-based notifications
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates!SignatureDisableNotification"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates' /v 'SignatureDisableNotification' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Microsoft Antimalware\Signature Updates!SignatureDisableNotification"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Microsoft Antimalware\Signature Updates'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\Microsoft Antimalware\Signature Updates' /v 'SignatureDisableNotification' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable Defender Antivirus cloud protection reporting---
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus cloud protection reporting
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'MAPSReporting'; $value = '0'; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -MAPSReporting $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet!SpyNetReporting"
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$registryPath = ''HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet'''+"^""`r`n"^""+'$data = ''0'''+"^""`r`n"^""+''+"^""`r`n"^""+'reg add ''HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet'' `'+"^""`r`n"^""+'    /v ''SpyNetReporting'' `'+"^""`r`n"^""+'    /t ''REG_DWORD'' `'+"^""`r`n"^""+'    /d "^""$data"^"" `'+"^""`r`n"^""+'    /f'; Invoke-AsTrustedInstaller $cmd"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet!LocalSettingOverrideSpynetReporting"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' /v 'LocalSettingOverrideSpynetReporting' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet!SpynetReporting"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' /v 'SpynetReporting' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Defender Antivirus automatic file submission to Microsoft
echo --- Disable Defender Antivirus automatic file submission to Microsoft
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'SubmitSamplesConsent'; $value = '2'; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -SubmitSamplesConsent $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet!SubmitSamplesConsent"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet'; $data = '2'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet' /v 'SubmitSamplesConsent' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet!SubmitSamplesConsent"
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$registryPath = ''HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet'''+"^""`r`n"^""+'$data = ''2'''+"^""`r`n"^""+''+"^""`r`n"^""+'reg add ''HKLM\SOFTWARE\Microsoft\Windows Defender\Spynet'' `'+"^""`r`n"^""+'    /v ''SubmitSamplesConsent'' `'+"^""`r`n"^""+'    /t ''REG_DWORD'' `'+"^""`r`n"^""+'    /d "^""$data"^"" `'+"^""`r`n"^""+'    /f'; Invoke-AsTrustedInstaller $cmd"
:: ----------------------------------------------------------


:: Disable Defender Antivirus real-time security intelligence updates
echo --- Disable Defender Antivirus real-time security intelligence updates
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates!RealtimeSignatureDelivery"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\Signature Updates' /v 'RealtimeSignatureDelivery' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable "Malicious Software Reporting Tool" diagnostic data
echo --- Disable "Malicious Software Reporting Tool" diagnostic data
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\MRT!DontReportInfectionInformation"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\MRT'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\MRT' /v 'DontReportInfectionInformation' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable Defender Antivirus Watson event reporting-----
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus Watson event reporting
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting!DisableGenericRePorts"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting' /v 'DisableGenericRePorts' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting!DisableGenericRePorts"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Reporting' /v 'DisableGenericRePorts' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable Defender Antivirus telemetry-----------
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus telemetry
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'DisableCoreService1DSTelemetry'; $value = $False; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -DisableCoreService1DSTelemetry $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\Features!DisableCoreService1DSTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\Features'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\Features' /v 'DisableCoreService1DSTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService!DisableCoreService1DSTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$registryPath = ''HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService'''+"^""`r`n"^""+'$data = ''1'''+"^""`r`n"^""+''+"^""`r`n"^""+'reg add ''HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService'' `'+"^""`r`n"^""+'    /v ''DisableCoreService1DSTelemetry'' `'+"^""`r`n"^""+'    /t ''REG_DWORD'' `'+"^""`r`n"^""+'    /d "^""$data"^"" `'+"^""`r`n"^""+'    /f'; Invoke-AsTrustedInstaller $cmd"
:: ----------------------------------------------------------


:: Disable Defender Antivirus remote experimentation and configurations
echo --- Disable Defender Antivirus remote experimentation and configurations
PowerShell -ExecutionPolicy Unrestricted -Command "$propertyName = 'DisableCoreServiceECSIntegration'; $value = $False; if((Get-MpPreference -ErrorAction Ignore).$propertyName -eq $value) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is already `"^""$value`"^"" as desired."^""; exit 0; }; $command = Get-Command 'Set-MpPreference' -ErrorAction Ignore; if (!$command) { Write-Warning 'Skipping. Command not found: "^""Set-MpPreference"^"".'; exit 0; }; if(!$command.Parameters.Keys.Contains($propertyName)) { Write-Host "^""Skipping. `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; }; try { Invoke-Expression "^""$($command.Name) -Force -$propertyName `$value -ErrorAction Stop"^""; Set-MpPreference -Force -DisableCoreServiceECSIntegration $value -ErrorAction Stop; Write-Host "^""Successfully set `"^""$propertyName`"^"" to `"^""$value`"^""."^""; exit 0; } catch { if ( $_.FullyQualifiedErrorId -like '*0x800106ba*') { Write-Warning "^""Cannot $($command.Name): Defender service (WinDefend) is not running. Try to enable it (revert) and re-run this?"^""; exit 0; } elseif (($_ | Out-String) -like '*Cannot convert*') { Write-Host "^""Skipping. Argument `"^""$value`"^"" for property `"^""$propertyName`"^"" is not supported for `"^""$($command.Name)`"^""."^""; exit 0; } else { Write-Error "^""Failed to set using $($command.Name): $_"^""; exit 1; }; }"
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows Defender\Features!DisableCoreServiceECSIntegration"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows Defender\Features'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows Defender\Features' /v 'DisableCoreServiceECSIntegration' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService!DisableCoreServiceECSIntegration"
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$registryPath = ''HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService'''+"^""`r`n"^""+'$data = ''1'''+"^""`r`n"^""+''+"^""`r`n"^""+'reg add ''HKLM\SOFTWARE\Microsoft\Windows Defender\CoreService'' `'+"^""`r`n"^""+'    /v ''DisableCoreServiceECSIntegration'' `'+"^""`r`n"^""+'    /t ''REG_DWORD'' `'+"^""`r`n"^""+'    /d "^""$data"^"" `'+"^""`r`n"^""+'    /f'; Invoke-AsTrustedInstaller $cmd"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable Defender Antivirus Azure data collection-----
:: ----------------------------------------------------------
echo --- Disable Defender Antivirus Azure data collection
:: Soft delete files matching pattern: "%PROGRAMFILES%\Windows Defender\MpAzSubmit.dll"  as TrustedInstaller
PowerShell -ExecutionPolicy Unrestricted -Command "function Invoke-AsTrustedInstaller($Script) { $principalSid = [System.Security.Principal.SecurityIdentifier]::new('S-1-5-80-956008885-3418522649-1831038044-1853292631-2271478464'); $principalName = $principalSid.Translate([System.Security.Principal.NTAccount]); $streamFile = New-TemporaryFile; $scriptFile = New-TemporaryFile; try { $scriptFile = Rename-Item -LiteralPath $scriptFile -NewName ($scriptFile.BaseName + '.ps1') -Force -PassThru; $Script | Out-File $scriptFile -Encoding UTF8; $taskName = "^""privacy$([char]0x002E)sexy invoke"^""; schtasks.exe /delete /tn $taskName /f 2>&1 | Out-Null; $executionCommand = "^""powershell.exe -ExecutionPolicy Bypass -File '$scriptFile' *>&1 | Out-File -FilePath '$streamFile' -Encoding UTF8"^""; $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "^""-ExecutionPolicy Bypass -Command `"^""$executionCommand`"^"""^""; $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries; Register-ScheduledTask -TaskName $taskName -Action $action -Settings $settings -Force -ErrorAction Stop | Out-Null; try { ($scheduleService = New-Object -ComObject Schedule.Service).Connect(); $scheduleService.GetFolder('\').GetTask($taskName).RunEx($null, 0, 0, $principalName) | Out-Null; $timeout = (Get-Date).AddMinutes(5); Write-Host "^""Running as $principalName"^""; while ((Get-ScheduledTaskInfo $taskName).LastTaskResult -eq 267009) { Start-Sleep -Milliseconds 200; if ((Get-Date) -gt $timeout) { Write-Warning 'Skipping: Timeout'; break; }; }; if (($result = (Get-ScheduledTaskInfo $taskName).LastTaskResult) -ne 0) { Write-Error "^""Failed, due to exit code: $result."^""; } } finally { schtasks.exe /delete /tn $taskName /f | Out-Null; }; Get-Content $streamFile } finally { Remove-Item $streamFile, $scriptFile; }; }; $cmd = '$pathGlobPattern = "^""%PROGRAMFILES%\Windows Defender\MpAzSubmit.dll"^""'+"^""`r`n"^""+'$expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern)'+"^""`r`n"^""+'Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""'+"^""`r`n"^""+''+"^""`r`n"^""+'$renamedCount   = 0'+"^""`r`n"^""+'$skippedCount   = 0'+"^""`r`n"^""+'$failedCount    = 0'+"^""`r`n"^""+''+"^""`r`n"^""+'$foundAbsolutePaths = @()'+"^""`r`n"^""+''+"^""`r`n"^""+'try {'+"^""`r`n"^""+'    $foundAbsolutePaths += @('+"^""`r`n"^""+'        Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName'+"^""`r`n"^""+'    )'+"^""`r`n"^""+'} catch [System.Management.Automation.ItemNotFoundException] {'+"^""`r`n"^""+'    <# Swallow, do not run `Test-Path` before, it''s unreliable for globs requiring extra permissions #>'+"^""`r`n"^""+'}'+"^""`r`n"^""+'$foundAbsolutePaths = $foundAbsolutePaths   `'+"^""`r`n"^""+'    | Select-Object -Unique                 `'+"^""`r`n"^""+'    | Sort-Object -Property { $_.Length } -Descending'+"^""`r`n"^""+'if (!$foundAbsolutePaths) {'+"^""`r`n"^""+'    Write-Host ''Skipping, no items available.'''+"^""`r`n"^""+'    exit 0'+"^""`r`n"^""+'}'+"^""`r`n"^""+'Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""'+"^""`r`n"^""+'foreach ($path in $foundAbsolutePaths) {'+"^""`r`n"^""+'    if (Test-Path -Path $path -PathType Container) {'+"^""`r`n"^""+'    Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""'+"^""`r`n"^""+'    $skippedCount++'+"^""`r`n"^""+'    continue'+"^""`r`n"^""+'}'+"^""`r`n"^""+'if($revert -eq $true) {'+"^""`r`n"^""+'    if (-not $path.EndsWith(''.OLD'')) {'+"^""`r`n"^""+'        Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""'+"^""`r`n"^""+'        $skippedCount++'+"^""`r`n"^""+'        continue'+"^""`r`n"^""+'    }'+"^""`r`n"^""+'} else {'+"^""`r`n"^""+'    if ($path.EndsWith(''.OLD'')) {'+"^""`r`n"^""+'        Write-Host "^""Skipping backup file: `"^""$path`"^""."^""'+"^""`r`n"^""+'        $skippedCount++'+"^""`r`n"^""+'        continue'+"^""`r`n"^""+'    }'+"^""`r`n"^""+'}'+"^""`r`n"^""+'$originalFilePath = $path'+"^""`r`n"^""+'Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""'+"^""`r`n"^""+'if (-Not (Test-Path $originalFilePath)) {'+"^""`r`n"^""+'    Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""'+"^""`r`n"^""+'    $skippedCount++'+"^""`r`n"^""+'    exit 0'+"^""`r`n"^""+'}'+"^""`r`n"^""+''+"^""`r`n"^""+'if ($revert -eq $true) {'+"^""`r`n"^""+'    $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4)'+"^""`r`n"^""+'} else {'+"^""`r`n"^""+'    $newFilePath = "^""$($originalFilePath).OLD"^""'+"^""`r`n"^""+'}'+"^""`r`n"^""+'try {'+"^""`r`n"^""+'    Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop'+"^""`r`n"^""+'    Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""'+"^""`r`n"^""+'    $renamedCount++'+"^""`r`n"^""+'    '+"^""`r`n"^""+'} catch {'+"^""`r`n"^""+'    Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""'+"^""`r`n"^""+'    $failedCount++'+"^""`r`n"^""+'    '+"^""`r`n"^""+'}'+"^""`r`n"^""+'}'+"^""`r`n"^""+'if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) {'+"^""`r`n"^""+'    Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""'+"^""`r`n"^""+'}'+"^""`r`n"^""+'if ($failedCount -gt 0) {'+"^""`r`n"^""+'    Write-Warning "^""Failed to process $($failedCount) items."^""'+"^""`r`n"^""+'}'+"^""`r`n"^""+''; Invoke-AsTrustedInstaller $cmd"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Disable online tips--------------------
:: ----------------------------------------------------------
echo --- Disable online tips
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\System!AllowOnlineTips"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' /v 'AllowOnlineTips' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable "Internet File Association" service--------
:: ----------------------------------------------------------
echo --- Disable "Internet File Association" service
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoInternetOpenWith"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoInternetOpenWith' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable "Order Prints" picture task------------
:: ----------------------------------------------------------
echo --- Disable "Order Prints" picture task
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoOnlinePrintsWizard"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoOnlinePrintsWizard' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable "Publish to Web" option for files and folders---
:: ----------------------------------------------------------
echo --- Disable "Publish to Web" option for files and folders
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoPublishingWizard"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoPublishingWizard' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable provider list downloads for wizards--------
:: ----------------------------------------------------------
echo --- Disable provider list downloads for wizards
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoWebServices"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoWebServices' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable history of recently opened documents-------
:: ----------------------------------------------------------
echo --- Disable history of recently opened documents
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer!NoRecentDocsHistory"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'NoRecentDocsHistory' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Clear recently opened document history upon exit-----
:: ----------------------------------------------------------
echo --- Clear recently opened document history upon exit
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer!ClearRecentDocsOnExit"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'ClearRecentDocsOnExit' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable Live Tiles push notifications-----------
:: ----------------------------------------------------------
echo --- Disable Live Tiles push notifications
:: Set the registry value: "HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications!NoTileApplicationNotification"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications'; $data = '1'; reg add 'HKCU\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications' /v 'NoTileApplicationNotification' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable the display of recently used files in Quick Access
echo --- Disable the display of recently used files in Quick Access
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer!ShowRecent"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer' /v 'ShowRecent' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Delete the registry value "(Default)" from the key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}'; $valueName = '(Default)'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: Delete the registry value "(Default)" from the key "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\HomeFolderDesktop\NameSpace\DelegateFolders\{3134ef9c-6b18-4996-ad04-ed5912e00eb5}'; $valueName = '(Default)'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: Disable hibernation for faster startup and to avoid sensitive data storage
echo --- Disable hibernation for faster startup and to avoid sensitive data storage
powercfg -h off
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Disable recent apps--------------------
:: ----------------------------------------------------------
echo --- Disable recent apps
:: Set the registry value: "HKCU\Software\Policies\Microsoft\Windows\EdgeUI!DisableRecentApps"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\Windows\EdgeUI'; $data = '1'; reg add 'HKCU\Software\Policies\Microsoft\Windows\EdgeUI' /v 'DisableRecentApps' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Disable app usage tracking----------------
:: ----------------------------------------------------------
echo --- Disable app usage tracking
:: Set the registry value: "HKCU\Software\Policies\Microsoft\Windows\EdgeUI!DisableMFUTracking"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\Windows\EdgeUI'; $data = '1'; reg add 'HKCU\Software\Policies\Microsoft\Windows\EdgeUI' /v 'DisableMFUTracking' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Remove insecure "Print 3D" app--------------
:: ----------------------------------------------------------
echo --- Remove insecure "Print 3D" app
:: Uninstall 'Microsoft.Print3D' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Print3D' | Remove-AppxPackage"
:: Mark 'Microsoft.Print3D' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Print3D_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Print3D_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Soft delete files matching pattern: "%SYSTEMROOT%\SystemApps\Windows.Print3D_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\SystemApps\Windows.Print3D_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMROOT%\$(("Windows.Print3D" -Split '\.')[-1])\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\$(("^""Windows.Print3D"^"" -Split '\.')[-1])\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMDRIVE%\Program Files\WindowsApps\Windows.Print3D_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMDRIVE%\Program Files\WindowsApps\Windows.Print3D_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Enable removal of system app 'Windows.Print3D' by marking it as "EndOfLife"
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.Print3D_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.Print3D_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Uninstall 'Windows.Print3D' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Windows.Print3D' | Remove-AppxPackage"
:: Mark 'Windows.Print3D' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Windows.Print3D_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Windows.Print3D_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove the registry key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.Print3D_cw5n1h2txyewy" (Revert 'Windows.Print3D' to its default, non-removable state.)
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.Print3D_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Soft delete files matching pattern: "%LOCALAPPDATA%\Packages\Windows.Print3D_cw5n1h2txyewy\*"  
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%LOCALAPPDATA%\Packages\Windows.Print3D_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }"
:: Soft delete files matching pattern: "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Windows.Print3D_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Windows.Print3D_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Microsoft 3D Builder" app-------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft 3D Builder" app
:: Uninstall 'Microsoft.3DBuilder' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.3DBuilder' | Remove-AppxPackage"
:: Mark 'Microsoft.3DBuilder' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.3DBuilder_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.3DBuilder_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Remove "3D Viewer" app------------------
:: ----------------------------------------------------------
echo --- Remove "3D Viewer" app
:: Uninstall 'Microsoft.Microsoft3DViewer' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Microsoft3DViewer' | Remove-AppxPackage"
:: Mark 'Microsoft.Microsoft3DViewer' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Microsoft3DViewer_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Microsoft3DViewer_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Remove "MSN Weather" app-----------------
:: ----------------------------------------------------------
echo --- Remove "MSN Weather" app
:: Uninstall 'Microsoft.BingWeather' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.BingWeather' | Remove-AppxPackage"
:: Mark 'Microsoft.BingWeather' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingWeather_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingWeather_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Remove "MSN Sports" app------------------
:: ----------------------------------------------------------
echo --- Remove "MSN Sports" app
:: Uninstall 'Microsoft.BingSports' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.BingSports' | Remove-AppxPackage"
:: Mark 'Microsoft.BingSports' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingSports_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingSports_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove "Microsoft News" app----------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft News" app
:: Uninstall 'Microsoft.BingNews' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.BingNews' | Remove-AppxPackage"
:: Mark 'Microsoft.BingNews' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingNews_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingNews_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Remove "MSN Money" app------------------
:: ----------------------------------------------------------
echo --- Remove "MSN Money" app
:: Uninstall 'Microsoft.BingFinance' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.BingFinance' | Remove-AppxPackage"
:: Mark 'Microsoft.BingFinance' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingFinance_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.BingFinance_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Remove "Sway" app---------------------
:: ----------------------------------------------------------
echo --- Remove "Sway" app
:: Uninstall 'Microsoft.Office.Sway' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Office.Sway' | Remove-AppxPackage"
:: Mark 'Microsoft.Office.Sway' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Office.Sway_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Office.Sway_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Remove "Xbox Console Companion" app------------
:: ----------------------------------------------------------
echo --- Remove "Xbox Console Companion" app
:: Uninstall 'Microsoft.XboxApp' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.XboxApp' | Remove-AppxPackage"
:: Mark 'Microsoft.XboxApp' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxApp_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxApp_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Remove "Xbox Live in-game experience" app---------
:: ----------------------------------------------------------
echo --- Remove "Xbox Live in-game experience" app
:: Uninstall 'Microsoft.Xbox.TCUI' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Xbox.TCUI' | Remove-AppxPackage"
:: Mark 'Microsoft.Xbox.TCUI' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Xbox.TCUI_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Xbox.TCUI_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove "Xbox Game Bar" app----------------
:: ----------------------------------------------------------
echo --- Remove "Xbox Game Bar" app
:: Uninstall 'Microsoft.XboxGamingOverlay' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.XboxGamingOverlay' | Remove-AppxPackage"
:: Mark 'Microsoft.XboxGamingOverlay' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxGamingOverlay_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Xbox Game Bar Plugin" app-------------
:: ----------------------------------------------------------
echo --- Remove "Xbox Game Bar Plugin" app
:: Uninstall 'Microsoft.XboxGameOverlay' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.XboxGameOverlay' | Remove-AppxPackage"
:: Mark 'Microsoft.XboxGameOverlay' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxGameOverlay_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxGameOverlay_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: Remove "Xbox Identity Provider" app (breaks Xbox sign-in)-
:: ----------------------------------------------------------
echo --- Remove "Xbox Identity Provider" app (breaks Xbox sign-in)
:: Uninstall 'Microsoft.XboxIdentityProvider' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.XboxIdentityProvider' | Remove-AppxPackage"
:: Mark 'Microsoft.XboxIdentityProvider' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxIdentityProvider_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Remove "Xbox Speech To Text Overlay" app---------
:: ----------------------------------------------------------
echo --- Remove "Xbox Speech To Text Overlay" app
:: Uninstall 'Microsoft.XboxSpeechToTextOverlay' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.XboxSpeechToTextOverlay' | Remove-AppxPackage"
:: Mark 'Microsoft.XboxSpeechToTextOverlay' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.XboxSpeechToTextOverlay_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove "Phone Companion" app---------------
:: ----------------------------------------------------------
echo --- Remove "Phone Companion" app
:: Uninstall 'Microsoft.WindowsPhone' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.WindowsPhone' | Remove-AppxPackage"
:: Mark 'Microsoft.WindowsPhone' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsPhone_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsPhone_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove "Microsoft Phone" app---------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Phone" app
:: Uninstall 'Microsoft.CommsPhone' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.CommsPhone' | Remove-AppxPackage"
:: Mark 'Microsoft.CommsPhone' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.CommsPhone_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.CommsPhone_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Remove "Phone Link" app------------------
:: ----------------------------------------------------------
echo --- Remove "Phone Link" app
:: Uninstall 'Microsoft.YourPhone' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.YourPhone' | Remove-AppxPackage"
:: Mark 'Microsoft.YourPhone' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.YourPhone_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.YourPhone_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Remove "Call" app---------------------
:: ----------------------------------------------------------
echo --- Remove "Call" app
:: Enable removal of system app 'Microsoft.Windows.CallingShellApp' by marking it as "EndOfLife"
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Uninstall 'Microsoft.Windows.CallingShellApp' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Windows.CallingShellApp' | Remove-AppxPackage"
:: Mark 'Microsoft.Windows.CallingShellApp' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove the registry key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy" (Revert 'Microsoft.Windows.CallingShellApp' to its default, non-removable state.)
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.CallingShellApp_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Remove "Candy Crush Saga" app---------------
:: ----------------------------------------------------------
echo --- Remove "Candy Crush Saga" app
:: Uninstall 'king.com.CandyCrushSaga' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'king.com.CandyCrushSaga' | Remove-AppxPackage"
:: Mark 'king.com.CandyCrushSaga' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\king.com.CandyCrushSaga_kgqvnymyfvs32" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\king.com.CandyCrushSaga_kgqvnymyfvs32'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Candy Crush Soda Saga" app------------
:: ----------------------------------------------------------
echo --- Remove "Candy Crush Soda Saga" app
:: Uninstall 'king.com.CandyCrushSodaSaga' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'king.com.CandyCrushSodaSaga' | Remove-AppxPackage"
:: Mark 'king.com.CandyCrushSodaSaga' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\king.com.CandyCrushSodaSaga_kgqvnymyfvs32" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\king.com.CandyCrushSodaSaga_kgqvnymyfvs32'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Remove "Shazam" app--------------------
:: ----------------------------------------------------------
echo --- Remove "Shazam" app
:: Uninstall 'ShazamEntertainmentLtd.Shazam' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'ShazamEntertainmentLtd.Shazam' | Remove-AppxPackage"
:: Mark 'ShazamEntertainmentLtd.Shazam' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ShazamEntertainmentLtd.Shazam_pqbynwjfrbcg4" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ShazamEntertainmentLtd.Shazam_pqbynwjfrbcg4'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Remove "Flipboard" app------------------
:: ----------------------------------------------------------
echo --- Remove "Flipboard" app
:: Uninstall 'Flipboard.Flipboard' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Flipboard.Flipboard' | Remove-AppxPackage"
:: Mark 'Flipboard.Flipboard' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Flipboard.Flipboard_3f5azkryzdbc4" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Flipboard.Flipboard_3f5azkryzdbc4'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Remove "Twitter" app-------------------
:: ----------------------------------------------------------
echo --- Remove "Twitter" app
:: Uninstall '9E2F88E3.Twitter' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage '9E2F88E3.Twitter' | Remove-AppxPackage"
:: Mark '9E2F88E3.Twitter' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\9E2F88E3.Twitter_wgeqdkkx372wm" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\9E2F88E3.Twitter_wgeqdkkx372wm'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Remove "iHeart: Radio, Music, Podcasts" app--------
:: ----------------------------------------------------------
echo --- Remove "iHeart: Radio, Music, Podcasts" app
:: Uninstall 'ClearChannelRadioDigital.iHeartRadio' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'ClearChannelRadioDigital.iHeartRadio' | Remove-AppxPackage"
:: Mark 'ClearChannelRadioDigital.iHeartRadio' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ClearChannelRadioDigital.iHeartRadio_a76a11dkgb644" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ClearChannelRadioDigital.iHeartRadio_a76a11dkgb644'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Remove "Duolingo - Language Lessons" app---------
:: ----------------------------------------------------------
echo --- Remove "Duolingo - Language Lessons" app
:: Uninstall 'D5EA27B7.Duolingo-LearnLanguagesforFree' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'D5EA27B7.Duolingo-LearnLanguagesforFree' | Remove-AppxPackage"
:: Mark 'D5EA27B7.Duolingo-LearnLanguagesforFree' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\D5EA27B7.Duolingo-LearnLanguagesforFree_yx6k7tf7xvsea" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\D5EA27B7.Duolingo-LearnLanguagesforFree_yx6k7tf7xvsea'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Remove "Adobe Photoshop Express" app-----------
:: ----------------------------------------------------------
echo --- Remove "Adobe Photoshop Express" app
:: Uninstall 'AdobeSystemsIncorporated.AdobePhotoshopExpress' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'AdobeSystemsIncorporated.AdobePhotoshopExpress' | Remove-AppxPackage"
:: Mark 'AdobeSystemsIncorporated.AdobePhotoshopExpress' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\AdobeSystemsIncorporated.AdobePhotoshopExpress_ynb6jyjzte8ga" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\AdobeSystemsIncorporated.AdobePhotoshopExpress_ynb6jyjzte8ga'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Remove "Pandora" app-------------------
:: ----------------------------------------------------------
echo --- Remove "Pandora" app
:: Uninstall 'PandoraMediaInc.29680B314EFC2' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'PandoraMediaInc.29680B314EFC2' | Remove-AppxPackage"
:: Mark 'PandoraMediaInc.29680B314EFC2' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\PandoraMediaInc.29680B314EFC2_n619g4d5j0fnw" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\PandoraMediaInc.29680B314EFC2_n619g4d5j0fnw'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove "Eclipse Manager" app---------------
:: ----------------------------------------------------------
echo --- Remove "Eclipse Manager" app
:: Uninstall '46928bounde.EclipseManager' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage '46928bounde.EclipseManager' | Remove-AppxPackage"
:: Mark '46928bounde.EclipseManager' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\46928bounde.EclipseManager_a5h4egax66k6y" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\46928bounde.EclipseManager_a5h4egax66k6y'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Remove "Code Writer" app-----------------
:: ----------------------------------------------------------
echo --- Remove "Code Writer" app
:: Uninstall 'ActiproSoftwareLLC.562882FEEB491' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'ActiproSoftwareLLC.562882FEEB491' | Remove-AppxPackage"
:: Mark 'ActiproSoftwareLLC.562882FEEB491' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ActiproSoftwareLLC.562882FEEB491_24pqs290vpjk0" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\ActiproSoftwareLLC.562882FEEB491_24pqs290vpjk0'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Remove "Spotify - Music and Podcasts" app---------
:: ----------------------------------------------------------
echo --- Remove "Spotify - Music and Podcasts" app
:: Uninstall 'SpotifyAB.SpotifyMusic' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'SpotifyAB.SpotifyMusic' | Remove-AppxPackage"
:: Mark 'SpotifyAB.SpotifyMusic' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\SpotifyAB.SpotifyMusic_zpdnekdrzrea0" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\SpotifyAB.SpotifyMusic_zpdnekdrzrea0'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Remove "My People" app------------------
:: ----------------------------------------------------------
echo --- Remove "My People" app
:: Soft delete files matching pattern: "%SYSTEMROOT%\SystemApps\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\SystemApps\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMROOT%\$(("Microsoft.Windows.PeopleExperienceHost" -Split '\.')[-1])\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\$(("^""Microsoft.Windows.PeopleExperienceHost"^"" -Split '\.')[-1])\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Enable removal of system app 'Microsoft.Windows.PeopleExperienceHost' by marking it as "EndOfLife"
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Uninstall 'Microsoft.Windows.PeopleExperienceHost' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Windows.PeopleExperienceHost' | Remove-AppxPackage"
:: Mark 'Microsoft.Windows.PeopleExperienceHost' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove the registry key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy" (Revert 'Microsoft.Windows.PeopleExperienceHost' to its default, non-removable state.)
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Soft delete files matching pattern: "%LOCALAPPDATA%\Packages\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*"  
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%LOCALAPPDATA%\Packages\Microsoft.Windows.PeopleExperienceHost_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }"
:: Soft delete files matching pattern: "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.Windows.PeopleExperienceHost_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Remove "Windows Feedback" app---------------
:: ----------------------------------------------------------
echo --- Remove "Windows Feedback" app
:: Soft delete files matching pattern: "%SYSTEMROOT%\SystemApps\Microsoft.WindowsFeedback_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\SystemApps\Microsoft.WindowsFeedback_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMROOT%\$(("Microsoft.WindowsFeedback" -Split '\.')[-1])\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\$(("^""Microsoft.WindowsFeedback"^"" -Split '\.')[-1])\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMDRIVE%\Program Files\WindowsApps\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Enable removal of system app 'Microsoft.WindowsFeedback' by marking it as "EndOfLife"
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.WindowsFeedback_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.WindowsFeedback_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Uninstall 'Microsoft.WindowsFeedback' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.WindowsFeedback' | Remove-AppxPackage"
:: Mark 'Microsoft.WindowsFeedback' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsFeedback_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsFeedback_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove the registry key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.WindowsFeedback_cw5n1h2txyewy" (Revert 'Microsoft.WindowsFeedback' to its default, non-removable state.)
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Microsoft.WindowsFeedback_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Soft delete files matching pattern: "%LOCALAPPDATA%\Packages\Microsoft.WindowsFeedback_cw5n1h2txyewy\*"  
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%LOCALAPPDATA%\Packages\Microsoft.WindowsFeedback_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }"
:: Soft delete files matching pattern: "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Microsoft.WindowsFeedback_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Remove "Camera Barcode Scanner" app------------
:: ----------------------------------------------------------
echo --- Remove "Camera Barcode Scanner" app
:: Soft delete files matching pattern: "%SYSTEMROOT%\SystemApps\Windows.CBSPreview_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\SystemApps\Windows.CBSPreview_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMROOT%\$(("Windows.CBSPreview" -Split '\.')[-1])\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\$(("^""Windows.CBSPreview"^"" -Split '\.')[-1])\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Soft delete files matching pattern: "%SYSTEMDRIVE%\Program Files\WindowsApps\Windows.CBSPreview_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMDRIVE%\Program Files\WindowsApps\Windows.CBSPreview_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: Enable removal of system app 'Windows.CBSPreview' by marking it as "EndOfLife"
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.CBSPreview_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.CBSPreview_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Uninstall 'Windows.CBSPreview' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Windows.CBSPreview' | Remove-AppxPackage"
:: Mark 'Windows.CBSPreview' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Windows.CBSPreview_cw5n1h2txyewy" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Windows.CBSPreview_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Remove the registry key "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.CBSPreview_cw5n1h2txyewy" (Revert 'Windows.CBSPreview' to its default, non-removable state.)
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\EndOfLife\$CURRENT_USER_SID\Windows.CBSPreview_cw5n1h2txyewy'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; $userSid = (New-Object System.Security.Principal.NTAccount($env:USERNAME)).Translate([Security.Principal.SecurityIdentifier]).Value; $registryPath = $registryPath.Replace('$CURRENT_USER_SID', $userSid); Write-Host "^""Removing registry key at `"^""$registryPath`"^""."^""; if (-not (Test-Path -LiteralPath $registryPath)) { Write-Host "^""Skipping, no action needed, registry key `"^""$registryPath`"^"" does not exist."^""; exit 0; }; try { Remove-Item -LiteralPath $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully removed the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to remove the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: Soft delete files matching pattern: "%LOCALAPPDATA%\Packages\Windows.CBSPreview_cw5n1h2txyewy\*"  
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%LOCALAPPDATA%\Packages\Windows.CBSPreview_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }"
:: Soft delete files matching pattern: "%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Windows.CBSPreview_*_cw5n1h2txyewy\*" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%PROGRAMDATA%\Microsoft\Windows\AppRepository\Packages\Windows.CBSPreview_*_cw5n1h2txyewy\*"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Remove "Cortana" app-------------------
:: ----------------------------------------------------------
echo --- Remove "Cortana" app
:: Uninstall 'Microsoft.549981C3F5F10' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.549981C3F5F10' | Remove-AppxPackage"
:: Mark 'Microsoft.549981C3F5F10' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.549981C3F5F10_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.549981C3F5F10_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove "Microsoft Tips" app----------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Tips" app
:: Uninstall 'Microsoft.Getstarted' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Getstarted' | Remove-AppxPackage"
:: Mark 'Microsoft.Getstarted' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Getstarted_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Getstarted_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Remove "Microsoft Messaging" app-------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Messaging" app
:: Uninstall 'Microsoft.Messaging' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Messaging' | Remove-AppxPackage"
:: Mark 'Microsoft.Messaging' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Messaging_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Messaging_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Mixed Reality Portal" app-------------
:: ----------------------------------------------------------
echo --- Remove "Mixed Reality Portal" app
:: Uninstall 'Microsoft.MixedReality.Portal' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.MixedReality.Portal' | Remove-AppxPackage"
:: Mark 'Microsoft.MixedReality.Portal' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MixedReality.Portal_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MixedReality.Portal_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove "Feedback Hub" app-----------------
:: ----------------------------------------------------------
echo --- Remove "Feedback Hub" app
:: Uninstall 'Microsoft.WindowsFeedbackHub' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.WindowsFeedbackHub' | Remove-AppxPackage"
:: Mark 'Microsoft.WindowsFeedbackHub' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsFeedbackHub_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Remove "Paint 3D" app-------------------
:: ----------------------------------------------------------
echo --- Remove "Paint 3D" app
:: Uninstall 'Microsoft.MSPaint' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.MSPaint' | Remove-AppxPackage"
:: Mark 'Microsoft.MSPaint' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MSPaint_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MSPaint_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove "Windows Maps" app-----------------
:: ----------------------------------------------------------
echo --- Remove "Windows Maps" app
:: Uninstall 'Microsoft.WindowsMaps' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.WindowsMaps' | Remove-AppxPackage"
:: Mark 'Microsoft.WindowsMaps' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsMaps_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.WindowsMaps_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Minecraft for Windows" app------------
:: ----------------------------------------------------------
echo --- Remove "Minecraft for Windows" app
:: Uninstall 'Microsoft.MinecraftUWP' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.MinecraftUWP' | Remove-AppxPackage"
:: Mark 'Microsoft.MinecraftUWP' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MinecraftUWP_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MinecraftUWP_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Remove "Microsoft People" app---------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft People" app
:: Uninstall 'Microsoft.People' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.People' | Remove-AppxPackage"
:: Mark 'Microsoft.People' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.People_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.People_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove "Microsoft Pay" app----------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Pay" app
:: Uninstall 'Microsoft.Wallet' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Wallet' | Remove-AppxPackage"
:: Mark 'Microsoft.Wallet' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Wallet_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Wallet_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove "Mobile Plans" app-----------------
:: ----------------------------------------------------------
echo --- Remove "Mobile Plans" app
:: Uninstall 'Microsoft.OneConnect' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.OneConnect' | Remove-AppxPackage"
:: Mark 'Microsoft.OneConnect' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.OneConnect_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.OneConnect_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Remove "Microsoft Solitaire Collection" app--------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Solitaire Collection" app
:: Uninstall 'Microsoft.MicrosoftSolitaireCollection' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.MicrosoftSolitaireCollection' | Remove-AppxPackage"
:: Mark 'Microsoft.MicrosoftSolitaireCollection' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftSolitaireCollection_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Remove "Microsoft Sticky Notes" app------------
:: ----------------------------------------------------------
echo --- Remove "Microsoft Sticky Notes" app
:: Uninstall 'Microsoft.MicrosoftStickyNotes' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.MicrosoftStickyNotes' | Remove-AppxPackage"
:: Mark 'Microsoft.MicrosoftStickyNotes' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.MicrosoftStickyNotes_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------------Remove "Skype" app--------------------
:: ----------------------------------------------------------
echo --- Remove "Skype" app
:: Uninstall 'Microsoft.SkypeApp' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.SkypeApp' | Remove-AppxPackage"
:: Mark 'Microsoft.SkypeApp' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.SkypeApp_kzf8qxf38zg5c" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.SkypeApp_kzf8qxf38zg5c'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Remove "GroupMe" app-------------------
:: ----------------------------------------------------------
echo --- Remove "GroupMe" app
:: Uninstall 'Microsoft.GroupMe10' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.GroupMe10' | Remove-AppxPackage"
:: Mark 'Microsoft.GroupMe10' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.GroupMe10_kzf8qxf38zg5c" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.GroupMe10_kzf8qxf38zg5c'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Remove "Microsoft To Do: Lists, Tasks & Reminders" app--
:: ----------------------------------------------------------
echo --- Remove "Microsoft To Do: Lists, Tasks ^& Reminders" app
:: Uninstall 'Microsoft.Todos' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.Todos' | Remove-AppxPackage"
:: Mark 'Microsoft.Todos' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Todos_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.Todos_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Remove "Network Speed Test" app--------------
:: ----------------------------------------------------------
echo --- Remove "Network Speed Test" app
:: Uninstall 'Microsoft.NetworkSpeedTest' Store app
PowerShell -ExecutionPolicy Unrestricted -Command "Get-AppxPackage 'Microsoft.NetworkSpeedTest' | Remove-AppxPackage"
:: Mark 'Microsoft.NetworkSpeedTest' as deprovisioned to block reinstall during Windows updates.
:: Create "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.NetworkSpeedTest_8wekyb3d8bbwe" registry key
PowerShell -ExecutionPolicy Unrestricted -Command "$keyPath='HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned\Microsoft.NetworkSpeedTest_8wekyb3d8bbwe'; $registryHive = $keyPath.Split('\')[0]; $registryPath = "^""$($registryHive):$($keyPath.Substring($registryHive.Length))"^""; if (Test-Path $registryPath) { Write-Host "^""Skipping, no action needed, registry path `"^""$registryPath`"^"" already exists."^""; exit 0; }; try { New-Item -Path $registryPath -Force -ErrorAction Stop | Out-Null; Write-Host "^""Successfully created the registry key at path `"^""$registryPath`"^""."^""; } catch { Write-Error "^""Failed to create the registry key at path `"^""$registryPath`"^"": $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Kill OneDrive process-------------------
:: ----------------------------------------------------------
echo --- Kill OneDrive process
:: Check and terminate the running process "OneDrive.exe"
tasklist /fi "ImageName eq OneDrive.exe" /fo csv 2>NUL | find /i "OneDrive.exe">NUL && (
    echo OneDrive.exe is running and will be killed.
    taskkill /f /im OneDrive.exe
) || (
    echo Skipping, OneDrive.exe is not running.
)
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Remove OneDrive from startup---------------
:: ----------------------------------------------------------
echo --- Remove OneDrive from startup
:: Delete the registry value "OneDrive" from the key "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run'; $valueName = 'OneDrive'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Remove OneDrive through official installer--------
:: ----------------------------------------------------------
echo --- Remove OneDrive through official installer
if exist "%SYSTEMROOT%\System32\OneDriveSetup.exe" (
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall
) else (
    if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
        "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall
    ) else (
        echo Failed to uninstall, uninstaller could not be found. 1>&2
    )
)
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Remove OneDrive user data and synced folders-------
:: ----------------------------------------------------------
echo --- Remove OneDrive user data and synced folders
:: Delete directory  : "%USERPROFILE%\OneDrive*"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%USERPROFILE%\OneDrive*'; if (-Not $directoryGlob.EndsWith('\')) { $directoryGlob += '\' }; $directoryGlob )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $oneDriveUserFolderPattern = [System.Environment]::ExpandEnvironmentVariables('%USERPROFILE%\OneDrive') + '*'; while ($true) { <# Loop to control the execution of the subsequent code #>; try { $userShellFoldersRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'; if (-not (Test-Path $userShellFoldersRegistryPath)) { Write-Output "^""Skipping verification: The registry path for user shell folders is missing: `"^""$userShellFoldersRegistryPath`"^"""^""; break; }; $userShellFoldersRegistryKeys = Get-ItemProperty -Path $userShellFoldersRegistryPath; $userShellFoldersEntries = @($userShellFoldersRegistryKeys.PSObject.Properties); if ($userShellFoldersEntries.Count -eq 0) { Write-Warning "^""Skipping verification: No entries found for user shell folders in the registry: `"^""$userShellFoldersRegistryPath`"^"""^""; break; }; Write-Output "^""Initiating verification: Checking if any of the ${userShellFoldersEntries.Count} user shell folders point to the OneDrive user folder pattern ($oneDriveUserFolderPattern)."^""; $userShellFoldersInOneDrive = @(); foreach ($registryEntry in $userShellFoldersEntries) { $userShellFolderName = $registryEntry.Name; $userShellFolderPath = $registryEntry.Value; if (!$userShellFolderPath) { Write-Output "^""Skipping: The user shell folder `"^""$userShellFolderName`"^"" does not have a defined path."^""; continue; }; $expandedUserShellFolderPath = [System.Environment]::ExpandEnvironmentVariables($userShellFolderPath); if(-not ($expandedUserShellFolderPath -like $oneDriveUserFolderPattern)) { continue; }; $userShellFoldersInOneDrive += [PSCustomObject]@{ Name = $userShellFolderName;  Path = $expandedUserShellFolderPath }; }; if ($userShellFoldersInOneDrive.Count -gt 0) { $warningMessage = 'To keep your computer running smoothly, OneDrive user folder will not be deleted.'; $warningMessage += "^""`nIt's being used by the OS as a user shell directory for the following folders:"^""; $userShellFoldersInOneDrive.ForEach( { $warningMessage += "^""`n- $($_.Name): $($_.Path)"^""; }); Write-Warning $warningMessage; exit 0; }; Write-Output "^""Successfully verified that none of the $($userShellFoldersEntries.Count) user shell folders point to the OneDrive user folder pattern."^""; break; } catch { Write-Warning "^""An error occurred during verification of user shell folders. Skipping prevent potential issues. Error: $($_.Exception.Message)"^""; exit 0; }; }; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { try { if (Test-Path -Path $path -PathType Leaf) { Write-Warning "^""Retaining file `"^""$path`"^"" to safeguard your data."^""; continue; } elseif (Test-Path -Path $path -PathType Container) { if ((Get-ChildItem "^""$path"^"" -Recurse | Measure-Object).Count -gt 0) { Write-Warning "^""Preserving non-empty folder `"^""$path`"^"" to protect your files."^""; continue; }; }; } catch { Write-Warning "^""An error occurred while processing `"^""$path`"^"". Skipping to protect your data. Error: $($_.Exception.Message)"^""; continue; }; if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Remove OneDrive installation files and cache-------
:: ----------------------------------------------------------
echo --- Remove OneDrive installation files and cache
:: Delete directory (with additional permissions) : "%LOCALAPPDATA%\Microsoft\OneDrive"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%LOCALAPPDATA%\Microsoft\OneDrive'; if (-Not $directoryGlob.EndsWith('\')) { $directoryGlob += '\' }; $directoryGlob )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; <# Not using `Get-Acl`/`Set-Acl` to avoid adjusting token privileges #>; $parentDirectory = [System.IO.Path]::GetDirectoryName($expandedPath); $fileName = [System.IO.Path]::GetFileName($expandedPath); if ($parentDirectory -like '*[*?]*') { throw "^""Unable to grant permissions to glob path parent directory: `"^""$parentDirectory`"^"", wildcards in parent directory are not supported by ``takeown`` and ``icacls``."^""; }; if (($fileName -ne '*') -and ($fileName -like '*[*?]*')) { throw "^""Unable to grant permissions to glob path file name: `"^""$fileName`"^"", wildcards in file name is not supported by ``takeown`` and ``icacls``."^""; }; Write-Host "^""Taking ownership of `"^""$expandedPath`"^""."^""; $cmdPath = $expandedPath; if ($cmdPath.EndsWith('\')) { $cmdPath += '\' <# Escape trailing backslash for correct handling in batch commands #>; }; $takeOwnershipCommand = "^""takeown /f `"^""$cmdPath`"^"" /a"^"" <# `icacls /setowner` does not succeed, so use `takeown` instead. #>; if (-not (Test-Path -Path "^""$expandedPath"^"" -PathType Leaf)) { $localizedYes = 'Y' <# Default 'Yes' flag (fallback) #>; try { $choiceOutput = cmd /c "^""choice <nul 2>nul"^""; if ($choiceOutput -and $choiceOutput.Length -ge 2) { $localizedYes = $choiceOutput[1]; } else { Write-Warning "^""Failed to determine localized 'Yes' character. Output: `"^""$choiceOutput`"^"""^""; }; } catch { Write-Warning "^""Failed to determine localized 'Yes' character. Error: $_"^""; }; $takeOwnershipCommand += "^"" /r /d $localizedYes"^""; }; $takeOwnershipOutput = cmd /c "^""$takeOwnershipCommand 2>&1"^"" <# `stderr` message is misleading, e.g. "^""ERROR: The system cannot find the file specified."^"" is not an error. #>; if ($LASTEXITCODE -eq 0) { Write-Host "^""Successfully took ownership of `"^""$expandedPath`"^"" (using ``$takeOwnershipCommand``)."^""; } else { Write-Host "^""Did not take ownership of `"^""$expandedPath`"^"" using ``$takeOwnershipCommand``, status code: $LASTEXITCODE, message: $takeOwnershipOutput."^""; <# Do not write as error or warning, because this can be due to missing path, it's handled in next command. #>; <# `takeown` exits with status code `1`, making it hard to handle missing path here. #>; }; Write-Host "^""Granting permissions for `"^""$expandedPath`"^""."^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminAccountName = $adminAccount.Value; $grantPermissionsCommand = "^""icacls `"^""$cmdPath`"^"" /grant `"^""$($adminAccountName):F`"^"" /t"^""; $icaclsOutput = cmd /c "^""$grantPermissionsCommand"^""; if ($LASTEXITCODE -eq 3) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } elseif ($LASTEXITCODE -ne 0) { Write-Host "^""Take ownership message:`n$takeOwnershipOutput"^""; Write-Host "^""Grant permissions:`n$icaclsOutput"^""; Write-Warning "^""Failed to assign permissions for `"^""$expandedPath`"^"" using ``$grantPermissionsCommand``, status code: $LASTEXITCODE."^""; } else { $fileStats = $icaclsOutput | ForEach-Object { $_ -match '\d+' | Out-Null; $matches[0] } | Where-Object { $_ -ne $null } | ForEach-Object { [int]$_ }; if ($fileStats.Count -gt 0 -and ($fileStats | ForEach-Object { $_ -eq 0 } | Where-Object { $_ -eq $false }).Count -eq 0) { Write-Host "^""Skipping, no items available for deletion according to: ``$grantPermissionsCommand``."^""; exit 0; } else { Write-Host "^""Successfully granted permissions for `"^""$expandedPath`"^"" (using ``$grantPermissionsCommand``)."^""; }; }; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete directory  : "%PROGRAMDATA%\Microsoft OneDrive"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%PROGRAMDATA%\Microsoft OneDrive'; if (-Not $directoryGlob.EndsWith('\')) { $directoryGlob += '\' }; $directoryGlob )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: Delete directory  : "%SYSTEMDRIVE%\OneDriveTemp"
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""$($directoryGlob = '%SYSTEMDRIVE%\OneDriveTemp'; if (-Not $directoryGlob.EndsWith('\')) { $directoryGlob += '\' }; $directoryGlob )"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $deletedCount = 0; $failedCount = 0; $foundAbsolutePaths = @(); Write-Host 'Iterating files and directories recursively.'; try { $foundAbsolutePaths += @(; Get-ChildItem -Path $expandedPath -Force -Recurse -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (-not (Test-Path $path)) { <# Re-check existence as prior deletions might remove subsequent items (e.g., subdirectories). #>; Write-Host "^""Successfully deleted: $($path) (already deleted)."^""; $deletedCount++; continue; }; try { Remove-Item -Path $path -Force -Recurse -ErrorAction Stop; $deletedCount++; Write-Host "^""Successfully deleted: $($path)"^""; } catch { $failedCount++; Write-Warning "^""Unable to delete $($path): $_"^""; }; }; Write-Host "^""Successfully deleted $($deletedCount) items."^""; if ($failedCount -gt 0) { Write-Warning "^""Failed to delete $($failedCount) items."^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Remove OneDrive shortcuts-----------------
:: ----------------------------------------------------------
echo --- Remove OneDrive shortcuts
PowerShell -ExecutionPolicy Unrestricted -Command "$shortcuts = @(; @{ Revert = $True;  Path = "^""$env:APPDATA\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"^""; }; @{ Revert = $False; Path = "^""$env:USERPROFILE\Links\OneDrive.lnk"^""; }; @{ Revert = $False; Path = "^""$env:SYSTEMROOT\ServiceProfiles\LocalService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"^""; }; @{ Revert = $False; Path = "^""$env:SYSTEMROOT\ServiceProfiles\NetworkService\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"^""; }; ); foreach ($shortcut in $shortcuts) { if (-Not (Test-Path $shortcut.Path)) { Write-Host "^""Skipping, shortcut does not exist: `"^""$($shortcut.Path)`"^""."^""; continue; }; try { Remove-Item -Path $shortcut.Path -Force -ErrorAction Stop; Write-Output "^""Successfully removed shortcut: `"^""$($shortcut.Path)`"^""."^""; } catch { Write-Error "^""Encountered an issue while attempting to remove shortcut at: `"^""$($shortcut.Path)`"^""."^""; }; }"
PowerShell -ExecutionPolicy Unrestricted -Command "Set-Location "^""HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace"^""; Get-ChildItem | ForEach-Object {Get-ItemProperty $_.pspath} | ForEach-Object { $leftnavNodeName = $_."^""(default)"^""; if (($leftnavNodeName -eq "^""OneDrive"^"") -Or ($leftnavNodeName -eq "^""OneDrive - Personal"^"")) { if (Test-Path $_.pspath) { Write-Host "^""Deleting $($_.pspath)."^""; Remove-Item $_.pspath; }; }; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Disable OneDrive usage------------------
:: ----------------------------------------------------------
echo --- Disable OneDrive usage
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive!DisableFileSyncNGSC"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive' /v 'DisableFileSyncNGSC' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive!DisableFileSync"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive' /v 'DisableFileSync' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable automatic OneDrive installation----------
:: ----------------------------------------------------------
echo --- Disable automatic OneDrive installation
:: Delete the registry value "OneDriveSetup" from the key "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" 
:: This operation will not run on Windows versions earlier than Windows10-1909.This operation will not run on Windows versions later than Windows10-1909.
PowerShell -ExecutionPolicy Unrestricted -Command "$versionName = 'Windows10-1909'; $buildNumber = switch ($versionName) { 'Windows11-FirstRelease' { '10.0.22000' }; 'Windows11-22H2' { '10.0.22621' }; 'Windows11-21H2' { '10.0.22000' }; 'Windows10-22H2' { '10.0.19045' }; 'Windows10-21H2' { '10.0.19044' }; 'Windows10-20H2' { '10.0.19042' }; 'Windows10-1909' { '10.0.18363' }; 'Windows10-1607' { '10.0.14393' }; default { throw "^""Internal privacy$([char]0x002E)sexy error: No build for minimum Windows '$versionName'"^""; }; }; $minVersion = [System.Version]::Parse($buildNumber); $ver = [Environment]::OSVersion.Version; $verNoPatch = [System.Version]::new($ver.Major, $ver.Minor, $ver.Build); if ($verNoPatch -lt $minVersion) { Write-Output "^""Skipping: Windows ($verNoPatch) is below minimum $minVersion ($versionName)"^""; Exit 0; }$versionName = 'Windows10-1909'; $buildNumber = switch ($versionName) { 'Windows11-21H2' { '10.0.22000' }; 'Windows10-MostRecent' { '10.0.19045' }; 'Windows10-22H2' { '10.0.19045' }; 'Windows10-1909' { '10.0.18363' }; 'Windows10-1903' { '10.0.18362' }; default { throw "^""Internal privacy$([char]0x002E)sexy error: No build for maximum Windows '$versionName'"^""; }; }; $maxVersion=[System.Version]::Parse($buildNumber); $ver = [Environment]::OSVersion.Version; $verNoPatch = [System.Version]::new($ver.Major, $ver.Minor, $ver.Build); if ($verNoPatch -gt $maxVersion) { Write-Output "^""Skipping: Windows ($verNoPatch) is above maximum $maxVersion ($versionName)"^""; Exit 0; }; $keyName = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Run'; $valueName = 'OneDriveSetup'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Remove OneDrive folder from File Explorer---------
:: ----------------------------------------------------------
echo --- Remove OneDrive folder from File Explorer
:: Set the registry value: "HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}!System.IsPinnedToNameSpaceTree"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'; $data = '0'; reg add 'HKCU\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' /v 'System.IsPinnedToNameSpaceTree' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}!System.IsPinnedToNameSpaceTree"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'; $data = '0'; reg add 'HKCU\Software\Classes\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' /v 'System.IsPinnedToNameSpaceTree' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable OneDrive scheduled tasks-------------
:: ----------------------------------------------------------
echo --- Disable OneDrive scheduled tasks
:: Disable scheduled task(s): `\OneDrive Reporting Task-*`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\'; $taskNamePattern='OneDrive Reporting Task-*'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\OneDrive Standalone Update Task-*`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\'; $taskNamePattern='OneDrive Standalone Update Task-*'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\OneDrive Per-Machine Standalone Update`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\'; $taskNamePattern='OneDrive Per-Machine Standalone Update'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Clear OneDrive environment variable------------
:: ----------------------------------------------------------
echo --- Clear OneDrive environment variable
:: Delete the registry value "OneDrive" from the key "HKCU\Environment" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKCU\Environment'; $valueName = 'OneDrive'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Xbox Live Auth Manager--------------
:: ----------------------------------------------------------
echo --- Disable Xbox Live Auth Manager
:: Disable service(s): `XblAuthManager`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'XblAuthManager'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable Xbox Live Game Save----------------
:: ----------------------------------------------------------
echo --- Disable Xbox Live Game Save
:: Disable service(s): `XblGameSave`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'XblGameSave'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable Xbox Live Networking---------------
:: ----------------------------------------------------------
echo --- Disable Xbox Live Networking
:: Disable service(s): `XboxNetApiSvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'XboxNetApiSvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Downloaded Maps Manager--------------
:: ----------------------------------------------------------
echo --- Disable Downloaded Maps Manager
:: Disable service(s): `MapsBroker`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'MapsBroker'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Microsoft Retail Demo---------------
:: ----------------------------------------------------------
echo --- Disable Microsoft Retail Demo
:: Disable service(s): `RetailDemo`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'RetailDemo'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Remove "Meet Now" icon from taskbar------------
:: ----------------------------------------------------------
echo --- Remove "Meet Now" icon from taskbar
:: Set the registry value: "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer!HideSCAMeetNow"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $data = '1'; reg add 'HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' /v 'HideSCAMeetNow' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Customer Experience Improvement Program data collection
echo --- Disable Customer Experience Improvement Program data collection
:: Set the registry value: "HKLM\Software\Policies\Microsoft\SQMClient\Windows!CEIPEnable"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\SQMClient\Windows'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\SQMClient\Windows' /v 'CEIPEnable' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Microsoft\SQMClient\Windows!CEIPEnable"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\SQMClient\Windows'; $data = '0'; reg add 'HKLM\Software\Microsoft\SQMClient\Windows' /v 'CEIPEnable' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Customer Experience Improvement Program data uploads
echo --- Disable Customer Experience Improvement Program data uploads
:: Set the registry value: "HKLM\Software\Microsoft\SQMClient!UploadDisableFlag"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\SQMClient'; $data = '0'; reg add 'HKLM\Software\Microsoft\SQMClient' /v 'UploadDisableFlag' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable automatic Software Quality Metrics (SQM) data transmission
echo --- Disable automatic Software Quality Metrics (SQM) data transmission
:: Disable scheduled task(s): `\Microsoft\Windows\Autochk\Proxy`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Autochk\'; $taskNamePattern='Proxy'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -Disable kernel-level customer experience data collection-
:: ----------------------------------------------------------
echo --- Disable kernel-level customer experience data collection
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\'; $taskNamePattern='KernelCeipTask'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable Bluetooth usage data collection----------
:: ----------------------------------------------------------
echo --- Disable Bluetooth usage data collection
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\BthSQM`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\'; $taskNamePattern='BthSQM'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable disk diagnostic data collection----------
:: ----------------------------------------------------------
echo --- Disable disk diagnostic data collection
:: Disable scheduled task(s): `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\DiskDiagnostic\'; $taskNamePattern='Microsoft-Windows-DiskDiagnosticDataCollector'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable disk diagnostic user notifications--------
:: ----------------------------------------------------------
echo --- Disable disk diagnostic user notifications
:: Disable scheduled task(s): `\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\DiskDiagnostic\'; $taskNamePattern='Microsoft-Windows-DiskDiagnosticResolver'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable USB data collection----------------
:: ----------------------------------------------------------
echo --- Disable USB data collection
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\'; $taskNamePattern='UsbCeip'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------Disable customer experience data consolidation------
:: ----------------------------------------------------------
echo --- Disable customer experience data consolidation
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\Consolidator`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\'; $taskNamePattern='Consolidator'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable customer experience data uploads---------
:: ----------------------------------------------------------
echo --- Disable customer experience data uploads
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\Uploader`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\'; $taskNamePattern='Uploader'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable server customer experience data assistant-----
:: ----------------------------------------------------------
echo --- Disable server customer experience data assistant
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerCeipAssistant`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\Server\'; $taskNamePattern='ServerCeipAssistant'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable server role telemetry collection---------
:: ----------------------------------------------------------
echo --- Disable server role telemetry collection
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleCollector`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\Server\'; $taskNamePattern='ServerRoleCollector'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable server role usage data collection---------
:: ----------------------------------------------------------
echo --- Disable server role usage data collection
:: Disable scheduled task(s): `\Microsoft\Windows\Customer Experience Improvement Program\Server\ServerRoleUsageCollector`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Customer Experience Improvement Program\Server\'; $taskNamePattern='ServerRoleUsageCollector'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: Disable daily compatibility data collection ("Microsoft Compatibility Appraiser" task)
echo --- Disable daily compatibility data collection ("Microsoft Compatibility Appraiser" task)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='Microsoft Compatibility Appraiser'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: Disable telemetry collector and sender process (`CompatTelRunner.exe`)
echo --- Disable telemetry collector and sender process (`CompatTelRunner.exe`)
:: Check and terminate the running process "CompatTelRunner.exe"
tasklist /fi "ImageName eq CompatTelRunner.exe" /fo csv 2>NUL | find /i "CompatTelRunner.exe">NUL && (
    echo CompatTelRunner.exe is running and will be killed.
    taskkill /f /im CompatTelRunner.exe
) || (
    echo Skipping, CompatTelRunner.exe is not running.
)
:: Configure termination of "CompatTelRunner.exe" immediately upon its startup
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe!Debugger"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe'; $data = '%SYSTEMROOT%\System32\taskkill.exe'; reg add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\CompatTelRunner.exe' /v 'Debugger' /t 'REG_SZ' /d "^""$data"^"" /f"
:: Add a rule to prevent the executable "CompatTelRunner.exe" from running via File Explorer
PowerShell -ExecutionPolicy Unrestricted -Command "$executableFilename='CompatTelRunner.exe'; try { $registryPathForDisallowRun='HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun'; $existingBlockEntries = Get-ItemProperty -Path "^""$registryPathForDisallowRun"^"" -ErrorAction Ignore; $nextFreeRuleIndex = 1; if ($existingBlockEntries) { $existingBlockingRuleForExecutable = $existingBlockEntries.PSObject.Properties | Where-Object { $_.Value -eq $executableFilename }; if ($existingBlockingRuleForExecutable) { $existingBlockingRuleIndexForExecutable = $existingBlockingRuleForExecutable.Name; Write-Output "^""Skipping, no action needed: '$executableFilename' is already blocked under rule index `"^""$existingBlockingRuleIndexForExecutable`"^""."^""; exit 0; }; $occupiedRuleIndexes = $existingBlockEntries.PSObject.Properties | Where-Object { $_.Name -Match '^\d+$' } | Select -ExpandProperty Name; if ($occupiedRuleIndexes) { while ($occupiedRuleIndexes -Contains $nextFreeRuleIndex) { $nextFreeRuleIndex += 1; }; }; }; Write-Output "^""Adding block rule for `"^""$executableFilename`"^"" under rule index `"^""$nextFreeRuleIndex`"^""."^""; if (!(Test-Path $registryPathForDisallowRun)) { New-Item -Path "^""$registryPathForDisallowRun"^"" -Force -ErrorAction Stop | Out-Null; }; New-ItemProperty -Path "^""$registryPathForDisallowRun"^"" -Name "^""$nextFreeRuleIndex"^"" -PropertyType String -Value "^""$executableFilename"^"" ` -ErrorAction Stop | Out-Null; Write-Output "^""Successfully blocked `"^""$executableFilename`"^"" with rule index `"^""$nextFreeRuleIndex`"^""."^""; } catch { Write-Error "^""Failed to block `"^""$executableFilename`"^"": $_"^""; Exit 1; }"
:: Activate the DisallowRun policy to block specified programs from running via File Explorer
PowerShell -ExecutionPolicy Unrestricted -Command "try { $fileExplorerDisallowRunRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $currentDisallowRunPolicyValue = Get-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -ErrorAction Ignore | Select -ExpandProperty DisallowRun; if ([string]::IsNullOrEmpty($currentDisallowRunPolicyValue)) { Write-Output "^""Creating DisallowRun policy at `"^""$fileExplorerDisallowRunRegistryPath`"^""."^""; if (!(Test-Path $fileExplorerDisallowRunRegistryPath)) { New-Item -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Force -ErrorAction Stop | Out-Null; }; New-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -Value 1 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null; Write-Output 'Successfully activated DisallowRun policy.'; Exit 0; }; if ($currentDisallowRunPolicyValue -eq 1) { Write-Output 'Skipping, no action needed: DisallowRun policy is already in place.'; Exit 0; }; Write-Output 'Updating DisallowRun policy from unexpected value `"^""$currentDisallowRunPolicyValue`"^"" to `"^""1`"^"".'; Set-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -Value 1 -Type DWORD -Force -ErrorAction Stop | Out-Null; Write-Output 'Successfully activated DisallowRun policy.'; } catch { Write-Error "^""Failed to activate DisallowRun policy: $_"^""; Exit 1; }"
:: Soft delete files matching pattern: "%SYSTEMROOT%\System32\CompatTelRunner.exe" with additional permissions 
PowerShell -ExecutionPolicy Unrestricted -Command "$pathGlobPattern = "^""%SYSTEMROOT%\System32\CompatTelRunner.exe"^""; $expandedPath = [System.Environment]::ExpandEnvironmentVariables($pathGlobPattern); Write-Host "^""Searching for items matching pattern: `"^""$($expandedPath)`"^""."^""; $renamedCount   = 0; $skippedCount   = 0; $failedCount    = 0; Add-Type -TypeDefinition "^""using System;`r`nusing System.Runtime.InteropServices;`r`npublic class Privileges {`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall,`r`n        ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);`r`n    [DllImport(`"^""advapi32.dll`"^"", ExactSpelling = true, SetLastError = true)]`r`n    internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);`r`n    [DllImport(`"^""advapi32.dll`"^"", SetLastError = true)]`r`n    internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);`r`n    [StructLayout(LayoutKind.Sequential, Pack = 1)]`r`n    internal struct TokPriv1Luid {`r`n        public int Count;`r`n        public long Luid;`r`n        public int Attr;`r`n    }`r`n    internal const int SE_PRIVILEGE_ENABLED = 0x00000002;`r`n    internal const int TOKEN_QUERY = 0x00000008;`r`n    internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;`r`n    public static bool AddPrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = SE_PRIVILEGE_ENABLED;`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    public static bool RemovePrivilege(string privilege) {`r`n        try {`r`n            bool retVal;`r`n            TokPriv1Luid tp;`r`n            IntPtr hproc = GetCurrentProcess();`r`n            IntPtr htok = IntPtr.Zero;`r`n            retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);`r`n            tp.Count = 1;`r`n            tp.Luid = 0;`r`n            tp.Attr = 0;  // This line is changed to revoke the privilege`r`n            retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);`r`n            retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);`r`n            return retVal;`r`n        } catch (Exception ex) {`r`n            throw new Exception(`"^""Failed to adjust token privileges`"^"", ex);`r`n        }`r`n    }`r`n    [DllImport(`"^""kernel32.dll`"^"", CharSet = CharSet.Auto)]`r`n    public static extern IntPtr GetCurrentProcess();`r`n}"^""; [Privileges]::AddPrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::AddPrivilege('SeTakeOwnershipPrivilege') | Out-Null; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $adminFullControlAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $foundAbsolutePaths = @(); try { $foundAbsolutePaths += @(; Get-Item -Path $expandedPath -ErrorAction Stop | Select-Object -ExpandProperty FullName; ); } catch [System.Management.Automation.ItemNotFoundException] { <# Swallow, do not run `Test-Path` before, it's unreliable for globs requiring extra permissions #>; }; $foundAbsolutePaths = $foundAbsolutePaths | Select-Object -Unique | Sort-Object -Property { $_.Length } -Descending; if (!$foundAbsolutePaths) { Write-Host 'Skipping, no items available.'; exit 0; }; Write-Host "^""Initiating processing of $($foundAbsolutePaths.Count) items from `"^""$expandedPath`"^""."^""; foreach ($path in $foundAbsolutePaths) { if (Test-Path -Path $path -PathType Container) { Write-Host "^""Skipping folder (not its contents): `"^""$path`"^""."^""; $skippedCount++; continue; }; if($revert -eq $true) { if (-not $path.EndsWith('.OLD')) { Write-Host "^""Skipping non-backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; } else { if ($path.EndsWith('.OLD')) { Write-Host "^""Skipping backup file: `"^""$path`"^""."^""; $skippedCount++; continue; }; }; $originalFilePath = $path; Write-Host "^""Processing file: `"^""$originalFilePath`"^""."^""; if (-Not (Test-Path $originalFilePath)) { Write-Host "^""Skipping, file `"^""$originalFilePath`"^"" not found."^""; $skippedCount++; exit 0; }; $originalAcl = Get-Acl -Path "^""$originalFilePath"^""; $accessGranted = $false; try { $acl = Get-Acl -Path "^""$originalFilePath"^""; $acl.SetOwner($adminAccount) <# Take Ownership (because file is owned by TrustedInstaller) #>; $acl.AddAccessRule($adminFullControlAccessRule) <# Grant rights to be able to move the file #>; Set-Acl -Path $originalFilePath -AclObject $acl -ErrorAction Stop; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; if ($revert -eq $true) { $newFilePath = $originalFilePath.Substring(0, $originalFilePath.Length - 4); } else { $newFilePath = "^""$($originalFilePath).OLD"^""; }; try { Move-Item -LiteralPath "^""$($originalFilePath)"^"" -Destination "^""$newFilePath"^"" -Force -ErrorAction Stop; Write-Host "^""Successfully processed `"^""$originalFilePath`"^""."^""; $renamedCount++; if ($accessGranted) { try { Set-Acl -Path $newFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; }; }; } catch { Write-Error "^""Failed to rename `"^""$originalFilePath`"^"" to `"^""$newFilePath`"^"": $($_.Exception.Message)"^""; $failedCount++; if ($accessGranted) { try { Set-Acl -Path $originalFilePath -AclObject $originalAcl -ErrorAction Stop; } catch { Write-Warning "^""Failed to restore access on `"^""$originalFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; }; if (($renamedCount -gt 0) -or ($skippedCount -gt 0)) { Write-Host "^""Successfully processed $renamedCount items and skipped $skippedCount items."^""; }; if ($failedCount -gt 0) { Write-Warning "^""Failed to process $($failedCount) items."^""; }; [Privileges]::RemovePrivilege('SeRestorePrivilege') | Out-Null; [Privileges]::RemovePrivilege('SeTakeOwnershipPrivilege') | Out-Null"
:: ----------------------------------------------------------


:: Disable program data collection and reporting (`ProgramDataUpdater`)
echo --- Disable program data collection and reporting (`ProgramDataUpdater`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\ProgramDataUpdater`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='ProgramDataUpdater'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable application usage tracking (`AitAgent`)------
:: ----------------------------------------------------------
echo --- Disable application usage tracking (`AitAgent`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\AitAgent`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='AitAgent'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: Disable startup application data tracking (`StartupAppTask`)
echo --- Disable startup application data tracking (`StartupAppTask`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\StartupAppTask`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='StartupAppTask'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: Disable software compatibility updates (`PcaPatchDbTask`)-
:: ----------------------------------------------------------
echo --- Disable software compatibility updates (`PcaPatchDbTask`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\PcaPatchDbTask`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='PcaPatchDbTask'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: Disable compatibility adjustment data sharing (`SdbinstMergeDbTask`)
echo --- Disable compatibility adjustment data sharing (`SdbinstMergeDbTask`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\SdbinstMergeDbTask`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='SdbinstMergeDbTask'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; $taskFullPath = "^""$($task.TaskPath)$($task.TaskName)"^""; $adminSid = New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544'; $adminAccount = $adminSid.Translate([System.Security.Principal.NTAccount]); $taskFilePath="^""$($env:SYSTEMROOT)\System32\Tasks$($task.TaskPath)$($task.TaskName)"^""; $accessGranted = $false; try { $originalAcl= Get-Acl -Path $taskFilePath -ErrorAction Stop; $modifiedAcl= Get-Acl -Path $taskFilePath -ErrorAction Stop; $modifiedAcl.SetOwner($adminAccount); $taskFileAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule( $adminAccount, [System.Security.AccessControl.FileSystemRights]::FullControl, [System.Security.AccessControl.AccessControlType]::Allow ); $modifiedAcl.SetAccessRule($taskFileAccessRule); Set-Acl -Path $taskFilePath -AclObject $modifiedAcl -ErrorAction Stop; Write-Host "^""Successfully granted permissions for `"^""$taskFullPath`"^"" ."^""; $accessGranted = $true; } catch { Write-Warning "^""Failed to grant access to `"^""$taskFullPath`"^"": $($_.Exception.Message)"^""; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; if ($accessGranted) { try { Set-Acl -Path $taskFilePath -AclObject $originalAcl -ErrorAction Stop; Write-Host "^""Successfully restored permissions for `"^""$taskFullPath`"^"" ."^""; } catch { Write-Warning "^""Failed to restore access on `"^""$taskFilePath`"^"": $($_.Exception.Message)"^""; }; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -Disable application backup data gathering (`MareBackup`)-
:: ----------------------------------------------------------
echo --- Disable application backup data gathering (`MareBackup`)
:: Disable scheduled task(s): `\Microsoft\Windows\Application Experience\MareBackup`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Application Experience\'; $taskNamePattern='MareBackup'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable Application Impact Telemetry (AIT)--------
:: ----------------------------------------------------------
echo --- Disable Application Impact Telemetry (AIT)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\AppCompat!AITEnable"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\AppCompat'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\Windows\AppCompat' /v 'AITEnable' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable Application Compatibility Engine---------
:: ----------------------------------------------------------
echo --- Disable Application Compatibility Engine
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\AppCompat!DisableEngine"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\AppCompat'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\AppCompat' /v 'DisableEngine' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Remove "Program Compatibility" tab from file properties (context menu)
echo --- Remove "Program Compatibility" tab from file properties (context menu)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\AppCompat!DisablePropPage"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\AppCompat'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\AppCompat' /v 'DisablePropPage' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Steps Recorder (collects screenshots, mouse/keyboard input and UI data)
echo --- Disable Steps Recorder (collects screenshots, mouse/keyboard input and UI data)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\AppCompat!DisableUAR"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\AppCompat'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\AppCompat' /v 'DisableUAR' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable "Inventory Collector" task------------
:: ----------------------------------------------------------
echo --- Disable "Inventory Collector" task
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat!DisableInventory"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat' /v 'DisableInventory' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -Disable "Program Compatibility Assistant (PCA)" feature--
:: ----------------------------------------------------------
echo --- Disable "Program Compatibility Assistant (PCA)" feature
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat!DisablePCA"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat' /v 'DisablePCA' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable "Program Compatibility Assistant Service" (`PcaSvc`)
echo --- Disable "Program Compatibility Assistant Service" (`PcaSvc`)
:: Disable service(s): `PcaSvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'PcaSvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable diagnostic and usage telemetry----------
:: ----------------------------------------------------------
echo --- Disable diagnostic and usage telemetry
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection!AllowTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' /v 'AllowTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable automatic cloud configuration downloads------
:: ----------------------------------------------------------
echo --- Disable automatic cloud configuration downloads
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\DataCollection!DisableOneSettingsDownloads"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\DataCollection'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\DataCollection' /v 'DisableOneSettingsDownloads' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Disable license telemetry-----------------
:: ----------------------------------------------------------
echo --- Disable license telemetry
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform!NoGenTicket"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows NT\CurrentVersion\Software Protection Platform' /v 'NoGenTicket' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------------Disable error reporting------------------
:: ----------------------------------------------------------
echo --- Disable error reporting
:: Disable Windows Error Reporting (WER)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting!Disabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\Windows Error Reporting' /v 'Disabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting!Disabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting' /v 'Disabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Disable Windows Error Reporting (WER) consent
:: Set the registry value: "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent!DefaultConsent"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent'; $data = '1'; reg add 'HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent' /v 'DefaultConsent' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent!DefaultOverrideBehavior"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent'; $data = '1'; reg add 'HKLM\Software\Microsoft\Windows\Windows Error Reporting\Consent' /v 'DefaultOverrideBehavior' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Disable WER sending second-level data
:: Set the registry value: "HKLM\Software\Microsoft\Windows\Windows Error Reporting!DontSendAdditionalData"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Windows\Windows Error Reporting'; $data = '1'; reg add 'HKLM\Software\Microsoft\Windows\Windows Error Reporting' /v 'DontSendAdditionalData' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Microsoft\Windows\Windows Error Reporting!LoggingDisabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Windows\Windows Error Reporting'; $data = '1'; reg add 'HKLM\Software\Microsoft\Windows\Windows Error Reporting' /v 'LoggingDisabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Disable scheduled task(s): `\Microsoft\Windows\ErrorDetails\EnableErrorDetailsUpdate`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\ErrorDetails\'; $taskNamePattern='EnableErrorDetailsUpdate'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\Microsoft\Windows\Windows Error Reporting\QueueReporting`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Windows Error Reporting\'; $taskNamePattern='QueueReporting'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable service(s): `wersvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'wersvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: Disable service(s): `wercplsupport`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'wercplsupport'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: Disable "Connected User Experiences and Telemetry" (`DiagTrack`) service
echo --- Disable "Connected User Experiences and Telemetry" (`DiagTrack`) service
:: Disable service(s): `DiagTrack`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'DiagTrack'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------Disable WAP push notification routing service-------
:: ----------------------------------------------------------
echo --- Disable WAP push notification routing service
:: Disable service(s): `dmwappushservice`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'dmwappushservice'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Disable "Diagnostics Hub Standard Collector" service---
:: ----------------------------------------------------------
echo --- Disable "Diagnostics Hub Standard Collector" service
:: Disable service(s): `diagnosticshub.standardcollector.service`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'diagnosticshub.standardcollector.service'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable "Diagnostic Execution Service" (`diagsvc`)----
:: ----------------------------------------------------------
echo --- Disable "Diagnostic Execution Service" (`diagsvc`)
:: Disable service(s): `diagsvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'diagsvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Disable "Device" task-------------------
:: ----------------------------------------------------------
echo --- Disable "Device" task
:: Disable scheduled task(s): `\Microsoft\Windows\Device Information\Device`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Device Information\'; $taskNamePattern='Device'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Disable "Device User" task----------------
:: ----------------------------------------------------------
echo --- Disable "Device User" task
:: Disable scheduled task(s): `\Microsoft\Windows\Device Information\Device User`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Windows\Device Information\'; $taskNamePattern='Device User'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable device and configuration data collection tool---
:: ----------------------------------------------------------
echo --- Disable device and configuration data collection tool
:: Check and terminate the running process "DeviceCensus.exe"
tasklist /fi "ImageName eq DeviceCensus.exe" /fo csv 2>NUL | find /i "DeviceCensus.exe">NUL && (
    echo DeviceCensus.exe is running and will be killed.
    taskkill /f /im DeviceCensus.exe
) || (
    echo Skipping, DeviceCensus.exe is not running.
)
:: Configure termination of "DeviceCensus.exe" immediately upon its startup
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe!Debugger"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe'; $data = '%SYSTEMROOT%\System32\taskkill.exe'; reg add 'HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\DeviceCensus.exe' /v 'Debugger' /t 'REG_SZ' /d "^""$data"^"" /f"
:: Add a rule to prevent the executable "DeviceCensus.exe" from running via File Explorer
PowerShell -ExecutionPolicy Unrestricted -Command "$executableFilename='DeviceCensus.exe'; try { $registryPathForDisallowRun='HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer\DisallowRun'; $existingBlockEntries = Get-ItemProperty -Path "^""$registryPathForDisallowRun"^"" -ErrorAction Ignore; $nextFreeRuleIndex = 1; if ($existingBlockEntries) { $existingBlockingRuleForExecutable = $existingBlockEntries.PSObject.Properties | Where-Object { $_.Value -eq $executableFilename }; if ($existingBlockingRuleForExecutable) { $existingBlockingRuleIndexForExecutable = $existingBlockingRuleForExecutable.Name; Write-Output "^""Skipping, no action needed: '$executableFilename' is already blocked under rule index `"^""$existingBlockingRuleIndexForExecutable`"^""."^""; exit 0; }; $occupiedRuleIndexes = $existingBlockEntries.PSObject.Properties | Where-Object { $_.Name -Match '^\d+$' } | Select -ExpandProperty Name; if ($occupiedRuleIndexes) { while ($occupiedRuleIndexes -Contains $nextFreeRuleIndex) { $nextFreeRuleIndex += 1; }; }; }; Write-Output "^""Adding block rule for `"^""$executableFilename`"^"" under rule index `"^""$nextFreeRuleIndex`"^""."^""; if (!(Test-Path $registryPathForDisallowRun)) { New-Item -Path "^""$registryPathForDisallowRun"^"" -Force -ErrorAction Stop | Out-Null; }; New-ItemProperty -Path "^""$registryPathForDisallowRun"^"" -Name "^""$nextFreeRuleIndex"^"" -PropertyType String -Value "^""$executableFilename"^"" ` -ErrorAction Stop | Out-Null; Write-Output "^""Successfully blocked `"^""$executableFilename`"^"" with rule index `"^""$nextFreeRuleIndex`"^""."^""; } catch { Write-Error "^""Failed to block `"^""$executableFilename`"^"": $_"^""; Exit 1; }"
:: Activate the DisallowRun policy to block specified programs from running via File Explorer
PowerShell -ExecutionPolicy Unrestricted -Command "try { $fileExplorerDisallowRunRegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer'; $currentDisallowRunPolicyValue = Get-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -ErrorAction Ignore | Select -ExpandProperty DisallowRun; if ([string]::IsNullOrEmpty($currentDisallowRunPolicyValue)) { Write-Output "^""Creating DisallowRun policy at `"^""$fileExplorerDisallowRunRegistryPath`"^""."^""; if (!(Test-Path $fileExplorerDisallowRunRegistryPath)) { New-Item -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Force -ErrorAction Stop | Out-Null; }; New-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -Value 1 -PropertyType DWORD -Force -ErrorAction Stop | Out-Null; Write-Output 'Successfully activated DisallowRun policy.'; Exit 0; }; if ($currentDisallowRunPolicyValue -eq 1) { Write-Output 'Skipping, no action needed: DisallowRun policy is already in place.'; Exit 0; }; Write-Output 'Updating DisallowRun policy from unexpected value `"^""$currentDisallowRunPolicyValue`"^"" to `"^""1`"^"".'; Set-ItemProperty -Path "^""$fileExplorerDisallowRunRegistryPath"^"" -Name 'DisallowRun' -Value 1 -Type DWORD -Force -ErrorAction Stop | Out-Null; Write-Output 'Successfully activated DisallowRun policy.'; } catch { Write-Error "^""Failed to activate DisallowRun policy: $_"^""; Exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable commercial usage of collected data--------
:: ----------------------------------------------------------
echo --- Disable commercial usage of collected data
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowCommercialDataPipeline"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowCommercialDataPipeline' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable processing of Desktop Analytics----------
:: ----------------------------------------------------------
echo --- Disable processing of Desktop Analytics
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowDesktopAnalyticsProcessing"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowDesktopAnalyticsProcessing' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable sending device name in Windows diagnostic data--
:: ----------------------------------------------------------
echo --- Disable sending device name in Windows diagnostic data
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowDeviceNameInTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowDeviceNameInTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable collection of Edge browsing data for Desktop Analytics
echo --- Disable collection of Edge browsing data for Desktop Analytics
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!MicrosoftEdgeDataOptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'MicrosoftEdgeDataOptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable diagnostics data processing for Business cloud--
:: ----------------------------------------------------------
echo --- Disable diagnostics data processing for Business cloud
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowWUfBCloudProcessing"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowWUfBCloudProcessing' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -Disable Update Compliance processing of diagnostics data-
:: ----------------------------------------------------------
echo --- Disable Update Compliance processing of diagnostics data
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!AllowUpdateComplianceProcessing"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'AllowUpdateComplianceProcessing' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Disable peering download method for Windows Updates----
:: ----------------------------------------------------------
echo --- Disable peering download method for Windows Updates
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization!DODownloadMode"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' /v 'DODownloadMode' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable "Delivery Optimization" service (breaks Microsoft Store downloads)
echo --- Disable "Delivery Optimization" service (breaks Microsoft Store downloads)
:: Disable the service `DoSvc` 
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceQuery = 'DoSvc'; $stopWithDependencies= $false; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceQuery -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service query `"^""$serviceQuery`"^"" did not yield any results, no need to disable it."^""; Exit 0; }; $serviceName = $service.Name; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, attempting to stop it."^""; try { Write-Host "^""Stopping the service `"^""$serviceName`"^""."^""; $stopParams = @{ Name = $ServiceName; Force = $true; ErrorAction = 'Stop'; }; if (-not $stopWithDependencies) { $stopParams['NoWait'] = $true; }; Stop-Service @stopParams; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { if ($_.FullyQualifiedErrorId -eq 'CouldNotStopService,Microsoft.PowerShell.Commands.StopServiceCommand') { Write-Warning "^""The service `"^""$serviceName`"^"" does not accept a stop command and may need to be stopped manually or on reboot."^""; } else { Write-Warning "^""Failed to stop service `"^""$ServiceName`"^"". It will be stopped after reboot. Error: $($_.Exception.Message)"^""; }; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if service info is not found in registry #>; $registryKey = "^""HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName"^""; if (-Not (Test-Path $registryKey)) { Write-Host "^""`"^""$registryKey`"^"" is not found in registry, cannot enable it."^""; Exit 0; }; <# -- 4. Skip if already disabled #>; if( $(Get-ItemProperty -Path "^""$registryKey"^"").Start -eq 4) { Write-Host "^""`"^""$serviceName`"^"" is already disabled from start, no further action is needed."^""; Exit 0; }; <# -- 5. Disable service #>; try { Set-ItemProperty -LiteralPath $registryKey -Name "^""Start"^"" -Value 4 -ErrorAction Stop; Write-Host 'Successfully disabled the service. It will not start automatically on next boot.'; } catch { Write-Error "^""Failed to disable the service. Error: $($_.Exception.Message)"^""; Exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable search's access to location------------
:: ----------------------------------------------------------
echo --- Disable search's access to location
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AllowSearchToUseLocation"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowSearchToUseLocation' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!AllowSearchToUseLocation"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'AllowSearchToUseLocation' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -Disable local search history (breaks recent suggestions)-
:: ----------------------------------------------------------
echo --- Disable local search history (breaks recent suggestions)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\Explorer!DisableSearchHistory"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\Explorer'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\Explorer' /v 'DisableSearchHistory' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings!IsDeviceSearchHistoryEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings'; $data = '1'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' /v 'IsDeviceSearchHistoryEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Disable sharing personal search data with Microsoft----
:: ----------------------------------------------------------
echo --- Disable sharing personal search data with Microsoft
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!ConnectedSearchPrivacy"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '3'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'ConnectedSearchPrivacy' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable personal cloud content search in taskbar-----
:: ----------------------------------------------------------
echo --- Disable personal cloud content search in taskbar
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings!IsMSACloudSearchEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' /v 'IsMSACloudSearchEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings!IsAADCloudSearchEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings' /v 'IsAADCloudSearchEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Cortana during search---------------
:: ----------------------------------------------------------
echo --- Disable Cortana during search
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AllowCortana"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowCortana' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Disable Cortana experience----------------
:: ----------------------------------------------------------
echo --- Disable Cortana experience
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana!value"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\Experience\AllowCortana' /v 'value' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Cortana's access to cloud services such as OneDrive and SharePoint
echo --- Disable Cortana's access to cloud services such as OneDrive and SharePoint
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AllowCloudSearch"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowCloudSearch' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: Disable Cortana speech interaction while the system is locked
echo --- Disable Cortana speech interaction while the system is locked
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AllowCortanaAboveLock"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowCortanaAboveLock' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable participation in Cortana data collection-----
:: ----------------------------------------------------------
echo --- Disable participation in Cortana data collection
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\Search!CortanaConsent"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' /v 'CortanaConsent' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable enabling of Cortana----------------
:: ----------------------------------------------------------
echo --- Disable enabling of Cortana
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\Search!CanCortanaBeEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Search' /v 'CanCortanaBeEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Cortana in start menu---------------
:: ----------------------------------------------------------
echo --- Disable Cortana in start menu
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!CortanaEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'CortanaEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!CortanaEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'CortanaEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Remove "Cortana" icon from taskbar------------
:: ----------------------------------------------------------
echo --- Remove "Cortana" icon from taskbar
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced!ShowCortanaButton"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' /v 'ShowCortanaButton' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Cortana in ambient mode--------------
:: ----------------------------------------------------------
echo --- Disable Cortana in ambient mode
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!CortanaInAmbientMode"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'CortanaInAmbientMode' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable Cortana's history display-------------
:: ----------------------------------------------------------
echo --- Disable Cortana's history display
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!HistoryViewEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'HistoryViewEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable Cortana's device history usage----------
:: ----------------------------------------------------------
echo --- Disable Cortana's device history usage
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!DeviceHistoryEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'DeviceHistoryEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable "Hey Cortana" voice activation----------
:: ----------------------------------------------------------
echo --- Disable "Hey Cortana" voice activation
:: Set the registry value: "HKCU\Software\Microsoft\Speech_OneCore\Preferences!VoiceActivationOn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Speech_OneCore\Preferences'; $data = '0'; reg add 'HKCU\Software\Microsoft\Speech_OneCore\Preferences' /v 'VoiceActivationOn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\Software\Microsoft\Speech_OneCore\Preferences!VoiceActivationDefaultOn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Microsoft\Speech_OneCore\Preferences'; $data = '0'; reg add 'HKLM\Software\Microsoft\Speech_OneCore\Preferences' /v 'VoiceActivationDefaultOn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Cortana keyboard shortcut (**Windows logo key** + **C**)
echo --- Disable Cortana keyboard shortcut (**Windows logo key** + **C**)
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!VoiceShortcut"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'VoiceShortcut' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Cortana on locked device-------------
:: ----------------------------------------------------------
echo --- Disable Cortana on locked device
:: Set the registry value: "HKCU\Software\Microsoft\Speech_OneCore\Preferences!VoiceActivationEnableAboveLockscreen"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Speech_OneCore\Preferences'; $data = '0'; reg add 'HKCU\Software\Microsoft\Speech_OneCore\Preferences' /v 'VoiceActivationEnableAboveLockscreen' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable automatic update of speech data----------
:: ----------------------------------------------------------
echo --- Disable automatic update of speech data
:: Set the registry value: "HKCU\Software\Microsoft\Speech_OneCore\Preferences!ModelDownloadAllowed"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Speech_OneCore\Preferences'; $data = '0'; reg add 'HKCU\Software\Microsoft\Speech_OneCore\Preferences' /v 'ModelDownloadAllowed' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable Cortana voice support during Windows setup----
:: ----------------------------------------------------------
echo --- Disable Cortana voice support during Windows setup
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE!DisableVoice"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' /v 'DisableVoice' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable indexing of encrypted items------------
:: ----------------------------------------------------------
echo --- Disable indexing of encrypted items
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AllowIndexingEncryptedStoresOrItems"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AllowIndexingEncryptedStoresOrItems' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable automatic language detection when indexing----
:: ----------------------------------------------------------
echo --- Disable automatic language detection when indexing
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!AlwaysUseAutoLangDetection"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'AlwaysUseAutoLangDetection' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable remote access to search index-----------
:: ----------------------------------------------------------
echo --- Disable remote access to search index
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!PreventRemoteQueries"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'PreventRemoteQueries' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable iFilters and protocol handlers----------
:: ----------------------------------------------------------
echo --- Disable iFilters and protocol handlers
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!PreventUnwantedAddIns"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = ' '; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'PreventUnwantedAddIns' /t 'REG_SZ' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: Disable Bing search and recent search suggestions (breaks search history)
echo --- Disable Bing search and recent search suggestions (breaks search history)
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer!DisableSearchBoxSuggestions"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' /v 'DisableSearchBoxSuggestions' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!DisableSearchBoxSuggestions"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'DisableSearchBoxSuggestions' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable Bing search in start menu-------------
:: ----------------------------------------------------------
echo --- Disable Bing search in start menu
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search!BingSearchEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' /v 'BingSearchEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable web search in search bar-------------
:: ----------------------------------------------------------
echo --- Disable web search in search bar
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!DisableWebSearch"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'DisableWebSearch' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable web results in Windows Search-----------
:: ----------------------------------------------------------
echo --- Disable web results in Windows Search
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!ConnectedSearchUseWeb"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'ConnectedSearchUseWeb' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!ConnectedSearchUseWebOverMeteredConnections"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'ConnectedSearchUseWebOverMeteredConnections' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable Windows search highlights-------------
:: ----------------------------------------------------------
echo --- Disable Windows search highlights
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search!EnableDynamicContentInWSB"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search' /v 'EnableDynamicContentInWSB' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings!IsDynamicSearchBoxEnabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings'; $data = '1'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings' /v 'IsDynamicSearchBoxEnabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Suggest restarting explorer.exe for changes to take effect
PowerShell -ExecutionPolicy Unrestricted -Command "$message = 'This script will not take effect until you restart explorer.exe. You can restart explorer.exe by restarting your computer or by running following on command prompt: `taskkill /f /im explorer.exe & start explorer`.'; $warn =  $false; if ($warn) { Write-Warning "^""$message"^""; } else { Write-Host "^""Note: "^"" -ForegroundColor Blue -NoNewLine; Write-Output "^""$message"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable ad customization with Advertising ID-------
:: ----------------------------------------------------------
echo --- Disable ad customization with Advertising ID
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo!DisabledByGroupPolicy"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo' /v 'DisabledByGroupPolicy' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable suggested content in Settings app---------
:: ----------------------------------------------------------
echo --- Disable suggested content in Settings app
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager!SubscribedContent-338393Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v 'SubscribedContent-338393Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager!SubscribedContent-353694Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v 'SubscribedContent-353694Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager!SubscribedContent-353696Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'; $data = '0'; reg add 'HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' /v 'SubscribedContent-353696Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Disable Windows Tips-------------------
:: ----------------------------------------------------------
echo --- Disable Windows Tips
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent!DisableSoftLanding"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' /v 'DisableSoftLanding' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable Windows Spotlight (shows random wallpapers on lock screen)
echo --- Disable Windows Spotlight (shows random wallpapers on lock screen)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\CloudContent!DisableWindowsSpotlightFeatures"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\CloudContent'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\CloudContent' /v 'DisableWindowsSpotlightFeatures' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable Microsoft Consumer Experiences----------
:: ----------------------------------------------------------
echo --- Disable Microsoft Consumer Experiences
:: Set the registry value: "HKLM\Software\Policies\Microsoft\Windows\CloudContent!DisableWindowsConsumerFeatures"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\Windows\CloudContent'; $data = '1'; reg add 'HKLM\Software\Policies\Microsoft\Windows\CloudContent' /v 'DisableWindowsConsumerFeatures' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable "Windows Insider Service"-------------
:: ----------------------------------------------------------
echo --- Disable "Windows Insider Service"
:: Disable service(s): `wisvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'wisvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Microsoft feature trials-------------
:: ----------------------------------------------------------
echo --- Disable Microsoft feature trials
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds!EnableExperimentation"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' /v 'EnableExperimentation' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds!EnableConfigFlighting"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' /v 'EnableConfigFlighting' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation!value"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\System\AllowExperimentation' /v 'value' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable receipt of Windows preview builds---------
:: ----------------------------------------------------------
echo --- Disable receipt of Windows preview builds
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds!AllowBuildPreview"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\PreviewBuilds' /v 'AllowBuildPreview' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------Remove "Windows Insider Program" from Settings------
:: ----------------------------------------------------------
echo --- Remove "Windows Insider Program" from Settings
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility!HideInsiderPage"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\WindowsSelfHost\UI\Visibility' /v 'HideInsiderPage' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------------Disable Recall----------------------
:: ----------------------------------------------------------
echo --- Disable Recall
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot!DisableAIDataAnalysis"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' /v 'DisableAIDataAnalysis' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable cloud-based speech recognition----------
:: ----------------------------------------------------------
echo --- Disable cloud-based speech recognition
:: Set the registry value: "HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy!HasAccepted"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy'; $data = '0'; reg add 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' /v 'HasAccepted' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Opt out of Windows privacy consent------------
:: ----------------------------------------------------------
echo --- Opt out of Windows privacy consent
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Personalization\Settings!AcceptedPrivacyPolicy"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Personalization\Settings'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Personalization\Settings' /v 'AcceptedPrivacyPolicy' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable Windows feedback collection------------
:: ----------------------------------------------------------
echo --- Disable Windows feedback collection
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Siuf\Rules!NumberOfSIUFInPeriod"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Siuf\Rules' /v 'NumberOfSIUFInPeriod' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Delete the registry value "PeriodInNanoSeconds" from the key "HKCU\SOFTWARE\Microsoft\Siuf\Rules" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKCU\SOFTWARE\Microsoft\Siuf\Rules'; $valueName = 'PeriodInNanoSeconds'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection!DoNotShowFeedbackNotifications"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection'; $data = '1'; reg add 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' /v 'DoNotShowFeedbackNotifications' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection!DoNotShowFeedbackNotifications"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' /v 'DoNotShowFeedbackNotifications' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable text and handwriting data collection-------
:: ----------------------------------------------------------
echo --- Disable text and handwriting data collection
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization!RestrictImplicitInkCollection"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization' /v 'RestrictImplicitInkCollection' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization!RestrictImplicitTextCollection"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization' /v 'RestrictImplicitTextCollection' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports!PreventHandwritingErrorReports"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports' /v 'PreventHandwritingErrorReports' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC!PreventHandwritingDataSharing"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC' /v 'PreventHandwritingDataSharing' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization!AllowInputPersonalization"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\InputPersonalization' /v 'AllowInputPersonalization' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore!HarvestContacts"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\InputPersonalization\TrainedDataStore' /v 'HarvestContacts' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------------Disable device sensors------------------
:: ----------------------------------------------------------
echo --- Disable device sensors
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors!DisableSensors"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' /v 'DisableSensors' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------------Disable Wi-Fi Sense--------------------
:: ----------------------------------------------------------
echo --- Disable Wi-Fi Sense
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting!value"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' /v 'value' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config!AutoConnectAllowedOEM"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' /v 'AutoConnectAllowedOEM' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable automatic map downloads--------------
:: ----------------------------------------------------------
echo --- Disable automatic map downloads
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps!AllowUntriggeredNetworkTrafficOnSettingsPage"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' /v 'AllowUntriggeredNetworkTrafficOnSettingsPage' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps!AutoDownloadAndUpdateMapData"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Maps' /v 'AutoDownloadAndUpdateMapData' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable game screen recording---------------
:: ----------------------------------------------------------
echo --- Disable game screen recording
:: Set the registry value: "HKCU\System\GameConfigStore!GameDVR_Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\System\GameConfigStore'; $data = '0'; reg add 'HKCU\System\GameConfigStore' /v 'GameDVR_Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR!AllowGameDVR"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR' /v 'AllowGameDVR' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Activity Feed feature---------------
:: ----------------------------------------------------------
echo --- Disable Activity Feed feature
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\Windows\System!EnableActivityFeed"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System'; $data = '0'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\Windows\System' /v 'EnableActivityFeed' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------Disable typing feedback (sends typing data)--------
:: ----------------------------------------------------------
echo --- Disable typing feedback (sends typing data)
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\Input\TIPC!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\Input\TIPC'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\Input\TIPC' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Input\TIPC!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Input\TIPC'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Input\TIPC' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable participation in Visual Studio Customer Experience Improvement Program (VSCEIP)
echo --- Disable participation in Visual Studio Customer Experience Improvement Program (VSCEIP)
:: Set the registry value: "HKLM\Software\Policies\Microsoft\VisualStudio\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\Software\Policies\Microsoft\VisualStudio\SQM'; $data = '0'; reg add 'HKLM\Software\Policies\Microsoft\VisualStudio\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\VSCommon\14.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\VSCommon\14.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\VSCommon\14.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\14.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\VSCommon\15.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\VSCommon\15.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\VSCommon\15.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\15.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Microsoft\VSCommon\16.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Microsoft\VSCommon\16.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Microsoft\VSCommon\16.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\16.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM!OptIn"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM'; $data = '0'; reg add 'HKLM\SOFTWARE\Wow6432Node\Microsoft\VSCommon\17.0\SQM' /v 'OptIn' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Visual Studio telemetry--------------
:: ----------------------------------------------------------
echo --- Disable Visual Studio telemetry
:: Set the registry value: "HKCU\Software\Microsoft\VisualStudio\Telemetry!TurnOffSwitch"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Microsoft\VisualStudio\Telemetry'; $data = '1'; reg add 'HKCU\Software\Microsoft\VisualStudio\Telemetry' /v 'TurnOffSwitch' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable Visual Studio feedback--------------
:: ----------------------------------------------------------
echo --- Disable Visual Studio feedback
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback!DisableFeedbackDialog"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' /v 'DisableFeedbackDialog' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback!DisableEmailInput"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' /v 'DisableEmailInput' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback!DisableScreenshotCapture"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\Feedback' /v 'DisableScreenshotCapture' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----Disable "Visual Studio Standard Collector Service"----
:: ----------------------------------------------------------
echo --- Disable "Visual Studio Standard Collector Service"
:: Disable service(s): `VSStandardCollectorService150`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'VSStandardCollectorService150'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------Disable Diagnostics Hub log collection----------
:: ----------------------------------------------------------
echo --- Disable Diagnostics Hub log collection
:: Delete the registry value "LogLevel" from the key "HKLM\Software\Microsoft\VisualStudio\DiagnosticsHub" 
PowerShell -ExecutionPolicy Unrestricted -Command "$keyName = 'HKLM\Software\Microsoft\VisualStudio\DiagnosticsHub'; $valueName = 'LogLevel'; $hive = $keyName.Split('\')[0]; $path = "^""$($hive):$($keyName.Substring($hive.Length))"^""; Write-Host "^""Removing the registry value '$valueName' from '$path'."^""; if (-Not (Test-Path -LiteralPath $path)) { Write-Host 'Skipping, no action needed, registry key does not exist.'; Exit 0; }; $existingValueNames = (Get-ItemProperty -LiteralPath $path).PSObject.Properties.Name; if (-Not ($existingValueNames -Contains $valueName)) { Write-Host 'Skipping, no action needed, registry value does not exist.'; Exit 0; }; try { if ($valueName -ieq '(default)') { Write-Host 'Removing the default value.'; $(Get-Item -LiteralPath $path).OpenSubKey('', $true).DeleteValue(''); } else { Remove-ItemProperty -LiteralPath $path -Name $valueName -Force -ErrorAction Stop; }; Write-Host 'Successfully removed the registry value.'; } catch { Write-Error "^""Failed to remove the registry value: $($_.Exception.Message)"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Disable participation in IntelliCode data collection---
:: ----------------------------------------------------------
echo --- Disable participation in IntelliCode data collection
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode!DisableRemoteAnalysis"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\VisualStudio\IntelliCode' /v 'DisableRemoteAnalysis' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode!DisableRemoteAnalysis"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\VSCommon\16.0\IntelliCode' /v 'DisableRemoteAnalysis' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode!DisableRemoteAnalysis"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\VSCommon\17.0\IntelliCode' /v 'DisableRemoteAnalysis' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----------Disable Visual Studio Code telemetry-----------
:: ----------------------------------------------------------
echo --- Disable Visual Studio Code telemetry
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='telemetry.enableTelemetry'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable Visual Studio Code crash reporting--------
:: ----------------------------------------------------------
echo --- Disable Visual Studio Code crash reporting
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='telemetry.enableCrashReporter'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Disable online experiments by Microsoft in Visual Studio Code
echo --- Disable online experiments by Microsoft in Visual Studio Code
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='workbench.enableExperiments'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Disable Visual Studio Code automatic updates in favor of manual updates
echo --- Disable Visual Studio Code automatic updates in favor of manual updates
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='update.mode'; $settingValue='manual'; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Disable fetching release notes from Microsoft servers after an update
echo --- Disable fetching release notes from Microsoft servers after an update
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='update.showReleaseNotes'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Automatically check extensions from Microsoft online service
echo --- Automatically check extensions from Microsoft online service
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='extensions.autoCheckUpdates'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---Fetch recommendations from Microsoft only on demand----
:: ----------------------------------------------------------
echo --- Fetch recommendations from Microsoft only on demand
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='extensions.showRecommendationsOnlyOnDemand'; $settingValue=$true; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Disable automatic fetching of remote repositories in Visual Studio Code
echo --- Disable automatic fetching of remote repositories in Visual Studio Code
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='git.autofetch'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: Disable fetching package information from NPM and Bower in Visual Studio Code
echo --- Disable fetching package information from NPM and Bower in Visual Studio Code
PowerShell -ExecutionPolicy Unrestricted -Command "$settingKey='npm.fetchOnlinePackageInfo'; $settingValue=$false; $jsonFilePath = "^""$($env:APPDATA)\Code\User\settings.json"^""; if (!(Test-Path $jsonFilePath -PathType Leaf)) { Write-Host "^""Skipping, no updates. Settings file was not at `"^""$jsonFilePath`"^""."^""; exit 0; }; try { $fileContent = Get-Content $jsonFilePath -ErrorAction Stop; } catch { throw "^""Error, failed to read the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; if ([string]::IsNullOrWhiteSpace($fileContent)) { Write-Host "^""Settings file is empty. Treating it as default empty JSON object."^""; $fileContent = "^""{}"^""; }; try { $json = $fileContent | ConvertFrom-Json; } catch { throw "^""Error, invalid JSON format in the settings file: `"^""$jsonFilePath`"^"". Error: $_"^""; }; $existingValue = $json.$settingKey; if ($existingValue -eq $settingValue) { Write-Host "^""Skipping, `"^""$settingKey`"^"" is already configured as `"^""$settingValue`"^""."^""; exit 0; }; $json | Add-Member -Type NoteProperty -Name $settingKey -Value $settingValue -Force; $json | ConvertTo-Json | Set-Content $jsonFilePath; Write-Host "^""Successfully applied the setting to the file: `"^""$jsonFilePath`"^""."^"""
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable Microsoft Office logging-------------
:: ----------------------------------------------------------
echo --- Disable Microsoft Office logging
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Mail' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Mail' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar!EnableCalendarLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Outlook\Options\Calendar' /v 'EnableCalendarLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar!EnableCalendarLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Outlook\Options\Calendar' /v 'EnableCalendarLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Word\Options!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Word\Options'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Word\Options' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Word\Options!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Word\Options'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Word\Options' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM'; $data = '0'; reg add 'HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM!EnableLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM'; $data = '0'; reg add 'HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM' /v 'EnableLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM!EnableUpload"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM'; $data = '0'; reg add 'HKCU\SOFTWARE\Policies\Microsoft\Office\15.0\OSM' /v 'EnableUpload' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM!EnableUpload"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM'; $data = '0'; reg add 'HKCU\SOFTWARE\Policies\Microsoft\Office\16.0\OSM' /v 'EnableUpload' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------Disable Microsoft Office client telemetry---------
:: ----------------------------------------------------------
echo --- Disable Microsoft Office client telemetry
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry!DisableTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry' /v 'DisableTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry!DisableTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry' /v 'DisableTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry!DisableTelemetry"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry'; $data = '1'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry' /v 'DisableTelemetry' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry!VerboseLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\Common\ClientTelemetry' /v 'VerboseLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry!VerboseLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\ClientTelemetry' /v 'VerboseLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry!VerboseLogging"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\ClientTelemetry' /v 'VerboseLogging' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable user participation in Office Customer Experience Improvement Program (CEIP)
echo --- Disable user participation in Office Customer Experience Improvement Program (CEIP)
:: Set the registry value: "HKCU\Software\Policies\Microsoft\Office\15.0\Common!QMEnable"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\Office\15.0\Common'; $data = '0'; reg add 'HKCU\Software\Policies\Microsoft\Office\15.0\Common' /v 'QMEnable' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Policies\Microsoft\Office\16.0\Common!QMEnable"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\Office\16.0\Common'; $data = '0'; reg add 'HKCU\Software\Policies\Microsoft\Office\16.0\Common' /v 'QMEnable' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ------------Disable Microsoft Office feedback-------------
:: ----------------------------------------------------------
echo --- Disable Microsoft Office feedback
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Feedback!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Feedback'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\15.0\Common\Feedback' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\Office\16.0\Common\Feedback!Enabled"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\Feedback'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\Office\16.0\Common\Feedback' /v 'Enabled' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------Disable Microsoft Office telemetry agent---------
:: ----------------------------------------------------------
echo --- Disable Microsoft Office telemetry agent
:: Disable scheduled task(s): `\Microsoft\Office\OfficeTelemetryAgentFallBack`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Office\'; $taskNamePattern='OfficeTelemetryAgentFallBack'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\Microsoft\Office\OfficeTelemetryAgentFallBack2016`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Office\'; $taskNamePattern='OfficeTelemetryAgentFallBack2016'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\Microsoft\Office\OfficeTelemetryAgentLogOn`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Office\'; $taskNamePattern='OfficeTelemetryAgentLogOn'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: Disable scheduled task(s): `\Microsoft\Office\OfficeTelemetryAgentLogOn2016`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Office\'; $taskNamePattern='OfficeTelemetryAgentLogOn2016'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --Disable "Microsoft Office Subscription Heartbeat" task--
:: ----------------------------------------------------------
echo --- Disable "Microsoft Office Subscription Heartbeat" task
:: Disable scheduled task(s): `\Microsoft\Office\Office 15 Subscription Heartbeat`
PowerShell -ExecutionPolicy Unrestricted -Command "$taskPathPattern='\Microsoft\Office\'; $taskNamePattern='Office 15 Subscription Heartbeat'; Write-Output "^""Disabling tasks matching pattern `"^""$taskNamePattern`"^""."^""; $tasks = @(Get-ScheduledTask -TaskPath $taskPathPattern -TaskName $taskNamePattern -ErrorAction Ignore); if (-Not $tasks) { Write-Output "^""Skipping, no tasks matching pattern `"^""$taskNamePattern`"^"" found, no action needed."^""; exit 0; }; $operationFailed = $false; foreach ($task in $tasks) { $taskName = $task.TaskName; if ($task.State -eq [Microsoft.PowerShell.Cmdletization.GeneratedTypes.ScheduledTask.StateEnum]::Disabled) { Write-Output "^""Skipping, task `"^""$taskName`"^"" is already disabled, no action needed."^""; continue; }; try { $task | Disable-ScheduledTask -ErrorAction Stop | Out-Null; Write-Output "^""Successfully disabled task `"^""$taskName`"^""."^""; } catch { Write-Error "^""Failed to disable task `"^""$taskName`"^"": $($_.Exception.Message)"^""; $operationFailed = $true; }; }; if ($operationFailed) { Write-Output 'Failed to disable some tasks. Check error messages above.'; exit 1; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -----Disable sending Windows Media Player statistics------
:: ----------------------------------------------------------
echo --- Disable sending Windows Media Player statistics
:: Set the registry value: "HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences!UsageTracking"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences'; $data = '0'; reg add 'HKCU\SOFTWARE\Microsoft\MediaPlayer\Preferences' /v 'UsageTracking' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ----------------Disable metadata retrieval----------------
:: ----------------------------------------------------------
echo --- Disable metadata retrieval
:: Set the registry value: "HKCU\Software\Policies\Microsoft\WindowsMediaPlayer!PreventCDDVDMetadataRetrieval"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer'; $data = '1'; reg add 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer' /v 'PreventCDDVDMetadataRetrieval' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Policies\Microsoft\WindowsMediaPlayer!PreventMusicFileMetadataRetrieval"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer'; $data = '1'; reg add 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer' /v 'PreventMusicFileMetadataRetrieval' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Policies\Microsoft\WindowsMediaPlayer!PreventRadioPresetsRetrieval"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer'; $data = '1'; reg add 'HKCU\Software\Policies\Microsoft\WindowsMediaPlayer' /v 'PreventRadioPresetsRetrieval' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKLM\SOFTWARE\Policies\Microsoft\WMDRM!DisableOnline"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM'; $data = '1'; reg add 'HKLM\SOFTWARE\Policies\Microsoft\WMDRM' /v 'DisableOnline' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Disable "Windows Media Player Network Sharing Service" (`WMPNetworkSvc`)
echo --- Disable "Windows Media Player Network Sharing Service" (`WMPNetworkSvc`)
:: Disable service(s): `WMPNetworkSvc`
PowerShell -ExecutionPolicy Unrestricted -Command "$serviceName = 'WMPNetworkSvc'; Write-Host "^""Disabling service: `"^""$serviceName`"^""."^""; <# -- 1. Skip if service does not exist #>; $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue; if(!$service) { Write-Host "^""Service `"^""$serviceName`"^"" could not be not found, no need to disable it."^""; Exit 0; }; <# -- 2. Stop if running #>; if ($service.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running) { Write-Host "^""`"^""$serviceName`"^"" is running, stopping it."^""; try { Stop-Service -Name "^""$serviceName"^"" -Force -ErrorAction Stop; Write-Host "^""Stopped `"^""$serviceName`"^"" successfully."^""; } catch { Write-Warning "^""Could not stop `"^""$serviceName`"^"", it will be stopped after reboot: $_"^""; }; } else { Write-Host "^""`"^""$serviceName`"^"" is not running, no need to stop."^""; }; <# -- 3. Skip if already disabled #>; $startupType = $service.StartType <# Does not work before .NET 4.6.1 #>; if (!$startupType) { $startupType = (Get-WmiObject -Query "^""Select StartMode From Win32_Service Where Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; if(!$startupType) { $startupType = (Get-WmiObject -Class Win32_Service -Property StartMode -Filter "^""Name='$serviceName'"^"" -ErrorAction Ignore).StartMode; }; }; if ($startupType -eq 'Disabled') { Write-Host "^""$serviceName is already disabled, no further action is needed"^""; Exit 0; }; <# -- 4. Disable service #>; try { Set-Service -Name "^""$serviceName"^"" -StartupType Disabled -Confirm:$false -ErrorAction Stop; Write-Host "^""Disabled `"^""$serviceName`"^"" successfully."^""; } catch { Write-Error "^""Could not disable `"^""$serviceName`"^"": $_"^""; }"
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: --------------Disable NET Core CLI telemetry--------------
:: ----------------------------------------------------------
echo --- Disable NET Core CLI telemetry
setx DOTNET_CLI_TELEMETRY_OPTOUT 1
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: ---------------Disable PowerShell telemetry---------------
:: ----------------------------------------------------------
echo --- Disable PowerShell telemetry
setx POWERSHELL_TELEMETRY_OPTOUT 1
:: ----------------------------------------------------------


:: ----------------------------------------------------------
:: -------------Disable CCleaner data collection-------------
:: ----------------------------------------------------------
echo --- Disable CCleaner data collection
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!Monitoring"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'Monitoring' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!HelpImproveCCleaner"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'HelpImproveCCleaner' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!SystemMonitoring"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'SystemMonitoring' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!UpdateAuto"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'UpdateAuto' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!UpdateCheck"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'UpdateCheck' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!UpdateBackground"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'UpdateBackground' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!CheckTrialOffer"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v 'CheckTrialOffer' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)HealthCheck"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)HealthCheck' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)QuickClean"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)QuickClean' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)QuickCleanIpm"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)QuickCleanIpm' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)GetIpmForTrial"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)GetIpmForTrial' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)SoftwareUpdater"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)SoftwareUpdater' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: Set the registry value: "HKCU\Software\Piriform\CCleaner!(Cfg)SoftwareUpdaterIpm"
PowerShell -ExecutionPolicy Unrestricted -Command "$registryPath = 'HKCU\Software\Piriform\CCleaner'; $data = '0'; reg add 'HKCU\Software\Piriform\CCleaner' /v '(Cfg)SoftwareUpdaterIpm' /t 'REG_DWORD' /d "^""$data"^"" /f"
:: ----------------------------------------------------------


:: Pause the script to view the final state
pause
:: Restore previous environment settings
endlocal
goto main_menu

:system_repair
@echo off
cls
title Windows System Repair
echo ======================================
echo  Starting Windows System Repair...
echo ======================================
echo.

:: Run CHKDSK
echo (1/7) Running CHKDSK...
chkdsk /f
echo.
echo CHKDSK Completed.
pause

:: Run SFC /SCANNOW
echo (2/7) Running SFC /SCANNOW - 1st scan...
sfc /scannow
echo.
echo SFC Scan Completed.
pause

:: Run DISM /SCANHEALTH
echo (3/7) Running DISM /SCANHEALTH...
dism /online /cleanup-image /scanhealth
echo.
echo DISM ScanHealth Completed.
pause

:: Run DISM /CHECKHEALTH
echo (4/7) Running DISM /CHECKHEALTH...
dism /online /cleanup-image /checkhealth
echo.
echo DISM CheckHealth Completed.
pause

:: Run DISM /RESTOREHEALTH
echo (5/7) Running DISM /RESTOREHEALTH...
dism /online /cleanup-image /restorehealth
echo.
echo DISM RestoreHealth Completed.
pause

:: Run DISM /RESTOREHEALTH
echo (6/7) Running DISM /COMPONENTCLEANUP...
dism.exe /online /cleanup-image /startcomponentcleanup
echo.
echo DISM ComponentCleanUp Completed.
pause

:: Run SFC /SCANNOW again
echo (7/7) Running SFC /SCANNOW - 2nd scan...
sfc /scannow
echo.

echo Final SFC Scan Completed.
echo ======================================
echo  Windows System Repair Completed!
echo ======================================
pause

:: Prompt for DISM RestoreHealth with Source
:restore_health_source
echo ======================================
echo Do you want to run DISM RestoreHealth with install.wim source?
echo [1] Yes
echo [2] No (Skip)
echo ======================================
set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="1" goto run_restore_with_source
if "%choice%"=="2" goto main_menu
echo Invalid choice, please try again.
pause
goto restore_health_source

:run_restore_with_source
echo Running DISM RestoreHealth with install.wim source...
dism /Online /Cleanup-Image /RestoreHealth /Source:D:\Win11Pro_23H2_English_x64_Custom\sources\install.wim /limitaccess
echo.
echo DISM RestoreHealth with source completed.
pause
goto main_menu

:view_sysinfo
@echo off
title Export .NFO System Information
cls

set "NFO_FILE=%USERPROFILE%\Desktop\System_Info_Report.nfo"

echo =============================================
echo   EXPORTING SYSTEM INFORMATION TO .NFO FILE
echo =============================================
echo.
echo Please wait...

msinfo32 /nfo "%NFO_FILE%"

echo.
echo =============================================
echo        EXPORT COMPLETED SUCCESSFULLY!
echo =============================================
echo File saved at: %NFO_FILE%
echo.s

echo Opening .NFO file...
start "" "%NFO_FILE%"
pause
goto main_menu

:del_temp
cls
    @echo off
    echo:
    echo: =====================================
    echo:       Deleting All Temp Files...
    echo: =====================================
    echo:
    del /s /q /f C:\Windows\Temp\*
pause
goto main_menu

:reset_net
cls
    @echo off
    echo:
    echo: =====================================
    echo:         Resetting Network...
    echo: =====================================
    echo:
:: Step 1: Flush DNS
echo.
echo [1/5] Flushing DNS Resolver Cache...
netsh winsock reset
netsh int ip reset
ipconfig /flushdns
ipconfig /release
ipconfig /renew
echo.
:: Step 2: Flush & re-register NetBIOS
echo [2/5] Flushing NetBIOS cache...
nbtstat -R
echo [3/5] Re-registering NetBIOS names...
nbtstat -RR
echo.
:: Step 3: Restart Workstation service (NetBIOS helper)
echo [4/5] Restarting Workstation service...
net stop workstation >nul
net start workstation >nul
echo.
:: Step 4: Restart Network Adapter (optional, using devcon)
echo [5/5] Resetting Network Adapter...
echo (This may disconnect and reconnect your network temporarily)
echo.
:: You can replace "Wi-Fi" or "Ethernet" based on your adapter name:
netsh interface set interface name="Wi-Fi/Ethernet" admin=disable
timeout /t 3 >nul
netsh interface set interface name="Wi-Fi/Ethernet" admin=enable
:: Step 5: Restart Windows Explorer
echo.
echo Restarting Windows Explorer...
taskkill /f /im explorer.exe >nul
timeout /t 1 >nul
start explorer.exe

:: Done
echo.
echo Network Reset Completed!
pause
goto main_menu

:service_printer
@echo off
cls
echo.
:: Aktifkan Fitur Windows: SMB 1.0/CIFS File Sharing
echo Mengaktifkan fitur Windows: SMB 1.0/CIFS File Sharing Support...
dism /online /enable-feature /featurename:SMB1Protocol /all /quiet /norestart
echo.
echo.
echo Mengedit Group Policy untuk konfigurasi RPC
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcOverNamedPipes /t REG_DWORD /d 1 /f
reg add "HKLM\Software\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcOverTcp /t REG_DWORD /d 0 /f
echo.
echo.
echo Mengatur Registry RpcAuthnLevelPrivacyEnabled ke 0
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Print" /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 /f
echo.
echo.
echo Mengatur Registry AllowInsecureGuestAuth ke 1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v AllowInsecureGuestAuth /t REG_DWORD /d 1 /f
echo.
echo.
echo Mengaktifkan Fitur Windows Print and Document Services
dism /online /enable-feature /featurename:Printing-Foundation-LPRPortMonitor /quiet /norestart
dism /online /enable-feature /featurename:Printing-Foundation-LPDPrintService /quiet /norestart
echo.
echo.
echo Restart layanan Print Spooler
net stop spooler
net start spooler
echo.
echo.
echo Configuration is complete. Please restart the computer for the changes to take effect.
pause
goto main_menu

:extension_off
@echo off
cls
echo.
:: Fix Chrome Extension V2 Support Disabled Issue

echo Applying fix for unsupported Chrome extension...

reg add "HKCU\Software\Policies\Google\Chrome" /v ExtensionManifestV2Availability /t REG_DWORD /d 2 /f

echo.
echo Fix applied. Please restart Google Chrome.
pause
goto main_menu


:form_it
@echo off
cls
setlocal

:: Coba buka Chrome jika terinstall di lokasi default
set "chromePath=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if exist "%chromePath%" (
    start "" "%chromePath%" "https://forms.gle/skCPRWa44Zz5ojfr7" /b
)

:: Coba di lokasi 64-bit
set "chromePath=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if exist "%chromePath%" (
    start "" "%chromePath%" "https://forms.gle/skCPRWa44Zz5ojfr7" /b
)

:: Jika Chrome tidak ditemukan, buka pakai browser default
start "" "https://forms.gle/skCPRWa44Zz5ojfr7"
pause
goto main_menu

:bypasswin11
@echo off
cls
:: Bypass Windows 11 Installation Requirements via Registry
:: Harus dijalankan sebagai Administrator
echo.
echo ====================================================
echo       Applying Windows 11 Installation Bypass
echo ====================================================
echo.

echo Bypass CPU check
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f
echo.
echo Bypass TPM 2.0 check
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f
echo.
echo Bypass Secure Boot check
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f
echo.
echo Bypass RAM check (minimal 4GB)
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f
echo.
echo Bypass Storage Check
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f
echo.
echo Optional: Bypass Microsoft Account requirement
reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassNetworkCheck /t REG_DWORD /d 1 /f

echo.
echo ====================================================
echo              Bypass berhasil diterapkan
echo ====================================================
echo.
pause
goto main_menu

:error709
@echo off
cls
echo.
echo =====================================================
echo     Addtional Printer Settings (Error 0x00000709)
echo =====================================================
echo.
echo [1] Configure RPC connection settings
echo     - Status        : Enabled
echo     - Protocol used : RPC over named pipes
echo     - Lokasi        : Computer Configuration \ Administrative Templates \ Printers \ Configure RPC connection settings
echo.
echo.
echo [2] Configure RPC listener settings
echo     - Status        : Enabled
echo     - Protocol used : RPC over named pipes and TCP
echo     - Lokasi        : Computer Configuration \ Administrative Templates \ Printers \ Configure RPC listener settings
echo.
echo.
echo [3] Configure RPC over TCP port
echo     - Status        : Enabled
echo     - Lokasi        : Computer Configuration \ Administrative Templates \ Printers \ Configure RPC over TCP port
echo.
echo.
echo Catatan:
echo - Silakan buka 'Local Group Policy Editor' atau 'gpedit.msc' dan navigasikan ke lokasi di atas untuk menerapkan pengaturan tersebut secara manual.
echo - Restart komputer jika diperlukan.
echo.
echo.
pause
goto main_menu 

:error3e3
@echo off
cls
echo.
echo =====================================================
echo     Addtional Printer Settings (Error 0x000003e3)
echo =====================================================
echo.
echo [1] Tekan tombol Logo Windows + R pada keyboard untuk membuka Windows Run.
echo.
echo [2] Ketikkan: REGEDIT lalu tekan ENTER.
echo.
echo [3] Arahkan ke lokasi berikut di Registry Editor:
echo.
echo    HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3\Merk_Tipe_Printer_Kamu
echo.
echo [4] Klik dua kali, ubah nilainya menjadi: 1
echo.
echo [5] Klik OK dan tutup Registry Editor.
echo.
echo [6] Restart komputer jika diperlukan.
echo.
echo Catatan:
echo - Ganti "Merk_Tipe_Printer_Kamu" dengan nama folder sesuai printer yang kamu gunakan.
echo.
echo.
pause
goto main_menu 

:rstintel
@echo off
cls
echo.
echo =====================================================
echo         SSD TIDAK MUNCUL SAAT INSTAL WINDOWS
echo =====================================================
echo.
echo Konteks Permasalahan:
echo Saat melakukan instalasi Windows, SSD (terutama NVMe atau RAID) tidak terdeteksi di jendela pemilihan partisi
echo.
echo [1] Solusi: Extract Driver RST dengan SetupRST.exe
echo     - Download SetupRST dari situs resmi Intel:
echo     - Simpan file SetupRST.exe ke root drive C: (Contoh lokasi: C:\SetupRST.exe)  
echo.
echo [2] Langkah Ekstraksi Driver
echo     - Buka Command Prompt sebagai Administrator
echo     - Ketik cmd, klik kanan Command Prompt lalu pilih Run as Administrator.
echo     - Jalankan perintah berikut: "C:\SetupRST.exe -extractdrivers RST"
echo     - Setelah proses selesai, driver akan diekstrak ke: (C:RST)
echo.
echo [3] Gunakan Driver Saat Instalasi Windows
echo     - Buat USB installer Windows seperti biasa.
echo     - Salin folder hasil ekstrak (C:RST) ke dalam USB installer Windows.
echo       Bisa ke folder Drivers, atau langsung di root USB.
echo     - Saat instalasi Windows dan SSD tidak terdeteksi, klik:
echo       Load driver / Browse / Pilih folder Intel RST yang kamu salin tadi / pilih file dengan format .inf
echo     - Windows akan memuat driver, dan SSD akan muncul.
echo.
echo [4] Catatan Tambahan:
echo     - Pastikan BIOS Mode menggunakan RAID atau RST, bukan AHCI.
echo     - Jika BIOS menggunakan AHCI, SSD seharusnya langsung terdeteksi tanpa driver tambahan.
echo     - Download SetupRST.exe sesuai dengan Gen Intel kamu
echo.
echo.
pause
goto main_menu 

:undervoltloq
@echo off
cls
echo.
echo =====================================================
echo         SETTING SETUP UNDERVOLT LENOVO LOQ
echo =====================================================
echo.
echo [1] Aktifkan Pengaturan BIOS
echo     - Restart laptop dan masuk ke BIOS (biasanya dengan menekan tombol F2 atau Delete saat boot).
echo     - Cari dan aktifkan opsi: Legion Optimization
echo     - Simpan perubahan dan keluar dari BIOS (Save and Exit).
echo     - Laptop akan reboot secara otomatis.
echo.
echo [2] Konfigurasi di ThrottleStop
echo     - Buka aplikasi ThrottleStop sebagai Administrator.
echo     - Masuk ke menu FIVR (Voltage Adjustment).
echo     - Pastikan judul bagian ini adalah FIVR Control.
echo       Jika tertulis Unlocked atau Undervolt Protection, berarti ada pengaturan BIOS lain yang belum diaktifkan.
echo       • Konfigurasi FIVR
echo       • Untuk setiap bagian di bawah ini, lakukan langkah yang sama:
echo         → Centang Unlock Adjustable Voltage
echo         → Range Pilih 250 mV
echo         → Offset Voltage: Set ke -135.7 mV
echo       • Lakukan pada:
echo         → CPU Core
echo         → CPU P Cache
echo         → CPU E Cache
echo       • Setelah selesai, di bagian bawah, Klik OK - Save voltage after ThrottleStop exits
echo       • Klik Apply, lalu OK
echo.
echo [3] Atur Power Limits (TPL)
echo     - Kembali ke menu utama ThrottleStop
echo     - Klik TPL (Turbo Power Limits)
echo     - Hilangkan centang pada opsi Disable Controls
echo     - Di bagian kanan bawah (Clamp), ubah angka menjadi 45
echo     - Klik Apply dan OK
echo.
echo [4] Konfigurasi GPU via MSI Afterburner
echo     - Buka MSI Afterburner
echo     - Klik ikon Settings (⚙️)
echo     - Masuk ke tab General
echo     - Di bawah bagian Compatibility Properties:
echo     - Hapus centang pada Unlock voltage control
echo     - Klik Apply dan OK
echo     - Kembali ke layar utama, buka Curve Editor (tekan Ctrl + F).
echo       • Di dalam Curve Editor:
echo         → Temukan titik Voltage di sekitar 925 mV
echo         → Tambahkan sekitar 229 MHz pada titik tersebut
echo         → Tekan dan tahan Shift, lalu klik kiri pada titik tersebut
echo         → Tekan Enter untuk menyimpan
echo         → Keluar lalu Save
echo.
echo.
pause
goto main_menu 

