echo Restarting Noso...
TIMEOUT 5
tasklist /FI "IMAGENAME eq Noso.exe" 2>NUL | find /I /N "Noso.exe">NUL
if "%ERRORLEVEL%"=="0" taskkill /F /im Noso.exe
del noso.exe
ren nosonew noso.exe
start noso.exe
