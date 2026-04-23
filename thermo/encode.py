import sys

if len(sys.argv) != 3:
    print("encode.py inputfile outputfile")
    sys.exit()

f = open(sys.argv[1], "r")
out = open(sys.argv[2], "w")
sys.stdout = out

lines = f.readlines()
n = len(lines) - 2  # The last 2 lines are the numbers

# Process the grid
grid = []
for i in range(n):
    grid.append(lines[i].strip())

# Read the column and row numbers
col_nums = list(map(int, lines[n].split()))
row_nums = list(map(int, lines[n+1].split()))

print(f"#const n={n}.")
print(f"dim({n}).")

# Generate facts for the target columns and rows
for i, num in enumerate(col_nums):
    print(f"col_target({i},{num}).")

for i, num in enumerate(row_nums):
    print(f"row_target({i},{num}).")

# Identify thermometers and their bulbs
thermo_id = 0
visited = [[False]*n for _ in range(n)]

for i in range(n):
    for j in range(n):
        if not visited[i][j]:
            char = grid[i][j]
            
            # If it's a bulb, trace the whole thermometer
            if char in 'UDRL':
                cells = [(i, j)]
                visited[i][j] = True
                
                # Determine direction
                if char == 'U':
                    # Go up
                    x, y = i - 1, j
                    while x >= 0 and grid[x][y] in '^':
                        cells.append((x, y))
                        visited[x][y] = True
                        x -= 1
                elif char == 'D':
                    # Go down
                    x, y = i + 1, j
                    while x < n and grid[x][y] in 'v':
                        cells.append((x, y))
                        visited[x][y] = True
                        x += 1
                elif char == 'R':
                    # Go right
                    x, y = i, j + 1
                    while y < n and grid[x][y] in '>':
                        cells.append((x, y))
                        visited[x][y] = True
                        y += 1
                elif char == 'L':
                    # Go left
                    x, y = i, j - 1
                    while y >= 0 and grid[x][y] in '<':
                        cells.append((x, y))
                        visited[x][y] = True
                        y -= 1
                
                # Generate facts for this thermometer
                # print(f"bulb({thermo_id},{i},{j}).")
                for idx, (cx, cy) in enumerate(cells):
                    print(f"thermo({thermo_id},{cx},{cy},{idx}).")
                
                thermo_id += 1

f.close()
out.close()