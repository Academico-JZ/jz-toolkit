@echo off
echo [i] Iniciando Limpeza Silenciosa...
del /s /f /q %userprofile%\AppData\Local\Temp\*.*
del /s /f /q C:\Windows\Temp\*.*
del /s /f /q C:\Windows\Prefetch\*.*
ipconfig /flushdns
echo [OK] Limpeza concluida.
