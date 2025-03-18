import json
import numpy as np
import heapq
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.uix.screenmanager import ScreenManager, Screen
from kivy.graphics import Line, Color, Ellipse, Rectangle
from kivy.clock import Clock
from usb4a import usb
from usbserial4a import serial4a
from kivy.core.window import Window
from kivy.uix.popup import Popup
from kivy.uix.dropdown import DropDown


# Load the supermarket map image
MAP_IMAGE = 'top view2.png'
MAP_WIDTH_PIXELS  = 675
MAP_HEIGHT_PIXELS = 782
MAP_WIDTH_METERS  = 16.04
MAP_HEIGHT_METERS  = 18.34

grid_size = 0.5   #0.5m grids
num_of_rows = int(np.ceil(MAP_HEIGHT_METERS/grid_size) + 1)
num_of_cols = int(np.ceil(MAP_WIDTH_METERS/grid_size)  + 1)

map_grid = np.zeros((num_of_rows,num_of_cols))      # 1 for obstacles. 0 for walkable paths.


# --------------- Creating binary map with obstacles -------------------
map_grid[:9,6:27]       = 1
map_grid[:2,29:]        = 1
map_grid[:,31:]         = 1
map_grid[10:33,1:5]     = 1
map_grid[13:33,6:10]    = 1
map_grid[13:33,11:15]   = 1
map_grid[13:33,16:20]   = 1
map_grid[13:33,21:25]   = 1
map_grid[13:33,26:30]   = 1
map_grid[34:,:]         = 1
# ----------------------------------------------------------------------

# Initialize Serial Port
serial_port = None

def is_valid_point(x,y):   
    row = int(y / grid_size)
    col = int(x / grid_size)
    #print(row,col)
    if((row+1) <= num_of_rows and (col+1) <= num_of_cols ):

        if(map_grid[row,col] != 1):
            #print("valid point")
            return True        
    else:
        #print("Invalid point")
        return False
# Load item locations from JSON file
with open('items_v3.json', 'r') as file:
    item_data = json.load(file)
    items = item_data['items']
    item_locations = item_data['item_locations']

def open_serial_port():
    global serial_port
    usb_device_list = usb.get_usb_device_list()
    if usb_device_list:
        serial_port = serial4a.get_serial_port(
            usb_device_list[0].getDeviceName(), 115200, 8, 'N', 1
        )
        return True
    return False

def close_serial_port():
    global serial_port
    if serial_port and serial_port.is_open:
        serial_port.close()
        serial_port = None

def heuristic(a, b):
    """Calculate the Manhattan distance between two points."""
    return abs(a[0] - b[0]) + abs(a[1] - b[1])

def a_star(start, goal, grid):
    """A* algorithm to find the shortest path from start to goal."""
    neighbors = [(0, 1), (1, 0), (0, -1), (-1, 0)]  # 4-connected grid
    close_set = set()
    came_from = {}
    gscore = {start: 0}
    fscore = {start: heuristic(start, goal)}
    open_heap = []
    heapq.heappush(open_heap, (fscore[start], start))

    while open_heap:
        current = heapq.heappop(open_heap)[1]

        if current == goal:
            path = []
            while current in came_from:
                path.append(current)
                current = came_from[current]
            return path[::-1]  # Return reversed path

        close_set.add(current)
        for i, j in neighbors:
            neighbor = (current[0] + i, current[1] + j)
            tentative_g_score = gscore[current] + 1

            if 0 <= neighbor[0] < grid.shape[0] and 0 <= neighbor[1] < grid.shape[1]:
                if grid[neighbor[0], neighbor[1]] == 1:  # Obstacle
                    continue
            else:
                continue  # Out of bounds

            if neighbor in close_set and tentative_g_score >= gscore.get(neighbor, 0):
                continue

            if tentative_g_score < gscore.get(neighbor, 0) or neighbor not in [i[1] for i in open_heap]:
                came_from[neighbor] = current
                gscore[neighbor] = tentative_g_score
                fscore[neighbor] = tentative_g_score + heuristic(neighbor, goal)
                heapq.heappush(open_heap, (fscore[neighbor], neighbor))

    return None  # No path found

# Function to find the nearest valid point
def find_nearest_valid_point(x, y):
    """Find the nearest valid point (not in an obstacle) to the given coordinates."""
    row = int(y / grid_size)
    col = int(x / grid_size)
    
    # Search in increasing radius until a valid point is found
    for radius in range(1, max(num_of_rows, num_of_cols)):
        for i in range(-radius, radius + 1):
            for j in range(-radius, radius + 1):
                new_row = row + i
                new_col = col + j
                if 0 <= new_row < num_of_rows and 0 <= new_col < num_of_cols:
                    if map_grid[new_row, new_col] == 0:
                        return (new_col * grid_size, new_row * grid_size)
    return None

class HomeScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)
        
        # Logo
        self.logo = Image(source='logo.png', size_hint=(1, 0.6))
        layout.add_widget(self.logo)
        
        # Start Shopping Button
        self.start_button = Button(text='Start Shopping', size_hint=(1, 0.2))
        self.start_button.bind(on_press=self.start_shopping)
        layout.add_widget(self.start_button)
        
        self.add_widget(layout)
    
    def start_shopping(self, instance):
        if open_serial_port():
            self.manager.current = 'plot'
        else:
            popup = Popup(title='Error', content=Label(text='No serial device found!'),
                          size_hint=(None, None), size=(400, 200))
            popup.open()

class PlotWidget(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.path_x = []
        self.path_y = []
        self.map_texture = Image(source=MAP_IMAGE).texture
        
        # Keep track of the image scaling
        self.scaled_width = 0
        self.scaled_height = 0
        self.offset_x = 0
        self.offset_y = 0

        self.scale = 0

        self.prev_point = [0,0]

        self.path = []  # Store the A* path

        self.goal = None  # Store the goal position

    def update_plot(self, x, y):
        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        square_center_x_m = round(x*2)/2
        square_center_y_m = round(y*2)/2


        if(not is_valid_point(square_center_x_m,square_center_y_m)):
            print('not valid point')
            #square_center_x_m = self.prev_point[0]
            #square_center_y_m = self.prev_point[1]

            step = 0
            i = 0

            while(not is_valid_point(square_center_x_m,square_center_y_m) or i==0):
                #print('inside while loop')
                if(i%4 == 0):
                    step += grid_size
                    square_center_y_m += (step - grid_size)
                    square_center_x_m -= step
                elif (i%4 == 1):
                    square_center_x_m += step
                    square_center_y_m += step
                elif (i%4 == 2):
                    square_center_y_m -= step
                    square_center_x_m += step
                else:
                    square_center_x_m -= step
                    square_center_y_m -= step
                i+=1

        # self.prev_point[0] = square_center_x_m
        # self.prev_point[1] = square_center_y_m

        square_bottom_left_x_m = square_center_x_m - grid_size
        square_bottom_left_y_m = square_center_y_m - grid_size

        square_bottom_left_x = square_bottom_left_x_m * self.scale + self.offset_x
        square_bottom_left_y = square_bottom_left_y_m * self.scale + self.offset_y

        square_width = 1 * self.scale

        # self.path_x.append(scaled_x)
        # self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            # Draw the background map while keeping aspect ratio
            Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))

            # Color(0, 0, 1, 1)  # Blue Path
            # if len(self.path_x) > 1:
            #     Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)
            self.draw_item_locations()

            # Draw the A* path if it exists
            if self.path:
                Color(0, 0, 1, 1)  # Blue for path
                points = []
                for (row, col) in self.path:
                    x_path = col * grid_size * self.scale + self.offset_x
                    y_path = row * grid_size * self.scale + self.offset_y
                    points.extend([x_path, y_path])
                Line(points=points, width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))
            Line(rectangle=(square_bottom_left_x,square_bottom_left_y,square_width, square_width), width=2)

    def set_path(self, path):
        """Set the A* path to be drawn."""
        self.path = path
        self.update_plot(0, 0)  # Trigger a redraw

    def set_path(self, path):
        """Set the A* path to be drawn."""
        self.path = path
        self.update_plot(0, 0)  # Trigger a redraw

    def set_goal(self, goal):
        """Set the goal position."""
        self.goal = goal

    def check_deviation(self, x, y):
        """Check if the user has deviated from the path."""
        if not self.path:
            return False

        # Convert current position to grid indices
        current_row = int(y / grid_size)
        current_col = int(x / grid_size)

        # Check if the current position is close to any point on the path
        for (row, col) in self.path:
            if abs(row - current_row) <= 1 and abs(col - current_col) <= 1:
                return False  # User is on the path

        return True  # User has deviated

    def draw_obstacles(self):
        """Draw obstacles on the map as rectangles."""
        Color(1, 0, 0, 0.3)  # Red with 30% opacity
        for row in range(num_of_rows):
            for col in range(num_of_cols):
                if map_grid[row, col] == 1:
                    # Calculate the position and size of the obstacle rectangle
                    x = col * grid_size * self.scale + self.offset_x
                    y = row * grid_size * self.scale + self.offset_y
                    width = grid_size * self.scale
                    height = grid_size * self.scale
                    Rectangle(pos=(x, y), size=(width, height))
    
    def draw_item_locations(self):
        """Draw item locations on the map as markers with black labels."""
        for i, (x, y) in enumerate(item_locations):
            if i >= len(items):  # Stop if there are no more item names
                break

            # Scale the coordinates to match the map
            scaled_x = x * self.scale + self.offset_x
            scaled_y = y * self.scale + self.offset_y

            # Draw a green marker for the item location
            with self.canvas:
                Color(0, 1, 0, 1)  # Green for item markers
                Ellipse(pos=(scaled_x , scaled_y ), size=(10, 10))  # Draw a small circle
            
            # Alternate label position: below for even indices, above for odd indices
            if i % 3 == 0:
                # Display label below the point
                label_pos_y = scaled_y - 20  # Offset below the point       
            elif i % 3 == 1:
                label_pos_y = scaled_y + 10
                scaled_x = scaled_x + 10
            else:
                # Display label above the point
                label_pos_y = scaled_y + 20  # Offset above the point
            # Add a label for the item name
            label = Label(
                text=items[i],
                pos=(scaled_x, label_pos_y),  # Position the label next to the marker
                size=(10, 10),  # Set a fixed size for the label
                size_hint=(None, None),  # Disable size_hint to use fixed size
                color=(0, 0, 0, 1),  # Black text color
                font_size='7sp',  # Set font size
                halign='left',  # Align text to the left
                valign='middle'  # Align text vertically in the middle
            )
            self.add_widget(label)  # Add the label to the widget
    
    def on_size(self, *args):
        # Calculate the best fit while maintaining the aspect ratio
        widget_ratio = self.width / self.height
        image_ratio = MAP_WIDTH_PIXELS / MAP_HEIGHT_PIXELS


        if widget_ratio > image_ratio:
            self.scaled_height = self.height
            self.scaled_width = self.scaled_height * image_ratio
        else:
            self.scaled_width = self.width
            self.scaled_height = self.scaled_width / image_ratio
        
        self.scale = (self.scaled_width / MAP_WIDTH_METERS  + self.scaled_height / MAP_HEIGHT_METERS)/2

        # Center the image
        self.offset_x = (self.width - self.scaled_width) / 2
        self.offset_y = (self.height - self.scaled_height) / 2

        self.path_x.clear()
        self.path_y.clear()

        self.update_plot(0, 0)  # Redraw the plot when the widget size changes

    def clear_path(self):
            self.path_x = []
            self.path_y = []
            self.canvas.clear()
            with self.canvas:
                Rectangle(texture=self.map_texture, pos=((self.width - self.scaled_width) / 2, (self.height - self.scaled_height) / 2), size=(self.scaled_width, self.scaled_height))

class PlotScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        layout = BoxLayout(orientation='vertical')
        
        # Dropdown for item selection
        self.dropdown = DropDown()
        for item in items:
            btn = Button(text=item, size_hint_y=None, height=44)
            btn.bind(on_release=lambda btn: self.select_item(btn.text))
            self.dropdown.add_widget(btn)
        self.item_button = Button(text='Select Item', size_hint=(1, 0.1))
        self.item_button.bind(on_release=self.dropdown.open)
        layout.add_widget(self.item_button)

        # Plot Widget
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        
        # Cancel Button
        self.cancel_button = Button(text='Cancel', size_hint=(1, 0.1))
        self.cancel_button.bind(on_press=self.cancel_plot)
        layout.add_widget(self.cancel_button)
        
        self.add_widget(layout)
        Clock.schedule_interval(self.update_plot, 0.05)
    
    # Modify the select_item method in PlotScreen
    def select_item(self, item_name):
            """Handle item selection and calculate the A* path."""
            global item_index
            item_index = items.index(item_name)
            goal_x, goal_y = item_locations[item_index]

            # Check if the goal is in an obstacle
            if not is_valid_point(goal_x, goal_y):
                print(f"Item '{item_name}' is in an obstacle. Finding nearest valid point...")
                valid_point = find_nearest_valid_point(goal_x, goal_y)
                if valid_point:
                    goal_x, goal_y = valid_point
                    print(f"Adjusted goal to: {goal_x}, {goal_y}")
                else:
                    print("No valid point found near the goal.")
                    return

            # Set the goal in the plot widget
            self.plot_widget.set_goal((goal_x, goal_y))

            # Convert goal coordinates to grid indices
            goal_row = int(goal_y / grid_size)
            goal_col = int(goal_x / grid_size)

            # Get current position (assuming it's stored in self.plot_widget.prev_point)
            current_row = int(self.plot_widget.prev_point[1] / grid_size)
            current_col = int(self.plot_widget.prev_point[0] / grid_size)

            # Calculate the A* path
            path = a_star((current_row, current_col), (goal_row, goal_col), map_grid)
            if path:
                self.plot_widget.set_path(path)
            else:
                print("No path found!")

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            line = serial_port.readline().decode()
            if line:
                try:
                    data = json.loads(line)
                    x, y = float(data["X"]), float(data["Y"])
                    self.plot_widget.prev_point = [x, y]

                    # Check if the user has deviated from the path
                    if self.plot_widget.check_deviation(x, y):
                        print("User has deviated. Recalculating path...")
                        self.select_item(items[item_index])  # Recalculate path to the same goal

                    self.plot_widget.update_plot(x, y)
                except (json.JSONDecodeError, ValueError, KeyError):
                    pass
                
    def cancel_plot(self, instance):
        close_serial_port()
        self.plot_widget.clear_path()
        self.manager.current = 'home'

class ShoppingApp(App):
    def build(self):
        sm = ScreenManager()
        sm.add_widget(HomeScreen(name='home'))
        sm.add_widget(PlotScreen(name='plot'))
        return sm

if __name__ == '__main__':
    ShoppingApp().run()
