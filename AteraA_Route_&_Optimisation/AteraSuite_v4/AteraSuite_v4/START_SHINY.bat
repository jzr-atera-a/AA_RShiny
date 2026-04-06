@echo off
echo ================================================================================
echo  STEP 3: R SHINY APP
echo  Ensure Isaac Sim (START_SERVER.bat) and Flask (START_FLASK.bat) are running.
echo  You can restart this window freely without restarting Isaac Sim.
echo ================================================================================
echo.
Rscript -e "shiny::runApp('.', port=3838, launch.browser=TRUE)"
pause
