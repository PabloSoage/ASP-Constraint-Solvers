import pygame
import sys

### Main program

if len(sys.argv)<3:
    print("drawthermo.py <domainfile.txt> <solution_file.txt>")
    sys.exit()

# Opening files
f = open(sys.argv[1], "r", encoding='utf-8'); domain = f.readlines(); f.close()
f = open(sys.argv[2], "r", encoding='utf-8'); filled = f.readlines(); f.close()
n=len(domain)-2

# Mapping characters to images
char_to_image = {
    'R': 'r',
    'U': 'u',
    'L': 'l',
    'D': 'd',
    '>': 'rend',
    '<': 'lend',
    '^': 'uend',
    'v': 'dend',
    '2': '7T',
    '1': 'rT',
    '3': 'JT',
    '0': 'LT'
}

def get_image_name(char, row, col, domain, n):
    """Determines the image name based on character and context"""
    # Special characters (bulbs and curves)
    if char in ['R', 'U', 'L', 'D', '0', '1', '2', '3']:
        return char_to_image[char]
    
    # Segments that can be vertical/horizontal or ends
    if char == '^':
        # Check if there's something above
        if row > 0 and domain[row-1][col] in ['^', '1', '2']:
            return 'vert'
        return 'uend'
    
    if char == 'v':
        # Check if there's something below
        if row < n-1 and domain[row+1][col] in ['v', '3', '0']:
            return 'vert'
        return 'dend'
    
    if char == '>':
        # Check if there's something to the right
        if col < n-1 and domain[row][col+1] in ['>', '2', '3']:
            return 'hor'
        return 'rend'
    
    if char == '<':
        # Check if there's something to the left
        if col > 0 and domain[row][col-1] in ['<', '1', '0']:
            return 'hor'
        return 'lend'
    
    return 'r'  # default

# Visualization
pygame.init()
cellsize = 31  # Reduced from 41 to 31
screen = pygame.display.set_mode([cellsize*n, cellsize*n])
screen.fill(pygame.Color("white"))
pygame.display.set_caption("Thermometers puzzle")

for i in range(n):
    for j in range(n):
        char = domain[i][j]
        if char == '\n' or char not in char_to_image and char not in ['^', 'v', '>', '<']:
            continue
            
        img_name = get_image_name(char, i, j, domain, n)
        
        # Verify if filled (red)
        if i < len(filled) and j < len(filled[i]) and filled[i][j] == 'x':
            img_name = "red-" + img_name
        
        try:
            img = pygame.image.load(f"pics/{img_name}.png").convert()
            # Resize all images to 31x31 (high quality when reducing)
            img = pygame.transform.smoothscale(img, (cellsize, cellsize))
            screen.blit(img, [j*cellsize, i*cellsize])
        except Exception as e:
            print(f"Warning: Image not found or error - pics/{img_name}.png: {e}")

pygame.display.flip()
done = False
while not done:
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            done = True
pygame.quit()