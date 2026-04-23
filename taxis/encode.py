import sys

if len(sys.argv) != 3:
    print("Usage: encode.py <input.txt> <output.lp>")
    sys.exit(1)

# Read input file
with open(sys.argv[1], 'r') as f:
    lines = [line.rstrip('\n\r') for line in f.readlines()]

# Remove empty lines
lines = [line for line in lines if line]

n = len(lines)  # number of rows
m = max(len(line) for line in lines) if n > 0 else 0  # number of columns

# Pad lines to same length
lines = [line.ljust(m, '.') for line in lines]

# Open output file
with open(sys.argv[2], 'w') as out:
    sys.stdout = out
    
    # Grid dimensions
    print(f"#const n={n}.")
    print(f"#const m={m}.")
    print()
    
    # Buildings
    print("% Buildings")
    for i in range(n):
        for j in range(m):
            if j < len(lines[i]) and lines[i][j] == '#':
                print(f"building({i},{j}).")
    print()
    
    # Stations
    print("% Stations")
    for i in range(n):
        for j in range(m):
            if j < len(lines[i]) and lines[i][j] == 'X':
                print(f"station({i},{j}).")
    print()
    
    # Initial taxi positions
    print("% Initial taxi positions")
    for i in range(n):
        for j in range(m):
            if j < len(lines[i]) and lines[i][j].isdigit():
                taxi_id = lines[i][j]
                print(f"init_at({taxi_id},{i},{j}).")
    print()
    
    # Initial passenger positions
    print("% Initial passenger positions")
    for i in range(n):
        for j in range(m):
            if j < len(lines[i]) and lines[i][j].isalpha() and lines[i][j].islower():
                person = lines[i][j]
                print(f"init_person_at({person},{i},{j}).")

sys.stdout = sys.__stdout__
print(f"Encoding written to {sys.argv[2]}")