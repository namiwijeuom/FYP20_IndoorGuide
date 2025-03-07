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
MAP_WIDTH_PIXELS = 817
MAP_HEIGHT_PIXELS = 787
MAP_WIDTH_METERS = 19.02
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
            Rectangle(
                texture=self.map_texture,
                pos=(self.offset_x, self.offset_y),
                size=(self.scaled_width, self.scaled_height)
            )
            Color(0, 0, 1, 1)
            if len(self.path_x) > 1:
                Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)
            Color(1, 0, 0, 1)
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
        layout = BoxLayout()
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        Clock.schedule_interval(self.update_plot, 0.05)
        return layout

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            try:
                line = serial_port.readline().decode().strip()
                if line:
                    try:
                        data = json.loads(line)
                        x, y = float(data["X"]), float(data["Y"])
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