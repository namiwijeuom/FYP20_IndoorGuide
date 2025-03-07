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
MAP_WIDTH_PIXELS = 816
MAP_WIDTH_METERS = 19.02
SCALE = MAP_WIDTH_PIXELS / MAP_WIDTH_METERS  # Pixels per meter

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
        
        # Get image original dimensions
        self.img_width = MAP_WIDTH_PIXELS
        self.img_height = int(self.map_texture.height * (MAP_WIDTH_PIXELS / self.map_texture.width))  # Preserve aspect ratio

    def update_plot(self, x, y):
        scaled_x = x * SCALE
        scaled_y = y * SCALE

        self.path_x.append(scaled_x)
        self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            # Draw the background map while keeping aspect ratio
            Rectangle(texture=self.map_texture, pos=(200,200), size=self.size)

            Color(0, 0, 1, 1)  # Blue Path
            if len(self.path_x) > 1:
                Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))

    def on_size(self, *args):
        self.update_plot(0, 0)  # Redraw the plot when the widget size changes

class SerialPlotApp(App):
    def build(self):
        #Window.size = (1080,720)  # Set default landscape size (modify as needed)
        Window.orientation = 'landscape'  # Force landscape mode
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

if __name__ == '__main__':
    SerialPlotApp().run()