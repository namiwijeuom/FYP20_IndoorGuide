% Define the grid size
gridSize = 10; % Example grid size of 10x10 meters

% Create a figure and set up the grid
figure;
hold on;
axis([0 gridSize 0 gridSize]); % Set the grid limits
axis equal; % Ensure square proportions
grid on; % Enable grid display
xlabel('X (meters)');
ylabel('Y (meters)');

% Define initial position of the square
x = 5; % X-coordinate of the square's bottom-left corner
y = 5; % Y-coordinate of the square's bottom-left corner

% Draw the square using the rectangle function
square = rectangle('Position', [x, y, 1, 1], 'EdgeColor', 'r', 'LineWidth', 2);

% Simulate movement of the square
for i = 1:50
    % Update position (example: move diagonally)
    x = x + 0.1; 
    disp(x)
    disp(floor(x))

    y = y + 0.2;
    disp(y)
    disp(floor(x))

    % Update the square's position
    set(square, 'Position', [floor(x), floor(y), 1, 1]);
    
    % Pause to visualize the movement
    pause(0.5);
end
