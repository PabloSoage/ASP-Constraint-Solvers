# Thermometer Puzzle Solver

ASP-based solver for the Thermometer puzzle using Clingo.

## Overview

This project implements a constraint satisfaction solver for Thermometer puzzles using Answer Set Programming (ASP). The puzzle consists of a grid containing thermometers of various shapes that must be partially filled according to row and column constraints.

### Rules
- Each thermometer has a bulb (starting point) and extends in one or more directions
- If a cell is filled, all cells closer to the bulb must also be filled
- Row and column numbers indicate how many cells must be filled in each row/column

## Project Structure

### Core Components (Basic Version)

**`thermo.lp`** - ASP knowledge base
- Defines the constraint logic for valid thermometer filling
- Enforces the mercury rule (filled cells must be contiguous from bulb)
- Validates row/column target constraints
- Uses 2D coordinates: `thermo(ID, X, Y, Position)`

**`encode.py`** - Domain encoder for straight thermometers
- Converts text-based puzzle descriptions to ASP facts
- Supports thermometers extending in cardinal directions (U/D/R/L)
- Generates `thermo(ID, X, Y, Position)` facts

**`decode.py`** - Solution decoder (provided)
- Parses Clingo output and displays filled cells
- Converts ASP atoms back to grid visualization

**`drawthermo.py`** - Graphical visualizer (provided)
- PyGame-based visual representation
- Displays domain and solution side-by-side

### Alternative Basic Version (Linear Coordinates)

**`thermo2.lp`** - Alternative ASP knowledge base
- Uses linear indexing instead of 2D coordinates
- Cells represented as Z ∈ [0, N²-1]
- Row/column calculated via division/modulo: `Z/n` and `Z\n`
- Generates `thermo(ID, Z, Position)` facts

**`encode2alt.py`** - Linear coordinate encoder
- Converts (X,Y) positions to linear index: `Z = X * n + Y`
- Produces more compact fact representation
- Compatible with `thermo2.lp`

**`decode2alt.py`** - Linear coordinate decoder
- Converts linear indices back to 2D grid
- Uses `Z // n` for row, `Z % n` for column
- Two-pass processing: first determines grid size, then decodes positions

### Extended Version (Curved Thermometers)

**`encode2.py`** - Enhanced encoder
- Supports curved thermometers using box-drawing characters (└┌┐┘)
- Implements connection tracing via BFS
- Validates thermometer topology

**`drawthermo2.py`** - Enhanced visualizer
- Renders curved thermometer segments
- Context-aware image selection based on adjacent cells
- Scaled rendering (31x31px cells)

**`generator.py`** - Interactive puzzle creator
- Tkinter-based GUI for manual thermometer placement
- Load puzzles from HTML or text files
- Toggle between text/image display modes
- Export to encoded format

**`visualize_encoding.py`** - Encoding debugger
- PyGame visualization of encoded ASP facts
- Color-coded thermometer identification
- Statistical analysis (length, position, coverage)

### Utility Scripts

**`comp.bat`** - Solution validator
- Compares decoder output against expected solution
- Ignores whitespace and line breaks
- Usage: `comp.bat decode.py thermo.lp domain01.lp sol01.txt`

**`draw.bat`** - Quick visualization wrapper
- Chains decode and visualization in one command
- Automatically cleans up temporary files
- Usage: `draw.bat decode.py thermo.lp domain05.lp dom05.txt`

**`stats.bat`** - Encoding statistics
- Reports grounding metrics (text lines, atoms, rules)
- Uses Clingo's `--text` and `--output=reify` modes
- Usage: `stats.bat thermo.lp domain01.lp`

## Usage

### Basic Workflow (2D Coordinates)

```bash
# 1. Encode domain
python encode.py domain01.txt domain01.lp

# 2. Solve with Clingo
clingo thermo.lp domain01.lp > solution.txt

# 3. Decode solution
python decode.py thermo.lp domain01.lp > output.txt

# 4. Visualize
python drawthermo.py domain01.txt output.txt
```

### Alternative Workflow (Linear Coordinates)

```bash
# 1. Encode domain with linear indexing
python v2/encode2alt.py domain01.txt v2/domain01.lp

# 2. Solve with alternative knowledge base
clingo v2/thermo2.lp v2/domain01.lp

# 3. Decode solution
python v2/decode2alt.py v2/thermo2.lp v2/domain01.lp > output.txt
```

### Curved Thermometers

```bash
# Encode curved thermometers
python curved/encode2.py curved_domain.txt curved_domain.lp

# Solve and visualize
clingo thermo.lp curved_domain.lp
python curved/drawthermo2.py curved_domain.txt solution.txt

# Debug encoding
python curved/visualize_encoding.py curved_domain.lp
```

### Quick Commands

```bash
# Visualize solution directly
draw.bat decode.py thermo.lp domain05.lp dom05.txt

# Validate solution
comp.bat decode.py thermo.lp domain01.lp sol01.txt

# Check encoding statistics
stats.bat thermo.lp domain01.lp
```

## Input Format

Text file with grid followed by constraints:

```
1212
^vUv
02<L
R3R>
2 2 2 1
1 1 3 2
```

- First n lines: grid layout
  - Bulbs: `U` (up), `D` (down), `R` (right), `L` (left)
  - Segments: `^` `v` `>` `<`
  - Curves: `0`(└) `1`(┌) `2`(┐) `3`(┘)
- Line n+1: column targets (space-separated)
- Line n+2: row targets (space-separated)

## Coordinate Systems

### 2D Representation (`thermo.lp`)
- Facts: `thermo(T, X, Y, Pos)`, `fill(X, Y)`
- Row/column access: direct indexing
- More intuitive for manual inspection

### Linear Representation (`thermo2.lp`)
- Facts: `thermo(T, Z, Pos)`, `fill(Z)`
- Row/column access: `Z/n` and `Z\n`
- More compact encoding (~33% fewer atoms)
- Better performance for large grids

## Dependencies

- `clingo` - ASP solver
- `pygame` - Visualization
- `tkinter` - GUI generator (Python standard library)
- `Pillow` - Image processing for generator

## File Organization

```
thermo/
├── thermo.lp              # ASP knowledge base (2D)
├── encode.py              # Basic encoder (2D)
├── decode.py              # Solution decoder (2D)
├── drawthermo.py          # Basic visualizer
├── comp.bat               # Solution validator
├── draw.bat               # Quick visualization
├── stats.bat              # Encoding statistics
├── v2/
│   ├── thermo2.lp         # ASP knowledge base (linear)
│   ├── encode2alt.py      # Linear coordinate encoder
│   └── decode2alt.py      # Linear coordinate decoder
├── curved/
│   ├── encode2.py         # Curved thermometer encoder
│   ├── drawthermo2.py     # Enhanced visualizer
│   ├── generator.py       # Interactive puzzle creator
│   └── visualize_encoding.py  # Encoding debugger
├── pics/                  # Image assets for visualization
├── thermo_lp/             # Encoded basic domains (2D)
└── thermo_lpb/            # Encoded curved domains
```

## Notes

- The ASP model uses a single knowledge base (`thermo.lp`) for both straight and curved thermometers
- Linear coordinate version (`thermo2.lp`) offers better performance with equivalent semantics
- Encoding handles topology validation to detect invalid thermometer structures
- The generator supports importing puzzles from HTML (web-scraped puzzles)
- Batch scripts require Windows PowerShell