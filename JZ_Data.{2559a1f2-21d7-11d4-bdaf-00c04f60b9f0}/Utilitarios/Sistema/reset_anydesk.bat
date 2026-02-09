@echo off
:: Reset AnyDesk ID
taskkill /f /im AnyDesk.exe
del /f /q "C:\ProgramData\AnyDesk\service.conf"
del /f /q "%appdata%\AnyDesk\system.conf"
start "" "C:\Program Files (x86)\AnyDesk\AnyDesk.exe"
echo AnyDesk Resetado com sucesso.
