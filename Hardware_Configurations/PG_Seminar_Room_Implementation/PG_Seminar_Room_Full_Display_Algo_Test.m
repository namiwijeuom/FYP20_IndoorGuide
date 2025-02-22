
%% ---------------------- Environment Layout ------------------------------

anchors = [11.5 , 0.25;
           1.5  , 3.25;
           1.5  ,   10;
           11.5 , 11.5];

      
environment  = createEnvironment('PG_Seminar_Room_Inverted.jpg');

%expanded_env = expand_obstacles(environment);

% Plotting the anchor locations
showBaseStations(anchors); 

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
%for i = 1:length(items)
%    plot(item_locations(i,1), item_locations(i,2), 'bo', 'MarkerSize', 8, 'LineWidth', 2); 
%    text(item_locations(i,1) + 0.5, item_locations(i,2), items{i}, 'Color', 'blue');
%end

% Starting position
% For now, the starting position is a predefined position
start_pos = [5, 9];
disp(start_pos);
%plot(start_pos(1), start_pos(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Green for start
%text(start_pos(1), start_pos(2), 'Start', 'Color', 'green');


% Define start and end points for horizontal lines
x1_start = 2.3 ; x1_end = 10.7 ;     y1 = 1; % First horizontal line
x2_start = 2.3   ; x2_end = 10.7  ;  y2 = 8.3; % Second horizontal line


% Define start and end points for vertical lines
y3_start = 1 ; y3_end = 8.3; x3 = 4.9; % First vertical line
y4_start = 1 ; y4_end = 8.3;  x4 = 10.7; % Second vertical line
y5_start = 1 ; y5_end = 8.3; x5 = 2.3; % Third vertical line


% Plot horizontal lines
plot([x1_start, x1_end], [y1, y1], 'b-', 'LineWidth', 2); % First horizontal line
hold on;
plot([x2_start, x2_end], [y2, y2], 'r-', 'LineWidth', 2); % Second horizontal line

% Plot vertical lines
plot([x3, x3], [y3_start, y3_end], 'g-', 'LineWidth', 2); % First vertical line
plot([x4, x4], [y4_start, y4_end], 'm-', 'LineWidth', 2); % Second vertical line
plot([x5, x5], [y5_start, y5_end], 'c-', 'LineWidth', 2); % Second vertical line

%% Input: Specify items to access
input_items = {'Fruits', 'Biscuits', 'Vegetables'}; % Example input
        
%% Plan Path to the Selected Items    
if ~isempty(input_items)
            
            % Optimize the order of the items in the input list according
            % to the start node
            [~, optimized_locations] = optimize_order([start_pos(2),start_pos(1)], ...
                                                        input_items, ...
                                                        items, ...
                                                        item_locations_for_A_Star);
            
            colors = lines(length(input_items)); % Generate unique colors for each path
            
            % Store instructions for popup
            instructions = {}; 

            % Track the items in the optimized sequence
            optimized_items = {}; 
            
            % for i = 1:length(input_items)
            % 
            %     goal_pos = optimized_locations(i+1, :);
            % 
            %     planned_path = A_star_pathfinding(environment, ...
            %                                     [start_pos(2),start_pos(1)], ...
            %                                     goal_pos);
                
                % Build instructions dynamically based on optimized sequence
            %     if i == 1
            %         instructions{end+1} = sprintf('Start at the starting position.');
            %     end
            %     if i < size(optimized_locations, 1) - 1
            %         current_item = items{find(all(item_locations_for_A_Star == optimized_locations(i+1, :), 2))}; % Match location to item
            %         optimized_items{end+1} = current_item;
            %         instructions{end+1} = sprintf('Go to %s next.', current_item);
            %     else
            %         current_item = items{find(all(item_locations_for_A_Star == optimized_locations(i+1, :), 2))}; % Match location to item
            %         optimized_items{end+1} = current_item;
            %         instructions{end+1} = sprintf('Finally, go to %s.', current_item);
            %     end
            % 
            %     if isempty(planned_path)
            %         disp("No path found to " + items{i} + "!");
            %     else
            %         % Plot the planned path
            %         for j = 1:size(planned_path, 1) - 1
            %             plot([planned_path(j, 2), planned_path(j+1, 2)], [planned_path(j, 1), planned_path(j+1, 1)], '-', 'LineWidth', 2, 'Color', colors(i, :));
            %          end
            %         % Update current position
            %         start_pos = [goal_pos(2),goal_pos(1)];
            %     end
            % end
      disp([goal_pos(2),goal_pos(1)]);

      %plot(goal_pos(2), goal_pos(1), 'ro', 'MarkerSize', 10, 'LineWidth', 2); % Red for end
      %text(goal_pos(2), goal_pos(1), 'End', 'Color', 'red');

      % Display the popup message with correct order
    %  msgbox(strjoin(instructions, '\n'), 'Traversal Instructions');
end
%            break;



%% Plot handle initialization
filter_handle  = plot(nan, nan, 'r-', 'LineWidth', 1);
filterpoint_handle = plot(nan, nan, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'black');

%% Initialize history of coordinates
filterXHistory = [];
filterYHistory = [];

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

%% ------------------  Real-time location update --------------------------
try
    while true
        % Read LOC_XY characteristic
        xy_location = read(loc_xy_char);

        % Extract x and y from the byte array (xy_location)
        % First 2 bytes: MSB and LSB of x in cm
        % Next  2 bytes: MSB and LSB of y in cm
        x_cm = double(bitor(bitshift(uint16(xy_location(1)), 8), uint16(xy_location(2))));
        y_cm = double(bitor(bitshift(uint16(xy_location(3)), 8), uint16(xy_location(4))));

        % Convert to meters
        x_m = x_cm / 100; 
        y_m = y_cm / 100;

        % Update marker position (assuming map is in meters)
        filterXHistory(end+1) = x_m;
        filterYHistory(end+1) = y_m;

        % Update EKF path and current location
        set(filter_handle  , 'XData', filterXHistory, 'YData', filterYHistory);
        set(filterpoint_handle , 'XData', x_m, 'YData', y_m);

        drawnow;
        pause(0.1); % Adjust refresh rate as needed
    end
catch ME
    disp("Error or stopped: " + ME.message);
    clear device;
end


%% ----------------------  Helper functions -------------------------------
function pathPoints = A_star_pathfinding(environment, startNode, goalNode)
    % Validate inputs
    % Debug start and goal nodes
    %disp("Start Node: " + mat2str(startNode));
    %disp("Goal Node: " + mat2str(goalNode));
    
    % Check environment value at start and goal nodes
    %disp("Start Node Value: " + num2str(environment(startNode(1), startNode(2))));
    %disp("Goal Node Value: " + num2str(environment(goalNode(1), goalNode(2))));
    
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
