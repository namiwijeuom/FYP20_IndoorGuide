%% Initialize the grid environment
room_length = 12.124;
room_height = 11.64;
cell_size = 0.5;

rows = ceil(room_height / cell_size);
cols = ceil(room_length / cell_size);
grid = zeros(rows, cols);

% Define obstacles
grid(2:5, 1:4) = 1;    % Rack 01
grid(2:5, 6:9) = 1;    % Rack 02
grid(7:10, 1:4) = 1;   % Rack 03
grid(7:10, 6:9) = 1;   % Rack 04
grid(12:15, 1:4) = 1;  % Rack 05
grid(13:16, 6:9) = 1;  % Rack 06
grid(21:23, 1:4) = 1;  % Rack 07
grid(12:13, 12:13) = 1; % Brown block 1
grid(12:13, 23:24) = 1; % Brown block 2
grid(23:24, 12:13) = 1; % Brown block 3
grid(23:24, 23:24) = 1; % Brown block 4
grid(1:4, 13:24) = 1;  % Approximate position for the stage

% Anchors positions
anchors = [11.5, 11.5;
           0.9, 8;
           1.8, 1.5;
           11.5, 0.5];

%% Expand obstacles for not going near the obstacle
grid_with_buffer = expand_obstacles(grid);

%% Define items and their locations
items = {'Vegetables', 'Fruits', 'Meat', 'MilkPowder', 'Biscuits'};
item_locations = [20, 2; 
                  2, 12; 
                  6, 2; 
                  11, 13; 
                  20, 22];

% Start with an empty list of selected items
selected_items = {}; 

% Dynamic updates: Add/remove items from the predefined list
[~, item_locations] = dynamic_updates(items, item_locations, selected_items);

%% Input: Specify items to access
selected_items = {'Fruits', 'MilkPowder', 'Vegetables'};

%% Serial Port Setup
%s = serialport("COM3", 9600);
%configureTerminator(s, "LF");
%s.Timeout = 10;

%% Real-Time Path Plotting Initialization
figure;
imagesc(grid_with_buffer);
colormap(gray);
axis equal tight;
hold on;

% Plot anchors on the grid
for i = 1:size(anchors, 1)
    % Convert anchor positions to grid coordinates
    anchor_grid_x = round(anchors(i, 1) / cell_size);
    anchor_grid_y = round(anchors(i, 2) / cell_size);

    % Plot each anchor as a triangle
    plot(anchor_grid_x, anchor_grid_y, 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'red');
    text(anchor_grid_x + 0.5, anchor_grid_y, sprintf('Anchor %d', i), 'Color', 'red');
end

% Mark item locations
for i = 1:length(items)
    plot(item_locations(i, 2), item_locations(i, 1), 'bo', 'MarkerSize', 8, 'LineWidth', 2); % Blue for items
    text(item_locations(i, 2) + 0.5, item_locations(i, 1), items{i}, 'Color', 'blue');
end

% Add title and axis labels
title('Grid with Obstacles, Path, and Anchors');
xlabel('X (meters)');
ylabel('Y (meters)');

% Adjust axis ticks for clarity
xticks(1:1:cols);
xticklabels(arrayfun(@(x) sprintf('%.1f', x * cell_size), xticks, 'UniformOutput', false));
yticks(1:1:rows);
yticklabels(arrayfun(@(y) sprintf('%.1f', y * cell_size), yticks, 'UniformOutput', false));

ekfPath = plot(nan, nan, 'b-', 'LineWidth', 1);
mulPath = plot(nan, nan, 'r-', 'LineWidth', 1);
ekfPoint = plot(nan, nan, 'bo', 'MarkerSize', 5, 'MarkerFaceColor', 'blue');
mulPoint = plot(nan, nan, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'red');

ekfXHistory = [];
ekfYHistory = [];
mulXHistory = [];
mulYHistory = [];

disp("Plotting data. Press Ctrl+C to stop.");

% Define threshold for deviation (in grid units)
deviation_threshold = 2;

