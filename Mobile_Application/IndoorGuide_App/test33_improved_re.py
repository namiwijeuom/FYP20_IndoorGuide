import json
import numpy as np
import heapq
import time
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.image import Image
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.uix.widget import Widget
from kivy.uix.screenmanager import ScreenManager, Screen, FadeTransition
from kivy.graphics import Line, Color, Ellipse, Rectangle, RoundedRectangle
from kivy.clock import Clock
from usb4a import usb
from usbserial4a import serial4a
from kivy.uix.popup import Popup
from kivy.uix.dropdown import DropDown
from kivy.uix.progressbar import ProgressBar
from kivy.network.urlrequest import UrlRequest
from kivy.properties import NumericProperty
from kivy.metrics import dp

# Color palette
PRIMARY_COLOR = (0.2, 0.4, 0.8, 1)  # Soft blue
ACCENT_COLOR = (0.9, 0.3, 0.3, 1)  # Coral red
BACKGROUND_COLOR = (0.95, 0.95, 0.95, 1)  # Light gray
TEXT_COLOR = (0.1, 0.1, 0.1, 1)  # Dark gray
PROGRESS_BG_COLOR = (0.8, 0.8, 0.8, 1)  # Progress bar background

# Load the supermarket map image
MAP_IMAGE = 'top view2.png'
MAP_WIDTH_PIXELS = 675
MAP_HEIGHT_PIXELS = 782
MAP_WIDTH_METERS = 16.04
MAP_HEIGHT_METERS = 18.34

grid_size = 0.5
num_of_rows = int(np.ceil(MAP_HEIGHT_METERS/grid_size) + 1)
num_of_cols = int(np.ceil(MAP_WIDTH_METERS/grid_size) + 1)

map_grid = np.zeros((num_of_rows, num_of_cols))

# Creating binary map with obstacles
map_grid[:9,6:27] = 1
map_grid[:2,29:] = 1
map_grid[:,31:] = 1
map_grid[10:33,1:5] = 1
map_grid[13:33,6:10] = 1
map_grid[13:33,11:15] = 1
map_grid[13:33,16:20] = 1
map_grid[13:33,21:25] = 1
map_grid[13:33,26:30] = 1
map_grid[34:,:] = 1

valid_points = set()
for row in range(num_of_rows):
    for col in range(num_of_cols):
        if map_grid[row, col] == 0:
            valid_points.add((row, col))

serial_port = None

def is_valid_point(x, y):
    row = int(y / grid_size)
    col = int(x / grid_size)
    if (row+1) <= num_of_rows and (col+1) <= num_of_cols:
        if map_grid[row, col] != 1:
            return True
    return False

# Load item locations from JSON file
with open('items_v3_with_disounts.json', 'r') as file:
    item_data = json.load(file)
    items = item_data['items']
    item_locations = item_data['item_locations']
    item_discounts = item_data.get('item_discounts', {})

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

def heuristic(a, b):
    dx = abs(a[0] - b[0])
    dy = abs(a[1] - b[1])
    return 1.4 * min(dx, dy) + abs(dx - dy)

def convert_seconds(seconds):
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    remaining_seconds = seconds % 60
    return hours, minutes, remaining_seconds

def a_star(start, goal, grid, cache=None):
    if cache and (start, goal) in cache:
        return cache[(start, goal)]
    neighbors = [(0, 1), (1, 0), (0, -1), (-1, 0), 
                 (1, 1), (-1, 1), (1, -1), (-1, -1)]
    close_set = set()
    came_from = {}
    gscore = {start: 0}
    fscore = {start: heuristic(start, goal)}
    open_heap = []
    heapq.heappush(open_heap, (fscore[start], start))
    rows, cols = grid.shape
    
    while open_heap:
        current = heapq.heappop(open_heap)[1]
        if current == goal:
            path = []
            while current in came_from:
                path.append(current)
                current = came_from[current]
            path = path[::-1]
            if cache is not None:
                cache[(start, goal)] = path
            return path
        close_set.add(current)
        for i, j in neighbors:
            neighbor = (current[0] + i, current[1] + j)
            if not (0 <= neighbor[0] < rows and 0 <= neighbor[1] < cols):
                continue
            if grid[neighbor[0], neighbor[1]] == 1:
                continue
            tentative_g_score = gscore[current] + (1.4 if i and j else 1)
            if neighbor in close_set and tentative_g_score >= gscore.get(neighbor, float('inf')):
                continue
            if tentative_g_score < gscore.get(neighbor, float('inf')):
                came_from[neighbor] = current
                gscore[neighbor] = tentative_g_score
                fscore[neighbor] = tentative_g_score + heuristic(neighbor, goal)
                heapq.heappush(open_heap, (fscore[neighbor], neighbor))
    return None

