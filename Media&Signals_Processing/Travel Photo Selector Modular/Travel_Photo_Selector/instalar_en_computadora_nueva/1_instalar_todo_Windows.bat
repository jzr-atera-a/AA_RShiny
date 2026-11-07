@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Mis Fotos de Viaje - Instalacion
echo ================================================================
echo  MIS FOTOS DE VIAJE - INSTALAR R, RSTUDIO Y LOS PAQUETES
echo ================================================================
echo.
where winget >nul 2>&1
if errorlevel 1 (
  echo No se encontro 'winget' en esta computadora.
  echo Instale R a mano desde la pagina que se va a abrir y luego vuelva a correr este archivo.
  start "" "https://cloud.r-project.org/bin/windows/base/"
  start "" "https://posit.co/download/rstudio-desktop/"
  goto PAQUETES
)

echo [1/3] Instalando R 4.4.0 (la misma version de la computadora original)...
winget install -e --id RProject.R --version 4.4.0 --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
  echo Esa version exacta no esta disponible; instalando la version mas reciente de R...
  winget install -e --id RProject.R --accept-source-agreements --accept-package-agreements
)
echo.
echo [2/3] Instalando RStudio...
winget install -e --id Posit.RStudio --accept-source-agreements --accept-package-agreements
if errorlevel 1 winget install -e --id RStudio.RStudio --accept-source-agreements --accept-package-agreements

:PAQUETES
echo.
echo [3/3] Instalando los paquetes de R que usa la app...
set "RSCRIPT="
if exist "%ProgramFiles%\R\R-4.4.0\bin\Rscript.exe" set "RSCRIPT=%ProgramFiles%\R\R-4.4.0\bin\Rscript.exe"
if not defined RSCRIPT for /d %%D in ("%ProgramFiles%\R\R-*") do if exist "%%D\bin\Rscript.exe" set "RSCRIPT=%%D\bin\Rscript.exe"
if not defined RSCRIPT for /d %%D in ("%LOCALAPPDATA%\Programs\R\R-*") do if exist "%%D\bin\Rscript.exe" set "RSCRIPT=%%D\bin\Rscript.exe"
if not defined RSCRIPT (
  echo No encontre R instalado. Instale R y vuelva a correr este archivo.
  pause
  exit /b 1
)
echo Usando: %RSCRIPT%
set "AQUI=%~dp0"
"%RSCRIPT%" "%AQUI%2_instalar_paquetes.R"
echo.
echo Termino la instalacion. Para abrir la app use 3_abrir_la_app_Windows.bat
pause
