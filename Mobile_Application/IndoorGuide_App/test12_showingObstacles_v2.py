import json
import math
from collections import defaultdict
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.widget import Widget
from kivy.graphics import Line, Color, Ellipse, Rectangle
from kivy.clock import Clock
from kivy.uix.dropdown import DropDown
from kivy.uix.button import Button
from kivy.uix.label import Label
from usb4a import usb
from usbserial4a import serial4a
from kivy.core.window import Window

# Load the supermarket map image
MAP_IMAGE = 'top view.png'
MAP_WIDTH_PIXELS = 647
MAP_HEIGHT_PIXELS = 787
MAP_WIDTH_METERS = 15.34
MAP_HEIGHT_METERS = 18.34

# Initialize Serial Port
usb_device_list = usb.get_usb_device_list()
serial_port = None
if usb_device_list:
    try:
        serial_port = serial4a.get_serial_port(
            usb_device_list[0].getDeviceName(),
            115200, 8, 'N', 1
        )
        if serial_port:
            serial_port.open()
    except Exception as e:
        print(f"Error opening serial port: {e}")
else:
    print("No USB devices detected.")
    
# Load items from JSON file
with open('items_v3.json', 'r') as file:
    items_data = json.load(file)

items = items_data["items"]
item_locations = items_data["item_locations"]

# Obstacle Configuration (Rectangular areas - adjust coordinates to match your image)
OBSTACLES = [
    # Format: (x1, y1, x2, y2) in PIXEL coordinates
    (5, 210, 50, 680), #left corner
    (105, 270, 150, 680),  # obstacle 1
    (210, 270, 255, 680),  # obstacle 2
    (315, 270, 360, 680),  # obstacle 3
    (420, 270, 465, 680),  # obstacle 4
    (525, 270, 570, 680)  # obstacle 5
       
]

# Create environment matrix with obstacles
def create_environment():
    environment = [[0] * MAP_WIDTH_PIXELS for _ in range(MAP_HEIGHT_PIXELS)]
    
    # Mark obstacles
    for obstacle in OBSTACLES:
        x1, y1, x2, y2 = obstacle
        for x in range(x1, x2+1):
            for y in range(y1, y2+1):
                if 0 <= x < MAP_WIDTH_PIXELS and 0 <= y < MAP_HEIGHT_PIXELS:
                    environment[y][x] = 1  # Mark as blocked
    return environment

# A* Pathfinding Functions
def a_star_pathfinding(environment, start_node, goal_node):
    open_list = [start_node]
    came_from = {}
    g_score = defaultdict(lambda: float('inf'))
    f_score = defaultdict(lambda: float('inf'))

    g_score[tuple(start_node)] = 0
    f_score[tuple(start_node)] = heuristic(start_node, goal_node)

    while open_list:
        current = min(open_list, key=lambda node: f_score[tuple(node)])
        if current == goal_node:
            return reconstruct_path(came_from, current)

        open_list.remove(current)
        neighbors = get_neighbors(current, environment)

        for neighbor in neighbors:
            tentative_g_score = g_score[tuple(current)] + 1

            if tentative_g_score < g_score[tuple(neighbor)]:
                came_from[tuple(neighbor)] = current
                g_score[tuple(neighbor)] = tentative_g_score
                f_score[tuple(neighbor)] = tentative_g_score + heuristic(neighbor, goal_node)

                if neighbor not in open_list:
                    open_list.append(neighbor)

    return []

def heuristic(node, goal):
    return abs(node[0] - goal[0]) + abs(node[1] - goal[1])

def get_neighbors(node, environment):
    rows, cols = len(environment), len(environment[0])
    directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    neighbors = []

    for dx, dy in directions:
        r, c = node[0] + dx, node[1] + dy
        if 0 <= r < rows and 0 <= c < cols and environment[r][c] == 0:
            neighbors.append([r, c])

    return neighbors

def reconstruct_path(came_from, current):
    path_points = [current]
    while tuple(current) in came_from:
        current = came_from[tuple(current)]
        path_points.append(current)
    return list(reversed(path_points))

