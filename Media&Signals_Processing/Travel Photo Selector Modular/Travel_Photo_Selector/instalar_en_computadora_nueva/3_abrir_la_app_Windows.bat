@echo off
chcp 65001 >nul
title Mis Fotos de Viaje
set "RSCRIPT="
for /d %%D in ("%ProgramFiles%\R\R-*") do if exist "%%D\bin\Rscript.exe" set "RSCRIPT=%%D\bin\Rscript.exe"
if not defined RSCRIPT for /d %%D in ("%LOCALAPPDATA%\Programs\R\R-*") do if exist "%%D\bin\Rscript.exe" set "RSCRIPT=%%D\bin\Rscript.exe"
if not defined RSCRIPT ( echo No encontre R. Corra primero 1_instalar_todo_Windows.bat & pause & exit /b 1 )
cd /d "%~dp0.."
echo Abriendo Mis Fotos de Viaje en el navegador... (no cierre esta ventana mientras usa la app)
"%RSCRIPT%" -e "shiny::runApp('.', launch.browser = TRUE)"
pause
