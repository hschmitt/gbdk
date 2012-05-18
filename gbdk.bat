@echo off
rem # 
rem # GBDK.BAT 1.0 by Marc Rawer
rem # --------------------------
rem # This file helps you to work with gbdk if not installed to the root
rem # directory of your drive. GBDK.BAT will create a new drive letter using
rem # the SUBST command of MSDOS. To configure it you will need to set the
rem # variables below according to your system.
rem # %NEWDRIVE% is the drive to be created, %OLDPATH% is the actual drive
rem # and path to ...\SDK where SDK is stored.
rem # In this example path to the \bin directory of SDK would be:
rem # D:\Project\Software\SDK\gb-gb\2-0-16\bin =) NEWDRIVE=D:\Project\Software
rem #
rem # ----- PLEASE SET YOUR PARAMETERS HERE -----

rem # drive to create
set NEWDRIVE=G:

rem # path to SDK
set OLDPATH=D:\Project\Software

rem # path to GBDK directories - do not change unless you wrote SDK
set SDKPATH=sdk\gbz80-gb\2-0-18


rem ###
rem ### ----- Program part - do not modify below -----
rem ###

echo.
echo ###/
echo  #N# GBDK.BAT 1.0 by Marc Rawer
echo  /###
echo.

if "%1"=="-end" goto FREEDRIVE
if "%1"=="/end" goto FREEDRIVE
if "%1"=="end" goto FREEDRIVE
if "%1"=="" goto MAKEDRIVE
goto HELP

:HELP
 rem # If options not set correct display help
 echo This file helps to get GBDK running on MSDOS.
 echo The file *must* be configured before running the first time!
 echo Take your favorit editor and set the parameters used in this file.
 echo.
 echo Syntax: GBDK [-end]
 echo               -end  this will free the specified drive in gbdk.bat
 echo                     (use this option to end GBDK)
 echo.
 echo Special thanks to  -= Pascal Felber =-  and  -= Michael Hope =- ;)
goto END

:MAKEDRIVE
 if not exist %NEWDRIVE%\sdk\gbdk.bat  subst %NEWDRIVE% %OLDPATH%
 if exist %NEWDRIVE%\sdk\gbdk.bat  echo Drive %NEWDRIVE% now set up for GBDK.
 if exist %NEWDRIVE%\sdk\gbdk.bat  %NEWDRIVE%
 if exist %NEWDRIVE%\sdk\gbdk.bat  cd \sdk
 if not exist run.1st  goto 1ST
goto END

:1ST
 echo running GBDK for the first time - executing makefiles ...
 %NEWDRIVE%
 cd \%SDKPATH%\lib
  echo \%SDKPATH%\lib\make.bat
  call make.bat
 cd \%SDKPATH%\examples
  echo \%SDKPATH%\examples\make.bat
  call make.bat
 cd \%SDKPATH%\examples\dscan
  echo \%SDKPATH%\examples\dscan\make.bat
  call make.bat
 cd \%SDKPATH%\examples\gb-dtmf
  echo \%SDKPATH%\examples\gb-dtmf\make.bat
  call make.bat
 cd \sdk
 echo . > run.1st
goto END

:FREEDRIVE
 c:
 subst %NEWDRIVE% /d
 echo Drive %NEWDRIVE% is not used anymore
goto END

:END
rem # Deleting vars to save space
set NEWDRIVE=
set OLDPATH=
set SDKPATH=
