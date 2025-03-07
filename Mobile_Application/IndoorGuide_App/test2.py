import json
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.graphics import Line, Color, Ellipse
from kivy.uix.widget import Widget
from kivy.clock import Clock
from usb4a import usb
from usbserial4a import serial4a

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
        self.scale = 100  # Scaling factor for visualization
        self.offset_x = self.width // 2
        self.offset_y = self.height // 2

    def update_plot(self, x, y):
        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        self.path_x.append(scaled_x)
        self.path_y.append(scaled_y)

        self.canvas.clear()
        with self.canvas:
            Color(0, 0, 1, 1)  # Blue Path
            if len(self.path_x) > 1:
                Line(points=[coord for pair in zip(self.path_x, self.path_y) for coord in pair], width=2)

            Color(1, 0, 0, 1)  # Red Dot
            Ellipse(pos=(scaled_x - 5, scaled_y - 5), size=(10, 10))

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

if __name__ == '__main__':
    SerialPlotApp().run()
