# ASP Constraint Solvers

A collection of declarative logical models built with Answer Set Programming (ASP) to solve complex constraint satisfaction, pathfinding, and multi-agent spatio-temporal planning problems. The models are executed using the `clingo` and `telingo` solvers.

## Included Models

### 1. Taxi Routing (Spatio-Temporal Planning)
**Directory:** `/taxis`
A multi-agent logistics problem utilizing `telingo` for temporal logic.
* **Objective:** Coordinate multiple taxis on a grid to pick up and deliver passengers to designated stations in the minimum number of time steps.
* **Constraints:** Collision avoidance (taxis and passengers), action exclusivity (move, pick, drop, wait), and strict inertia rules for fluent persistence.
* **Optimizations:** Search space pruning through state constraints (e.g., preventing drop-and-immediate-pick loops, forcing idle states for empty taxis).

### 2. Masyu (Graph Topology & Loop Generation)
**Directory:** `/masyu`
An ASP implementation of the Masyu logic puzzle, focusing on graph traversal and path validation.
* **Objective:** Generate a single, continuous, non-intersecting closed loop that passes through specific nodes (black and white pearls).
* **Constraints:** Reachability validation to ensure a single connected component, and conditional directional constraints (straight lines through white pearls with 90º turns before/after; strict 90º turns on black pearls).

### 3. Thermometers (Grid Constraint Satisfaction)
**Directory:** `/thermo`
A discrete mathematical constraint problem.
* **Objective:** Fill variable-length structures (thermometers) on a 2D grid while satisfying strict row and column capacity targets.
* **Architecture:** Includes two separate ASP paradigms for performance comparison:
  1. **2D Coordinate System (`thermo.lp`):** Direct X, Y positional logic.
  2. **Linear Indexing System (`thermo2.lp`):** Compact Z-index mapping `(Z = X * n + Y)` resulting in ~33% fewer grounded atoms and faster execution for larger matrices.
* Includes a BFS-based Python encoder to map curved topological structures into flat ASP facts.

## Technology Stack

* **Solvers:** [Clingo](https://potassco.org/clingo/) (ASP) and [Telingo](https://github.com/potassco/telingo) (Temporal ASP).
* **Python 3.11/3.12:** Used for domain encoding (parsing `.txt` to `.lp` facts) and solution decoding.
* **Pygame:** Used for visual verification and step-by-step rendering of the solver outputs.

## Setup & Execution

**1. Environment Setup:**
It is recommended to use a standard Python virtual environment and install both the solvers and the visualization tools via `pip`:

**For Windows:**
```cmd
python -m venv .venv
.\.venv\Scripts\activate
pip install clingo telingo pygame
```

**For Linux / macOS:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install clingo telingo pygame
```

**2. Example Execution (Taxi Routing):**
Domain states must be encoded from text representations into ASP facts before solving.

```bash
cd taxis

# Encode the raw domain into ASP facts
python encode.py doms/dom01.txt doms/dom01.lp

# Solve using Telingo (specify min and max temporal horizon)
telingo taxi.lp doms/dom01.lp --imin=8 --imax=10 > solutions/sol01.txt

# Visualize the generated plan
python drawtaxi.py doms/dom01.txt solutions/sol01.txt
```

*(Specific execution instructions and batch scripts for `masyu` and `thermo` are detailed within their respective directories).*

## ⚖️ License

MIT License

Copyright (c) 2026 Pablo Soage Rodas

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.