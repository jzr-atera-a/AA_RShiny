@echo off
echo ================================================================================
echo  STEP 2 OF 2: FLASK HTTP API SERVER
echo  Run this after Isaac Sim shows "READY"
echo  Keep both windows open.
echo ================================================================================
echo.
pip install flask flask-cors requests >nul 2>&1
echo Starting Flask on http://localhost:5000 ...
python isaac_sim_flask_api_DUAL_VEHICLE.py
pause
