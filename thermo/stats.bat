@echo off
REM Usage: stats.bat [main_file.lp] [domain_file.lp]

REM Argument check
IF "%~1"=="" (
    echo Usage: %~nx0 [main_file.lp] [domain_file.lp]
    exit /b 1
)
IF "%~2"=="" (
    echo Usage: %~nx0 [main_file.lp] [domain_file.lp]
    exit /b 1
)

REM Executes everything in a single PowerShell command
powershell -Command ^
    "$main = '%~1';" ^
    "$domain = '%~2';" ^
    "$text_lines = (clingo --text 0 $main $domain | Measure-Object).Count;" ^
    "$atoms = (clingo --output=reify 0 $main $domain | Select-String '^atom_tuple\(' | Measure-Object).Count;" ^
    "$rules = (clingo --output=reify 0 $main $domain | Select-String '^rule\(' | Measure-Object).Count;" ^
    "Write-Output \"text_lines=$text_lines atoms=$atoms rules=$rules\""