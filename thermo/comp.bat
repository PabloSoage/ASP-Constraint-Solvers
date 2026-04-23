@echo off
REM Usage: comp.bat [decode.py] [thermo.lp] [domain01.lp] [sol01.txt]

IF "%~4"=="" (
    echo Usage: %~nx0 [decode.py] [thermo.lp] [domain01.lp] [sol01.txt]
    exit /b 1
)

REM Generates the temporary output
python "%~1" "%~2" "%~3" > temp_output.txt

REM Compares ignoring spaces and line breaks with PowerShell
powershell -Command ^
    "$a = (Get-Content 'temp_output.txt' | ForEach-Object { $_.Trim() }) -join '`n';" ^
    "$b = (Get-Content '%~4' | ForEach-Object { $_.Trim() }) -join '`n';" ^
    "if ($a -eq $b) { Write-Output 'The files are equal.'; exit 0 } else { Write-Output 'The files are different.'; exit 1 }"

@REM if %ERRORLEVEL% EQU 0 (
@REM     echo Match successful!
@REM ) else (
@REM     echo Mismatch detected!
@REM )

del temp_output.txt