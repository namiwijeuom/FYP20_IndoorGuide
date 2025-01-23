
% ---------------------- Environment Layout ------------------------

anchors = [11.5 , 0.25;
           1.5  , 3.25;
           1.5  ,   10;
           11.5 , 11.5];

      
environment  = createEnvironment('PG_Seminar_Room_Inverted.jpg');

%expanded_env = expand_obstacles(environment);

showBaseStations(anchors); % plotting anchor locations

% Define items and their locations
items = {'Vegetables', 'Fruits', 'Meat', 'MilkPowder', 'Biscuits'};
item_locations = [7 , 8; 
                  2 ,10; 
                  6 , 2; 
                  11, 5; 
                  7 ,4];
item_locations_for_A_Star = [   8 , 7; 
                                10 ,2; 
                                2 , 6; 
                                5, 11; 
                                4 , 7    ];
% Mark item locations
for i = 1:length(items)
    plot(item_locations(i,1), item_locations(i,2), 'bo', 'MarkerSize', 8, 'LineWidth', 2); 
    text(item_locations(i,1) + 0.5, item_locations(i,2), items{i}, 'Color', 'blue');
end

start_pos = [2, 11];
goal_pos = [7,4];
plot(start_pos(1), start_pos(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Green for start
text(start_pos(1), start_pos(2), 'Start', 'Color', 'green');

plot(goal_pos(1), goal_pos(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2); % Red for end
text(goal_pos(1), goal_pos(2), 'End', 'Color', 'red');

%% Input: Specify items to access
input_items = {'Fruits', 'Meat', 'Vegetables'}; % Example input

%% Plot handle initialization
ekfpath_handle  = plot(nan, nan, 'r-', 'LineWidth', 1);
ekfpoint_handle = plot(nan, nan, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'black');

%% Initialize history of coordinates
ekfXHistory = [];
ekfYHistory = [];

%% ------------------  Initialize BLE connection ------------------

% deviceName = "00:80:E1:27:9A:83";    % Replace with your BLE device name or address
% disp("Scanning for BLE devices...");
% device = ble(deviceName);            % Connect to the BLE device
% disp("Connected to BLE device.");
% 
% service_uuid         = "0000fe40-cc7a-482a-984a-7f2ed5b3e58f";  
% characteristic_uuid  = "0000fe41-8e22-4541-9d4c-21edae82ed19";
% 
% % characteristics for LOC_XY
% loc_xy_char = characteristic(device, service_uuid, characteristic_uuid);

%% ------------------  Real-time location update -------------------
try
    while true
        % % Read LOC_XY characteristic
        % xy_location = read(loc_xy_char);
        % 
        % % Extract x and y from the byte array (xy_location)
        % % First 2 bytes: MSB and LSB of x in cm
        % % Next  2 bytes: MSB and LSB of y in cm
        % x_cm = double(bitor(bitshift(uint16(xy_location(1)), 8), uint16(xy_location(2))));
        % y_cm = double(bitor(bitshift(uint16(xy_location(3)), 8), uint16(xy_location(4))));
        % 
        % % Convert to meters
        % x_m = x_cm / 100; 
        % y_m = y_cm / 100;
        % 
        % % Update marker position (assuming map is in meters)
        % ekfXHistory(end+1) = x_m;
        % ekfYHistory(end+1) = y_m;
        % 
        % % Update EKF path and current location
        % set(ekfpath_handle  , 'XData', ekfXHistory, 'YData', ekfYHistory);
        % set(ekfpoint_handle , 'XData', x_m, 'YData', y_m);

        % Plan Path to Next Item if Items Are Selected
        selected_items = input_items;
        if ~isempty(selected_items)
            % Get the current EKF position as the starting point
            %start_pos = approximateToMidpoint([x_m, y_m]);
            disp(start_pos);
            disp(goal_pos);
            % [~, optimized_locations] = optimize_order(start_pos, selected_items, items, item_locations);

            % Calculate path to the next item
            planned_path = A_star_pathfinding(environment, [start_pos(2),start_pos(1)], [goal_pos(2),goal_pos(1)]);
            
            if isempty(planned_path)
                disp("No path found!");
            end
            
            % Plot the planned path
            for i = 1:size(planned_path, 1) - 1
                plot([planned_path(i, 2), planned_path(i+1, 2)], [planned_path(i, 1), planned_path(i+1, 1)], 'g-', 'LineWidth', 2);
            end

            % Remove the visited item from the list
            selected_items(1) = [];
        end

        drawnow;
        pause(0.1); % Adjust refresh rate as needed
    end
catch ME
    disp("Error or stopped: " + ME.message);
    clear device;
end


%% ------------------  Helper functions -------------------------
function pathPoints = A_star_pathfinding(environment, startNode, goalNode)
    % Validate inputs
    % Debug start and goal nodes
    disp("Start Node: " + mat2str(startNode));
    disp("Goal Node: " + mat2str(goalNode));
    
    % Check environment value at start and goal nodes
    disp("Start Node Value: " + num2str(environment(startNode(1), startNode(2))));
    disp("Goal Node Value: " + num2str(environment(goalNode(1), goalNode(2))));
    
    [rows, cols] = size(environment);
    if startNode(1) < 1 || startNode(1) > rows || startNode(2) < 1 || startNode(2) > cols || ...
       goalNode(1) < 1 || goalNode(1) > rows || goalNode(2) < 1 || goalNode(2) > cols
        error('Start or goal node is out of bounds!');
    end
    if environment(startNode(1), startNode(2)) == 1
        error('Start node is in an obstacle!');
    end
    if environment(goalNode(1), goalNode(2)) == 1
        error('Goal node is in an obstacle!');
    end

    % A* variables
    openList = startNode; % Nodes to be evaluated
    cameFrom = containers.Map(); % Tracks the path
    gScore = containers.Map(); % Cost from start to node
    fScore = containers.Map(); % Estimated total cost (gScore + heuristic)
    nodeKey = @(node) sprintf('%d,%d', node(1), node(2)); % Create a unique key

    % Initialize start node
    startKey = nodeKey(startNode);
    gScore(startKey) = 0;
    fScore(startKey) = heuristic(startNode, goalNode);

    while ~isempty(openList)
        % Get node with lowest fScore
        current = getLowestFScore(openList, fScore, nodeKey);
        if isequal(current, goalNode)
            % Reconstruct and return the path
            pathPoints = reconstructPath(cameFrom, current, nodeKey);
            return;
        end

        % Remove current node from open list
        openList = removeFromOpenList(openList, current);

        % Get neighbors
        neighbors = getNeighbors(current, environment);
        currentKey = nodeKey(current);
        for i = 1:size(neighbors, 1)
            neighbor = neighbors(i, :);
            neighborKey = nodeKey(neighbor);

            % Tentative gScore
            tentative_gScore = gScore(currentKey) + 1;

            if ~isKey(gScore, neighborKey) || tentative_gScore < gScore(neighborKey)
                % Update path and scores
                cameFrom(neighborKey) = current;
                gScore(neighborKey) = tentative_gScore;
                fScore(neighborKey) = tentative_gScore + heuristic(neighbor, goalNode);

                % Add neighbor to open list if not already there
                if ~inOpenList(openList, neighbor)
                    openList = [openList; neighbor];
                end
            end
        end
    end

    % No path found
    pathPoints = [];
    disp('No path found!');
end

function h = heuristic(node, goal)
    % Manhattan distance heuristic
    h = abs(node(1) - goal(1)) + abs(node(2) - goal(2));
end

function neighbors = getNeighbors(node, environment)
    % Get valid neighbors around the node
    [rows, cols] = size(environment);
    potentialNeighbors = [
        node(1)-1, node(2); % Up
        node(1)+1, node(2); % Down
        node(1), node(2)-1; % Left
        node(1), node(2)+1  % Right
    ];
    neighbors = [];
    for i = 1:size(potentialNeighbors, 1)
        r = potentialNeighbors(i, 1);
        c = potentialNeighbors(i, 2);
        if r > 0 && r <= rows && c > 0 && c <= cols && environment(r, c) == 0
            neighbors = [neighbors; r, c];
        end
    end
end

function lowestNode = getLowestFScore(openList, fScore, nodeKey)
    % Get the node with the lowest fScore from the open list
    lowestScore = Inf;
    lowestNode = [];
    for i = 1:size(openList, 1)
        key = nodeKey(openList(i, :));
        if isKey(fScore, key) && fScore(key) < lowestScore
            lowestScore = fScore(key);
            lowestNode = openList(i, :);
        end
    end
end

function updatedList = removeFromOpenList(openList, node)
    % Remove the specified node from the open list
    updatedList = openList(~ismember(openList, node, 'rows'), :);
end

function inList = inOpenList(openList, node)
    % Check if a node is in the open list
    inList = any(ismember(openList, node, 'rows'));
end

function pathPoints = reconstructPath(cameFrom, current, nodeKey)
    % Reconstruct the path from start to goal
    pathPoints = current;
    while isKey(cameFrom, nodeKey(current))
        current = cameFrom(nodeKey(current));
        pathPoints = [current; pathPoints];
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
