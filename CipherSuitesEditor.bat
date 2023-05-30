@echo off
chcp 65001
setlocal EnableDelayedExpansion
set backup_dir=c:\backup
set now_date=%date:/=-%
mkdir %backup_dir%


echo 1. 備份於 %backup_dir%
REM 協定配置
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols" "%backup_dir%\bak1.reg" /Y
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers" "%backup_dir%\bak2.reg" /Y
REM GPO的 SSL/TLS 加密套件配置
reg export "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002" "%backup_dir%\bak3.reg" /Y
REM 本地的 SSL/TLS 加密套件配置
reg export "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\SSL\00010002" "%backup_dir%\bak4.reg" /Y

REM 合併備份檔案
type "%backup_dir%\bak1.reg" > "%backup_dir%\bak_%now_date%.reg"
type "%backup_dir%\bak2.reg" | findstr /V /C:"Windows Registry Editor Version" > "%backup_dir%\bak2_format.reg"
type "%backup_dir%\bak3.reg" | findstr /V /C:"Windows Registry Editor Version" > "%backup_dir%\bak3_format.reg"
type "%backup_dir%\bak4.reg" | findstr /V /C:"Windows Registry Editor Version" > "%backup_dir%\bak4_format.reg"
type "%backup_dir%\bak2_format.reg" >> "%backup_dir%\bak_%now_date%.reg"
type "%backup_dir%\bak3_format.reg" >> "%backup_dir%\bak_%now_date%.reg"
type "%backup_dir%\bak4_format.reg" >> "%backup_dir%\bak_%now_date%.reg"
del /F /Q %backup_dir%\bak1.reg
del /F /Q %backup_dir%\bak2.reg
del /F /Q %backup_dir%\bak3.reg
del /F /Q %backup_dir%\bak4.reg
del /F /Q %backup_dir%\bak2_format.reg
del /F /Q %backup_dir%\bak3_format.reg
del /F /Q %backup_dir%\bak4_format.reg

echo.
echo 2. 停用有風險的協定
REM  win7的3DES預設值是啟用的，所以要停用而不是刪除
REGEDIT.EXE /S DisableCiphers.reg

echo.
echo 3. 停用有風險的加密套件
call :removePolicyCipherSuites 3DES
call :removePolicyCipherSuites RC4
call :removeSystemCipherSuites 3DES
call :removeSystemCipherSuites RC4

echo.
echo 4. 加入高安全性的加密套件
set  "newCipherSuites=TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384"
call :addPolicyCipherSuites %newCipherSuites%
call :addSystemCipherSuites %newCipherSuites%

echo.
echo 5. 結束
goto :end



REM 依關鍵字移除有風險的加密套件(本地)
:removeSystemCipherSuites
setlocal
set "keyword=%~1"
set "regpath=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\SSL\00010002"
set "regkey="
set "functions="

echo.
echo 移除與 %keyword% 相關的加密套件(本地)
echo.

REM 讀取原本的 Functions 值
for /f "skip=2 tokens=3*" %%a in ('reg query "%regpath%" /v "Functions"') do (
    set "functions=%%a"
)

echo.
echo before functions: %functions%

set "functions=!functions:\0=,!"

REM 移除與 %keyword% 相關的加密套件
for %%a in (%functions%) do (
    echo %%a | findstr /C:"%keyword%" > nul
    if not errorlevel 1 (
        echo remove encryption suite: %%a
        REM 字串取代
        set "functions=!functions:%%a=!"
        REM 將兩個逗號取代成一個
        set "functions=!functions:,,=,!"
    )
)

REM 解決前後逗號的問題
set "functions=,%functions%,"
set "functions=!functions:,,=,!"
set "functions=!functions:~1,-1!"
set "functions=!functions:,=\0!"

echo.
echo after functions: %functions%

REM 更新註冊表的 Functions 值
reg add "%regpath%" /v "Functions" /t REG_MULTI_SZ /d "!functions!" /f >nul

endlocal
goto :eof


REM 依關鍵字移除有風險的加密套件(GPO)
:removePolicyCipherSuites
setlocal
set "keyword=%~1"
set "regpath=HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002"
set "regkey="
set "functions="

echo.
echo 移除與 %keyword% 相關的加密套件(GPO)
echo.

REM 讀取原本的 Functions 值
for /f "skip=2 tokens=3,*" %%a in ('reg query "%regpath%" /v "Functions"') do (
    set "functions=%%a"
)

echo.
echo before functions: %functions%

REM 移除與 %keyword% 相關的加密套件
for %%a in (%functions%) do (
    echo %%a | findstr /C:"%keyword%" > nul
    if not errorlevel 1 (
        echo remove encryption suite: %%a
        REM 字串取代
        set "functions=!functions:%%a=!"
        REM 將兩個逗號取代成一個
        set "functions=!functions:,,=,!"
    )
)

REM 解決前後逗號的問題
set "functions=,%functions%,"
set "functions=!functions:,,=,!"
set "functions=!functions:~1,-1!"

echo.
echo after functions: %functions%

REM 更新註冊表的 Functions 值
reg add "%regpath%" /v "Functions" /t REG_SZ /d "!functions!" /f >nul

endlocal
goto :eof


REM 加入安全性較高的加密套件(GPO)
:addPolicyCipherSuites
setlocal
set "regpath=HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Cryptography\Configuration\SSL\00010002"
set "functions="
set "cipherSuites=%~1"

echo.
echo 加入安全性較高的加密套件(GPO)
echo.

REM 讀取原本的 Functions 值
for /f "skip=2 tokens=3,*" %%a in ('reg query "%regpath%" /v "Functions"') do (
    set "functions=%%a"
)

echo add: %cipherSuites%
echo.
echo before functions: %functions%

for %%a in (%cipherSuites%) do (
	REM echo check %%a
    echo !functions! | findstr /C:"%%a" > nul
    if errorlevel 1 (
		echo add %%a
		set "functions=!functions!,%%a"
    )
)

REM 解決前後逗號的問題
set "functions=,%functions%,"
set "functions=!functions:,,=,!"
set "functions=!functions:~1,-1!"

echo.
echo after functions: %functions%

REM 更新註冊表的 Functions 值
reg add "%regpath%" /v "Functions" /t REG_SZ /d "!functions!" /f >nul

endlocal
goto :eof


REM 加入安全性較高的加密套件(本地)
:addSystemCipherSuites
setlocal
set "regpath=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Cryptography\Configuration\Local\SSL\00010002"
set "functions="
set "cipherSuites=%~1"


echo.
echo 加入安全性較高的加密套件(本地)
echo.

REM 讀取原本的 Functions 值
for /f "skip=2 tokens=3,*" %%a in ('reg query "%regpath%" /v "Functions"') do (
    set "functions=%%a"
)

echo add: %cipherSuites%
echo.
echo before functions: %functions%

for %%a in (%cipherSuites%) do (
	REM echo check %%a
    echo !functions! | findstr /C:"%%a" > nul
    if errorlevel 1 (
		echo add %%a
		set "functions=!functions!\0%%a"
    )
)

REM 解決前後逗號的問題
set "functions=\0%functions%\0"
set "functions=!functions:\0\0=\0!"
set "functions=!functions:~2,-2!"

echo.
echo after functions: %functions%

REM 更新註冊表的 Functions 值
reg add "%regpath%" /v "Functions" /t REG_MULTI_SZ /d "!functions!" /f >nul

endlocal
goto :eof

:end
