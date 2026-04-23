# Taxi Routing Problem - ASP Implementation

## Problem Description

The taxi routing problem involves coordinating multiple taxis to pick up and deliver passengers to designated stations on a grid-based map. The objective is to find the shortest plan (minimum number of time steps) that successfully delivers all passengers to any station.

**Grid Elements:**
- `.` - Empty cell
- `#` - Building (impassable)
- `X` - Station (drop-off point)
- `1-9` - Initial taxi positions
- `a-z` - Initial passenger positions

**Constraints:**
- Taxis move one cell per step (up/down/left/right)
- Two taxis cannot occupy the same cell simultaneously
- Two persons cannot occupy the same cell simultaneously (this includes having one person inside a taxi and another outside at the same location)
- Adjacent taxis cannot swap positions in a single step
- Passengers must be picked up by free taxis
- Each taxi performs exactly one action per time step: move, pick, drop, or wait

**Initial Conditions:**
- All stations start empty
- All taxis start free (empty)
- All passengers start outside taxis

**Goal:**
- Every passenger must be outside a taxi at some station position

## Files

### `encode.py`

Converts human-readable grid files (`.txt`) into ASP facts (`.lp`).

**Input format** (`domain.txt`):
```
1.ab.2XX
```

**Output format** (`domain.lp`):
```
#const n=1.
#const m=8.
station(0,6).
station(0,7).
init_at(1,0,0).
init_at(2,0,5).
init_person_at(a,0,2).
init_person_at(b,0,3).
```

**Usage:**
```bash
python encode.py <input.txt> <output.lp>
```

### `taxi.lp`

ASP encoding using telingo temporal syntax.

**Structure:**

1. **`#program initial`**: Defines initial state
   - Derives `taxi(T)` and `passenger(P)` from input
   - Creates `cell(I,J)` for all valid grid positions (excludes buildings)
   - Sets initial `at(T,I,J)`, `person_at(P,I,J)`, and `free(T)`

2. **`#program dynamic`**: Defines state transitions
   - **Inertia**: Fluents persist unless explicitly changed
   - **Actions**: `move(T,D)`, `pick(T)`, `drop(T)`, `wait(T)` where D ∈ {u,d,l,r}
   - **Constraints**: 
     - Prevents two taxis at same cell
     - Prevents two persons at same cell
     - Prevents taxi-person collision at same cell
     - Prevents adjacent taxis from swapping
     - Ensures valid pick/drop operations
   - **Optimizations**: Prunes search space without affecting correctness

3. **`#program final`**: Defines goal conditions
   - All passengers are at station positions
   - No passengers remain inside taxis

**Key Optimizations:**

- **OPT 1**: Prevents dropping then immediately picking same passenger
- **OPT 1b**: Prevents pick-wait-drop loops
  - This constraint (`:- drop(T), 'wait(T), ''pick(T)`) shows inconsistent behavior across domains
  - When enabled: dom02 movements increase (6→7), dom03 movements decrease (8→7)
- **OPT 2**: Prevents returning to immediately previous position
- **OPT 3**: Free taxi waits instead of moving when no passengers need service
- **OPT 4**: Prevents picking passengers already located at stations

### `run.ps1`

PowerShell script for executing telingo and managing solutions.

**Modes:**

1. **Normal execution**: Run telingo and optionally visualize
2. **Comparison mode** (`-Comp`): Compare generated solution with reference
3. **File comparison** (`-Comp2`): Compare two solution files
4. **Statistics mode** (`-Stats`): Run multiple domains and collect stats

**Parameters:**
- `TaxiLP`: Path to `taxi.lp`
- `DomTxt`: Path to domain `.txt` file (for visualization)
- `DomLP`: Path to domain `.lp` file (encoded facts)
- `-Min N`: Minimum time horizon
- `-Max N`: Maximum time horizon
- `-Output file`: Save solution to file
- `-Draw`: Launch pygame visualization
- `-Delay ms`: Animation delay (default 200ms)
- `-Comp file`: Compare with reference solution
- `-Comp2`: Compare two files mode
- `-Stats`: Statistics mode

### `drawtaxi.py`

Pygame-based visualization tool (provided).

Displays grid with:
- Buildings (gray blocks)
- Taxis (numbered vehicles)
- Passengers (letters)
- Stations (yellow markers)
- Animated step-by-step execution

