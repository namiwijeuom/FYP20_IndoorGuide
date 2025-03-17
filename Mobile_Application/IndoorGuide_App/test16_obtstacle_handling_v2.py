import json
import numpy as np
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

# Load the supermarket map image
MAP_IMAGE = 'top view2.png'
MAP_WIDTH_PIXELS = 675
MAP_HEIGHT_PIXELS = 782
MAP_WIDTH_METERS = 16.04
MAP_HEIGHT_METERS = 18.34

grid_size = 0.5  # 0.5m grids
num_of_rows = int(np.ceil(MAP_HEIGHT_METERS / grid_size) + 1)
num_of_cols = int(np.ceil(MAP_WIDTH_METERS / grid_size) + 1)

map_grid = np.zeros((num_of_rows, num_of_cols))  # 1 for obstacles. 0 for walkable paths.

# --------------- Creating binary map with obstacles -------------------
map_grid[:9, 6:27] = 1
map_grid[:2, 29:] = 1
map_grid[:, 31:] = 1
map_grid[10:33, 1:5] = 1
map_grid[13:33, 6:10] = 1
map_grid[13:33, 11:15] = 1
map_grid[13:33, 16:20] = 1
map_grid[13:33, 21:25] = 1
map_grid[13:33, 25:29] = 1
map_grid[34:, :] = 1
# ----------------------------------------------------------------------

def is_valid_point(x, y):
    row = int(y / grid_size)
    col = int(x / grid_size)

    if (row + 1) <= num_of_rows and (col + 1) <= num_of_cols:
        if map_grid[row, col] != 1:
            return True
    return False

# Load item locations from JSON file
with open('items_v3.json', 'r') as file:
    item_data = json.load(file)
    items = item_data['items']
    item_locations = item_data['item_locations']

# Initialize Serial Port
serial_port = None

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

class HomeScreen(Screen):
    def _init_(self, **kwargs):
        super()._init_(**kwargs)
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
    def _init_(self, **kwargs):
        super()._init_(**kwargs)
        self.path_x = []
        self.path_y = []
        self.map_texture = Image(source=MAP_IMAGE).texture

        # Keep track of the image scaling
        self.scaled_width = 0
        self.scaled_height = 0
        self.offset_x = 0
        self.offset_y = 0

        self.scale = 0

        self.prev_point = [0, 0]

    def update_plot(self, x, y):
        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        square_center_x_m = round(x * 2) / 2
        square_center_y_m = round(y * 2) / 2

        square_bottom_left_x_m = square_center_x_m - grid_size
        square_bottom_left_y_m = square_center_y_m - grid_size

        if not is_valid_point(square_center_x_m, square_center_y_m):
            square_center_x_m = self.prev_point[0]
            square_center_y_m = self.prev_point[1]

            step = grid_size
            i = 0
            while not is_valid_point(square_center_x_m, square_center_y_m):
                if i % 4 == 0:
                    square_center_x_m -= step
                elif i % 4 == 1:
                    square_center_x_m += step
                    square_center_y_m += step
                elif i % 4 == 2:
                    square_center_y_m -= step
                    square_center_x_m += step
                else:
                    square_center_x_m -= step
                    square_center_y_m -= step
                    step *= 2
                i += 1

        self.prev_point[0] = square_center_x_m
        self.prev_point[1] = square_center_y_m

        square_bottom_left_x = square_bottom_left_x_m * self.scale + self.offset_x
        square_bottom_left_y = square_bottom_left_y_m * self.scale + self.offset_y

        square_width = 1 * self.scale

        self.path_x.append(scaled_x)
        self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            # Draw the background map while keeping aspect ratio
            Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))

            # Draw obstacles as an overlay
            self.draw_obstacles()

            # Draw item locations
            self.draw_item_locations()

            Color(0, 0, 1, 1)  # Blue Path
            if len(self.path_x) > 1:
                Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))
            Line(rectangle=(square_bottom_left_x, square_bottom_left_y, square_width, square_width), width=2)

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

        self.scale = (self.scaled_width / MAP_WIDTH_METERS + self.scaled_height / MAP_HEIGHT_METERS) / 2

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
            self.draw_obstacles()  # Redraw obstacles when clearing the path
            self.draw_item_locations()  # Redraw item locations when clearing the path

class PlotScreen(Screen):
    def _init_(self, **kwargs):
        super()._init_(**kwargs)
        layout = BoxLayout(orientation='vertical')

        # Plot Widget
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)

        # Cancel Button
        self.cancel_button = Button(text='Cancel', size_hint=(1, 0.1))
        self.cancel_button.bind(on_press=self.cancel_plot)
        layout.add_widget(self.cancel_button)

        self.add_widget(layout)
        Clock.schedule_interval(self.update_plot, 0.05)

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            line = serial_port.readline().decode()
            if line:
                try:
                    data = json.loads(line)
                    x, y = float(data["X"]), float(data["Y"])
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

if __name__ == '_main_':
    ShoppingApp().run()