def find_nearest_valid_point(x, y):
    row = int(y / grid_size)
    col = int(x / grid_size)
    for radius in range(1, max(num_of_rows, num_of_cols)):
        for i in range(-radius, radius + 1):
            for j in range(-radius, radius + 1):
                new_row = row + i
                new_col = col + j
                if 0 <= new_row < num_of_rows and 0 <= new_col < num_of_cols:
                    if map_grid[new_row, new_col] == 0:
                        return (new_col * grid_size, new_row * grid_size)
    return None

class HomeScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.recommendation_popup = None
        self.selected_items = []
        self.recommendation_cache = {}  # Cache for recommendations
        layout = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        
        # Set background
        with layout.canvas.before:
            Color(*BACKGROUND_COLOR)
            self.bg_rect = Rectangle(pos=layout.pos, size=layout.size)
        layout.bind(pos=self.update_bg_rect, size=self.update_bg_rect)
        
        self.logo = Image(source='logo.png', size_hint=(1, 0.3))
        layout.add_widget(self.logo)
        
        self.selection_label = Label(text='Select Your Items:', font_size='20sp', color=TEXT_COLOR, size_hint=(1, 0.1))
        layout.add_widget(self.selection_label)
        
        self.selected_items_label = Label(text='No items selected', font_size='16sp', color=TEXT_COLOR, size_hint=(1, 0.1))
        layout.add_widget(self.selected_items_label)
        
        self.recommend_button = Button(text='Get Recommendations', size_hint=(1, 0.1), background_color=PRIMARY_COLOR, background_normal='')
        self.recommend_button.bind(on_press=self.show_recommendations)
        layout.add_widget(self.recommend_button)
        
        self.dropdown = DropDown()
        for item in items:
            btn = Button(text=item, size_hint_y=None, height=dp(44), background_color=BACKGROUND_COLOR, color=TEXT_COLOR)
            btn.bind(on_release=lambda btn: self.select_item(btn.text))
            self.dropdown.add_widget(btn)
        
        self.item_button = Button(text='Add Item', size_hint=(1, 0.1), background_color=PRIMARY_COLOR, background_normal='')
        self.item_button.bind(on_release=self.dropdown.open)
        layout.add_widget(self.item_button)
        
        self.clear_button = Button(text='Clear Selection', size_hint=(1, 0.1), background_color=ACCENT_COLOR, background_normal='')
        self.clear_button.bind(on_press=self.clear_selection)
        layout.add_widget(self.clear_button)
        
        self.start_button = Button(text='Start Shopping', size_hint=(1, 0.15), background_color=PRIMARY_COLOR, background_normal='', font_size='18sp')
        self.start_button.bind(on_press=self.start_shopping)
        layout.add_widget(self.start_button)
        
        self.add_widget(layout)

    def update_bg_rect(self, instance, value):
        self.bg_rect.pos = instance.pos
        self.bg_rect.size = instance.size

    def show_recommendations(self, instance):
        if not self.selected_items:
            popup = Popup(
                title='Warning',
                content=Label(text='Please select at least one item first!', color=TEXT_COLOR),
                size_hint=(0.8, 0.4),
                background_color=BACKGROUND_COLOR
            )
            popup.open()
            return

        # Create a cache key from sorted selected items to ensure consistency
        cache_key = tuple(sorted(self.selected_items))
        if cache_key in self.recommendation_cache:
            self.display_recommendations(self.recommendation_cache[cache_key])
            return

        # Show loading popup
        content = BoxLayout(orientation='vertical', spacing=dp(10))
        content.add_widget(Label(text='Fetching recommendations...', color=TEXT_COLOR))
        self.recommendation_popup = Popup(
            title='Loading',
            content=content,
            size_hint=(0.6, 0.3),
            background_color=BACKGROUND_COLOR,
            auto_dismiss=False
        )
        self.recommendation_popup.open()

        # Make asynchronous request
        headers = {'Content-Type': 'application/json'}
        payload = json.dumps({'items': self.selected_items})
        UrlRequest(
            url='http://192.168.1.5:5000/recommend',
            req_body=payload,
            req_headers=headers,
            on_success=self.on_request_success,
            on_failure=self.on_request_failure,
            on_error=self.on_request_error,
            timeout=5.0,  # 5-second timeout
            method='POST'
        )

    def on_request_success(self, request, result):
        self.recommendation_popup.dismiss()
        recommendations = result.get('recommendations', [])
        if not recommendations:
            self.show_error_popup('No recommendations returned from server.')
            return

        # Cache the recommendations
        cache_key = tuple(sorted(self.selected_items))
        self.recommendation_cache[cache_key] = recommendations

        self.display_recommendations(recommendations)

    def on_request_failure(self, request, result):
        self.recommendation_popup.dismiss()
        self.show_error_popup('Failed to get recommendations. Server returned an error.')

    def on_request_error(self, request, error):
        self.recommendation_popup.dismiss()
        self.show_error_popup('Network error. Please check your connection and try again.')

    def show_error_popup(self, message):
        popup = Popup(
            title='Error',
            content=Label(text=message, color=TEXT_COLOR),
            size_hint=(0.8, 0.4),
            background_color=BACKGROUND_COLOR
        )
        popup.open()

    def display_recommendations(self, recommendations):
        content = BoxLayout(orientation='vertical', spacing=dp(10), padding=dp(10))
        content.add_widget(Label(text='Recommended Items:', color=TEXT_COLOR, font_size='16sp'))
        
        for item in recommendations[:5]:  # Limit to 5 recommendations
            btn = Button(
                text=item,
                size_hint_y=None,
                height=dp(44),
                background_color=PRIMARY_COLOR,
                background_normal='',
                color=(1, 1, 1, 1)
            )
            btn.bind(on_press=lambda btn, item=item: self.add_recommendation(item))
            content.add_widget(btn)
        
        close_button = Button(
            text='Close',
            size_hint_y=None,
            height=dp(44),
            background_color=ACCENT_COLOR,
            background_normal=''
        )
        content.add_widget(close_button)
        
        self.recommendation_popup = Popup(
            title='Recommendations',
            content=content,
            size_hint=(0.8, 0.6),
            background_color=BACKGROUND_COLOR
        )
        close_button.bind(on_press=self.recommendation_popup.dismiss)
        self.recommendation_popup.open()

    def add_recommendation(self, item):
        if len(self.selected_items) >= 5:
            popup = Popup(
                title='Warning',
                content=Label(text='You can select up to 5 items only!', color=TEXT_COLOR),
                size_hint=(0.8, 0.4),
                background_color=BACKGROUND_COLOR
            )
            popup.open()
            return
        if item not in self.selected_items:
            self.selected_items.append(item)
            self.update_selection_label()
        if self.recommendation_popup:
            self.recommendation_popup.dismiss()

    def select_item(self, item_name):
        if item_name in self.selected_items:
            return
        if len(self.selected_items) >= 5:
            popup = Popup(
                title='Warning',
                content=Label(text='You can select up to 5 items only!', color=TEXT_COLOR),
                size_hint=(0.8, 0.4),
                background_color=BACKGROUND_COLOR
            )
            popup.open()
            return
        self.selected_items.append(item_name)
        self.update_selection_label()

    def clear_selection(self, instance):
        self.selected_items = []
        self.update_selection_label()

    def update_selection_label(self):
        if not self.selected_items:
            self.selected_items_label.text = 'No items selected'
        else:
            self.selected_items_label.text = 'Selected: ' + ', '.join(self.selected_items)

    def start_shopping(self, instance):
        if not self.selected_items:
            popup = Popup(
                title='Warning',
                content=Label(text='Please select at least one item!', color=TEXT_COLOR),
                size_hint=(0.8, 0.4),
                background_color=BACKGROUND_COLOR
            )
            popup.open()
            return
        if open_serial_port():
            plot_screen = self.manager.get_screen('plot')
            plot_screen.set_shopping_list(self.selected_items)
            self.manager.current = 'plot'
        else:
            popup = Popup(
                title='Error',
                content=Label(text='No serial device found!', color=TEXT_COLOR),
                size_hint=(0.8, 0.4),
                background_color=BACKGROUND_COLOR
            )
            popup.open()