**Usage:**
```bash
python drawtaxi.py <domain.txt> <solution.txt> [delay_ms]
```

Requires `picstaxi/` folder with image assets (included in `picstaxi.zip`).

## Usage Guide

### Basic Workflow

**1. Encode domain:**
```powershell
python encode.py .\domains\dom01.txt .\domains\dom01.lp
```

**2. Solve:**
```powershell
.\run.ps1 taxi.lp .\domains\dom01.txt .\domains\dom01.lp -Min 8 -Max 10
```

**3. Solve and visualize:**
```powershell
.\run.ps1 taxi.lp .\domains\dom01.txt .\domains\dom01.lp -Min 8 -Max 10 -Draw
```

**4. Save solution:**
```powershell
.\run.ps1 taxi.lp .\domains\dom01.txt .\domains\dom01.lp -Min 8 -Max 10 -Output sol01.txt
```

**5. Visualize saved solution:**
```powershell
python drawtaxi.py .\domains\dom01.txt .\solutions\sol01.txt 500
```

### Advanced Usage

**Compare with reference solution:**
```powershell
.\run.ps1 taxi.lp .\domains\dom01.lp -Comp .\solutions\reference01.txt -Min 8 -Max 10
```

**Compare two solution files:**
```powershell
.\run.ps1 .\solutions\sol01.txt .\solutions\reference01.txt -Comp2
```

**Batch statistics collection:**
```powershell
.\run.ps1 taxi.lp -Stats .\domains\dom01.lp 8 .\domains\dom02.lp 9 .\domains\dom03.lp 9 -Output stats.txt
```

**Find optimal horizon:**
```powershell
# Start with estimated minimum, increase max if UNSAT
.\run.ps1 taxi.lp .\domains\dom04.txt .\domains\dom04.lp -Min 18 -Max 25
```

## Performance

Benchmark results on provided test domains:

| Domain | Steps | Movements | Optimal Moves | Difference | Taxis | Passengers | Time    |
|--------|-------|-----------|---------------|------------|-------|------------|---------|
| dom01  | 8  | 12        | 12            | 0%         | 2     | 2          | 0.09s   |
| dom02  | 9  | 7         | 6             | +17%       | 2     | 1          | 0.09s   |
| dom03  | 9  | 7         | 7             | 0%         | 1     | 1          | 0.29s   |
| dom04  | 20 | 18        | 18            | 0%         | 1     | 1          | 4.36s   |
| dom05  | 14 | 22        | 22            | 0%         | 2     | 2          | 1.74s   |
| dom06  | 19 | 28        | 28            | 0%         | 2     | 2          | 20.6s   |
| dom07  | 26 | 22        | 22            | 0%         | 1     | 2          | 84.6s   |
| dom08  | 22 | 58        | 58            | 0%         | 3     | 3          | 136.5s  |
| dom09  | 12 | 23        | 23            | 0%         | 3     | 4          | 73.7s   |
| dom10  | 23 | 39        | 39            | 0%         | 2     | 3          | 301.5s  |

**Summary:**
- All solutions achieve **optimal plan length** (minimum time steps)
- 9/10 domains achieve **optimal taxi movements**
- dom02 has +1 extra movement (7 vs 6) due to suboptimal coordination

## Requirements

- **telingo** 2.1.2+
- **Python** 3.7+
- **pygame** (for visualization)
- **PowerShell** 5.1+ (Windows) or PowerShell Core (cross-platform)

Install Python dependencies:
```bash
pip install pygame
```

Extract visualization assets:
```bash
unzip picstaxi.zip
```

## Notes

- Solutions minimize **time steps** as primary objective
- Movement counts match reference solutions in 9/10 cases
- Complex domains (dom08-10) may require several minutes
- Visualization requires `picstaxi/` folder with image assets
- Grid coordinates use (row, column) indexing starting at (0,0)
- The number of stations must be ≥ number of passengers for solvability

## Experimental Optimizations

Additional constraints were tested to reduce search space:

**"Never pick same person twice in same taxi":**
- Manual inertia approach (`picked_before`): +129% time, no benefit
- Temporal operators (`&tel`): +13% time, no benefit  

These were excluded from the final implementation as they added grounding overhead without improving solution quality on the test domains.
**"Cannot wait between pick and drop":**
- This constraint shows conflicting effects across domains
- Enabling it optimizes dom03 (8→7 movements) but degrades dom02 (6→7 movements)