try
    while true
        % Read serial data
        data = readline(s);

        % Parse EKF and MUL positions
        ekfTokens = regexp(data, 'Current Location-EKF : ([\d\.\-]+) X , ([\d\.\-]+) Y', 'tokens');
        mulTokens = regexp(data, 'Current Location-MUL : ([\d\.\-]+) X , ([\d\.\-]+) Y', 'tokens');

        % Update EKF Position
        if ~isempty(ekfTokens)
            ekfX = str2double(ekfTokens{1}{1});
            ekfY = str2double(ekfTokens{1}{2});
            ekfXHistory(end+1) = ekfX;
            ekfYHistory(end+1) = ekfY;

            set(ekfPath, 'XData', ekfXHistory, 'YData', ekfYHistory);
            set(ekfPoint, 'XData', ekfX, 'YData', ekfY);

        end

        % Update MUL Position
        if ~isempty(mulTokens)
            mulX = str2double(mulTokens{1}{1});
            mulY = str2double(mulTokens{1}{2});
            mulXHistory(end+1) = mulX;
            mulYHistory(end+1) = mulY;

            set(mulPath, 'XData', mulXHistory, 'YData', mulYHistory);
            set(mulPoint, 'XData', mulX, 'YData', mulY);
        end

        % Plan Path to Next Item if Items Are Selected
        if ~isempty(selected_items)
            % Get the current EKF position as the starting point
            start_pos = approximateToMidpoint([ekfX, ekfY]);
            [~, optimized_locations] = optimize_order(start_pos, selected_items, items, item_locations);

            % Calculate path to the next item
            path = A_star_pathfinding(grid_with_buffer, start_pos, optimized_locations(2, :));

            % Plot the planned path
            for i = 1:size(path, 1) - 1
                plot([path(i, 2), path(i+1, 2)], [path(i, 1), path(i+1, 1)], 'g-', 'LineWidth', 2);
            end

            % Remove the visited item from the list
            selected_items(1) = [];
        end

        % Check for deviation from planned path
            if ~isOnPath([ekfX, ekfY], path, deviation_threshold)
                disp('Deviation detected. Recalculating path...');
                
                % Update start position
                start_pos = approximateToMidpoint([ekfX, ekfY]);
                
                % Recalculate path to the goal
                path = A_star_pathfinding(grid_with_buffer, start_pos, goal_pos);
                
                % Update path visualization
                delete(findall(gca, 'Type', 'line', 'Color', 'g')); % Remove old path
                for i = 1:size(path, 1) - 1
                    plot([path(i, 2), path(i+1, 2)], [path(i, 1), path(i+1, 1)], 'g-', 'LineWidth', 2);
                end
            end

        drawnow;
    end
catch ME
    disp("Stopped plotting.");
    disp("Error (if any):");
    disp(ME.message);
    clear s;
end

%% Function to expand obstacles (buffer zone)
function expanded_grid = expand_obstacles(grid)
    padding = 0; % 50 cm corresponds to 1 cell in the new grid resolution
    padded_grid = padarray(grid, [padding, padding], 0, 'both');
    expanded_grid = grid;
    for row = padding + 1:size(padded_grid, 1) - padding
        for col = padding + 1:size(padded_grid, 2) - padding
            if padded_grid(row, col) == 1
                expanded_grid(row-padding:row+padding, col-padding:col+padding) = 1;
            end
        end
    end
end

