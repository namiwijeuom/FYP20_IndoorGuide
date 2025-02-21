import kivy
from kivy.app import App
from kivy.uix.image import Image
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.label import Label
from kivy.graphics import Ellipse, Color
from kivy.clock import Clock
import json
import serial
import threading
import heapq  # For A* pathfinding
import numpy as np
from scipy.spatial.distance import cdist
import random

# Serial Configuration (Change for BLE or USB)
SERIAL_PORT = "COM10"  
BAUD_RATE = 115200
ROOM_SIZE_M = 12.0

# Define items and their locations
items = ['Vegetables', 'Fruits', 'Meat', 'Grains', 'Juices', 'Snacks', 'Fish', 'Bread', 'MilkPowder', 'Rice',
         'Nuts', 'Spices', 'IceCream', 'Chocolates', 'Oil', 'Soda']

item_locations = np.array([
    [10, 9], [2, 8], [3, 5], [6, 7], [10, 1], [5, 10], [0, 5], [8, 8],
    [11, 3], [1, 11], [1, 2], [3, 11], [6, 3], [9, 5], [4, 1], [11, 7]
])


class SerialReader:
    """Reads serial data and updates coordinates"""

    def __init__(self):
        self.ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=1)
        self.x, self.y = 0.0, 0.0
        self.running = True

    def read_serial(self):
        while self.running:
            try:
                line = self.ser.readline().decode('utf-8').strip()
                if line:
                    data = json.loads(line)
                    self.x, self.y = float(data["X"]), float(data["Y"])
            except Exception as e:
                print(f"Error reading serial: {e}")

    def start(self):
        threading.Thread(target=self.read_serial, daemon=True).start()

    def stop(self):
        self.running = False
        self.ser.close()


def a_star(start, goal):
    """A* Pathfinding Algorithm"""
    open_list = []
    heapq.heappush(open_list, (0, start))
    came_from = {}
    g_score = {start: 0}
    f_score = {start: np.linalg.norm(np.array(start) - np.array(goal))}

    while open_list:
        _, current = heapq.heappop(open_list)

        if current == goal:
            path = [current]
            while current in came_from:
                current = came_from[current]
                path.append(current)
            return path[::-1]

        for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:  # 4 directions
            neighbor = (current[0] + dx, current[1] + dy)

            tentative_g = g_score[current] + 1
            if neighbor not in g_score or tentative_g < g_score[neighbor]:
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + np.linalg.norm(np.array(neighbor) - np.array(goal))
                heapq.heappush(open_list, (f_score[neighbor], neighbor))

    return []


def find_nearby_items(current_path, item_locations, threshold=2.0):
    """Find nearby items along a planned path"""
    nearby_items = []
    for item, loc in zip(items, item_locations):
        if np.any(cdist([loc], current_path) <= threshold):
            nearby_items.append(item)
    return nearby_items


class MapApp(App):
    """Kivy App for displaying the environment"""

    def build(self):
        self.serial_reader = SerialReader()
        self.serial_reader.start()
        self.layout = FloatLayout()

        # Load Map
        self.map = Image(source="/mnt/data/PG_Seminar_Room_Map.png", allow_stretch=True, keep_ratio=False)
        self.layout.add_widget(self.map)

        # Labels
        self.coord_label = Label(text="X: 0.00, Y: 0.00", font_size=20, pos_hint={"x": 0.05, "y": 0.85})
        self.nearby_label = Label(text="Nearby Items: None", font_size=16, pos_hint={"x": 0.05, "y": 0.75})
        self.discount_label = Label(text="Discounts: None", font_size=16, pos_hint={"x": 0.05, "y": 0.65})
        self.layout.add_widget(self.coord_label)
        self.layout.add_widget(self.nearby_label)
        self.layout.add_widget(self.discount_label)

        # Moving Point
        with self.layout.canvas:
            Color(1, 0, 0, 1)  # Red dot
            self.point = Ellipse(size=(20, 20))

        Clock.schedule_interval(self.update_ui, 0.1)
        return self.layout

    def update_ui(self, dt):
        """Update UI with position, nearby items, and discounts"""
        x, y = self.serial_reader.x, self.serial_reader.y
        pixel_x, pixel_y = (x / ROOM_SIZE_M) * self.map.width, (y / ROOM_SIZE_M) * self.map.height
        self.point.pos = (pixel_x - 10, pixel_y - 10)
        self.coord_label.text = f"X: {x:.2f}, Y: {y:.2f}"

        # Path Planning
        start = (int(x), int(y))
        goal = (random.choice(item_locations))  # Select a random goal for testing
        path = a_star(start, tuple(goal))

        # Find Nearby Items
        nearby_items = find_nearby_items(path, item_locations)
        self.nearby_label.text = f"Nearby Items: {', '.join(nearby_items)}" if nearby_items else "Nearby Items: None"

    def on_stop(self):
        self.serial_reader.stop()


if __name__ == "__main__":
    MapApp().run()
