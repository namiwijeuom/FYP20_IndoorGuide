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
MAP_WIDTH_PIXELS  = 647
MAP_HEIGHT_PIXELS = 787
MAP_WIDTH_METERS  = 15.34
MAP_HEIGHT_METERS = 18.34

# Load items from JSON file
with open('items.json', 'r') as file:
    items_data = json.load(file)

items = items_data["items"]
item_locations = items_data["item_locations"]

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

# A* Pathfinding Functions
def a_star_pathfinding(environment, start_node, goal_node, item_locations_for_a_star):
    print(f"Start Node for A*: {start_node}")
    print(f"Goal Node for A*: {goal_node}")

    open_list = [start_node]
    came_from = {}
    g_score = defaultdict(lambda: float('inf'))
    f_score = defaultdict(lambda: float('inf'))

    g_score[tuple(start_node)] = 0
    f_score[tuple(start_node)] = heuristic(start_node, goal_node)

    while open_list:
        current = min(open_list, key=lambda node: f_score[tuple(node)])
        if current == goal_node:
            path_points = reconstruct_path(came_from, current)
            if path_points:
                find_nearby_items(path_points, item_locations_for_a_star)
            return path_points

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

    print("No path found!")
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

def find_nearby_items(path, item_locations):
    discounted_items = {'MilkPowder', 'Rice', 'Snacks', 'Chocolates', 'Grains', 'Bread'}
    discount_rates = {'MilkPowder': 10, 'Rice': 15, 'Snacks': 5, 'Chocolates': 20, 'Grains': 12, 'Bread': 8}
    proximity_threshold = 2.0

    nearby_items = set()
    discounted_nearby_items = {}

    for i, item_location in enumerate(item_locations):
        for path_point in path:
            if math.hypot(item_location[0] - path_point[0], item_location[1] - path_point[1]) <= proximity_threshold:
                nearby_items.add(items[i])
                if items[i] in discounted_items:
                    discounted_nearby_items[items[i]] = discount_rates[items[i]]
                break

    if nearby_items:
        print("Nearby items along the path:", ", ".join(nearby_items))
    else:
        print("No nearby items found along the path.")

    if discounted_nearby_items:
        print("Discounted items nearby:", ", ".join([f"{item} ({rate}% off)" for item, rate in discounted_nearby_items.items()]))
    else:
        print("No nearby items have discounts.")

# Kivy App
class PlotWidget(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
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

            # Draw the path
            if self.selected_item_location:
                environment = [[0] * MAP_WIDTH_PIXELS for _ in range(MAP_HEIGHT_PIXELS)]  # Example environment
                start_node = [int(round(self.current_location[0])), int(round(self.current_location[1]))]  # Round to integers
                goal_node = [int(round(self.selected_item_location[0])), int(round(self.selected_item_location[1]))]  # Round to integers
                path = a_star_pathfinding(environment, start_node, goal_node, item_locations)
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

if __name__ == '__main__':
    SerialPlotApp().run()