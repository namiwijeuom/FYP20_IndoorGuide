import kivy
from kivy.app import App
from kivy.uix.image import Image
from kivy.uix.floatlayout import FloatLayout
from kivy.graphics import Ellipse, Color
from kivy.clock import Clock
import serial
import json
import threading

# Serial Port Configuration (Change for your system)
SERIAL_PORT = "COM10"  # Example for Linux/macOS, for Windows use "COM3"
BAUD_RATE = 115200

# Real-world dimensions of the seminar room (12m x 12m)
ROOM_SIZE_M = 12.0

class SerialReader:
    """ Reads serial data and updates coordinates """
    def __init__(self):
        self.ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        self.x = 0.0
        self.y = 0.0
        self.running = True

    def read_serial(self):
        while self.running:
            try:
                line = self.ser.readline().decode('utf-8').strip()
                if line:
                    data = json.loads(line)  # Read JSON
                    self.x = float(data["X"])
                    self.y = float(data["Y"])
            except Exception as e:
                print(f"Error reading serial: {e}")

    def start(self):
        threading.Thread(target=self.read_serial, daemon=True).start()

    def stop(self):
        self.running = False
        self.ser.close()

class MapApp(App):
    """ Kivy App that displays real-time coordinates on a map """

    def build(self):
        self.serial_reader = SerialReader()
        self.serial_reader.start()

        self.layout = FloatLayout()

        # Load the background map image
        self.map = Image(source="C:/Users/Namina Wijetunga/Desktop/IndoorGuide/FYP20_IndoorGuide/Mobile_Application/PG_Seminar_Room_Map.png", allow_stretch=True, keep_ratio=False)
        self.layout.add_widget(self.map)

        # Add red dot to represent current position
        with self.layout.canvas:
            Color(1, 0, 0, 1)  # Red color
            self.point = Ellipse(size=(20, 20))

        # Schedule UI updates
        Clock.schedule_interval(self.update_ui, 0.1)

        return self.layout

    def update_ui(self, dt):
        """ Update the position of the point based on serial data """
        x, y = self.serial_reader.x, self.serial_reader.y

        # Convert real-world (0-12m) to image pixel coordinates
        pixel_x = (x / ROOM_SIZE_M) * self.map.width  # X remains the same
        pixel_y = (y / ROOM_SIZE_M) * self.map.height  # Y is now bottom-up

        self.point.pos = (pixel_x - 10, pixel_y - 10)  # Centering the dot

    def on_stop(self):
        """ Stop serial reading when the app closes """
        self.serial_reader.stop()

# Run the app
if __name__ == "__main__":
    MapApp().run()
