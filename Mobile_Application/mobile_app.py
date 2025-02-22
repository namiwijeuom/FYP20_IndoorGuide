import kivy
from kivy.app import App
from kivy.uix.label import Label
from kivy.uix.boxlayout import BoxLayout
from kivy.graphics import Ellipse, Color
from kivy.clock import Clock
import threading
import serial
import json

# Configure Serial Port
#SERIAL_PORT = "/dev/ttyUSB0"  # Change this for Windows (e.g., "COM3")
SERIAL_PORT = "COM10"  # Change this for Windows (e.g., "COM3")
BAUD_RATE = 115200

class SerialReader:
    """Handles reading from the serial port in a separate thread."""
    
    def __init__(self):
        self.ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        self.x = 0.0
        self.y = 0.0
        self.running = True

    def read_serial(self):
        """Continuously read serial data and update coordinates."""
        while self.running:
            try:
                line = self.ser.readline().decode('utf-8').strip()
                if line:
                    data = json.loads(line)  # Convert JSON string to dictionary
                    self.x = float(data["X"])
                    self.y = float(data["Y"])
            except Exception as e:
                print(f"Error reading serial: {e}")

    def start(self):
        """Start reading data in a new thread."""
        threading.Thread(target=self.read_serial, daemon=True).start()

    def stop(self):
        """Stop the serial reader."""
        self.running = False
        self.ser.close()


class SerialApp(App):
    """Main Kivy App to display serial data."""
    
    def build(self):
        self.serial_reader = SerialReader()
        self.serial_reader.start()

        self.layout = BoxLayout(orientation='vertical')

        self.label = Label(text="X: 0.00, Y: 0.00", font_size=24)
        self.layout.add_widget(self.label)

        # Canvas to draw the moving point
        with self.layout.canvas:
            Color(1, 0, 0, 1)  # Red color
            self.point = Ellipse(pos=(300, 300), size=(20, 20))

        # Schedule UI updates
        Clock.schedule_interval(self.update_ui, 0.1)

        return self.layout

    def update_ui(self, dt):
        """Update label and move the point."""
        x, y = self.serial_reader.x, self.serial_reader.y
        self.label.text = f"X: {x:.2f}, Y: {y:.2f}"
        self.point.pos = (300 + x * 10, 300 + y * 10)  # Adjust scaling

    def on_stop(self):
        """Stop serial thread when app closes."""
        self.serial_reader.stop()


if __name__ == "__main__":
    SerialApp().run()
