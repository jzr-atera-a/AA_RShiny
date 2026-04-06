@echo off
echo ================================================================================
echo  STEP 1 OF 2: ISAAC SIM PERSISTENT SERVER
echo  Run this ONCE. Isaac Sim stays alive until you close this window.
echo  You can restart R Shiny as many times as you like without restarting this.
echo ================================================================================
echo.
echo Starting Isaac Sim persistent server...
echo This will take 60-120 seconds on first start (GPU initialisation).
echo Once you see "ISAAC SIM PERSISTENT SERVER -- READY", run START_FLASK.bat
echo.
C:\isaac-sim\python.bat isaac_sim_persistent_server.py
pause
