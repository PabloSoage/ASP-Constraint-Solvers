import pygame
import sys
import random

if len(sys.argv) < 2:
    print("visualize_encoding.py <domain.lp>")
    sys.exit()

# Read the .lp file
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Parse the data
n = 0
thermos = {}  # {thermo_id: [(x,y,pos), ...]}
col_targets = {}
row_targets = {}

for line in lines:
    line = line.strip()
    
    if line.startswith('#const n='):
        n = int(line.split('=')[1].rstrip('.'))
    
    elif line.startswith('thermo('):
        # thermo(ID,X,Y,Pos).
        parts = line[7:-2].split(',')
        tid = int(parts[0])
        x = int(parts[1])
        y = int(parts[2])
        pos = int(parts[3])
        
        if tid not in thermos:
            thermos[tid] = []
        thermos[tid].append((x, y, pos))
    
    elif line.startswith('col_target('):
        parts = line[11:-2].split(',')
        col_targets[int(parts[0])] = int(parts[1])
    
    elif line.startswith('row_target('):
        parts = line[11:-2].split(',')
        row_targets[int(parts[0])] = int(parts[1])

# Sort each thermometer by position
for tid in thermos:
    thermos[tid].sort(key=lambda x: x[2])

# Generate unique colors for each thermometer
def generate_colors(num_colors):
    colors = []
    random.seed(42)  # For consistent colors
    for _ in range(num_colors):
        colors.append((random.randint(50, 255), 
                      random.randint(50, 255), 
                      random.randint(50, 255)))
    return colors

colors = generate_colors(len(thermos))

# Visualization
pygame.init()
cell_size = 40
margin = 50
screen_width = n * cell_size + 2 * margin
screen_height = n * cell_size + 2 * margin

screen = pygame.display.set_mode([screen_width, screen_height])
screen.fill((255, 255, 255))
pygame.display.set_caption(f"Thermometer Encoding Visualization - {len(thermos)} thermos")

font = pygame.font.Font(None, 20)
font_small = pygame.font.Font(None, 16)

# Draw grid
for i in range(n + 1):
    # Vertical lines
    pygame.draw.line(screen, (200, 200, 200), 
                    (margin + i * cell_size, margin), 
                    (margin + i * cell_size, margin + n * cell_size))
    # Horizontal lines
    pygame.draw.line(screen, (200, 200, 200), 
                    (margin, margin + i * cell_size), 
                    (margin + n * cell_size, margin + i * cell_size))

# Draw column targets
for col, target in col_targets.items():
    text = font_small.render(str(target), True, (0, 0, 0))
    screen.blit(text, (margin + col * cell_size + cell_size//2 - 5, margin - 25))

# Draw row targets
for row, target in row_targets.items():
    text = font_small.render(str(target), True, (0, 0, 0))
    screen.blit(text, (margin - 30, margin + row * cell_size + cell_size//2 - 5))

# Draw each thermometer
for tid, cells in thermos.items():
    color = colors[tid % len(colors)]
    
    # Draw lines connecting the cells
    for i in range(len(cells) - 1):
        x1, y1, _ = cells[i]
        x2, y2, _ = cells[i + 1]
        
        px1 = margin + y1 * cell_size + cell_size // 2
        py1 = margin + x1 * cell_size + cell_size // 2
        px2 = margin + y2 * cell_size + cell_size // 2
        py2 = margin + x2 * cell_size + cell_size // 2
        
        pygame.draw.line(screen, color, (px1, py1), (px2, py2), 3)
    
    # Mark the bulb (pos=0) with a large circle
    if cells:
        bulb_x, bulb_y, _ = cells[0]
        px = margin + bulb_y * cell_size + cell_size // 2
        py = margin + bulb_x * cell_size + cell_size // 2
        pygame.draw.circle(screen, color, (px, py), 12)
        pygame.draw.circle(screen, (255, 255, 255), (px, py), 8)
        
        # Thermometer number on the bulb
        text = font_small.render(str(tid), True, (0, 0, 0))
        text_rect = text.get_rect(center=(px, py))
        screen.blit(text, text_rect)
        
        # Mark the end with an arrow
        if len(cells) > 1:
            end_x, end_y, end_pos = cells[-1]
            px_end = margin + end_y * cell_size + cell_size // 2
            py_end = margin + end_x * cell_size + cell_size // 2
            
            # Small arrow (circle)
            pygame.draw.circle(screen, color, (px_end, py_end), 6)
            
            # Show length
            text_len = font_small.render(f"L={end_pos+1}", True, color)
            screen.blit(text_len, (px_end + 10, py_end - 10))

# Additional information
info_text = f"Thermometers: {len(thermos)} | Grid: {n}x{n} | Total cells: {sum(len(t) for t in thermos.values())}"
text = font.render(info_text, True, (0, 0, 0))
screen.blit(text, (margin, screen_height - 30))

pygame.display.flip()

# Print statistics to console
print(f"\n=== ENCODING STATISTICS ===")
print(f"Grid: {n}x{n}")
print(f"Number of thermometers: {len(thermos)}")
print(f"Total cells in thermometers: {sum(len(t) for t in thermos.values())}")
print(f"\nDetails per thermometer:")
for tid, cells in sorted(thermos.items()):
    bulb = cells[0]
    end = cells[-1]
    print(f"  T{tid}: {len(cells)} cells | Bulb: ({bulb[0]},{bulb[1]}) | End: ({end[0]},{end[1]}) Pos={end[2]}")

print(f"\nColumn targets: {col_targets}")
print(f"Row targets: {row_targets}")

# Check consistency
total_cells = sum(len(t) for t in thermos.values())
if total_cells != n * n:
    print(f"\n⚠️ WARNING: Expected {n*n} cells but found {total_cells}")
    print(f"   Difference: {n*n - total_cells} cells")

# Event loop
done = False
while not done:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True

pygame.quit()