%% Function for A* Algorithm
function pathPoints = A_star_pathfinding(environment, startNode, goalNode)
    openList = [startNode]; % Nodes to be evaluated
    cameFrom = containers.Map(); % Map to track the path
    gScore = containers.Map(); % Cost from start to the node
    fScore = containers.Map(); % Estimated total cost (gScore + heuristic)

    key = nodeKey(startNode);
    gScore(key) = 0;
    fScore(key) = heuristic(startNode, goalNode);

    while ~isempty(openList)
        current = getLowestFScore(openList, fScore);

        if isequal(current, goalNode) % Reached the goal
            pathPoints = reconstructPath(cameFrom, current);
            return;
        end

        openList = removeFromOpenList(openList, current);
        keyCurrent = nodeKey(current);

        neighbors = getNeighbors(current, environment);
        for i = 1:size(neighbors, 1)
            neighbor = neighbors(i, :);
            keyNeighbor = nodeKey(neighbor);
            tentative_gScore = gScore(keyCurrent) + 1;

            if ~isKey(gScore, keyNeighbor) || tentative_gScore < gScore(keyNeighbor)
                cameFrom(keyNeighbor) = current;
                gScore(keyNeighbor) = tentative_gScore;
                fScore(keyNeighbor) = tentative_gScore + heuristic(neighbor, goalNode);

                if ~inOpenList(openList, neighbor)
                    openList = [openList; neighbor];
                end
            end
        end
    end

    pathPoints = [];
end
%% Helper Functions

function midpoint = approximateToMidpoint(point)
    % Snap point to the nearest midpoint of the grid
    midpoint = round(point) - 0.5;
end

