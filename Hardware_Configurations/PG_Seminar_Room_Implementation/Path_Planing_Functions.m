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