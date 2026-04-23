import tkinter as tk
from tkinter import filedialog, messagebox
import re
from html.parser import HTMLParser
from PIL import Image, ImageTk
import os

class ThermoHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.cells = []
        self.col_targets = []
        self.row_targets = []
        self.current_class = None
        
    def handle_starttag(self, tag, attrs):
        if tag == "div":
            attrs_dict = dict(attrs)
            class_attr = attrs_dict.get('class', '')
            style = attrs_dict.get('style', '')
            
            if 'cell task v' in class_attr:
                self.current_class = 'col_target'
            elif 'cell task h' in class_attr:
                self.current_class = 'row_target'
            elif 'cell selectable' in class_attr:
                top_match = re.search(r'top: (\d+)px', style)
                left_match = re.search(r'left: (\d+)px', style)
                
                if top_match and left_match:
                    top = int(top_match.group(1))
                    left = int(left_match.group(1))
                    
                    cell_info = {
                        'row': (top - 3) // 31,
                        'col': (left - 3) // 31,
                        'class': class_attr,
                        'is_start': 'start' in class_attr
                    }
                    self.cells.append(cell_info)
    
    def handle_data(self, data):
        data = data.strip()
        if data and self.current_class:
            if self.current_class == 'col_target':
                self.col_targets.append(int(data))
            elif self.current_class == 'row_target':
                self.row_targets.append(int(data))
            self.current_class = None

class ThermoTracerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Thermometer Tracer - Manual")
        
        self.cells = []
        self.col_targets = []
        self.row_targets = []
        self.n = 0
        self.grid_data = []
        self.cell_buttons = {}
        self.image_mode = False
        self.images = {}
        
        # Available characters
        self.chars = ['U', 'D', 'R', 'L', '^', 'v', '>', '<', '┐', '┌', '┘', '└', '.']
        self.char_names = {
            'U': 'Bulb ↑', 
            'D': 'Bulb ↓', 
            'R': 'Bulb →', 
            'L': 'Bulb ←',
            '^': 'End ↑', 
            'v': 'End ↓', 
            '>': 'End →', 
            '<': 'End ←',
            '┐': 'Curve ┐',
            '┌': 'Curve ┌',
            '┘': 'Curve ┘',
            '└': 'Curve └',
            '.': 'Empty'
        }
        self.current_char = '.'
        
        # Load images if they exist
        self.load_images()
        
        self.create_menu()
        self.create_toolbar()
        self.create_grid_frame()
        
    def load_images(self):
        """Loads images from the pics folder"""
        pics_dir = "../pics"
        if not os.path.exists(pics_dir):
            return
        
        image_files = {
            '┐': '7T.png',
            '┘': 'JT.png',
            '└': 'LT.png',
            'D': 'd.png',
            'dend': 'dend.png',
            'hor': 'hor.png',
            'L': 'l.png',
            'lend': 'lend.png',
            'R': 'r.png',
            '┌': 'rT.png',
            'rend': 'rend.png',
            'U': 'u.png',
            'uend': 'uend.png',
            'vert': 'vert.png'
        }
        
        for key, filename in image_files.items():
            path = os.path.join(pics_dir, filename)
            if os.path.exists(path):
                try:
                    img = Image.open(path)
                    img = img.resize((30, 30), Image.Resampling.LANCZOS)
                    self.images[key] = ImageTk.PhotoImage(img)
                except:
                    pass
    
    def get_image_for_cell(self, row, col):
        """Determines which image to show for a cell according to the rules"""
        char = self.grid_data[row][col]
        
        # Direct bulbs
        if char in ['U', 'D', 'R', 'L']:
            return self.images.get(char)
        
        # Curves
        if char in ['┐', '┌', '┘', '└']:
            return self.images.get(char)
        
        # Ends and segments - needs contextual logic
        if char == '^':
            # Check if there's something above
            if row > 0:
                above = self.grid_data[row-1][col]
                if above in ['^', '┌', '┐']:
                    return self.images.get('vert')
            return self.images.get('uend')
        
        if char == 'v':
            # Check if there's something below
            if row < self.n - 1:
                below = self.grid_data[row+1][col]
                if below in ['v', '┘', '└']:
                    return self.images.get('vert')
            return self.images.get('dend')
        
        if char == '>':
            # Check if there's something to the right
            if col < self.n - 1:
                right = self.grid_data[row][col+1]
                if right in ['>', '┐', '┘']:
                    return self.images.get('hor')
            return self.images.get('rend')
        
        if char == '<':
            # Check if there's something to the left
            if col > 0:
                left = self.grid_data[row][col-1]
                if left in ['<', '┌', '└']:
                    return self.images.get('hor')
            return self.images.get('lend')
        
        return None
    
    def create_menu(self):
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="File", menu=file_menu)
        file_menu.add_command(label="Load HTML", command=self.load_html)
        file_menu.add_command(label="Load TXT", command=self.load_txt)
        file_menu.add_command(label="Save TXT", command=self.save_txt)
        file_menu.add_separator()
        file_menu.add_command(label="Exit", command=self.root.quit)
        
        view_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="View", menu=view_menu)
        view_menu.add_command(label="Toggle Image Mode", command=self.toggle_image_mode)
    
    def create_toolbar(self):
        toolbar = tk.Frame(self.root, relief=tk.RAISED, borderwidth=2)
        toolbar.pack(side=tk.TOP, fill=tk.X, padx=5, pady=5)
        
        tk.Label(toolbar, text="Select type:", font=('Arial', 10, 'bold')).pack(side=tk.LEFT, padx=5)
        
        for char in self.chars:
            btn = tk.Button(
                toolbar, 
                text=f"{char}",
                command=lambda c=char: self.select_char(c),
                relief=tk.RAISED,
                width=4,
                height=1,
                font=('Courier', 10, 'bold')
            )
            btn.pack(side=tk.LEFT, padx=2)
            if char == '.':
                btn.config(bg='lightgray')
        
        self.status_label = tk.Label(toolbar, text=f"Selected: {self.char_names[self.current_char]}", 
                                     font=('Arial', 10), fg='blue')
        self.status_label.pack(side=tk.RIGHT, padx=10)
    
    def create_grid_frame(self):
        self.grid_frame = tk.Frame(self.root)
        self.grid_frame.pack(padx=10, pady=10)
        
        tk.Label(self.grid_frame, text="Load an HTML or TXT file first", 
                font=('Arial', 12)).pack(pady=20)
    
    def select_char(self, char):
        self.current_char = char
        self.status_label.config(text=f"Selected: {self.char_names[char]}")
    
    def load_html(self):
        filename = filedialog.askopenfilename(
            title="Select HTML file",
            filetypes=[("HTML files", "*.html"), ("All files", "*.*")]
        )
        
        if not filename:
            return
        
        with open(filename, 'r', encoding='utf-8') as f:
            html_content = f.read()
        
        parser = ThermoHTMLParser()
        parser.feed(html_content)
        
        self.cells = parser.cells
        self.col_targets = parser.col_targets
        self.row_targets = parser.row_targets
        
        if not self.cells:
            messagebox.showerror("Error", "No cells found in the HTML")
            return
        
        self.n = max([c['row'] for c in self.cells]) + 1
        
        # Initialize all empty
        self.grid_data = [['.' for _ in range(self.n)] for _ in range(self.n)]
        
        # ONLY mark bulbs (start) - the rest empty
        for cell in self.cells:
            if cell['is_start']:
                row, col = cell['row'], cell['col']
                self.grid_data[row][col] = 'B'  # Temporary, user will assign U/D/R/L
        
        self.draw_grid()
    
    def load_txt(self):
        """Loads a previously saved TXT file"""
        filename = filedialog.askopenfilename(
            title="Select TXT file",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if not filename:
            return
        
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        if len(lines) < 3:
            messagebox.showerror("Error", "Invalid TXT file")
            return
        
        # Read grid and convert numbers to symbols
        self.n = len(lines) - 2
        self.grid_data = []
        for i in range(self.n):
            row_str = lines[i].strip()
            # Convert numbers to symbols: 0→└, 1→┌, 2→┐, 3→┘
            row_str = row_str.replace('0', '└').replace('1', '┌').replace('2', '┐').replace('3', '┘')
            row = list(row_str)
            # Ensure the row has the correct size
            while len(row) < self.n:
                row.append('.')
            self.grid_data.append(row[:self.n])
        
        # Read targets
        self.col_targets = list(map(int, lines[self.n].split()))
        self.row_targets = list(map(int, lines[self.n+1].split()))
        
        self.draw_grid()
    
    def toggle_image_mode(self):
        """Toggles between text and image mode"""
        if not self.images:
            messagebox.showwarning("Warning", "No images found in the 'pics' folder")
            return
        
        self.image_mode = not self.image_mode
        self.draw_grid()
    
    def draw_grid(self):
        # Clear frame
        for widget in self.grid_frame.winfo_children():
            widget.destroy()
        
        self.cell_buttons = {}
        
        # Draw grid
        for i in range(self.n):
            for j in range(self.n):
                char = self.grid_data[i][j]
                
                if self.image_mode and char != '.':
                    img = self.get_image_for_cell(i, j)
                    if img:
                        btn = tk.Button(
                            self.grid_frame,
                            image=img,
                            width=30,
                            height=30,
                            bd=0,  # No border
                            highlightthickness=0,  # No highlight
                            command=lambda row=i, col=j: self.cell_clicked(row, col)
                        )
                    else:
                        color = self.get_cell_color(char)
                        btn = tk.Button(
                            self.grid_frame,
                            text=char,
                            width=3,
                            height=1,
                            bg=color,
                            font=('Courier', 12, 'bold'),
                            bd=0,
                            highlightthickness=0,
                            command=lambda row=i, col=j: self.cell_clicked(row, col)
                        )
                else:
                    color = self.get_cell_color(char)
                    btn = tk.Button(
                        self.grid_frame,
                        text=char,
                        width=3,
                        height=1,
                        bg=color,
                        font=('Courier', 12, 'bold'),
                        command=lambda row=i, col=j: self.cell_clicked(row, col)
                    )
                
                # No padding in image mode to remove gaps
                padx = 0 if self.image_mode else 1
                pady = 0 if self.image_mode else 1
                btn.grid(row=i, column=j, padx=padx, pady=pady)
                self.cell_buttons[(i, j)] = btn
        
        # Show targets
        info_text = f"Grid {self.n}x{self.n} - Mode: {'Image' if self.image_mode else 'Text'}\n"
        info_text += f"Columns: {self.col_targets}\n"
        info_text += f"Rows: {self.row_targets}"
        
        info_label = tk.Label(self.grid_frame, text=info_text, 
                             font=('Arial', 10), justify=tk.LEFT)
        info_label.grid(row=self.n, column=0, columnspan=self.n, pady=10)
    
    def get_cell_color(self, char):
        colors = {
            'U': '#FFB6C6', 'D': '#FFB6C6', 'R': '#FFB6C6', 'L': '#FFB6C6',  # Bulbs pink
            '^': '#C6E2FF', 'v': '#C6E2FF', '>': '#C6E2FF', '<': '#C6E2FF',  # Ends light blue
            '┐': '#D4F1D4', '┌': '#D4F1D4', '┘': '#D4F1D4', '└': '#D4F1D4',  # Curves light green
            'B': '#FFFF99',  # Unspecified bulb - yellow
            '.': 'white'
        }
        return colors.get(char, 'lightgray')
    
    def cell_clicked(self, row, col):
        self.grid_data[row][col] = self.current_char
        btn = self.cell_buttons[(row, col)]
        
        if self.image_mode and self.current_char != '.':
            img = self.get_image_for_cell(row, col)
            if img:
                btn.config(image=img, text='', bd=0, highlightthickness=0)
            else:
                btn.config(text=self.current_char, bg=self.get_cell_color(self.current_char))
        else:
            btn.config(text=self.current_char, bg=self.get_cell_color(self.current_char))
    
    def save_txt(self):
        if not self.grid_data:
            messagebox.showwarning("Warning", "There is no grid to save")
            return
        
        filename = filedialog.asksaveasfilename(
            title="Save TXT file",
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if not filename:
            return
        
        # Convert symbols to numbers and B to . before saving
        with open(filename, 'w', encoding='utf-8') as f:
            for row in self.grid_data:
                line = ''.join(row).replace('B', '.')
                # Convert symbols to numbers: └→0, ┌→1, ┐→2, ┘→3
                line = line.replace('└', '0').replace('┌', '1').replace('┐', '2').replace('┘', '3')
                f.write(line + '\n')
            f.write(' '.join(map(str, self.col_targets)) + '\n')
            f.write(' '.join(map(str, self.row_targets)) + '\n')
        
        messagebox.showinfo("Success", f"File saved:\n{filename}")

if __name__ == "__main__":
    root = tk.Tk()
    app = ThermoTracerGUI(root)
    root.mainloop()