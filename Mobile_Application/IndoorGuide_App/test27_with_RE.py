import json
import numpy as np
import heapq
import time  # For time tracking
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
from kivy.uix.progressbar import ProgressBar
import requests

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

valid_points = set()

for row in range(num_of_rows):
    for col in range(num_of_cols):
        if map_grid[row, col] == 0:
            valid_points.add((row, col))

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
    """Optimized diagonal distance heuristic (octile distance)."""
    dx = abs(a[0] - b[0])
    dy = abs(a[1] - b[1])
    return 1.4 * min(dx, dy) + abs(dx - dy)  # 1.4 ≈ sqrt(2)

def convert_seconds(seconds):
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    remaining_seconds = seconds % 60
    return hours, minutes, remaining_seconds

def a_star(start, goal, grid):
    """Optimized A* algorithm with faster pathfinding."""
    # 8-connected grid for more natural paths
    neighbors = [(0, 1), (1, 0), (0, -1), (-1, 0), 
                 (1, 1), (-1, 1), (1, -1), (-1, -1)]
    
    close_set = set()
    came_from = {}
    gscore = {start: 0}
    fscore = {start: heuristic(start, goal)}
    
    # Use a priority queue with heap
    open_heap = []
    heapq.heappush(open_heap, (fscore[start], start))
    
    # Pre-calculate grid boundaries
    rows, cols = grid.shape
    
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
            
            # Boundary check first (faster than obstacle check)
            if not (0 <= neighbor[0] < rows and 0 <= neighbor[1] < cols):
                continue
                
            # Skip obstacles
            if grid[neighbor[0], neighbor[1]] == 1:
                continue
                
            # Diagonal movement cost (sqrt(2) ≈ 1.4)
            tentative_g_score = gscore[current] + (1.4 if i and j else 1)
            
            if neighbor in close_set and tentative_g_score >= gscore.get(neighbor, float('inf')):
                continue
                
            if tentative_g_score < gscore.get(neighbor, float('inf')):
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
        self.recommendation_popup = None  # Recommendation popup
        self.selected_items = []  # Store selected items
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)

        # Logo
        self.logo = Image(source='logo.png', size_hint=(1, 0.4))
        layout.add_widget(self.logo)
        
        # Item selection label
        self.selection_label = Label(text='Select up to 5 items:', size_hint=(1, 0.1))
        layout.add_widget(self.selection_label)
        
        # Selected items display
        self.selected_items_label = Label(text='No items selected', size_hint=(1, 0.1))
        layout.add_widget(self.selected_items_label)
        
        # Add recommendation button
        self.recommend_button = Button(text='Get Recommendations', size_hint=(1, 0.1))
        self.recommend_button.bind(on_press=self.show_recommendations)
        layout.add_widget(self.recommend_button)  # Add this to your layout

        # Item selection dropdown
        self.dropdown = DropDown()
        for item in items:
            btn = Button(text=item, size_hint_y=None, height=44)
            btn.bind(on_release=lambda btn: self.select_item(btn.text))
            self.dropdown.add_widget(btn)
        
        self.item_button = Button(text='Add Item', size_hint=(1, 0.1))
        self.item_button.bind(on_release=self.dropdown.open)
        layout.add_widget(self.item_button)
        
        # Clear selection button
        self.clear_button = Button(text='Clear Selection', size_hint=(1, 0.1))
        self.clear_button.bind(on_press=self.clear_selection)
        layout.add_widget(self.clear_button)
        
        # Start Shopping Button
        self.start_button = Button(text='Start Shopping', size_hint=(1, 0.2))
        self.start_button.bind(on_press=self.start_shopping)
        layout.add_widget(self.start_button)
        
        self.add_widget(layout)

    def show_recommendations(self, instance):
        if not self.selected_items:
            popup = Popup(title='Warning', 
                         content=Label(text='Please select at least one item first!'),
                         size_hint=(None, None), size=(400, 200))
            popup.open()
            return
            
        try:
            response = requests.post('http://192.168.1.5:5000/recommend',
                                    json={'items': self.selected_items})
            recommendations = response.json().get('recommendations', [])
            
            if not recommendations:
                raise ValueError("No recommendations returned")
                
            # Show popup with recommendations (same as before)
            
        except Exception as e:
            popup = Popup(title='Error', 
                         content=Label(text='Could not get recommendations'),
                         size_hint=(None, None), size=(400, 200))
            popup.open()
    
    def add_recommendation(self, item):
        if len(self.selected_items) >= 5:
            popup = Popup(title='Warning', 
                         content=Label(text='You can select up to 5 items only!'),
                         size_hint=(None, None), size=(400, 200))
            popup.open()
            return
            
        if item not in self.selected_items:
            self.selected_items.append(item)
            self.update_selection_label()
        
        if self.recommendation_popup:
            self.recommendation_popup.dismiss()

    def select_item(self, item_name):
        if item_name in self.selected_items:
            return  # Item already selected
        
        if len(self.selected_items) >= 5:
            popup = Popup(title='Warning', 
                         content=Label(text='You can select up to 5 items only!'),
                         size_hint=(None, None), size=(400, 200))
            popup.open()
            return
            
        self.selected_items.append(item_name)
        self.update_selection_label()
    
    def clear_selection(self, instance):
        self.selected_items = []
        self.update_selection_label()
    
    def update_selection_label(self):
        if not self.selected_items:
            self.selected_items_label.text = 'No items selected'
        else:
            self.selected_items_label.text = 'Selected: ' + ', '.join(self.selected_items)
    
    def start_shopping(self, instance):
        if not self.selected_items:
            popup = Popup(title='Warning', 
                         content=Label(text='Please select at least one item!'),
                         size_hint=(None, None), size=(400, 200))
            popup.open()
            return
            
        if open_serial_port():
            plot_screen = self.manager.get_screen('plot')
            plot_screen.set_shopping_list(self.selected_items)
            self.manager.current = 'plot'
        else:
            popup = Popup(title='Error', 
                         content=Label(text='No serial device found!'),
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

        # Add these for faster rerouting
        self.last_reroute_time = 0
        self.reroute_cooldown = 1.0  # seconds between reroutes
        self.last_valid_position = (0, 0)

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

                    square_center_x_m_path = round(x_path*2)/2
                    square_center_y_m_path = round(y_path*2)/2

                    points.extend([square_center_x_m_path, square_center_y_m_path])
                    
                Line(points=points, width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))
            Line(rectangle=(square_bottom_left_x,square_bottom_left_y,square_width, square_width), width=2)
        
        # Highlight current goal
        if self.goal:
            goal_x, goal_y = self.goal
            scaled_goal_x = goal_x * self.scale + self.offset_x
            scaled_goal_y = goal_y * self.scale + self.offset_y
            with self.canvas:
                Color(1, 1, 0, 1)  # Yellow for goal
                Ellipse(pos=(scaled_goal_x - 10, scaled_goal_y - 10), size=(20, 20))

    def set_path(self, path):
        """Set the A* path to be drawn."""
        self.path = path
        self.update_plot(0, 0)  # Trigger a redraw

    def set_goal(self, goal):
        """Set the goal position."""
        self.goal = goal

    def check_deviation(self, x, y):
        """Optimized deviation check with cooldown."""
        current_time = time.time()
        if current_time - self.last_reroute_time < self.reroute_cooldown:
            return False
            
        if not self.path:
            return False

        # Convert to grid coordinates once
        current_row = int(y / grid_size)
        current_col = int(x / grid_size)
        
        # Check against last few path points (not whole path)
        check_range = min(10, len(self.path))
        for (row, col) in self.path[-check_range:]:
            if abs(row - current_row) <= 1 and abs(col - current_col) <= 1:
                self.last_valid_position = (current_row, current_col)
                return False
                
        self.last_reroute_time = current_time
        return True

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
        self.shopping_list = []
        self.current_item_index = 0
        self.path = []
        self.start_time = None  # Track shopping start time

        self.last_data_time = time.time()  # Track last successful data reception
        self.signal_lost_popup = None  # Track signal lost popup
        self.signal_check_event = None  # For signal monitoring

        layout = BoxLayout(orientation='vertical')
        
        # Current item display
        self.current_item_label = Label(text='No current item', size_hint=(1, 0.1))
        layout.add_widget(self.current_item_label)
        
        # Navigation buttons
        btn_layout = BoxLayout(size_hint=(1, 0.1))
        self.prev_button = Button(text='Previous Item')
        self.prev_button.bind(on_press=self.prev_item)
        btn_layout.add_widget(self.prev_button)
        
        self.next_button = Button(text='Next Item')
        self.next_button.bind(on_press=self.next_item)
        btn_layout.add_widget(self.next_button)
        layout.add_widget(btn_layout)
        
        # Plot Widget
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        
        # Progress Bar
        self.progress_bar = ProgressBar(max=100, size_hint=(1, 0.1))
        layout.add_widget(self.progress_bar)
        
        # Cancel Button
        self.cancel_button = Button(text='Cancel', size_hint=(1, 0.1))
        self.cancel_button.bind(on_press=self.cancel_plot)
        layout.add_widget(self.cancel_button)
        
        self.add_widget(layout)
        Clock.schedule_interval(self.update_plot, 0.05)

    def start_signal_monitoring(self):
        """Start checking for signal loss periodically"""
        if self.signal_check_event is None:
            self.signal_check_event = Clock.schedule_interval(self.check_signal, 1.0)
    
    def stop_signal_monitoring(self):
        """Stop checking for signal loss"""
        if self.signal_check_event:
            self.signal_check_event.cancel()
            self.signal_check_event = None
    
    def check_signal(self, dt):
        """Check if we've lost signal for too long"""
        if time.time() - self.last_data_time > 2.0:  # 2 seconds without data
            self.handle_signal_loss()
    
    def check_connection_health(self):
        """Periodically check the overall connection quality"""
        now = time.time()
        if now - self.last_data_time > 5.0:  # 5 seconds without data
            self.connection_quality = "poor"
        elif now - self.last_data_time > 2.0:  # 2 seconds without data
            self.connection_quality = "unstable"
        else:
            self.connection_quality = "good"
        
        # Optional: Visual indicator
        if hasattr(self, 'connection_label'):
            colors = {
                "good": (0, 1, 0, 1),      # Green
                "unstable": (1, 1, 0, 1),   # Yellow
                "poor": (1, 0, 0, 1)        # Red
            }
            self.connection_label.color = colors[self.connection_quality]
            self.connection_label.text = f"Connection: {self.connection_quality.upper()}"

    def handle_signal_loss(self):
        """Handle UWB signal loss"""
        if self.signal_lost_popup is not None:
            return  # Already showing popup
        
        # First try to reconnect automatically
        if self.attempt_reconnect():
            self.last_data_time = time.time()
            return
                
        self.stop_signal_monitoring()
        
        # Create popup
        content = BoxLayout(orientation='vertical', spacing=10)
        content.add_widget(Label(text='UWB Signal Lost!\nTrying to reconnect...'))
        
        self.signal_lost_popup = Popup(
            title='Connection Error',
            content=content,
            size_hint=(0.8, 0.4),
            auto_dismiss=False
        )
        self.signal_lost_popup.open()
        
        # Start countdown
        self.reconnect_start_time = time.time()
        Clock.schedule_once(self.wait_for_reconnection, 0.1)
    
    def wait_for_reconnection(self, dt):
        """Wait for reconnection for up to 10 seconds"""
        if time.time() - self.reconnect_start_time > 10.0:
            # Timeout reached
            self.signal_lost_popup.dismiss()
            self.show_restart_message()
            return
            
        if serial_port and serial_port.is_open:
            try:
                # Try to read a line to check connection
                line = serial_port.readline()
                if line:
                    # Got data - dismiss popup and continue
                    self.signal_lost_popup.dismiss()
                    self.signal_lost_popup = None
                    self.last_data_time = time.time()
                    self.start_signal_monitoring()
                    return
            
            except:
                pass
                
        # Schedule next check
        Clock.schedule_once(self.wait_for_reconnection, 0.1)
    
    def show_restart_message(self):
        """Show message asking user to restart"""
        content = BoxLayout(orientation='vertical', spacing=10)
        content.add_widget(Label(text='Could not reconnect to UWB device.\nPlease restart the application.'))
        
        close_button = Button(text='OK', size_hint=(1, 0.4))
        content.add_widget(close_button)
        
        popup = Popup(
            title='Connection Lost',
            content=content,
            size_hint=(0.8, 0.4)
        )
        
        close_button.bind(on_press=popup.dismiss)
        popup.open()
        
        # Disable navigation while showing this error
        self.prev_button.disabled = True
        self.next_button.disabled = True
        self.cancel_button.disabled = True

    def update_progress(self, current_x, current_y, goal_x, goal_y, path):
        """Update progress bar based on distance to current goal."""
        if not path:
            self.progress_bar.value = 0
            return
        
        # Calculate total path length in meters
        total_distance = 0
        for i in range(len(path)-1):
            x1, y1 = path[i][1] * grid_size, path[i][0] * grid_size
            x2, y2 = path[i+1][1] * grid_size, path[i+1][0] * grid_size
            total_distance += np.sqrt((x2-x1)**2 + (y2-y1)**2)
        
        # Calculate distance covered
        current_row = int(current_y / grid_size)
        current_col = int(current_x / grid_size)
        
        # Find closest point on path
        closest_dist = float('inf')
        closest_index = 0
        for i, (row, col) in enumerate(path):
            dist = (row - current_row)**2 + (col - current_col)**2
            if dist < closest_dist:
                closest_dist = dist
                closest_index = i
        
        # Calculate covered distance
        covered_distance = 0
        for i in range(closest_index):
            x1, y1 = path[i][1] * grid_size, path[i][0] * grid_size
            x2, y2 = path[i+1][1] * grid_size, path[i+1][0] * grid_size
            covered_distance += np.sqrt((x2-x1)**2 + (y2-y1)**2)
        
        # Update progress bar
        if total_distance > 0:
            progress = (covered_distance / total_distance) * 100
            self.progress_bar.value = min(100, max(0, progress))
    
    def update_current_item(self):
        if not hasattr(self, 'next_button'):
            return
            
        if self.current_item_index < len(self.shopping_list):
            item = self.shopping_list[self.current_item_index]
            self.current_item_label.text = f"Item {self.current_item_index+1}/{len(self.shopping_list)}: {item}"
            
            # Update button text for last item
            if self.current_item_index == len(self.shopping_list) - 1:
                self.next_button.text = "Reached Last Item"
            else:
                self.next_button.text = "Next Item"
                
            self.select_item(item)
        else:
            self.show_completion()
    
    def select_item(self, item_name):
        """Handle item selection and calculate the A* path."""
        global item_index
        item_index = items.index(item_name)
        goal_x, goal_y = item_locations[item_index]

        # Check if the goal is in an obstacle
        if not is_valid_point(goal_x, goal_y):
            valid_point = find_nearest_valid_point(goal_x, goal_y)
            if valid_point:
                goal_x, goal_y = valid_point
            else:
                print("No valid point found near the goal.")
                return

        # Set the goal in the plot widget
        self.plot_widget.set_goal((goal_x, goal_y))

        # Convert goal coordinates to grid indices
        goal_row = int(goal_y / grid_size)
        goal_col = int(goal_x / grid_size)

        # Get current position
        current_row = int(self.plot_widget.prev_point[1] / grid_size)
        current_col = int(self.plot_widget.prev_point[0] / grid_size)

        # Calculate the A* path
        path = a_star((current_row, current_col), (goal_row, goal_col), map_grid)
        if path:
            self.path = path
            self.plot_widget.set_path(path)
        else:
            print("No path found!")
    
    def prev_item(self, instance):
        if self.current_item_index > 0:
            self.current_item_index -= 1
            self.update_current_item()
    
    def next_item(self, instance):
        if self.current_item_index < len(self.shopping_list) - 1:
            self.current_item_index += 1
            self.update_current_item()
        else:
            # User reached the last item - show completion
            self.show_completion()

    def show_completion(self):
        """Show completion UI and change button state"""
        # Update the label
        self.current_item_label.text = "All items found!"
        
        # Change the next button to "End Shopping"
        self.next_button.text = "End Shopping"
        self.next_button.unbind(on_press=self.next_item)
        self.next_button.bind(on_press=self.end_shopping)
        
        # Show checkmark animation
        celebration_layout = BoxLayout(orientation='vertical', 
                                    size_hint=(None, None),
                                    size=(200, 200),
                                    pos_hint={'center_x': 0.5, 'center_y': 0.8})
        
        checkmark = Image(source='checkmark.png',
                        size_hint=(1, 0.7))
        
        success_label = Label(text="All Items Collected!",
                            font_size='24sp',
                            color=(0, 0.7, 0, 1))
        
        celebration_layout.add_widget(checkmark)
        celebration_layout.add_widget(success_label)
        self.add_widget(celebration_layout)
        
        # Remove animation after 3 seconds
        Clock.schedule_once(lambda dt: self.remove_widget(celebration_layout), 3)
        
    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            try:
                # Use in_waiting to check for available data first
                if serial_port.in_waiting > 0:
                    line = serial_port.readline()
                    try:
                        data = json.loads(line.decode().strip())
                        x, y = float(data["X"]), float(data["Y"])
                        self.last_data_time = time.time()  # Update last successful data time
                        
                        self.plot_widget.prev_point = [x, y]
                        
                        if self.current_item_index < len(self.shopping_list):
                            # if self.plot_widget.check_deviation(x, y):
                            item = self.shopping_list[self.current_item_index]
                            self.select_item(item)
                            
                            self.update_progress(x, y, *self.get_current_goal(), self.path)
                            
                        self.plot_widget.update_plot(x, y)
                        
                    except (json.JSONDecodeError, ValueError, KeyError, UnicodeDecodeError):
                        # Handle parsing errors but don't count as signal loss
                        pass
            
            except Exception as e:
                print(f"Serial error: {e}")
                self.handle_signal_loss()

    def on_enter(self):
        """Start signal monitoring when screen is entered"""
        self.start_signal_monitoring()
    
    def on_leave(self):
        """Stop signal monitoring when leaving screen"""
        self.stop_signal_monitoring()

    def get_current_goal(self):
        """Helper to get current goal coordinates"""
        if self.current_item_index < len(self.shopping_list):
            item_index = items.index(self.shopping_list[self.current_item_index])
            return item_locations[item_index]
        return (0, 0)
    
    def set_shopping_list(self, items):
        """Start tracking time when shopping begins"""
        self.shopping_list = items
        self.current_item_index = 0
        self.start_time = time.time()  # Record start time
        self.update_current_item()

    def end_shopping(self, instance):
        """Calculate time and go to summary screen"""
        if hasattr(self, 'start_time') and self.start_time:  # Check if time was tracked
            time_taken = time.time() - self.start_time
        else:
            time_taken = 0  # Fallback if timing wasn't started
        
        # Get reference to summary screen and pass data
        summary_screen = self.manager.get_screen('summary')
        summary_screen.show_summary(self.shopping_list, time_taken)
        
        # Navigate to summary screen
        self.manager.current = 'summary'  # This must match the name in ScreenManager
        
        # Reset shopping state without going home
        self.reset_shopping_state()

    def reset_shopping_state(self):
        """Reset all shopping-related UI"""
        self.next_button.text = "Next Item"
        self.next_button.unbind(on_press=self.end_shopping)
        self.next_button.bind(on_press=self.next_item)
        self.current_item_label.text = "No current item"
        self.plot_widget.clear_path()
    
    def cancel_plot(self, instance):
        close_serial_port()
        self.reset_shopping_state()
        self.manager.current = 'home'


class SummaryScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        layout = BoxLayout(orientation='vertical', padding=20, spacing=10)

        # Title
        self.title_label = Label(
            text="Here is Your Shopping Summary",
            font_size='24sp',
            size_hint=(1, 0.2)
        )
        layout.add_widget(self.title_label)

        # Time Taken
        self.time_label = Label(
            text="",
            font_size='18sp',
            size_hint=(1, 0.2)
        )
        layout.add_widget(self.time_label)

        # Items Purchased List
        self.items_label = Label(
            text="",
            font_size='16sp',
            size_hint=(1, 0.5),
            halign='left',
            valign='top'
        )
        layout.add_widget(self.items_label)

        # thanking
        self.thanking_label = Label(
            text="",
            font_size='16sp',
            size_hint=(1, 0.2),
            halign='left',
            valign='top'
        )
        layout.add_widget(self.thanking_label)

        # Return to Home Button
        self.home_button = Button(
            text="Return to Home",
            size_hint=(1, 0.1)
        )
        self.home_button.bind(on_press=self.return_home)
        layout.add_widget(self.home_button)

        self.add_widget(layout)

    def show_summary(self, shopping_list, time_taken):
        """Update summary with shopping data"""

        hours, minutes, seconds = convert_seconds(time_taken)

        self.time_label.text = f"Your Time with Us: {hours:.1f} hours, {minutes:.1f} minutes, {seconds:.1f} seconds"
        self.items_label.text = "You Found These Items:\n" + "\n".join(f"* {item}" for item in shopping_list)
        self.thanking_label.text = "Thank you for Using IndoorGuide. Have a Great Day!"

    def return_home(self, instance):
        """Go back to Home screen"""
        self.manager.current = 'home'

class ShoppingApp(App):
    def build(self):
        sm = ScreenManager()
        sm.add_widget(HomeScreen(name='home'))
        sm.add_widget(PlotScreen(name='plot'))
        sm.add_widget(SummaryScreen(name='summary'))  # Add summary screen
        return sm

if __name__ == '__main__':
    ShoppingApp().run()