function displayEnvironment(env, startNode, goalNode)
    % Function to display the environment grid
    imagesc(~env');  % Invert the environment to display free space as black and obstacles as white
    hold on;
    colormap(gray);  % Use grayscale but inverted for obstacle and free space colors
    plot(startNode(1), startNode(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Start node in green
    plot(goalNode(1), goalNode(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);   % Goal node in red
    axis equal;
    grid on;
    xticks(0:1:size(env, 1));  % Set grid ticks for better visual guidance
    yticks(0:1:size(env, 2));
end

function h = heuristic(node, goalNode)
    % Manhattan distance heuristic (grid-based movement)
    h = abs(node(1) - goalNode(1)) + abs(node(2) - goalNode(2));
end

function neighbors = getNeighbors(node, environment)
    % Get the neighbors (up, down, left, right) for the current node
    potentialMoves = [1 0; -1 0; 0 1; 0 -1];  % Right, left, down, up
    neighbors = [];

    for i = 1:size(potentialMoves, 1)
        newNode = node + potentialMoves(i, :);
        if newNode(1) > 0 && newNode(1) <= size(environment, 1) && ...
           newNode(2) > 0 && newNode(2) <= size(environment, 2) && ...
           environment(round(newNode(1)), round(newNode(2))) == 0  % Valid free space
            neighbors = [neighbors; newNode];
        end
    end
end

function key = nodeKey(node)
    % Generate a string key for the node for use in containers.Map
    key = sprintf('%f_%f', node(1), node(2));
end

function lowestNode = getLowestFScore(openList, fScore)
    % Get the node in the openList with the lowest fScore
    lowestNode = openList(1, :);
    lowestScore = fScore(nodeKey(lowestNode));

    for i = 2:size(openList, 1)
        node = openList(i, :);
        score = fScore(nodeKey(node));
        if score < lowestScore
            lowestNode = node;
            lowestScore = score;
        end
    end
end

function openList = removeFromOpenList(openList, node)
    % Remove a node from the openList
    for i = 1:size(openList, 1)
        if isequal(openList(i, :), node)
            openList(i, :) = [];
            break;
        end
    end
end

function inList = inOpenList(openList, node)
    % Check if a node is in the openList
    inList = false;
    for i = 1:size(openList, 1)
        if isequal(openList(i, :), node)
            inList = true;
            break;
        end
    end
end

function path = reconstructPath(cameFrom, current)
    % Reconstruct the path from the cameFrom map
    path = current;
    while isKey(cameFrom, nodeKey(current))
        current = cameFrom(nodeKey(current));
        path = [current; path];
    end
end

function plotPath(path)
    % Plot the final path
    plot(path(:, 1), path(:, 2), 'r-', 'LineWidth', 3);  % Thicker red line for visibility
    plot(path(:, 1), path(:, 2), 'ko', 'MarkerFaceColor', 'r');  % Red dots for nodes
end

function animateMovement(pathPoints)
    % Animate the movement through the pathPoints (after the path is found)
    for i = 1:size(pathPoints, 1)
        plot(pathPoints(i, 1), pathPoints(i, 2), 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b'); % Moving point as blue dot
        drawnow;  % Update the figure for animation
        pause(0.3);  % Slow down to visualize the movement
    end
end

%% Function to optimize order using nearest neighbor heuristic
function [start_pos, optimized_locations] = optimize_order(start_pos, input_items, items, item_locations)
    % Get locations of input items
    idxs = cellfun(@(x) find(strcmp(items, x)), input_items);
    locations = [start_pos; item_locations(idxs, :)];

    % Nearest neighbor TSP heuristic
    optimized_locations = [start_pos];
    current = start_pos;
    remaining = locations(2:end, :); % Exclude start position

    while ~isempty(remaining)
        distances = sqrt(sum((remaining - current).^2, 2));
        [~, idx] = min(distances);
        optimized_locations = [optimized_locations; remaining(idx, :)];
        current = remaining(idx, :);
        remaining(idx, :) = [];
    end
end

%% Function for dynamic updates
function [items, item_locations, selected_items] = dynamic_updates(items, item_locations, selected_items)
    % Ensure selected_items is a cell array
    if isempty(selected_items)
        selected_items = {};
    end
    
    % Dynamic menu for adding/removing items from the predefined list
    disp('Dynamic Updates:');
    disp('1. Add an item');
    disp('2. Remove an item');
    disp('3. Finish');
    
    while true
        choice = input('Choose an option: ');
        switch choice
            case 1 % Add an item
                disp('Available items to add:');
                available_items = setdiff(items, selected_items); % Items not yet selected
                if isempty(available_items)
                    disp('No items available to add.');
                else
                    for i = 1:length(available_items)
                        fprintf('%d. %s\n', i, available_items{i});
                    end
                    idx = input('Enter the number of the item to add: ');
                    if idx > 0 && idx <= length(available_items)
                        selected_items{end+1} = available_items{idx};
                        disp([available_items{idx}, ' added.']);
                    else
                        disp('Invalid selection.');
                    end
                end
                
            case 2 % Remove an item
                disp('Currently selected items:');
                if isempty(selected_items)
                    disp('No items to remove.');
                else
                    for i = 1:length(selected_items)
                        fprintf('%d. %s\n', i, selected_items{i});
                    end
                    idx = input('Enter the number of the item to remove: ');
                    if idx > 0 && idx <= length(selected_items)
                        removed_item = selected_items{idx};
                        selected_items(idx) = [];
                        disp([removed_item, ' removed.']);
                    else
                        disp('Invalid selection.');
                    end
                end
                
            case 3 % Finish
                break;
                
            otherwise
                disp('Invalid choice. Please select 1, 2, or 3.');
        end
    end
end


%% Always show middle path
function [corridor_mask, corridor_bounds] = identify_corridor(grid, start_pos, goal_pos)
    corridor_mask = zeros(size(grid));
    corridor_bounds = [];
    
    % Define the range where a corridor is required
    obstacles = (grid == 1);
    vertical_lines = any(obstacles, 2); % Vertical obstacles
    horizontal_lines = any(obstacles, 1); % Horizontal obstacles
    
    % Check for gaps
    [rows, cols] = size(grid);
    for r = 1:rows - 1
        for c = 1:cols - 1
            if obstacles(r, c) && obstacles(r, c+1) && ~obstacles(r+1, c) && ~obstacles(r+1, c+1)
                corridor_bounds = [c + 0.5, r + 0.5, 1, 1]; % Box for 1m gap
                corridor_mask(r:r+1, c:c+1) = 1; % Allow path only within the corridor
                break;
            end
        end
    end
end

%% Check if User is on Path
function is_on_path = isOnPath(current_pos, path, threshold)
    % Calculate distances from current position to all path points
    distances = sqrt(sum((path - current_pos).^2, 2));
    
    % Check if any distance is below the threshold
    is_on_path = any(distances <= threshold);
end