class PlotWidget(Widget):
    last_x = NumericProperty(0)
    last_y = NumericProperty(0)
    needs_redraw = NumericProperty(0)

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.path_x = []
        self.path_y = []
        self.map_texture = Image(source=MAP_IMAGE).texture
        self.scaled_width = 0
        self.scaled_height = 0
        self.offset_x = 0
        self.offset_y = 0
        self.scale = 0
        self.prev_point = [0,0]
        self.path = []
        self.goal = None
        self.last_reroute_time = 0
        self.reroute_cooldown = 2.0
        self.last_valid_position = (0, 0)
        self.nearby_discount_labels = []
        self.path_cache = {}
        self.discount_grid = self.precompute_discount_grid()

    def precompute_discount_grid(self):
        discount_grid = {}
        for row in range(num_of_rows):
            for col in range(num_of_cols):
                if map_grid[row, col] == 1:
                    continue
                cell_x = col * grid_size
                cell_y = row * grid_size
                nearby = []
                for i, (item_x, item_y) in enumerate(item_locations):
                    if i >= len(items):
                        break
                    distance = np.sqrt((cell_x - item_x)**2 + (cell_y - item_y)**2)
                    if distance <= 3.0 and items[i] in item_discounts and item_discounts[items[i]] > 0:
                        nearby.append((items[i], item_discounts[items[i]], item_x, item_y))
                if nearby:
                    discount_grid[(row, col)] = nearby
        return discount_grid

    def update_plot(self, x, y):
        if abs(x - self.last_x) < 0.1 and abs(y - self.last_y) < 0.1 and not self.needs_redraw:
            return
        self.last_x = x
        self.last_y = y
        self.needs_redraw = 0

        scaled_x = x * self.scale + self.offset_x
        scaled_y = y * self.scale + self.offset_y

        square_center_x_m = round(x*2)/2
        square_center_y_m = round(y*2)/2

        if not is_valid_point(square_center_x_m, square_center_y_m):
            step = 0
            i = 0
            while (not is_valid_point(square_center_x_m, square_center_y_m) or i==0):
                if i%4 == 0:
                    step += grid_size
                    square_center_y_m += (step - grid_size)
                    square_center_x_m -= step
                elif i%4 == 1:
                    square_center_x_m += step
                    square_center_y_m += step
                elif i%4 == 2:
                    square_center_y_m -= step
                    square_center_x_m += step
                else:
                    square_center_x_m -= step
                    square_center_y_m -= step
                i+=1

        square_bottom_left_x_m = square_center_x_m - grid_size
        square_bottom_left_y_m = square_center_y_m - grid_size

        square_bottom_left_x = square_bottom_left_x_m * self.scale + self.offset_x
        square_bottom_left_y = square_bottom_left_y_m * self.scale + self.offset_y

        square_width = 1 * self.scale

        self.canvas.clear()
        with self.canvas:
            Color(1, 1, 1, 0.8)
            Rectangle(texture=self.map_texture, pos=(self.offset_x, self.offset_y), size=(self.scaled_width, self.scaled_height))
            self.draw_item_locations()
            if self.path:
                Color(0.2, 0.6, 1, 1)
                points = []
                for (row, col) in self.path:
                    x_path = col * grid_size * self.scale + self.offset_x
                    y_path = row * grid_size * self.scale + self.offset_y
                    points.extend([x_path, y_path])
                Line(points=points, width=dp(3))
            Color(1, 0.2, 0.2, 1)
            Ellipse(pos=(scaled_x - dp(6), scaled_y - dp(6)), size=(dp(12), dp(12)))
            Color(1, 0.2, 0.2, 0.5)
            Line(rectangle=(square_bottom_left_x, square_bottom_left_y, square_width, square_width), width=dp(2))
        
        if self.goal:
            goal_x, goal_y = self.goal
            scaled_goal_x = goal_x * self.scale + self.offset_x
            scaled_goal_y = goal_y * self.scale + self.offset_y
            with self.canvas:
                Color(1, 0.8, 0.2, 1)
                Ellipse(pos=(scaled_goal_x - dp(12), scaled_goal_y - dp(12)), size=(dp(24), dp(24)))

        self.show_nearby_discounted_items(x, y)

    def set_path(self, path):
        self.path = path
        self.needs_redraw = 1

    def set_goal(self, goal):
        self.goal = goal
        self.needs_redraw = 1

    def check_deviation(self, x, y):
        current_time = time.time()
        if current_time - self.last_reroute_time < self.reroute_cooldown:
            return False
        if not self.path:
            return False
        current_row = int(y / grid_size)
        current_col = int(x / grid_size)
        check_range = min(5, len(self.path))
        for (row, col) in self.path[-check_range:]:
            if abs(row - current_row) <= 1 and abs(col - current_col) <= 1:
                self.last_valid_position = (current_row, current_col)
                return False
        self.last_reroute_time = current_time
        return True

    def draw_item_locations(self):
        for i, (x, y) in enumerate(item_locations):
            if i >= len(items):
                break
            scaled_x = x * self.scale + self.offset_x
            scaled_y = y * self.scale + self.offset_y
            with self.canvas:
                Color(0.2, 0.8, 0.2, 1)
                Ellipse(pos=(scaled_x - dp(5), scaled_y - dp(5)), size=(dp(10), dp(10)))
            if i % 3 == 0:
                label_pos_y = scaled_y - dp(20)
            elif i % 3 == 1:
                label_pos_y = scaled_y + dp(10)
                scaled_x = scaled_x + dp(10)
            else:
                label_pos_y = scaled_y + dp(20)
            label = Label(
                text=items[i],
                pos=(scaled_x, label_pos_y),
                size=(dp(100), dp(20)),
                size_hint=(None, None),
                color=TEXT_COLOR,
                font_size='12sp',
                halign='center',
                valign='middle'
            )
            self.add_widget(label)

    def show_nearby_discounted_items(self, x, y):
        for label in self.nearby_discount_labels:
            self.remove_widget(label)
        self.nearby_discount_labels = []

        row = int(y / grid_size)
        col = int(x / grid_size)
        nearby_discounts = self.discount_grid.get((row, col), [])

        for i, (item, discount, item_x, item_y) in enumerate(nearby_discounts[:3]):
            scaled_x = item_x * self.scale + self.offset_x
            scaled_y = item_y * self.scale + self.offset_y
            with self.canvas:
                Color(*ACCENT_COLOR)
                RoundedRectangle(pos=(scaled_x - dp(50), scaled_y + dp(30 + i*25)), size=(dp(200), dp(30)), radius=[dp(5)])
            label = Label(
                text=f"{item}: {discount}% OFF",
                pos=(scaled_x, scaled_y + dp(35 + i*25)),
                size=(dp(100), dp(20)),
                size_hint=(None, None),
                color=(1, 1, 1, 1),
                font_size='12sp',
                halign='center',
                valign='middle'
            )
            self.add_widget(label)
            self.nearby_discount_labels.append(label)

    def on_size(self, *args):
        if self.height == 0 or self.width == 0:  # Prevent division by zero
            return
        widget_ratio = self.width / self.height
        image_ratio = MAP_WIDTH_PIXELS / MAP_HEIGHT_PIXELS
        if widget_ratio > image_ratio:
            self.scaled_height = self.height
            self.scaled_width = self.scaled_height * image_ratio
        else:
            self.scaled_width = self.width
            self.scaled_height = self.scaled_width / image_ratio
        self.scale = (self.scaled_width / MAP_WIDTH_METERS + self.scaled_height / MAP_HEIGHT_METERS)/2
        self.offset_x = (self.width - self.scaled_width) / 2
        self.offset_y = (self.height - self.scaled_height) / 2
        self.path_x.clear()
        self.path_y.clear()
        self.needs_redraw = 1
        self.update_plot(self.last_x, self.last_y)

    def clear_path(self):
        self.path_x = []
        self.path_y = []
        self.canvas.clear()
        with self.canvas:
            Rectangle(texture=self.map_texture, pos=((self.width - self.scaled_width) / 2, (self.height - self.scaled_height) / 2), size=(self.scaled_width, self.scaled_height))
        self.needs_redraw = 1

class PlotScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.shopping_list = []
        self.current_item_index = 0
        self.path = []
        self.start_time = None
        self.last_data_time = time.time()
        self.signal_lost_popup = None
        self.signal_check_event = None
        layout = BoxLayout(orientation='vertical', padding=dp(10), spacing=dp(10))
        
        # Set background
        with layout.canvas.before:
            Color(*BACKGROUND_COLOR)
            self.bg_rect = Rectangle(pos=layout.pos, size=layout.size)
        layout.bind(pos=self.update_bg_rect, size=self.update_bg_rect)
        
        self.current_item_label = Label(text='No current item', font_size='18sp', color=TEXT_COLOR, size_hint=(1, 0.1))
        layout.add_widget(self.current_item_label)
        
        btn_layout = BoxLayout(size_hint=(1, 0.1), spacing=dp(10))
        self.prev_button = Button(text='Previous', size_hint=(0.5, 1), background_color=PRIMARY_COLOR, background_normal='')
        self.prev_button.bind(on_press=self.prev_item)
        btn_layout.add_widget(self.prev_button)
        
        self.next_button = Button(text='Next', size_hint=(0.5, 1), background_color=PRIMARY_COLOR, background_normal='')
        self.next_button.bind(on_press=self.next_item)
        btn_layout.add_widget(self.next_button)
        layout.add_widget(btn_layout)
        
        self.plot_widget = PlotWidget()
        layout.add_widget(self.plot_widget)
        
        self.progress_bar = ProgressBar(max=100, size_hint=(1, 0.05))
        with self.progress_bar.canvas.before:
            Color(*PROGRESS_BG_COLOR)
            self.progress_rect = Rectangle(pos=self.progress_bar.pos, size=self.progress_bar.size)
        self.progress_bar.bind(pos=self.update_progress_rect, size=self.update_progress_rect)
        layout.add_widget(self.progress_bar)
        
        self.cancel_button = Button(text='Cancel', size_hint=(1, 0.1), background_color=ACCENT_COLOR, background_normal='')
        self.cancel_button.bind(on_press=self.cancel_plot)
        layout.add_widget(self.cancel_button)
        
        self.add_widget(layout)
        Clock.schedule_interval(self.update_plot, 0.1)

    def update_bg_rect(self, instance, value):
        self.bg_rect.pos = instance.pos
        self.bg_rect.size = instance.size

    def update_progress_rect(self, instance, value):
        self.progress_rect.pos = instance.pos
        self.progress_rect.size = instance.size

    def start_signal_monitoring(self):
        if self.signal_check_event is None:
            self.signal_check_event = Clock.schedule_interval(self.check_signal, 1.0)

    def stop_signal_monitoring(self):
        if self.signal_check_event:
            self.signal_check_event.cancel()
            self.signal_check_event = None

    def check_signal(self, dt):
        if time.time() - self.last_data_time > 2.0:
            self.handle_signal_loss()

    def check_connection_health(self):
        now = time.time()
        if now - self.last_data_time > 5.0:
            self.connection_quality = "poor"
        elif now - self.last_data_time > 2.0:
            self.connection_quality = "unstable"
        else:
            self.connection_quality = "good"
        if hasattr(self, 'connection_label'):
            colors = {
                "good": (0, 1, 0, 1),
                "unstable": (1, 1, 0, 1),
                "poor": (1, 0, 0, 1)
            }
            self.connection_label.color = colors[self.connection_quality]
            self.connection_label.text = f"Connection: {self.connection_quality.upper()}"

    def handle_signal_loss(self):
        if self.signal_lost_popup is not None:
            return
        if self.attempt_reconnect():
            self.last_data_time = time.time()
            return
        self.stop_signal_monitoring()
        content = BoxLayout(orientation='vertical', spacing=dp(10))
        content.add_widget(Label(text='UWB Signal Lost!\nTrying to reconnect...', color=TEXT_COLOR))
        self.signal_lost_popup = Popup(
            title='Connection Error',
            content=content,
            size_hint=(0.8, 0.4),
            background_color=BACKGROUND_COLOR
        )
        self.signal_lost_popup.open()
        self.reconnect_start_time = time.time()
        Clock.schedule_once(self.wait_for_reconnection, 0.1)

    def wait_for_reconnection(self, dt):
        if time.time() - self.reconnect_start_time > 10.0:
            self.signal_lost_popup.dismiss()
            self.show_restart_message()
            return
        if serial_port and serial_port.is_open:
            try:
                line = serial_port.readline()
                if line:
                    self.signal_lost_popup.dismiss()
                    self.signal_lost_popup = None
                    self.last_data_time = time.time()
                    self.start_signal_monitoring()
                    return
            except:
                pass
        Clock.schedule_once(self.wait_for_reconnection, 0.1)

    def show_restart_message(self):
        content = BoxLayout(orientation='vertical', spacing=dp(10))
        content.add_widget(Label(text='Could not reconnect to UWB device.\nPlease restart the application.', color=TEXT_COLOR))
        close_button = Button(text='OK', size_hint=(1, 0.4), background_color=PRIMARY_COLOR, background_normal='')
        content.add_widget(close_button)
        popup = Popup(
            title='Connection Lost',
            content=content,
            size_hint=(0.8, 0.4),
            background_color=BACKGROUND_COLOR
        )
        close_button.bind(on_press=popup.dismiss)
        popup.open()
        self.prev_button.disabled = True
        self.next_button.disabled = True
        self.cancel_button.disabled = True

    def update_progress(self, current_x, current_y, goal_x, goal_y, path):
        if not path:
            self.progress_bar.value = 0
            return
        total_distance = 0
        for i in range(len(path)-1):
            x1, y1 = path[i][1] * grid_size, path[i][0] * grid_size
            x2, y2 = path[i+1][1] * grid_size, path[i+1][0] * grid_size
            total_distance += np.sqrt((x2-x1)**2 + (y2-y1)**2)
        current_row = int(current_y / grid_size)
        current_col = int(current_x / grid_size)
        closest_dist = float('inf')
        closest_index = 0
        for i, (row, col) in enumerate(path):
            dist = (row - current_row)**2 + (col - current_col)**2
            if dist < closest_dist:
                closest_dist = dist
                closest_index = i
        covered_distance = 0
        for i in range(closest_index):
            x1, y1 = path[i][1] * grid_size, path[i][0] * grid_size
            x2, y2 = path[i+1][1] * grid_size, path[i+1][0] * grid_size
            covered_distance += np.sqrt((x2-x1)**2 + (y2-y1)**2)
        if total_distance > 0:
            progress = (covered_distance / total_distance) * 100
            self.progress_bar.value = min(100, max(0, progress))

    def update_current_item(self):
        if not hasattr(self, 'next_button'):
            return
        if self.current_item_index < len(self.shopping_list):
            item = self.shopping_list[self.current_item_index]
            self.current_item_label.text = f"Item {self.current_item_index+1}/{len(self.shopping_list)}: {item}"
            if self.current_item_index == len(self.shopping_list) - 1:
                self.next_button.text = "Finish"
            else:
                self.next_button.text = "Next"
            self.select_item(item)
        else:
            self.show_completion()

    def select_item(self, item_name):
        global item_index
        item_index = items.index(item_name)
        goal_x, goal_y = item_locations[item_index]
        if not is_valid_point(goal_x, goal_y):
            valid_point = find_nearest_valid_point(goal_x, goal_y)
            if valid_point:
                goal_x, goal_y = valid_point
            else:
                print("No valid point found near the goal.")
                return
        self.plot_widget.set_goal((goal_x, goal_y))
        goal_row = int(goal_y / grid_size)
        goal_col = int(goal_x / grid_size)
        current_row = int(self.plot_widget.prev_point[1] / grid_size)
        current_col = int(self.plot_widget.prev_point[0] / grid_size)
        path = a_star((current_row, current_col), (goal_row, goal_col), map_grid, self.plot_widget.path_cache)
        if path:
            self.path = path
            self.plot_widget.set_path(path)
        else:
            print("No path found!")

    def prev_item(self, instance):
        if self.current_item_index > 0:
            self.current_item_index -= 1
            self.update_current_item()

    def next_item(self, instance):
        if self.current_item_index < len(self.shopping_list) - 1:
            self.current_item_index += 1
            self.update_current_item()
        else:
            self.show_completion()

    def show_completion(self):
        self.current_item_label.text = "All Items Found!"
        self.next_button.text = "End Shopping"
        self.next_button.unbind(on_press=self.next_item)
        self.next_button.bind(on_press=self.end_shopping)
        celebration_layout = BoxLayout(
            orientation='vertical', 
            size_hint=(None, None),
            size=(dp(200), dp(200)),
            pos_hint={'center_x': 0.5, 'center_y': 0.8}
        )
        checkmark = Image(source='checkmark.png', size_hint=(1, 0.7))
        success_label = Label(text="All Items Collected!", font_size='24sp', color=PRIMARY_COLOR)
        celebration_layout.add_widget(checkmark)
        celebration_layout.add_widget(success_label)
        self.add_widget(celebration_layout)
        Clock.schedule_once(lambda dt: self.remove_widget(celebration_layout), 3)

    def update_plot(self, dt):
        if serial_port and serial_port.is_open:
            try:
                if serial_port.in_waiting > 0:
                    line = serial_port.readline()
                    try:
                        data = json.loads(line.decode().strip())
                        x, y = float(data["X"]), float(data["Y"])
                        self.last_data_time = time.time()
                        self.plot_widget.prev_point = [x, y]
                        if self.current_item_index < len(self.shopping_list):
                            if self.plot_widget.check_deviation(x, y):
                                item = self.shopping_list[self.current_item_index]
                                self.select_item(item)
                            self.update_progress(x, y, *self.get_current_goal(), self.path)
                        self.plot_widget.update_plot(x, y)
                    except (json.JSONDecodeError, ValueError, KeyError, UnicodeDecodeError):
                        pass
            except Exception as e:
                print(f"Serial error: {e}")
                self.handle_signal_loss()

    def on_enter(self):
        self.start_signal_monitoring()

    def on_leave(self):
        self.stop_signal_monitoring()

    def get_current_goal(self):
        if self.current_item_index < len(self.shopping_list):
            item_index = items.index(self.shopping_list[self.current_item_index])
            return item_locations[item_index]
        return (0, 0)

    def set_shopping_list(self, items):
        self.shopping_list = items
        self.current_item_index = 0
        self.start_time = time.time()
        self.update_current_item()

    def end_shopping(self, instance):
        if hasattr(self, 'start_time') and self.start_time:
            time_taken = time.time() - self.start_time
        else:
            time_taken = 0
        summary_screen = self.manager.get_screen('summary')
        summary_screen.show_summary(self.shopping_list, time_taken)
        self.manager.current = 'summary'
        self.reset_shopping_state()

    def reset_shopping_state(self):
        self.next_button.text = "Next"
        self.next_button.unbind(on_press=self.end_shopping)
        self.next_button.bind(on_press=self.next_item)
        self.current_item_label.text = "No current item"
        self.plot_widget.clear_path()

    def cancel_plot(self, instance):
        close_serial_port()
        self.reset_shopping_state()
        self.manager.current = 'home'

    def attempt_reconnect(self):
        try:
            close_serial_port()
            return open_serial_port()
        except:
            return False

