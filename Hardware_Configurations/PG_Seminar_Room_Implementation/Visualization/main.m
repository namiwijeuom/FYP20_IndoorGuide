anchors = [11.5, 11.5;
           0.9, 8;
           1.8, 1.5;
           11.5, 0.2];

      
environment = createEnvironment('PG_Seminar_Room_Map.png');
showBaseStations(anchors);


% Create a serial port object
s = serialport(portName, baudRate);

% Set optional parameters
configureTerminator(s, "LF"); % Line feed terminator
s.Timeout = 10; % Timeout in seconds


% Initialize plot elements for paths
ekfPath = plot(nan, nan, 'b-', 'LineWidth', 1); % Blue line for EKF path
mulPath = plot(nan, nan, 'r-', 'LineWidth', 1); % Red line for MUL path
ekfPoint = plot(nan, nan, 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'blue'); % Blue dot for EKF current location
mulPoint = plot(nan, nan, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'red'); % Red dot for MUL current location

% Initialize history of coordinates
ekfXHistory = [];
ekfYHistory = [];
mulXHistory = [];
mulYHistory = [];

disp("Plotting data. Press Ctrl+C to stop.");

% Continuously read data and update the plot
try
    while true
        % Read a line of data
        data = readline(s);

        % Parse EKF and MUL locations
        % Example: "Current Location-EKF : 3.06 X , 0.87 Y , 1.09 Z"
        ekfTokens = regexp(data, 'Current Location-EKF : ([\d\.\-]+) X , ([\d\.\-]+) Y', 'tokens');
        mulTokens = regexp(data, 'Current Location-MUL : ([\d\.\-]+) X , ([\d\.\-]+) Y', 'tokens');

        % Update EKF location
        if ~isempty(ekfTokens)
            ekfX = str2double(ekfTokens{1}{1});
            ekfY = str2double(ekfTokens{1}{2});
            ekfXHistory(end+1) = ekfX;
            ekfYHistory(end+1) = ekfY;

            % Update EKF path and current location
            set(ekfPath, 'XData', ekfXHistory, 'YData', ekfYHistory);
            set(ekfPoint, 'XData', ekfX, 'YData', ekfY);
        end

        % Update MUL location
        if ~isempty(mulTokens)
            mulX = str2double(mulTokens{1}{1});
            mulY = str2double(mulTokens{1}{2});
            mulXHistory(end+1) = mulX;
            mulYHistory(end+1) = mulY;

            % Update MUL path and current location
            set(mulPath, 'XData', mulXHistory, 'YData', mulYHistory);
            set(mulPoint, 'XData', mulX, 'YData', mulY);
        end

        drawnow; % Update the plot immediately
    end
catch ME
    % If Ctrl+C or error, show message and clean up
    disp("Stopped plotting.");
    disp("Error (if any):");
    disp(ME.message);
    % Clean up
    clear s; % Release the serial port
end
