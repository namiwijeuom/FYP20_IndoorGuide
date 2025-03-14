import json
import csv
from collections import deque  # Use deque for efficient FIFO operations
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.widget import Widget
from kivy.graphics import Line, Color, Ellipse, Rectangle
from kivy.clock import Clock
from usb4a import usb
from usbserial4a import serial4a

# Load the supermarket map image
MAP_IMAGE = 'top view.png'
MAP_WIDTH_PIXELS = 647
MAP_HEIGHT_PIXELS = 787
MAP_WIDTH_METERS = 15.34
MAP_HEIGHT_METERS = 18.34

# Number of data points to store
DATA_POINTS_LIMIT = 400

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

        # For storing the last 400 data points
        self.data_points = deque(maxlen=DATA_POINTS_LIMIT)  # Keep only the last 400 data points

        # For CSV storage
        self.csv_file = open('data_log.csv', 'w', newline='')
        self.csv_writer = csv.writer(self.csv_file)
        self.csv_writer.writerow(['X', 'Y'])

        # Keep track of the image scaling
        self.scaled_width = 0
        self.scaled_height = 0
        self.offset_x = 0
        self.offset_y = 0
        self.scale = 0

        # Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))

        # Color(0, 0, 1, 1)  # Fixed Point
        # Ellipse(pos=(self.scale * 7, self.scale * 7), size=(10, 10))


    def update_plot(self, x, y):
        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        self.path_x.append(scaled_x)
        self.path_y.append(scaled_y)

        # Store the data point
        self.data_points.append((x, y))

        # Write data to CSV
        self.csv_writer.writerow([x, y])
        self.csv_file.flush()

        # Color(1, 0, 0, 1)  # Red Dot
        # Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))

        self.canvas.clear()
        with self.canvas:
            # Draw the background map while keeping aspect ratio
            Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))

            Color(0, 0, 1, 1)  # Fixed Position
            Ellipse(pos=(self.scale * 7, self.scale * 7), size=(10, 10))

            # Color(0, 0, 1, 1)  # Blue Path
            # if len(self.path_x) > 1:
            #     Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)

            Color(1, 0, 0, 1)  # Red Dot -  Current Position
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

    def on_close(self):
        # Close the CSV file when the application exits
        self.csv_file.close()


class SerialPlotApp(App):
    def build(self):
        layout = BoxLayout()
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        Clock.schedule_interval(self.update_plot, 0.05)
        return layout

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

    def on_stop(self):
        # Ensure the CSV file is closed when the app stops
        self.plot_widget.on_close()


if __name__ == '__main__':
    SerialPlotApp().run()