param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$TaxiLP,
    
    [Parameter(Position=1)]
    [string]$DomTxt,
    
    [Parameter(Position=2)]
    [string]$DomLP,
    
    [int]$Min,
    [int]$Max,
    [string]$Output,
    [switch]$Draw,
    [int]$Delay,
    [string]$Comp,
    [switch]$Comp2,
    [switch]$Stats,
    [Parameter(ValueFromRemainingArguments=$true)]
    [string[]]$Domains
)

# Stats mode
if ($Stats) {
    Write-Host "=== STATISTICS MODE ===" -ForegroundColor Cyan
    
    # Debug: Show what was captured
    Write-Host "DEBUG: Domains array = $($Domains -join ', ')" -ForegroundColor Magenta
    Write-Host "DEBUG: DomTxt = $DomTxt" -ForegroundColor Magenta
    Write-Host "DEBUG: DomLP = $DomLP" -ForegroundColor Magenta
    
    # Combine all potential domain arguments
    $allArgs = @()
    if ($DomTxt) { $allArgs += $DomTxt }
    if ($DomLP) { $allArgs += $DomLP }
    if ($Domains) { $allArgs += $Domains }
    
    Write-Host "DEBUG: All args = $($allArgs -join ', ')" -ForegroundColor Magenta
    
    if ($allArgs.Count -eq 0) {
        Write-Host "Error: No domains specified!" -ForegroundColor Red
        Write-Host "Usage: .\run.ps1 taxi.lp -Stats dom01.lp 9 dom02.lp 10 [-Output stats.txt]" -ForegroundColor Yellow
        exit 1
    }
    
    # Parse domain specifications (pairs of path and limit)
    if ($allArgs.Count % 2 -ne 0) {
        Write-Host "Error: Domains must be specified in pairs (path limit)" -ForegroundColor Red
        Write-Host "Example: .\run.ps1 taxi.lp -Stats dom01.lp 9 dom02.lp 10" -ForegroundColor Yellow
        Write-Host "Received: $($allArgs -join ' ')" -ForegroundColor Yellow
        exit 1
    }
    
    $domainList = @()
    for ($i = 0; $i -lt $allArgs.Count; $i += 2) {
        $domainList += @{
            Path = $allArgs[$i]
            Limit = [int]$allArgs[$i + 1]
        }
    }
    
    Write-Host "DEBUG: Processing $($domainList.Count) domains" -ForegroundColor Magenta
    
    $allStats = @()
    
    foreach ($domain in $domainList) {
        $domPath = $domain.Path
        $limit = $domain.Limit
        
        Write-Host "`n=== Processing: $domPath (limit: $limit) ===" -ForegroundColor Cyan
        
        if (!(Test-Path $domPath)) {
            Write-Host "Error: File '$domPath' not found!" -ForegroundColor Red
            $allStats += "=== $domPath (limit: $limit) ==="
            $allStats += "ERROR: File not found"
            $allStats += ""
            $allStats += "=" * 80
            $allStats += ""
            continue
        }
        
        # Build telingo command
        $telingoCmd = "telingo $TaxiLP $domPath --imin=$limit --imax=$limit --stats"
        
        Write-Host "Executing: $telingoCmd" -ForegroundColor Yellow
        
        # Execute telingo and capture output
        $telingoOutput = Invoke-Expression $telingoCmd 2>&1 | Out-String
        
        # Extract solution to count states and movements
        $answerPattern = '(?s)Answer:.*?(State 0:.*?)(?=SATISFIABLE|UNSATISFIABLE|$)'
        $numStates = 0
        $numMovements = 0
        
        if ($telingoOutput -match $answerPattern) {
            $solutionText = $matches[1]
            
            # Count states (excluding State 0)
            $stateMatches = [regex]::Matches($solutionText, 'State (\d+):')
            if ($stateMatches.Count -gt 0) {
                $maxState = ($stateMatches | ForEach-Object { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum
                $numStates = $maxState  # State 0 to State N = N states (excluding State 0)
            }
            
            # Count movements (move actions)
            $movementMatches = [regex]::Matches($solutionText, 'move\(')
            $numMovements = $movementMatches.Count
        }
        
        # Extract relevant output (from "Answer:" to end of statistics)
        $relevantPattern = '(?s)(Answer:.*?Constraints\s+:.*?\n)'
        if ($telingoOutput -match $relevantPattern) {
            $relevantOutput = $matches[1].Trim()
            
            # Add summary header
            $summary = "Plan Length: $numStates steps"
            $summary += "`nTaxi Movements: $numMovements"
            
            # Display to console
            Write-Host "`n$summary" -ForegroundColor Cyan
            Write-Host "`n$relevantOutput" -ForegroundColor Green
            
            # Store for file output
            $allStats += "=== $domPath (limit: $limit) ==="
            $allStats += ""
            $allStats += $summary
            $allStats += ""
            $allStats += $relevantOutput
            $allStats += ""
            $allStats += "=" * 80
            $allStats += ""
        } else {
            Write-Host "Warning: Could not extract output" -ForegroundColor Yellow
            $allStats += "=== $domPath (limit: $limit) ==="
            $allStats += "ERROR: Could not extract output"
            $allStats += ""
            $allStats += "=" * 80
            $allStats += ""
        }
    }
    
    # Save to file if requested
    if ($Output) {
        $outputDir = Split-Path -Parent $Output
        if ($outputDir -and !(Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $allStats -join "`n" | Out-File -FilePath $Output -Encoding UTF8
        Write-Host "`n✓ Statistics saved to: $Output" -ForegroundColor Green
    }
    
    exit 0
}

# Compare two files mode
if ($Comp2) {
    Write-Host "=== FILE COMPARISON MODE ===" -ForegroundColor Cyan
    
    # In this mode, TaxiLP is the first file, DomTxt is the second file
    $file1 = $TaxiLP
    $file2 = $DomTxt
    
    if (!$file1 -or !$file2) {
        Write-Host "Error: Missing file parameters!" -ForegroundColor Red
        Write-Host "Usage: .\run.ps1 file1.txt file2.txt -Comp2" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if files exist
    if (!(Test-Path $file1)) {
        Write-Host "Error: File '$file1' not found!" -ForegroundColor Red
        exit 1
    }
    
    if (!(Test-Path $file2)) {
        Write-Host "Error: File '$file2' not found!" -ForegroundColor Red
        exit 1
    }
    
    # Read both files
    $solution1 = Get-Content $file1 -Raw
    $solution1 = $solution1.Trim()
    
    $solution2 = Get-Content $file2 -Raw
    $solution2 = $solution2.Trim()
    
    # Normalize both solutions for comparison (remove all leading/trailing spaces from each line)
    $normalized1 = ($solution1 -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) -join "`n"
    $normalized2 = ($solution2 -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) -join "`n"
    
    if ($normalized1 -eq $normalized2) {
        Write-Host "`n✓ MATCH: Files are equal!" -ForegroundColor Green
        Write-Host "`nFile 1: $file1" -ForegroundColor Cyan
        Write-Host "File 2: $file2" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "`n✗ MISMATCH: Files are different!" -ForegroundColor Red
        Write-Host "`nFile 1: $file1" -ForegroundColor Cyan
        Write-Host "File 2: $file2" -ForegroundColor Cyan
        
        # Show diff
        Write-Host "`n=== DIFF ===" -ForegroundColor Yellow
        
        $lines1 = $normalized1 -split "`n"
        $lines2 = $normalized2 -split "`n"
        
        $maxLines = [Math]::Max($lines1.Count, $lines2.Count)
        
        for ($i = 0; $i -lt $maxLines; $i++) {
            $line1 = if ($i -lt $lines1.Count) { $lines1[$i] } else { "" }
            $line2 = if ($i -lt $lines2.Count) { $lines2[$i] } else { "" }
            
            if ($line1 -eq $line2) {
                Write-Host "  $line1" -ForegroundColor Gray
            } else {
                if ($line2 -ne "") {
                    Write-Host "- $line2" -ForegroundColor Red
                }
                if ($line1 -ne "") {
                    Write-Host "+ $line1" -ForegroundColor Green
                }
            }
        }
        
        exit 1
    }
}

# Compare mode
if ($Comp) {
    Write-Host "=== COMPARISON MODE ===" -ForegroundColor Cyan
    
    # In comparison mode, DomTxt is actually DomLP (2nd parameter)
    if (!$DomTxt) {
        Write-Host "Error: Missing DomLP parameter!" -ForegroundColor Red
        Write-Host "Usage: .\run.ps1 taxi.lp dom.lp -Comp sol.txt [-Min N] [-Max N] [-Output file]" -ForegroundColor Yellow
        exit 1
    }
    
    $actualDomLP = $DomTxt
    
    # Build telingo command
    $telingoCmd = "telingo $TaxiLP $actualDomLP"
    
    if ($Min -and $Max) {
        $telingoCmd += " --imin=$Min --imax=$Max"
    } elseif ($Min) {
        $telingoCmd += " --imin=$Min"
    } elseif ($Max) {
        $telingoCmd += " --imax=$Max"
    }
    
    Write-Host "Executing: $telingoCmd" -ForegroundColor Cyan
    
    # Execute telingo and capture output
    $telingoOutput = Invoke-Expression $telingoCmd 2>&1 | Out-String
    
    # Extract solution
    $answerPattern = '(?s)Answer:.*?(State 0:.*?)(?=SATISFIABLE|UNSATISFIABLE|$)'
    if ($telingoOutput -match $answerPattern) {
        $rawSolution = $matches[1]
        
        # Process solution
        $solution = ($rawSolution -split "`n" | ForEach-Object {
            if ($_ -match '^\s+(State \d+:)') {
                $matches[1]
            } elseif ($_ -match '^\s+(State \d+:)(.*)') {
                $matches[1] + $matches[2]
            } else {
                $_
            }
        }) -join "`n"
        
        $solution = $solution -replace '(?m)^\s*$\n', "`n"
        $solution = $solution.Trim()
        
        # Save to temp file if Output specified
        if ($Output) {
            $outputDir = Split-Path -Parent $Output
            if ($outputDir -and !(Test-Path $outputDir)) {
                New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
            }
            $solution | Out-File -FilePath $Output -Encoding UTF8
            Write-Host "Solution saved to: $Output" -ForegroundColor Green
        }
        
        # Read expected solution
        if (!(Test-Path $Comp)) {
            Write-Host "Error: Comparison file '$Comp' not found!" -ForegroundColor Red
            exit 1
        }
        
        $expectedSolution = Get-Content $Comp -Raw
        $expectedSolution = $expectedSolution.Trim()
        
        # Normalize both solutions for comparison (remove all leading/trailing spaces from each line)
        $normalizedSolution = ($solution -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) -join "`n"
        $normalizedExpected = ($expectedSolution -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }) -join "`n"
        
        if ($normalizedSolution -eq $normalizedExpected) {
            Write-Host "`n✓ MATCH: Solutions are equal!" -ForegroundColor Green
            Write-Host "`n=== SOLUTION ===" -ForegroundColor Yellow
            Write-Host $solution
            exit 0
        } else {
            Write-Host "`n✗ MISMATCH: Solutions are different!" -ForegroundColor Red
            
            # Show diff
            Write-Host "`n=== DIFF ===" -ForegroundColor Yellow
            
            $solutionLines = $normalizedSolution -split "`n"
            $expectedLines = $normalizedExpected -split "`n"
            
            $maxLines = [Math]::Max($solutionLines.Count, $expectedLines.Count)
            
            for ($i = 0; $i -lt $maxLines; $i++) {
                $solLine = if ($i -lt $solutionLines.Count) { $solutionLines[$i] } else { "" }
                $expLine = if ($i -lt $expectedLines.Count) { $expectedLines[$i] } else { "" }
                
                if ($solLine -eq $expLine) {
                    Write-Host "  $solLine" -ForegroundColor Gray
                } else {
                    if ($expLine -ne "") {
                        Write-Host "- $expLine" -ForegroundColor Red
                    }
                    if ($solLine -ne "") {
                        Write-Host "+ $solLine" -ForegroundColor Green
                    }
                }
            }
            
            exit 1
        }
    } else {
        Write-Host "`nNo solution found in telingo output!" -ForegroundColor Red
        Write-Host $telingoOutput
        exit 1
    }
}

# Normal execution mode
if (!$DomTxt -or !$DomLP) {
    Write-Host "Error: Missing parameters!" -ForegroundColor Red
    Write-Host "Usage: .\run.ps1 taxi.lp dom.txt dom.lp [-Min N] [-Max N] [-Output file] [-Draw] [-Delay ms]" -ForegroundColor Yellow
    Write-Host "   or: .\run.ps1 taxi.lp dom.lp -Comp sol.txt [-Min N] [-Max N] [-Output file]" -ForegroundColor Yellow
    Write-Host "   or: .\run.ps1 file1.txt file2.txt -Comp2" -ForegroundColor Yellow
    Write-Host "   or: .\run.ps1 taxi.lp -Stats dom01.lp 9 dom02.lp 10 [-Output stats.txt]" -ForegroundColor Yellow
    exit 1
}

# Build telingo command
$telingoCmd = "telingo $TaxiLP $DomLP"

if ($Min -and $Max) {
    $telingoCmd += " --imin=$Min --imax=$Max"
} elseif ($Min) {
    $telingoCmd += " --imin=$Min"
} elseif ($Max) {
    $telingoCmd += " --imax=$Max"
}

Write-Host "Executing: $telingoCmd" -ForegroundColor Cyan

# Execute telingo and capture output
$telingoOutput = Invoke-Expression $telingoCmd 2>&1 | Out-String

# Extract solution (from "Answer:" to SATISFIABLE/UNSATISFIABLE)
$answerPattern = '(?s)Answer:.*?(State 0:.*?)(?=SATISFIABLE|UNSATISFIABLE|$)'
if ($telingoOutput -match $answerPattern) {
    $rawSolution = $matches[1]
    
    # Process solution: remove leading spaces from State lines
    $solution = ($rawSolution -split "`n" | ForEach-Object {
        if ($_ -match '^\s+(State \d+:)') {
            $matches[1]
        } elseif ($_ -match '^\s+(State \d+:)(.*)') {
            $matches[1] + $matches[2]
        } else {
            $_
        }
    }) -join "`n"
    
    # Clean up extra blank lines
    $solution = $solution -replace '(?m)^\s*$\n', "`n"
    $solution = $solution.Trim()
    
    # Output to file if specified
    if ($Output) {
        # Create directory if it doesn't exist
        $outputDir = Split-Path -Parent $Output
        if ($outputDir -and !(Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        $solution | Out-File -FilePath $Output -Encoding UTF8
        Write-Host "`nSolution saved to: $Output" -ForegroundColor Green
    }
    
    # Always display solution
    Write-Host "`n=== SOLUTION ===" -ForegroundColor Yellow
    Write-Host $solution
    
    # Draw if requested
    if ($Draw) {
        if ($Output) {
            $solutionFile = $Output
        } else {
            # Create temporary file
            $solutionFile = Join-Path $env:TEMP "temp_solution.txt"
            $solution | Out-File -FilePath $solutionFile -Encoding UTF8
        }
        
        Write-Host "`nDrawing solution..." -ForegroundColor Cyan
        
        # Execute with or without delay
        if ($Delay) {
            python drawtaxi.py $DomTxt $solutionFile $Delay
        } else {
            python drawtaxi.py $DomTxt $solutionFile
        }
        
        # Clean up temp file if created
        if (!$Output -and (Test-Path $solutionFile)) {
            Remove-Item $solutionFile
        }
    }
    
} else {
    Write-Host "`nNo solution found!" -ForegroundColor Red
    Write-Host $telingoOutput
}