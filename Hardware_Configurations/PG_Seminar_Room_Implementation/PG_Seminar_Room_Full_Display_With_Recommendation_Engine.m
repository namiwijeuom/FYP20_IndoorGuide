
%% ---------------------- Environment Layout ------------------------------
clear; clc; close all;

anchors = [11.5 , 0.25;
           1.5  , 3.25;
           1.5  ,   10;
           11.5 , 11.5];

      
environment  = createEnvironment('PG_Seminar_Room_Inverted.jpg');

%expanded_env = expand_obstacles(environment);

% Plotting the anchor locations
showBaseStations(anchors); 

% Define items and their locations
items = {'Vegetables', 'Fruits', 'Meat', 'Grains','Juices', 'Snacks', 'Fish', 'Bread','MilkPowder', 'Rice', 'Nuts', 'Spices','IceCream', 'Chocolates', 'Oil', 'Soda'};

item_locations = [  10, 9; % Vegetables
                    2, 8 ; % Fruits
                    3, 5 ; % Meat
                    6, 7 ; % Grains
                    10, 1 ; % Juices
                    5, 10 ; % Snacks
                    0, 5 ; % Fish
                    8, 8 ; % Bread
                    11, 3; % MilkPowder
                    1, 11 ; % Rice
                    1, 2; % Nuts
                    3, 11; % Spices
                    6, 3; % IceCream
                    9, 5; % Chocolates
                    4, 1; % Oil
                    12, 7 ]; % Soda

item_locations_for_A_Star = [  9, 10; % Vegetables
                    8, 2 ; % Fruits
                    5, 3 ; % Meat
                    7, 6 ; % Grains
                    1, 10 ; % Juices
                    10, 5 ; % Snacks
                    5, 0 ; % Fish
                    8, 8 ; % Bread
                    3, 11; % MilkPowder
                    11, 1 ; % Rice
                    2, 1; % Nuts
                    11, 3; % Spices
                    3, 6; % IceCream
                    5, 9; % Chocolates
                    1, 4; % Oil
                    7, 12 ]; % Soda

% Mark item locations
for i = 1:length(items)
   plot(item_locations(i,1), item_locations(i,2), 'bo', 'MarkerSize', 8, 'LineWidth', 2); 
   text(item_locations(i,1)+0.2, item_locations(i,2), items{i}, 'Color', 'blue');
end

%% Only for Simulation purpose
count = 0;

%% Reference Lines
% Define start and end points for horizontal lines
x1_start = 2.3 ; x1_end = 10.7 ;     y1 = 1; % First horizontal line
x2_start = 2.3   ; x2_end = 10.7  ;  y2 = 8.3; % Second horizontal line

% Define start and end points for vertical lines
y3_start = 1 ; y3_end = 8.3; x3 = 4.9; % First vertical line
y4_start = 1 ; y4_end = 8.3;  x4 = 10.7; % Second vertical line
y5_start = 1 ; y5_end = 8.3; x5 = 2.3; % Third vertical line

% Plot horizontal lines
plot([x1_start, x1_end], [y1, y1], 'black', 'LineWidth', 1,'LineStyle','--'); % First horizontal line
hold on;
plot([x2_start, x2_end], [y2, y2], 'black', 'LineWidth', 1,'LineStyle','--'); % Second horizontal line

% Plot vertical lines
plot([x3, x3], [y3_start, y3_end], 'black', 'LineWidth', 1,'LineStyle','--'); % First vertical line
plot([x4, x4], [y4_start, y4_end], 'black', 'LineWidth', 1,'LineStyle','--'); % Second vertical line
plot([x5, x5], [y5_start, y5_end], 'black', 'LineWidth', 1,'LineStyle','--'); % Second vertical line

%% Input: Specify items to access
input_items = grocerySelectionDialog();
disp('You selected:');
disp(input_items);

%% -----------------------  Initialize BLE connection ---------------------

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

