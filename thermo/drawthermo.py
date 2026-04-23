import pygame
import sys

def windowdata(lits):
    params={'h':200,'w':400,'caption':''}
    for l in lits:
        for e in thatoms[l]:
            if e[0]=='window':
                for t in e[1:]:
                    if t[0] in params:
                        if type(t[1])==str:
                            params[t[0]]=t[1][1:-1]
                        else:
                            params[t[0]]=t[1]
                return params
    return params

def getvalue(dict,attr,default):
    if attr in dict: return dict[attr]
    return default

### Main program

if len(sys.argv)<2:
    print("drawthermo.py <domainfile.txt> <solution_file.txt>")
    sys.exit()

# Opening files
f = open(sys.argv[1], "r"); domain = f.readlines(); f.close()
f = open(sys.argv[2], "r"); filled = f.readlines(); f.close()
n=len(domain)-2

name={'R':'r', 'U':'u', 'L':'l', 'D':'d', '>':'rend', '<':'lend', '^':'uend', 'v':'dend'}

# Visualization
pygame.init()
cellsize=41
screen = pygame.display.set_mode([cellsize*n,cellsize*n])
screen.fill(pygame.Color("white"))
pygame.display.set_caption("Thermometers puzzle")
img = pygame.image.load("pics/r.png").convert()
screen.blit(img, [0,0])
img = pygame.image.load("pics/rend.png").convert()
screen.blit(img, [41,0])

for i in range(n):
    for j in range(n):
        if domain[i][j]=='>' and j<n and domain[i][j+1]=='>': s='hor'
        elif domain[i][j]=='<' and j>0 and domain[i][j-1]=='<': s='hor'
        elif domain[i][j]=='^' and i>0 and domain[i-1][j]=='^': s='vert'
        elif domain[i][j]=='v' and i<n and domain[i+1][j]=='v': s='vert'
        else: s=name[domain[i][j]]
        if filled[i][j]=='x': s="red-"+s
        img = pygame.image.load("pics/"+s+".png").convert()
        screen.blit(img, [j*cellsize,i*cellsize])

pygame.display.flip()
done=False
while not done:
    for evento in pygame.event.get():
        if evento.type == pygame.QUIT:
            done = True
pygame.quit()