echo Restarting Noso...
TIMEOUT 5
tasklist /FI "IMAGENAME eq noso.exe" 2>NUL | find /I /N "noso.exe">NUL
if "%ERRORLEVEL%"=="0" taskkill /F /im noso.exe
start noso.exe
