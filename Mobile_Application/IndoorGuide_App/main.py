import json
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.clock import Clock
from kivy.garden.matplotlib.backend_kivyagg import FigureCanvasKivyAgg
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

# Plot Setup
fig, ax = plt.subplots()
ax.set_xlim(-1, 4)
ax.set_ylim(-1, 4)
ax.set_xticks([i * 0.5 for i in range(-2, 9)])
ax.set_yticks([i * 0.5 for i in range(-2, 9)])
ax.grid(True)

path_x, path_y = [], []
point, = ax.plot([], [], 'ro', markersize=8)  # Red dot for current location
path_line, = ax.plot([], [], 'b-', linewidth=2)  # Blue line for path

class SerialPlotApp(App):
    def build(self):
        layout = BoxLayout()
        self.canvas_widget = FigureCanvasKivyAgg(fig)
        layout.add_widget(self.canvas_widget)
        Clock.schedule_interval(self.update_plot, 0.05)
        return layout

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            line = serial_port.readline().decode()
            if line:
                try:
                    data = json.loads(line)
                    x, y = float(data["X"]), float(data["Y"])
                    path_x.append(x)
                    path_y.append(y)
                    point.set_data(x, y)
                    path_line.set_data(path_x, path_y)
                    self.canvas_widget.draw()
                except (json.JSONDecodeError, ValueError, KeyError):
                    pass

if __name__ == '__main__':
    SerialPlotApp().run()
