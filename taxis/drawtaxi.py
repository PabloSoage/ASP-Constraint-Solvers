import pygame
import sys

cellsize=65
walls=[]
taxis={}
person_at=[]
taxi_at=[]
free={}
goals=[]
domain=[]
delay=200
inc = {'u': (-1,0), 'd':(1,0), 'l':(0,-1), 'r':(0,1)}
font = 0

def drawcell(p,s):
   img = pygame.image.load("picstaxi/"+s+".png").convert()
   screen.blit(img, (p[1]*cellsize,p[0]*cellsize))

def drawgrid(screen,n,m):
    screen.fill(pygame.Color('white'))
    for w in walls: drawcell(w,"building")
    for i in range(n):
        for j in range(m):
            if taxi_at[i][j]!=' ':
                if    person_at[i][j]==' ': drawcell((i,j),"free-taxi")
                elif  free[taxi_at[i][j]]: drawcell((i,j),"taxi-person")
                else: drawcell((i,j),"occup-taxi")
                text_surface = font.render(str(taxi_at[i][j]), True,pygame.Color("black"))
                screen.blit(text_surface, dest=(j*cellsize+55 ,i*cellsize+2))
            elif person_at[i][j]!=' ': drawcell((i,j),"person")
            if person_at[i][j]!=' ':
                k=14
                if taxi_at[i][j]!=' ' and not free[taxi_at[i][j]]: k=36
                text_surface = font.render(person_at[i][j], True,pygame.Color("black"))
                screen.blit(text_surface, dest=(j*cellsize+k ,i*cellsize+2))
    for g in goals:
        pygame.draw.rect(screen,pygame.Color("yellow"),[g[1]*cellsize ,g[0]*cellsize+50,65,15],0)
        font2=pygame.font.Font(pygame.font.get_default_font(), 14)
        text_surface = font2.render("STATION", True,pygame.Color("black"))
        screen.blit(text_surface, dest=(g[1]*cellsize+2 ,g[0]*cellsize+51))
    for i in range(n):
        pygame.draw.line(screen,pygame.Color("gray"),(0,i*cellsize),(m*cellsize,i*cellsize),1)
    for i in range(m):
        pygame.draw.line(screen,pygame.Color("gray"),(i*cellsize,0),(i*cellsize,n*cellsize),1)
    pygame.display.flip()
    pygame.event.pump()

def move(t,d):
    i,j=taxis[t][0],taxis[t][1]
    taxi_at[i][j]=' '
    if not free[t]: person_at[i][j]=' '
    ni,nj=i+inc[d][0],j+inc[d][1]
    taxis[t][0],taxis[t][1]=ni,nj

def pick(t):
    free[t]=False; taxis[t][2]=person_at[taxis[t][0]][taxis[t][1]]
def drop(t):
    free[t]=True; taxis[t][2]=' '

def execute(actions):
    for a in actions:
        if   a[0]=='m': move(a[5],a[7]);
        elif a[0]=='p': pick(a[5])
        elif a[0]=='d': drop(a[5])
    for t in taxis:
        taxi_at[taxis[t][0]][taxis[t][1]]=t
        if not free[t]: person_at[taxis[t][0]][taxis[t][1]]=taxis[t][2]
    drawgrid(screen,n,m)
    pygame.display.flip()
    pygame.event.pump()
    pygame.time.wait(delay)    

### Main program ####################
# Checking arguments
if len(sys.argv)!=3 and len(sys.argv)!=4:
    print("python drawtaxi.py <domainfile.txt> <solutionfile.txt> <delayMilisecs>")
    exit(0)
if len(sys.argv)==4:
    delay=int(sys.argv[3])

# Opening files
f = open(sys.argv[1], "r"); domain = f.readlines(); f.close()
f = open(sys.argv[2], "r"); solution = f.readlines(); f.close()
n=len(domain)
for i in range(n):
    domain[i]=list(domain[i][:-1])
m=len(domain[0])
person_at = [[' ' for i in range(m)] for j in range(n)]
taxi_at   = [[' ' for i in range(m)] for j in range(n)]
# Visualization
pygame.init()

screen = pygame.display.set_mode([cellsize*m,cellsize*n])
screen.fill(pygame.Color("white"))
pygame.display.set_caption("Taxi routing")
font=pygame.font.Font(pygame.font.get_default_font(), 16)

for i in range(n):
    for j in range(m):
        s=''
        if domain[i][j]=='#': walls.append((i,j));
        elif domain[i][j]>='a' and domain[i][j]<='z': person_at[i][j]=domain[i][j]
        elif domain[i][j]>='0' and domain[i][j]<='9': 
            taxis[domain[i][j]]=[i,j,' ']; free[domain[i][j]]=True; taxi_at[i][j]=domain[i][j]
        if domain[i][j]=='X': goals.append((i,j));

drawgrid(screen,n,m)
plan=[]
step=[]
i=0; words=solution[0].split()
while i<len(solution) and not (words!=[] and words[0]=='State'): words=solution[i].split(); i=i+1
## Processing the solution file
for l in solution[i:]:
    words=l.split()
    if words[0]=='State': 
        if step!=[]: plan.append(step); step=[]
    else: step=step+words
if step!=[]: plan.append(step)
for step in plan:
    execute(step)
done=False
while not done:
    for evento in pygame.event.get():
        if evento.type == pygame.QUIT:
            done = True
pygame.quit()