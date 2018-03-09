@echo off
@title WURS v4
echo Windows Update Reset Script v4 - (c) henryolik 2018 - https://wur.ministudios.ml
:check_Permissions

    net session >nul 2>&1
    if %errorLevel% == 0 (
        echo ...
    ) else (
        echo Please run this file as administrator and try again.
    pause
EXIT
    )
	cd %SystemRoot%\System32\Wbem
wmic.exe Alias /? >NUL 2>&1 || GOTO s_error
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
   IF "%%~L"=="" goto s_done
      Set _yyyy=%%L
      Set _mm=00%%J
      Set _dd=00%%G
      Set _hour=00%%H
      SET _minute=00%%I
      SET _second=00%%K
)
:s_done
      Set _mm=%_mm:~-2%
      Set _dd=%_dd:~-2%
      Set _hour=%_hour:~-2%
      Set _minute=%_minute:~-2%
      Set _second=%_second:~-2%

Set logtimestamp=%_yyyy%-%_mm%-%_dd%_%_hour%_%_minute%_%_second%
goto continue

:s_error
echo WMIC is not available, using default log filename
SET HOUR=%time:~0,2%
SET dtStamp9=%date:~-4%%date:~4,2%%date:~7,2%_0%time:~1,1%%time:~3,2%%time:~6,2% 
SET dtStamp24=%date:~-4%%date:~4,2%%date:~7,2%_%time:~0,2%%time:~3,2%%time:~6,2%

if "%HOUR:~0,1%" == " " (SET dtStamp=%dtStamp9%) else (SET dtStamp=%dtStamp24%)
Set logtimestamp=%dtStamp%
:continue
cd %SystemRoot%\System32
echo DO YOU WANT TO BACKUP YOUR SYSTEM? (RECOMMENDED)
set INPUT=
set /P INPUT=Y/N: %=%
If /I "%INPUT%"=="y" goto yes 
If /I "%INPUT%"=="n" goto next
echo Incorrect input & goto Ask
:yes
echo BACKING UP REGISTRY...
mkdir "C:/regbak"
mkdir "C:/regbak/%logtimestamp%"
echo -Backing up HKLM...
reg export HKLM C:/regbak/%logtimestamp%/hklm.reg > nul
echo -Backing up HKCU...
reg export HKCU C:/regbak/%logtimestamp%/hkcu.reg > nul
echo -Backing up HKCR...
reg export HKCR C:/regbak/%logtimestamp%/hkcr.reg > nul
echo -Backing up HKU...
reg export HKU  C:/regbak/%logtimestamp%/hku.reg > nul
echo -Backing up HKCC...
reg export HKCC C:/regbak/%logtimestamp%/hkcc.reg > nul
echo CREATING SYSTEM RESTORE POINT...
cd %SystemRoot%\System32\Wbem
wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "%DATE%", 100, 7
cd %SystemRoot%\System32
goto next
:next
echo STOPPING BITS SERVICE...
net stop bits
echo STOPPING WU SERVICE...
net stop wuauserv
echo STOPPING APPID SERVICE...
net stop appidsvc
echo STOPPING CRYPTO SERVICE...
net stop cryptsvc
echo DELETING TEMPORARY FILES...
Del "%ALLUSERSPROFILE%\Application Data\Microsoft\Network\Downloader\qmgr*.dat"
echo DELETING DOWNLOAD FOLDERS...
Ren %systemroot%\SoftwareDistribution SoftwareDistribution.bak
Ren %systemroot%\system32\catroot2 catroot2.bak
echo RESETTING BITS...
sc.exe sdset bits D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)
echo RESETTING WU...
sc.exe sdset wuauserv D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;AU)(A;;CCLCSWRPWPDTLOCRRC;;;PU)
echo REGISTERING BITS AND WU DLL...
cd /d %windir%\system32
regsvr32.exe /s atl.dll
regsvr32.exe /s urlmon.dll
regsvr32.exe /s mshtml.dll
regsvr32.exe /s shdocvw.dll
regsvr32.exe /s browseui.dll
regsvr32.exe /s jscript.dll
regsvr32.exe /s vbscript.dll
regsvr32.exe /s scrrun.dll
regsvr32.exe /s msxml.dll
regsvr32.exe /s msxml3.dll
regsvr32.exe /s msxml6.dll
regsvr32.exe /s actxprxy.dll
regsvr32.exe /s softpub.dll
regsvr32.exe /s wintrust.dll
regsvr32.exe /s dssenh.dll
regsvr32.exe /s rsaenh.dll
regsvr32.exe /s gpkcsp.dll
regsvr32.exe /s sccbase.dll
regsvr32.exe /s slbcsp.dll
regsvr32.exe /s cryptdlg.dll
regsvr32.exe /s oleaut32.dll
regsvr32.exe /s ole32.dll
regsvr32.exe /s shell32.dll
regsvr32.exe /s initpki.dll
regsvr32.exe /s wuapi.dll
regsvr32.exe /s wuaueng.dll
regsvr32.exe /s wuaueng1.dll
regsvr32.exe /s wucltui.dll
regsvr32.exe /s wups.dll
regsvr32.exe /s wups2.dll
regsvr32.exe /s wuweb.dll
regsvr32.exe /s qmgr.dll
regsvr32.exe /s qmgrprxy.dll
regsvr32.exe /s wucltux.dll
regsvr32.exe /s muweb.dll
regsvr32.exe /s wuwebv.dll
echo RESETTING WINSOCK...
netsh winsock reset
echo STARTING BITS SERVICE...
net start bits
echo STARTING WU SERVICE...
net start wuauserv
echo STARTING APPID SERVICE...
net start appidsvc
echo STARTING CRYPTO SERVICE...
net start cryptsvc
echo DONE!
pause