# Kivy App
class PlotWidget(Widget):
    def _init_(self, **kwargs):
        super()._init_(**kwargs)
        self.path_x = []
        self.path_y = []
        self.map_texture = Image(source=MAP_IMAGE).texture
        self.scaled_width = 0
        self.scaled_height = 0
        self.offset_x = 0
        self.offset_y = 0
        self.scale_x = 0
        self.scale_y = 0
        self.current_location = [0, 0]  # Track user's current location
        self.selected_item_location = None  # Track selected item location

    def update_plot(self, x, y):
        if not self.scale_x or not self.scale_y:
            return  # Scaling not initialized yet

        scaled_x = x * self.scale_x + self.offset_x
        scaled_y = y * self.scale_y + self.offset_y

        if 0 <= scaled_x <= self.width and 0 <= scaled_y <= self.height:
            self.path_x.append(scaled_x)
            self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            # Draw the map
            Rectangle(
                texture=self.map_texture,
                pos=(self.offset_x, self.offset_y),
                size=(self.scaled_width, self.scaled_height)
            )

            # Draw obstacles
            for obstacle in OBSTACLES:
                x1, y1, x2, y2 = obstacle
                # Scale obstacle coordinates to match the map
                scaled_x1 = x1 * (self.scaled_width / MAP_WIDTH_PIXELS) + self.offset_x
                scaled_y1 = y1 * (self.scaled_height / MAP_HEIGHT_PIXELS) + self.offset_y
                scaled_x2 = x2 * (self.scaled_width / MAP_WIDTH_PIXELS) + self.offset_x
                scaled_y2 = y2 * (self.scaled_height / MAP_HEIGHT_PIXELS) + self.offset_y
                # Draw the obstacle as a semi-transparent red rectangle
                Color(1, 0, 0, 0.5)  # Red with 50% opacity
                Rectangle(
                    pos=(scaled_x1, scaled_y1),
                    size=(scaled_x2 - scaled_x1, scaled_y2 - scaled_y1)
                )

            # Draw the path
            if self.selected_item_location:
                environment = create_environment()  # Use the obstacle configuration
                start_node = [int(round(self.current_location[0])), int(round(self.current_location[1]))]  # Round to integers
                goal_node = [int(round(self.selected_item_location[0])), int(round(self.selected_item_location[1]))]  # Round to integers
                path = a_star_pathfinding(environment, start_node, goal_node)
                if path:
                    Color(0, 0, 1, 1)  # Blue for path
                    Line(points=[(p[0] * self.scale_x + self.offset_x, p[1] * self.scale_y + self.offset_y) for p in path], width=2)

            # Draw the user's current location
            Color(1, 0, 0, 1)  # Red for current location
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))

    def on_size(self, *args):
        widget_ratio = self.width / self.height
        image_ratio = MAP_WIDTH_PIXELS / MAP_HEIGHT_PIXELS

        if widget_ratio > image_ratio:
            self.scaled_height = self.height
            self.scaled_width = self.scaled_height * image_ratio
        else:
            self.scaled_width = self.width
            self.scaled_height = self.scaled_width / image_ratio

        self.scale_x = self.scaled_width / MAP_WIDTH_METERS
        self.scale_y = self.scaled_height / MAP_HEIGHT_METERS

        self.offset_x = (self.width - self.scaled_width) / 2
        self.offset_y = (self.height - self.scaled_height) / 2

        self.path_x.clear()
        self.path_y.clear()
        self.update_plot(0, 0)

class SerialPlotApp(App):
    def build(self):
        layout = BoxLayout(orientation='vertical')
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)

        # Dropdown for item selection
        self.dropdown = DropDown()
        for item in items:
            btn = Button(text=item, size_hint_y=None, height=44)
            btn.bind(on_release=lambda btn: self.select_item(btn.text))
            self.dropdown.add_widget(btn)

        self.selected_item_label = Label(text="Selected Item: None", size_hint_y=None, height=44)
        layout.add_widget(self.selected_item_label)

        self.select_item_button = Button(text="Select Item", size_hint_y=None, height=44)
        self.select_item_button.bind(on_release=self.dropdown.open)
        layout.add_widget(self.select_item_button)

        Clock.schedule_interval(self.update_plot, 0.05)
        return layout

    def select_item(self, item):
        self.selected_item_label.text = f"Selected Item: {item}"
        self.dropdown.dismiss()

        # Set the selected item location
        self.plot_widget.selected_item_location = item_locations[items.index(item)]
        self.plot_widget.update_plot(self.plot_widget.current_location[0], self.plot_widget.current_location[1])

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            try:
                line = serial_port.readline().decode().strip()
                if line:
                    try:
                        data = json.loads(line)
                        x, y = float(data["X"]), float(data["Y"])
                        self.plot_widget.current_location = [x, y]  # Update current location
                        self.plot_widget.update_plot(x, y)
                    except json.JSONDecodeError:
                        print(f"Invalid JSON: {line}")
                    except KeyError:
                        print(f"Missing 'X' or 'Y' in data: {line}")
                    except ValueError:
                        print(f"Invalid float values in data: {line}")
            except Exception as e:
                print(f"Error reading from serial port: {e}")

    def on_stop(self):
        if serial_port and serial_port.is_open:
            serial_port.close()

if __name__ == '_main_':
    SerialPlotApp().run()