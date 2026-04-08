@echo off
setlocal DisableDelayedExpansion

:: #######################################
for /f %%a in ('echo prompt $E ^| cmd') do set "ESC=%%a"

:: echo %ESC%[32m Green %ESC%[0m
:: echo %ESC%[33m Yellow %ESC%[0m
:: echo %ESC%[35m Magenta %ESC%[0m
:: echo %ESC%[36m Cyan %ESC%[0m
:: echo %ESC%[91m Red %ESC%[0m
:: echo %ESC%[94m Blue %ESC%[0m
:: echo %ESC%[100m Black %ESC%[0m

:: #######################################

set "BASE=%~dp0" 
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%" :: remove trailing slash
set "FOLDER="
set "GAME="
set "MOD="
set "PACK=pack.exe"
set "FILES=0"
set "PACKED=0"
set "MOVED=0"
set "PFF="

:: #######################################

cd /d "%BASE%"

:: #######################################

echo  %ESC%[0m%ESC%[36m/////////////////////////////////////////////////%ESC%[0m
echo %ESC%[36m      _   _  _____     ___    _   _  ___
echo      ^| \ ^| ^|/ _ \ \   / / \  ^| ^| ^| ^|/ _ \
echo      ^|  \^| ^| ^| ^| \ \ / / _ \ ^| ^|_^| ^| ^| ^| ^|
echo      ^| ^|\  ^| ^|_^| ^|\ V / ___ \^|  _  ^| ^|_^| ^|
echo      ^|_^| \_^|\___/  \_/_/   \_\_^| ^|_^|\__\_\
echo. 
echo %ESC%[0m%ESC%[1m      DFX1/2 LAN Mode https://novahq.net %ESC%[0m
echo. 
echo  %ESC%[0m%ESC%[36m/////////////////////////////////////////////////%ESC%[0m
echo.
:: #######################################

net session >nul 2>&1
if errorlevel 1 (
    echo %ESC%[91m It's recommended to run this as Administrator. Do you want to run as Administrator (Y/N^)? %ESC%[0m
    choice /c YN /n >nul
    echo.

    rem CHOICE returns:
    rem   Y => errorlevel 1
    rem   N => errorlevel 2

    if errorlevel 2 (
		rem User pressed N (or something not 1)
    ) else (
        echo %ESC%[94m Relaunching as Administrator... %ESC%[0m

        timeout /t 2 /nobreak >nul 2>&1

        :: https://stackoverflow.com/questions/6811372/how-to-code-a-bat-file-to-always-run-as-admin-mode
        set "params=%*"
		cd /d "%~dp0" && ( if exist "%temp%\getadmin.vbs" del "%temp%\getadmin.vbs" ) && fsutil dirty query %systemdrive% 1>nul 2>nul || (  echo Set UAC = CreateObject^("Shell.Application"^) : UAC.ShellExecute "cmd.exe", "/c cd ""%~sdp0"" && %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs" && "%temp%\getadmin.vbs" && exit /B )

        pause

        exit /b
    )
)

:: #######################################

:: Auto-detect if the script is already in the game directory
if exist "%BASE%\localres.pff" (
    if exist "%BASE%\dfx.exe" goto :SetAutoDetect
    if exist "%BASE%\dfx2.exe" goto :SetAutoDetect
)
goto :Browse

:SetAutoDetect
set "FOLDER=%BASE%"
echo %ESC%[32m Game detected in current directory: %FOLDER% %ESC%[0m
echo.
goto :DetectGame

:Browse

echo  Select your games folder (where localres.pff, dfx.exe, dfx2.exe etc. reside)
echo.

for /f "delims=" %%I in ('
	powershell -NoLogo -NoProfile -Command ^
		"$f = New-Object -ComObject Shell.Application;" ^
		"$folder = $f.BrowseForFolder(0,'Select game folder',0,0);" ^
		"if ($folder) { $folder.Self.Path }"
') do set "FOLDER=%%I"

if not defined FOLDER (
	echo %ESC%[91m ERROR: No folder selected. Run this batch file again when you're ready. %ESC%[0m
	goto :Exit
)

:: #######################################

:DetectGame

if exist "%FOLDER%\localres.pff" (
    if exist "%FOLDER%\dfx.exe" goto :SetDFX
    if exist "%FOLDER%\dfx2.exe" goto :SetDFX
)
goto :Unknown

:SetDFX
set "GAME=DFXLan"
set "PFF=localres.pff"
goto :Install

:Unknown

::Unknown
echo %ESC%[91m ERROR: A valid *.pff file was not found in "%FOLDER%" %ESC%[0m
goto :Exit

:: #######################################

:Install

:: #######################################
:: #######################################

set "MOD=MOD_%GAME%"

if not exist "%MOD%\*" (
	echo %ESC%[91m ERROR: .\%MOD% not found! Extract the entire contents of the archive before running the install. %ESC%[0m
	goto :Exit
)

for %%F in ("%MOD%\*") do (
	set /a FILES+=1
)

if %FILES%==0 (
	echo %ESC%[91m ERROR: .\%MOD% is empty! Extract the entire contents of the archive before running the install. %ESC%[0m
	goto :Exit
)

:: #######################################

if not exist "%FOLDER%\%PACK%" (
	echo %ESC%[91m ERROR: %PACK% not found in "%FOLDER%". %ESC%[0m
	goto :Exit
)

:: #######################################

echo %ESC%[32m Detected game: %GAME% %ESC%[0m
echo %ESC%[32m Found %PACK% in "%FOLDER%" %ESC%[0m
echo %ESC%[32m Found %PFF% in "%FOLDER%" %ESC%[0m
echo %ESC%[32m Found %FILES% MOD files in "%BASE%\%MOD%" %ESC%[0m
echo.
echo  Proceed with installation (Y/N)?
choice /c YN /n >nul

if %ERRORLEVEL% == 2 (
	echo %ESC%[91m Installation canceled! Press any key to exit... %ESC%[0m
	echo.
	pause > nul
	exit /b
)

:: #######################################

echo.
echo  Create backup of %PFF% (Recommended) (Y/N)?
choice /c YN /n >nul
echo.

if %ERRORLEVEL% == 1 (
	copy /y "%FOLDER%\%PFF%" "%FOLDER%\%PFF%.modinstallerbak" >nul

	if not exist "%FOLDER%\%PFF%.modinstallerbak" (
		echo %ESC%[91m ERROR: Failed to create backup %ESC%[0m
		goto :Exit
	) else (
		echo %ESC%[32m Backup saved: "%FOLDER%\%PFF%.modinstallerbak" %ESC%[0m
		echo.
		timeout /t 2 /nobreak >nul 2>&1
	)
	
)

:: #######################################

echo %ESC%[94m Installing MOD files... %ESC%[0m
echo.

for %%F in ("%MOD%\*.*") do (

	if /i "%%~xF"==".bms" (
		echo  moving %%~nxF
		copy /y "%%F" "%FOLDER%" >nul
		set /a MOVED+=1

	) else if /i "%%~xF"==".txt" (
		echo  moving %%~nxF
		copy /y "%%F" "%FOLDER%" >nul
		set /a MOVED+=1

	) else (
		echo  %PACK% %PFF% %%~nxF
		"%FOLDER%\%PACK%" "%FOLDER%\%PFF%" "%BASE%\%MOD%\%%~nxF" /FORCE >nul 2>&1
		set /a PACKED+=1
	)

)

:: #######################################

echo.
echo %ESC%[32m%ESC%[1m Installation was a success: %ESC%[0m
echo %ESC%[94m - %PACKED% files packed %ESC%[0m
echo %ESC%[94m - %MOVED% files moved %ESC%[0m
echo.
echo  Keep LAN Mode installer files (Y/N)?
choice /c YN /n >nul

if %ERRORLEVEL% == 2 (

	echo.
	echo %ESC%[94m Cleaning up and exiting.... %ESC%[0m

	timeout /t 2 /nobreak >nul 2>&1

	rmdir /s /q "%BASE%\%MOD%" >nul 2>&1
	del "%BASE%\pack.log" >nul 2>&1

	(
		ping 127.0.0.1 -n 2 >nul
		del "%~f0"
	) >nul 2>&1

	exit /b
)


:: #######################################

:Exit
echo.
echo  Press any key to exit...
pause > nul
exit /b