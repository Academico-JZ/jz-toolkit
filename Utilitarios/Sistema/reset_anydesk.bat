@echo off
echo [i] Resetando AnyDesk...
taskkill /f /im AnyDesk.exe >nul 2>&1
net stop AnyDesk >nul 2>&1
del /s /q %appdata%\AnyDesk\*.conf >nul 2>&1
net start AnyDesk >nul 2>&1
echo [OK] AnyDesk resetado.
