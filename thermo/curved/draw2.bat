@echo off
REM Usage: draw2.bat [drawthermo.py] [decode.py] [thermo.lp] [domain05.lp] [dom05.txt]

REM Argument check
IF "%~5"=="" (
    echo Usage: %~nx0 [drawthermo.py] [decode.py] [thermo.lp] [domain05.lp] [dom05.txt]
    exit /b 1
)

REM Run decode.py and save output to a temp file
python "%~2" "%~3" "%~4" > temp_output.txt

REM Draw using drawthermo.py, the example file and the generated output
python "%~1" "%~5" temp_output.txt

REM Delete temp file
del temp_output.txt