%% Plot handle Initialization
filter_handle  = plot(nan, nan, 'r-', 'LineWidth', 1);
filterpoint_handle = plot(nan, nan, 'ko', 'MarkerSize', 5, 'MarkerFaceColor', 'black');

%% Other Initialization Parameters 
filterXHistory = [];
filterYHistory = [];

planned_path_segments = [];
planned_path_segments_initial = [];
current_pos_handle = [];

%% Set the acceptable drift threshold (1 meter)
drift_threshold = 1.0;

%% Initialize the current position
% For now, the starting position is a predefined position
start_pos = [5, 1];
disp(start_pos);

plot(start_pos(1), start_pos(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Green for start
text(start_pos(1), start_pos(2), 'Start', 'Color', 'green');

current_pos = start_pos;

if ~isempty(input_items)
    %% Optimize the order of the items in the input list
    [~, optimized_locations] = optimize_order([start_pos(2),start_pos(1)], ...
                                               input_items, ...
                                               items, ...
                                               item_locations_for_A_Star);
    disp("Optimized Locations:" + num2str(optimized_locations));
    colors = lines(length(input_items)); % Generate unique colors for each path

    %% Initialize instructions and optimized items
    instructions = {};
    optimized_items = {};

    for i = 1:length(input_items)
        % Goal position for the current item
        goal_pos = optimized_locations(i+1, :);

        % Initial planned path
        planned_path = A_star_pathfinding(environment, ...
                                          [current_pos(2), current_pos(1)], ...
                                          goal_pos);
        disp("test_point_1");

        % Find the matching item
        matching_index = find(all(item_locations_for_A_Star == optimized_locations(i+1, :), 2));
        if isempty(matching_index)
            warning('No matching item found for location [%d, %d]. Skipping.', goal_pos(1), goal_pos(2));
            continue;
        elseif length(matching_index) > 1
            error('Multiple items found for location [%d, %d]. Check your item data.', goal_pos(1), goal_pos(2));
        else
            current_item = items{matching_index};
            optimized_items{end+1} = current_item;

            % Create instructions dynamically
            if i == 1
                instructions{end+1} = sprintf('Here is Your Summary!');
            end
    
            if i < size(optimized_locations, 1) - 1
                instructions{end+1} = sprintf('You got %s .', current_item);
            else
                instructions{end+1} = sprintf('Finally, you got %s.', current_item);
                sprintf('Please Proceed to the Cashier');
                sprintf('Thank You!');
            end
        end

        % Plot the initial path
        for j = 1:size(planned_path, 1) - 1
            h = plot([planned_path(j, 2), planned_path(j+1, 2)], ...
                 [planned_path(j, 1), planned_path(j+1, 1)], ...
                 '-', 'LineWidth', 2, 'Color', colors(i, :));
            planned_path_segments = [planned_path_segments, h]; % Store segment handle

        end

        %% Monitor current position and check for drift
        while true
            %new_pos = get_current_position(start_pos);
            disp("Monitoring the Tag Location");
            % %-
            % % Add the BLE coordinate read code here 
            % 
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
            % filterXHistory(end+1) = x_m;
            % filterYHistory(end+1) = y_m;
            % 
            % % Update EKF path and current location
            % set(filter_handle  , 'XData', filterXHistory, 'YData', filterYHistory);
            % set(filterpoint_handle , 'XData', x_m, 'YData', y_m);
            % 
            % drawnow;
            % 
            % %new_pos = [round(x_m),round(y_m)];
            % increment = 0.5; % 50 cm in meters
            % new_pos = [round(x_m / increment) * increment, round(y_m / increment) * increment];
            %-
            
            %-
            % Simulate getting the current coordinate dynamically
            x_m = 5; %6.5
            y_m = 1; %8.3
            new_pos = [round(x_m + count) ,round(y_m + count)];
            %-

            % Update the current position marker
            if isempty(current_pos_handle) || ~isvalid(current_pos_handle)
                % Plot the current position for the first time
                current_pos_handle = plot(new_pos(1), new_pos(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
            else
                % Update the marker's position
                set(current_pos_handle, 'XData', new_pos(1), 'YData', new_pos(2));
            end
            
            disp("New position:" + mat2str(new_pos));

            %% Check if the position has drifted
            drift_distance = sqrt((new_pos(1) - current_pos(1))^2 + (new_pos(2) - current_pos(2))^2);
            disp("Drift distance: " + num2str(drift_distance));

            if drift_distance >= drift_threshold
                % Re-plan the path from the new position to the goal

                % Remove the previous planned path if it exists
                if ~isempty(planned_path_segments)
                    % Delete all previous path segments
                    for seg = planned_path_segments
                        if isvalid(seg)
                            delete(seg);
                        end
                    end
                    planned_path_segments = []; % Reset path segment handles
                end

                disp('Re-planning path due to drift...');
                planned_path = A_star_pathfinding(environment, ...
                                                  [new_pos(2), new_pos(1)], ...
                                                  goal_pos);
                current_pos = new_pos; % Update current position

                % Re-plot the updated path
                hold on;
                for j = 1:size(planned_path, 1) - 1
                    h = plot([planned_path(j, 2), planned_path(j+1, 2)], ...
                         [planned_path(j, 1), planned_path(j+1, 1)], ...
                         '-', 'LineWidth', 2, 'Color', colors(i, :));
                    planned_path_segments = [planned_path_segments, h]; % Store segment handle

                end

                % Highlight the current goal position
                %plot(goal_pos(2), goal_pos(1), 'ro', 'MarkerSize', 10, 'LineWidth', 2); % Mark item position
                %text(goal_pos(2), goal_pos(1), sprintf('Item %d', i), 'Color', 'red');
            
            % elseif drift_distance == 0
            %     disp(['Reached item: ' current_item]);
            % 
            %     % Wait for user confirmation to proceed
            %     choice = questdlg(['Did you collect the item at location ' sprintf('[%d, %d, %s]', goal_pos(2), goal_pos(1),current_item) '?'], ...
            %                       'Item Collected', ...
            %                       'Yes', 'No', 'Yes');
            % 
            %     if strcmp(choice, 'Yes')
            %         % Update the current position to the goal position
            %         current_pos = [goal_pos(2),goal_pos(1)];
            %         disp(['User confirmed collecting item at location: ' num2str(goal_pos)]);
            %         break; % Move to the next item
            %     else
            %         disp('Waiting for user confirmation...');
            %         % Optionally, handle "No" case here if needed
            %     end
                
            end

            %% Check if the tag has reached the goal position
            if isequal(round(new_pos), round([goal_pos(2), goal_pos(1)]))
                disp(['Reached item: ' current_item]);

                % Wait for user confirmation to proceed
                choice = questdlg(['Did you collect the item at location ' sprintf('[%d, %d, %s]', goal_pos(2), goal_pos(1),current_item) '?'], ...
                                  'Item Collected', ...
                                  'Yes', 'No', 'Yes');

                if strcmp(choice, 'Yes')
                    % Update the current position to the goal position
                    current_pos = [goal_pos(2),goal_pos(1)];
                    disp(['User confirmed collecting item at location: ' num2str(goal_pos)]);
                    break; % Move to the next item
                else
                    disp('Waiting for user confirmation...');
                    % Optionally, handle "No" case here if needed
                end
            end
            
            %- 
            % Only for Simulating the movement in the grid
            count = count + 0.1;
            disp(count);
            %-

            % Pause briefly to simulate live data processing
            pause(0.1);

        end
    end

    %% Display the summary
    msgbox(strjoin(instructions, '\n'), 'Traversal Instructions');
    clear device;
end

%clear device;
%% ------------------  A* Algorithm and Helper functions ------------------
function pathPoints = A_star_pathfinding(environment, startNode, goalNode)
    % Validate inputs
    % Debug start and goal nodes
    disp("Start Node for A*: " + mat2str(startNode));
    disp("Goal Node for A*: " + mat2str(goalNode));
    
    % Check environment value at start and goal nodes
    %disp("Start Node Value: " + num2str(environment(startNode(1), startNode(2))));
    %disp("Goal Node Value: " + num2str(environment(goalNode(1), goalNode(2))));
    
    % [rows, cols] = size(environment);
    % if startNode(1) < 1 || startNode(1) > rows || startNode(2) < 1 || startNode(2) > cols || ...
    %    goalNode(1) < 1 || goalNode(1) > rows || goalNode(2) < 1 || goalNode(2) > cols
    %     error('Start or goal node is out of bounds!');
    % end
    % if environment(round(startNode(1)), round(startNode(2))) == 1
    %     error('Start node is in an obstacle!');
    %     %continue;
    % end
    % if environment(round(goalNode(1)), round(goalNode(2))) == 1
    %     error('Goal node is in an obstacle!');
    % end

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
        neighbors = getNeighbors(round(current), environment);
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

%% -------- Optimize The Item Order using nearest neighbor heuristic-------
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


%% User Input Dialog Box
% % Create a dialog box with customized appearance
% [selectedIndices, ok] = listdlg('PromptString', {'Select the items you need:', '', 'Hold Ctrl to select multiple items'}, ...
%                                 'SelectionMode', 'multiple', ...
%                                 'ListString', items, ...
%                                 'Name', 'Grocery Selection', ...
%                                 'ListSize', [300, 200], ...  % Set size of the dialog
%                                 'OKString', 'Confirm', ...  % Change OK button text
%                                 'CancelString', 'Dismiss'); % Change Cancel button text
% 
% % Check if the user pressed OK
% if ok
%     % Get the selected items
%     input_items = items(selectedIndices);
%     disp('You selected:');
%     disp(input_items);
% else
%     disp('No items were selected.');
% end
function selectedItems = grocerySelectionDialog()
    % Define your items for selection
    items = {'Vegetables', 'Fruits', 'Meat', 'Grains','Juices', 'Snacks', 'Fish', 'Bread','MilkPowder', 'Rice', 'Nuts', 'Spices','IceCream', 'Chocolates', 'Oil', 'Soda'};

    % Create a UI figure
    fig = uifigure('Name', 'Grocery Selection', 'Position', [200 200 400 400]);

    % Add a logo to the dialog
    logo = uiimage(fig);
    logo.Position = [150 320 100 50]; % Adjust position [x, y, width, height]
    logo.ImageSource = 'logo.png'; % Provide the path to your logo file

    % Add a label for the prompt
    lbl = uilabel(fig, 'Text', 'Select the Items You Need:');
    lbl.Position = [50 280 300 30];
    lbl.FontSize = 12;

    % Add a listbox for item selection
    listbox = uilistbox(fig, 'Items', items, 'MultiSelect', 'on');
    listbox.Position = [50 100 300 150];
    listbox.FontSize = 12;

    % Add a confirmation button
    btnConfirm = uibutton(fig, 'Text', 'Confirm', ...
        'Position', [100 40 100 30], ...
        'ButtonPushedFcn', @(btn, event) confirmSelection());

    % Add a dismissal button
    btnDismiss = uibutton(fig, 'Text', 'Dismiss', ...
        'Position', [200 40 100 30], ...
        'ButtonPushedFcn', @(btn, event) dismissDialog());

    % Initialize selectedItems as empty
    selectedItems = {};

    % Pause execution until user action
    uiwait(fig);

    % Callback for confirm button
    function confirmSelection()
        selectedItems = listbox.Value; % Get the selected items
        uiresume(fig); % Resume execution
        delete(fig); % Close the dialog
    end

    % Callback for dismiss button
    function dismissDialog()
        selectedItems = {}; % Set selectedItems to empty
        uiresume(fig); % Resume execution
        delete(fig); % Close the dialog
    end
end