class SummaryScreen(Screen):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        layout = BoxLayout(orientation='vertical', padding=dp(20), spacing=dp(15))
        
        # Set background
        with layout.canvas.before:
            Color(*BACKGROUND_COLOR)
            self.bg_rect = Rectangle(pos=layout.pos, size=layout.size)
        layout.bind(pos=self.update_bg_rect, size=self.update_bg_rect)
        
        self.title_label = Label(text="Shopping Summary", font_size='28sp', color=PRIMARY_COLOR, size_hint=(1, 0.2))
        layout.add_widget(self.title_label)
        
        self.time_label = Label(text="", font_size='18sp', color=TEXT_COLOR, size_hint=(1, 0.15))
        layout.add_widget(self.time_label)
        
        self.items_label = Label(text="", font_size='16sp', color=TEXT_COLOR, size_hint=(1, 0.4), halign='left', valign='top')
        layout.add_widget(self.items_label)
        
        self.thanking_label = Label(text="", font_size='16sp', color=TEXT_COLOR, size_hint=(1, 0.15), halign='left', valign='top')
        layout.add_widget(self.thanking_label)
        
        self.home_button = Button(text="Back to Home", size_hint=(1, 0.1), background_color=PRIMARY_COLOR, background_normal='')
        self.home_button.bind(on_press=self.return_home)
        layout.add_widget(self.home_button)
        
        self.add_widget(layout)

    def update_bg_rect(self, instance, value):
        self.bg_rect.pos = instance.pos
        self.bg_rect.size = instance.size

    def show_summary(self, shopping_list, time_taken):
        hours, minutes, seconds = convert_seconds(time_taken)
        self.time_label.text = f"Time Spent: {int(hours)}h {int(minutes)}m {int(seconds)}s"
        self.items_label.text = "Items Collected:\n" + "\n".join(f"• {item}" for item in shopping_list)
        self.thanking_label.text = "Thank you for using IndoorGuide!"

    def return_home(self, instance):
        self.manager.current = 'home'

class ShoppingApp(App):
    def build(self):
        sm = ScreenManager(transition=FadeTransition())
        sm.add_widget(HomeScreen(name='home'))
        sm.add_widget(PlotScreen(name='plot'))
        sm.add_widget(SummaryScreen(name='summary'))
        return sm

if __name__ == '__main__':
    ShoppingApp().run()