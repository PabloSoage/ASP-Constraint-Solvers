import sys

if len(sys.argv) != 3:
    print("encode2.py inputfile outputfile")
    sys.exit()

f = open(sys.argv[1], "r", encoding='utf-8')
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

# Valid thermometer characters
valid_chars = 'UDRL^v><0123'

def get_connections(char, row, col):
    """
    Returns the positions (row, col) to which this character connects
    Based on the logic of drawthermo2.py
    """
    connections = []
    
    # Bulbs - only one direction
    if char == 'U': return [(row-1, col)]
    if char == 'D': return [(row+1, col)]
    if char == 'R': return [(row, col+1)]
    if char == 'L': return [(row, col-1)]
    
    # Curves - two directions
    if char == '2': return [(row, col-1), (row+1, col)]  # ┐ left and down
    if char == '1': return [(row, col+1), (row+1, col)]  # ┌ right and down
    if char == '3': return [(row, col-1), (row-1, col)]  # ┘ left and up
    if char == '0': return [(row, col+1), (row-1, col)]  # └ right and up
    
    # Segments - check if it's an end or continues
    if char == '^':
        # If there's something valid above, connect up
        if row > 0 and grid[row-1][col] in ['^', '1', '2']:
            return [(row-1, col)]
        # If not, it's an end (doesn't connect to anything else)
        return []
    
    if char == 'v':
        # If there's something valid below, connect down
        if row < n-1 and grid[row+1][col] in ['v', '3', '0']:
            return [(row+1, col)]
        return []
    
    if char == '>':
        # If there's something valid to the right, connect right
        if col < n-1 and grid[row][col+1] in ['>', '2', '3']:
            return [(row, col+1)]
        return []
    
    if char == '<':
        # If there's something valid to the left, connect left
        if col > 0 and grid[row][col-1] in ['<', '1', '0']:
            return [(row, col-1)]
        return []
    
    return []

# Identify thermometers and their bulbs
thermo_id = 0
visited = [[False]*n for _ in range(n)]

for i in range(n):
    for j in range(n):
        if not visited[i][j] and grid[i][j] in 'UDRL':
            char = grid[i][j]
            cells = [(i, j)]
            visited[i][j] = True
            
            # BFS/tracing from the bulb
            current = (i, j)
            
            while True:
                row, col = current
                char = grid[row][col]
                
                # Get connections from this cell
                connections = get_connections(char, row, col)
                
                # Filter only the NOT visited ones
                next_cells = [(r, c) for r, c in connections 
                             if 0 <= r < n and 0 <= c < n 
                             and not visited[r][c]
                             and grid[r][c] in valid_chars]
                
                if not next_cells:
                    break  # End of thermometer
                
                # There must be exactly 1 next cell
                if len(next_cells) > 1:
                    print(f"% ERROR: Branching at ({row},{col})", file=sys.stderr)
                    break
                
                next_row, next_col = next_cells[0]
                cells.append((next_row, next_col))
                visited[next_row][next_col] = True
                current = (next_row, next_col)
            
            # Generate facts for this thermometer
            for idx, (cx, cy) in enumerate(cells):
                print(f"thermo({thermo_id},{cx},{cy},{idx}).")
            
            thermo_id += 1

f.close()
out.close()