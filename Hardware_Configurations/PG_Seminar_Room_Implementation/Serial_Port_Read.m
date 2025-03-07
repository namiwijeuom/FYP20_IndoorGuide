% List all serial ports
serialPorts = serialportlist;

% Display the available serial ports
disp('Available Serial Ports:');
disp(serialPorts);

% If you want to connect to a specific USB device, you can specify the port name
% For example, if the port name is 'COM3' (on Windows) or '/dev/ttyUSB0' (on Linux/Mac)
portName = 'COM3'; % Change this to your specific port name
usbDevice = serialport(portName, 9600); % 9600 is the baud rate, adjust as needed

% Display the connected USB device
disp('Connected USB Device:');
disp(usbDevice);
