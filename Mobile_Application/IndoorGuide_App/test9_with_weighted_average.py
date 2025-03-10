import json
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.widget import Widget
from kivy.graphics import Line, Color, Ellipse, Rectangle
from kivy.clock import Clock
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
    serial_port = serial4a.get_serial_port(
        usb_device_list[0].getDeviceName(),
        115200, 8, 'N', 1
    )
else:
    print("No USB devices detected.")


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

    def update_plot(self, x, y):
        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        self.path_x.append(scaled_x)
        self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            # Draw the background map while keeping aspect ratio
            Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))

            Color(0, 0, 1, 1)  # Blue Path
            if len(self.path_x) > 1:
                Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))

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


class SerialPlotApp(App):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.coordinate_buffer = []  # Store the last 5 coordinates
        self.weights = [1, 2, 3, 4, 5]  # Weights for the last 5 coordinates

    def build(self):
        layout = BoxLayout()
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        Clock.schedule_interval(self.update_plot, 0.05)
        return layout

    def calculate_weighted_average(self):
        """Calculate the weighted average of the last 5 coordinates."""
        if len(self.coordinate_buffer) == 0:
            return None

        # Ensure the buffer has exactly 5 coordinates
        while len(self.coordinate_buffer) < 5:
            self.coordinate_buffer.append((0, 0))  # Pad with zeros if necessary

        # Calculate the weighted average of X and Y coordinates
        total_weight = sum(self.weights)
        weighted_x = sum(coord[0] * weight for coord, weight in zip(self.coordinate_buffer, self.weights)) / total_weight
        weighted_y = sum(coord[1] * weight for coord, weight in zip(self.coordinate_buffer, self.weights)) / total_weight
        return weighted_x, weighted_y

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            line = serial_port.readline().decode()
            if line:
                try:
                    data = json.loads(line)
                    x, y = float(data["X"]), float(data["Y"])

                    # Add the new coordinate to the buffer
                    self.coordinate_buffer.append((x, y))

                    # Keep only the last 5 coordinates
                    if len(self.coordinate_buffer) > 5:
                        self.coordinate_buffer.pop(0)

                    # Calculate the weighted average
                    weighted_coord = self.calculate_weighted_average()
                    if weighted_coord:
                        weighted_x, weighted_y = weighted_coord
                        self.plot_widget.update_plot(weighted_x, weighted_y)
                except (json.JSONDecodeError, ValueError, KeyError):
                    pass


if __name__ == '__main__':
    SerialPlotApp().run()