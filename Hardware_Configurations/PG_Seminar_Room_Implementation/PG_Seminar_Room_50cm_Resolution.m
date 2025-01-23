%% Define the grid (with obstacles)
room_length = 12.124; % Length in meters
room_height = 11.64;  % Height in meters
cell_size = 0.5;      % Each cell is 10x10 cm (0.1m x 0.1m)

rows = ceil(room_height / cell_size); % Number of rows
cols = ceil(room_length / cell_size); % Number of columns
grid = zeros(rows, cols); % Initialize the grid

% Define obstacles (scaled for 50 cm resolution)
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

%% Expand obstacles for not going near the obstacle
grid_with_buffer = expand_obstacles(grid);

%% Define items and their locations in the grid (scaled for 50 cm resolution)
items = {'Vegetables', 'Fruits', 'Meat', 'MilkPowder', 'Biscuits'};
item_locations = [20, 2;  % Vegetables
                  2, 12;  % Fruits
                  6, 2;   % Meat
                  11, 13; % Milk Powder
                  20, 22]; % Biscuits

%% Dynamic updates: Add/remove items or obstacles
% Start with an empty list of selected items
selected_items = {}; 

% Dynamic updates: Add/remove items from the predefined list
[selected_items, item_locations] = dynamic_updates(items, item_locations, selected_items);

% Define and plot specific points
start_pos = [4, 5]; % Example start position in grid coordinates

%% Input: Specify items to access
input_items = {'Fruits', 'Meat', 'Vegetables'}; % Example input

%% Optimize the order of visiting items using TSP-like optimization
[start_pos, input_locations] = optimize_order(start_pos, input_items, items, item_locations);

%% Plan the path to access the items in the optimized order
path = [];
path_segments = {}; % Store individual path segments
instructions = {}; % Store instructions for popup
optimized_items = {}; % Track the items in the optimized sequence

for i = 1:size(input_locations, 1) - 1
    sub_path = A_star_pathfinding(grid_with_buffer, input_locations(i, :), input_locations(i+1, :));
    if isempty(sub_path)
        disp('Path not found between some items!');
        break;
    end
    path = [path; sub_path(2:end, :)]; % Append the sub-path, avoiding duplicate start points
    path_segments{i} = sub_path; % Store the segment for visualization

    % Build instructions dynamically based on optimized sequence
    if i == 1
        instructions{end+1} = sprintf('Start at the starting position.');
    end
    if i < size(input_locations, 1) - 1
        current_item = items{find(all(item_locations == input_locations(i+1, :), 2))}; % Match location to item
        optimized_items{end+1} = current_item;
        instructions{end+1} = sprintf('Go to %s next.', current_item);
    else
        current_item = items{find(all(item_locations == input_locations(i+1, :), 2))}; % Match location to item
        optimized_items{end+1} = current_item;
        instructions{end+1} = sprintf('Finally, go to %s.', current_item);
    end
end

%% Display the popup message with correct order
msgbox(strjoin(instructions, '\n'), 'Traversal Instructions');

%% Display the grid and path
figure;
imagesc(grid_with_buffer);
colormap(gray);
axis equal tight;
title('Grid with Obstacles and Path');
xlabel('X (meters)');
ylabel('Y (meters)');

% Adjust axis ticks and labels for 50 cm resolution
xticks(1:1:cols);
xticklabels(arrayfun(@(x) sprintf('%.1f', x * cell_size), xticks, 'UniformOutput', false));
yticks(1:1:rows);
yticklabels(arrayfun(@(y) sprintf('%.1f', y * cell_size), yticks, 'UniformOutput', false));

hold on;

%% Mark item locations
for i = 1:length(items)
    plot(item_locations(i, 2), item_locations(i, 1), 'bo', 'MarkerSize', 8, 'LineWidth', 2); % Blue for items
    text(item_locations(i, 2) + 0.5, item_locations(i, 1), items{i}, 'Color', 'blue');
end

%% Mark the start position
plot(start_pos(2), start_pos(1), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Green for start
text(start_pos(2) + 0.5, start_pos(1), 'Start', 'Color', 'green');

%% Plot the path with distinct colors
Colors = [
    1, 1, 0;   % Red
    0, 1, 0;   % Green
    0, 1, 1;   % Blue
];

for i = 1:length(path_segments)
    segment = path_segments{i};
    for j = 1:size(segment, 1) - 1
        plot([segment(j, 2), segment(j+1, 2)], [segment(j, 1), segment(j+1, 1)], ...
             'Color', Colors(i, :), 'LineWidth', 2);
    end
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
