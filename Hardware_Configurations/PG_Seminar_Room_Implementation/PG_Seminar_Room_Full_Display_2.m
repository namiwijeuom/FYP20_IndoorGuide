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
    anchor_grid_x = round(anchors(i, 1) / cell_size);
    anchor_grid_y = round(anchors(i, 2) / cell_size);
    plot(anchor_grid_x, anchor_grid_y, 'ms', 'MarkerSize', 10, 'MarkerFaceColor', 'red');
    text(anchor_grid_x + 0.5, anchor_grid_y, sprintf('Anchor %d', i), 'Color', 'red');
end

% Mark item locations
for i = 1:length(items)
    plot(item_locations(i, 2), item_locations(i, 1), 'bo', 'MarkerSize', 8, 'LineWidth', 2);
    text(item_locations(i, 2) + 0.5, item_locations(i, 1), items{i}, 'Color', 'blue');
end

title('Grid with Obstacles, Path, and Anchors');
xlabel('X (meters)');
ylabel('Y (meters)');

ekfPath = plot(nan, nan, 'b-', 'LineWidth', 1);
userPoint = plot(nan, nan, 'ro', 'MarkerSize', 5, 'MarkerFaceColor', 'red');

%% Path Planning Initialization
current_goal = [20, 2]; % Initial goal (Vegetables)
current_path = A_star_pathfinding(grid_with_buffer, [1, 1], current_goal);
plot_path(current_path);

disp("Plotting data. Press Ctrl+C to stop.");

try
    while true
        % Read serial data
        data = readline(s);

        % Parse user's current position
        userTokens = regexp(data, 'Current Location : ([\d\.\-]+) X , ([\d\.\-]+) Y', 'tokens');
        if ~isempty(userTokens)
            userX = str2double(userTokens{1}{1});
            userY = str2double(userTokens{1}{2});

            % Update user's position on the grid
            set(userPoint, 'XData', userX, 'YData', userY);

            % Check for path deviation
            if ~is_on_path(current_path, [userX, userY])
                disp('User deviated from the path. Recalculating...');
                current_path = A_star_pathfinding(grid_with_buffer, [userX, userY], current_goal);
                plot_path(current_path);
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
    padding = 0; % 1 cell buffer
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
    openList = [startNode];
    cameFrom = containers.Map();
    gScore = containers.Map();
    fScore = containers.Map();

    key = nodeKey(startNode);
    gScore(key) = 0;
    fScore(key) = heuristic(startNode, goalNode);

    while ~isempty(openList)
        current = getLowestFScore(openList, fScore);

        if isequal(current, goalNode)
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
function plot_path(path)
    plot(path(:, 2), path(:, 1), 'g-', 'LineWidth', 2);
end

function onPath = is_on_path(path, position)
    % Check if the user's position is near the planned path
    distances = sqrt((path(:, 1) - position(1)).^2 + (path(:, 2) - position(2)).^2);
    onPath = any(distances < 0.5); % Threshold for deviation
end

function key = nodeKey(node)
    key = sprintf('%f_%f', node(1), node(2));
end

function lowestNode = getLowestFScore(openList, fScore)
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
    for i = 1:size(openList, 1)
        if isequal(openList(i, :), node)
            openList(i, :) = [];
            break;
        end
    end
end

function inList = inOpenList(openList, node)
    inList = false;
    for i = 1:size(openList, 1)
        if isequal(openList(i, :), node)
            inList = true;
            break;
        end
    end
end

function path = reconstructPath(cameFrom, current)
    path = current;
    while isKey(cameFrom, nodeKey(current))
        current = cameFrom(nodeKey(current));
        path = [current; path];
    end
end

function neighbors = getNeighbors(node, environment)
    potentialMoves = [1 0; -1 0; 0 1; 0 -1];
    neighbors = [];

    for i = 1:size(potentialMoves, 1)
        newNode = node + potentialMoves(i, :);
        if newNode(1) > 0 && newNode(1) <= size(environment, 1) && ...
           newNode(2) > 0 && newNode(2) <= size(environment, 2) && ...
           environment(round(newNode(1)), round(newNode(2))) == 0
            neighbors = [neighbors; newNode];
        end
    end
end

function h = heuristic(node, goalNode)
    h = abs(node(1) - goalNode(1)) + abs(node(2) - goalNode(2));
end
