import time
import json
import serial
from serial.serialutil import SerialException
from math import sqrt
from collections import deque
import numpy as np

# Load the supermarket map image
MAP_IMAGE = 'top view2.png'
MAP_WIDTH_PIXELS  = 675
MAP_HEIGHT_PIXELS = 782
MAP_WIDTH_METERS  = 16.04
MAP_HEIGHT_METERS  = 18.34

grid_size = 0.5   #0.5m grids
num_of_rows = int(np.ceil(MAP_HEIGHT_METERS/grid_size) + 1)
num_of_cols = int(np.ceil(MAP_WIDTH_METERS/grid_size)  + 1)

map_grid = np.zeros((num_of_rows,num_of_cols))      # 1 for obstacles. 0 for walkable paths.

# --------------- Creating binary map with obstacles -------------------
map_grid[:9,6:27]       = 1
map_grid[:2,29:]        = 1
map_grid[:,31:]         = 1
map_grid[10:33,1:5]     = 1
map_grid[13:33,6:10]    = 1
map_grid[13:33,11:15]   = 1
map_grid[13:33,16:20]   = 1
map_grid[13:33,21:25]   = 1
map_grid[13:33,26:30]   = 1
map_grid[34:,:]         = 1

class SerialDataHandler:
    def __init__(self):
        # Connection state tracking
        self.last_valid_time = time.time()
        self.data_timeout = 2.0  # seconds before considering data lost
        self.reconnect_timeout = 10.0  # seconds before giving up
        self.reconnect_attempts = 0
        self.max_reconnect_attempts = 3
        self.connection_state = "connected"  # "disconnected", "reconnecting", "failed"
        
        # Position tracking
        self.last_valid_position = (0.0, 0.0)  # (x, y)
        self.position_history = deque(maxlen=5)  # Stores last 5 positions for velocity estimation
        self.last_velocity = (0.0, 0.0)  # (vx, vy) in m/s
        
        # Data validation parameters
        self.max_speed = 2.0  # Maximum plausible speed in m/s
        self.map_bounds = (16.04, 18.34)  # (width, height) of map in meters
        
        # Serial port reference (to be set externally)
        self.serial_port = None
        
    def handle_serial_data(self, raw_data):
        """Process incoming serial data and update system state"""
        try:
            # Parse and validate the data
            data = self._parse_data(raw_data)
            print("Data :", data)

            # if not self._is_valid_data(data):
            #    return None
                
            # Update position tracking
            data = json.loads(raw_data.decode().strip())
            current_pos = (float(data['X']), float(data['Y']))
            print("Current position: ",current_pos)

            self._update_position_history(current_pos)
            self.last_valid_position = current_pos
            
            # Update connection state
            self._update_connection_state(True)
            
            return {
                'X': current_pos[0],
                'Y': current_pos[1],
                'timestamp': time.time(),
                'quality': self._calculate_signal_quality(raw_data)
            }
            
        except (SerialException, ValueError, KeyError, UnicodeDecodeError) as e:
            self._update_connection_state(False)
            return None
            
    def _parse_data(self, raw_data):
        """Parse raw serial data into a dictionary"""
        try:
            # Try JSON parsing first
            decoded = raw_data.decode('utf-8').strip()
            data = json.loads(decoded)
            
            # Validate required fields
            if 'X' not in data or 'Y' not in data:
                raise ValueError("Missing position fields")
                
            return data
            
        except json.JSONDecodeError:
            # Fallback to simple comma/tab separated format
            parts = raw_data.decode('utf-8').strip().split()
            if len(parts) >= 2:
                return {'X': float(parts[0]), 'Y': float(parts[1])}
            raise ValueError("Invalid data format")
            
    def _is_valid_data(self, data):
        """Validate position data against multiple criteria"""
        try:
            x, y = float(data['X']), float(data['Y'])
            
            # 1. Check if within map bounds
            if not (0 <= x <= self.map_bounds[0] and 0 <= y <= self.map_bounds[1]):
                return False
                
            # 2. Check if position is in obstacle (using your map_grid)
            row = int(y / grid_size)
            col = int(x / grid_size)
            if map_grid[row, col] == 1:
                return False
                
            # 3. Check for sudden implausible movement
            if self.position_history:
                last_x, last_y = self.position_history[-1]
                time_elapsed = time.time() - self.last_valid_time
                distance = sqrt((x - last_x)**2 + (y - last_y)**2)
                
                # Calculate speed in m/s
                if time_elapsed > 0:
                    speed = distance / time_elapsed
                    if speed > self.max_speed:
                        return False
                        
            return True
            
        except (ValueError, KeyError, IndexError):
            return False
            
    def _update_position_history(self, current_pos):
        """Update position history and calculate velocity"""
        now = time.time()
        self.position_history.append((current_pos[0], current_pos[1], now))
        
        # Calculate velocity if we have enough history
        if len(self.position_history) >= 2:
            x1, y1, t1 = self.position_history[-2]
            x2, y2, t2 = self.position_history[-1]
            time_diff = t2 - t1
            
            if time_diff > 0:
                self.last_velocity = (
                    (x2 - x1) / time_diff,
                    (y2 - y1) / time_diff
                )
                
    def _calculate_signal_quality(self, raw_data):
        """Calculate signal quality metric (0-1) based on data characteristics"""
        # Simple implementation - could be enhanced with actual signal metrics
        try:
            # Check if data is complete JSON
            json.loads(raw_data.decode('utf-8'))
            return 1.0
        except:
            return 0.7  # Partial credit for non-JSON but parseable data
            
    def _update_connection_state(self, data_received):
        """Manage connection state machine"""
        current_time = time.time()
        
        if data_received:
            self.last_valid_time = current_time
            if self.connection_state != "connected":
                self.connection_state = "connected"
                self.reconnect_attempts = 0
        else:
            time_since_last = current_time - self.last_valid_time
            
            if time_since_last > self.data_timeout:
                if self.connection_state == "connected":
                    self.connection_state = "disconnected"
                    self._start_reconnection()
                elif self.connection_state == "reconnecting":
                    if time_since_last > self.reconnect_timeout:
                        self._handle_reconnection_failure()
                        
    def _start_reconnection(self):
        """Attempt to reestablish serial connection"""
        self.connection_state = "reconnecting"
        self.reconnect_attempts += 1
        
        try:
            if self.serial_port:
                # Close and reopen the port
                self.serial_port.close()
                time.sleep(0.5)  # Brief pause
                self.serial_port.open()
                
                # Reset buffer
                if self.serial_port.in_waiting:
                    self.serial_port.reset_input_buffer()
                    
        except Exception as e:
            print(f"Reconnection attempt {self.reconnect_attempts} failed: {str(e)}")
            
    def _handle_reconnection_failure(self):
        """Handle failed reconnection attempts"""
        if self.reconnect_attempts >= self.max_reconnect_attempts:
            self.connection_state = "failed"
            print("Max reconnection attempts reached. Connection failed.")
        else:
            self._start_reconnection()
            
    def get_current_position(self):
        """Get current position with dead reckoning when needed"""
        if self.connection_state == "connected":
            return self.last_valid_position
        else:
            # Dead reckoning implementation
            time_elapsed = time.time() - self.last_valid_time
            estimated_x = self.last_valid_position[0] + self.last_velocity[0] * time_elapsed
            estimated_y = self.last_valid_position[1] + self.last_velocity[1] * time_elapsed
            
            # Constrain to map bounds
            estimated_x = max(0, min(self.map_bounds[0], estimated_x))
            estimated_y = max(0, min(self.map_bounds[1], estimated_y))
            
            return (estimated_x, estimated_y)
            
    def set_serial_port(self, port):
        """Set the serial port reference"""
        self.serial_port = port
        
    def get_connection_state(self):
        """Get current connection state"""
        return self.connection_state
        
    def reset(self):
        """Reset the handler to initial state"""
        self.__init__()


# Initialize
#print(serial.__version__)  # Should print the pyserial version (e.g., 3.5)
try:
    serial_port = serial.Serial('COM6', baudrate=115200)
    print("Serial port opened successfully")
except serial.SerialException as e:
    print(f"Error opening serial port: {e}")

handler = SerialDataHandler()
handler.set_serial_port(serial_port)  # Your existing serial port

# Main loop
while True:
    if serial_port.in_waiting:
        raw_data = serial_port.readline()
        print("Raw data: ",raw_data)
        position = handler.handle_serial_data(raw_data)
        print("Position: ",position)
        if position:
            print(f"Good position: {position['X']}, {position['Y']}")
        else:
            print("Using estimated position")
            x, y = handler.get_current_position()
            print(f"Estimated: {x}, {y}")
            
    time.sleep(0.05)
    
    # Check connection state
    if handler.get_connection_state() == "failed":
        print("Connection failed! Need user intervention")
        break