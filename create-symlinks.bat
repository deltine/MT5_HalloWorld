setlocal

set user=deltine
set current_dir=%~dp0
set data_dir=%~1

REM Exit if not admin
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Need to run as Administrator
    exit /b
)

REM Check if the data dir is specified
if "%data_dir%"=="" (
    echo Usage: %~n0 MT_DATA_DIR
    echo You can check the path by pressing CTRL+SHIFT+D in MetaTrader platform
    exit /b
)

REM Create symbolic links
cd /d %data_dir%
mklink /d Experts\%user% %current_dir%Experts\%user%
mklink /d Include\%user% %current_dir%Include\%user%
mklink /d Indicators\%user% %current_dir%Indicators\%user%
mklink /d Libraries\%user% %current_dir%Libraries\%user%
mklink /d Scripts\%user% %current_dir%Scripts\%user%

REM copy original file
xcopy %current_dir%update . /S /Y /I /K