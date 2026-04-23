@echo off
REM Usage: draw.bat [decode.py] [thermo.lp] [domain05.lp] [dom05.txt]

REM Argument check
IF "%~4"=="" (
    echo Usage: %~nx0 [decode.py] [thermo.lp] [domain05.lp] [dom05.txt]
    exit /b 1
)

REM Executes decode.py and saves the output to a temporary file
python "%~1" "%~2" "%~3" > temp_output.txt

REM Draws using drawthermo.py, the example file, and the generated output
python drawthermo.py "%~4" temp_output.txt

REM Deletes the temporary file
del temp_output.txt