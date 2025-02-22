
%% ---------------------- Environment Layout ------------------------------
clear; clc; close all;

anchors = [11.71 , 0.50;
           0.00  , 1.70;
           0.70  , 9.44;
           11.21 , 11.64];

      
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
                    11, 7 ]; % Soda

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
                    7, 11 ]; % Soda

% Mark item locations
for i = 1:length(items)
   plot(item_locations(i,1), item_locations(i,2), 'bo', 'MarkerSize', 8, 'LineWidth', 2); 
   text(item_locations(i,1)+0.2, item_locations(i,2), items{i}, 'Color', 'blue');
end

%% Create a UI figure for the map 
% Define normalized position for text (annotation uses normalized coordinates)
textPosition = [0.8, 0.9, 0.1, 0.1]; % [x, y, width, height]

% Create a background box for the text
statusBox = annotation('textbox', textPosition, ...
                       'String', 'Initializing...', ...
                       'FontSize', 12, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', 'y', ...
                       'EdgeColor', 'k', ...
                       'LineWidth', 1.5, ...
                       'HorizontalAlignment', 'center', ...
                       'VerticalAlignment', 'middle');

% Store it properly inside figure UserData
fig.UserData.statusBox = statusBox;

textPositionforNearbyItems = [0.1, 0.1, 0.1, 0.1]; % [x, y, width, height]

% Create a background box for the text
statusBoxforNearbyItems = annotation('textbox', textPositionforNearbyItems, ...
                       'String', 'Nearby Items...', ...
                       'FontSize', 12, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', 'cyan', ...
                       'EdgeColor', 'k', ...
                       'LineWidth', 1.5, ...
                       'HorizontalAlignment', 'center', ...
                       'VerticalAlignment', 'middle');

% Store it properly inside figure UserData
fig.UserData.statusBoxforNearbyItems = statusBoxforNearbyItems;

textPositionforDiscountedItems = [0.1, 0.5, 0.1, 0.1]; % [x, y, width, height]

% Create a background box for the text
statusBoxforDiscountedItems = annotation('textbox', textPositionforDiscountedItems, ...
                       'String', 'Discounts...', ...
                       'FontSize', 12, ...
                       'FontWeight', 'bold', ...
                       'BackgroundColor', 'green', ...
                       'EdgeColor', 'k', ...
                       'LineWidth', 1.5, ...
                       'HorizontalAlignment', 'center', ...
                       'VerticalAlignment', 'middle');

% Store it properly inside figure UserData
fig.UserData.statusBoxforDiscountedItems = statusBoxforDiscountedItems;
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

% Define serial port
port = "COM9"; % Change this if needed
baudRate = 115200; % Adjust baud rate if necessary
s = serialport(port, baudRate);

% Configure terminator for reading lines
configureTerminator(s, "CR");

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
    updateStatus("Locations Updated! Lets Go Shopping!");
    pause(1);

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
                                          goal_pos,item_locations_for_A_Star);
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
            updateStatus("Monitoring the Tag Location");

            % %-
            % % Serial read code here 

            % Read a line of data
            data = readline(s);
    
            % Parse JSON formatted data
            jsonData = jsondecode(data);
    
            % Extract X and Y coordinates
            x_m = str2double(jsonData.X);
            y_m = str2double(jsonData.Y);
    
            % Plot data
            set(filter_handle  , 'XData', filterXHistory, 'YData', filterYHistory);
            set(filterpoint_handle , 'XData', x_m, 'YData', y_m);

            drawnow;

            increment = 0.5; % 50 cm in meters
            new_pos = [round(x_m / increment) * increment, round(y_m / increment) * increment];
            
            %-
            % Simulate getting the current coordinate dynamically
            % x_m = 5; %6.5
            % y_m = 1; %8.3
            % new_pos = [round(x_m + count) ,round(y_m + count)];
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
            %updateStatus("New position: " + mat2str(new_pos));


            %% Check if the position has drifted
            drift_distance = sqrt((new_pos(1) - current_pos(1))^2 + (new_pos(2) - current_pos(2))^2);
            disp("Drift distance: " + num2str(drift_distance));
            %updateStatus("Drift distance: " + num2str(drift_distance));

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
                updateStatus('Re-planning path due to drift...');

                planned_path = A_star_pathfinding(environment, ...
                                                  [new_pos(2), new_pos(1)], ...
                                                  goal_pos,item_locations_for_A_Star);
                current_pos = new_pos; % Update current position

                % Re-plot the updated path
                hold on;
                for j = 1:size(planned_path, 1) - 1
                    h = plot([planned_path(j, 2), planned_path(j+1, 2)], ...
                         [planned_path(j, 1), planned_path(j+1, 1)], ...
                         '-', 'LineWidth', 2, 'Color', colors(i, :));
                    planned_path_segments = [planned_path_segments, h]; % Store segment handle

                end
            end

            %% Check if the tag has reached the goal position
            if isequal(round(new_pos), round([goal_pos(2), goal_pos(1)]))
                disp(['Reached item: ' current_item]);
                updateStatus('Reached Item');

                % Wait for user confirmation to proceed
                choice = questdlg(['Did you collect the item at location ' sprintf('[%d, %d, %s]', goal_pos(2), goal_pos(1),current_item) '?'], ...
                                  'Item Collected', ...
                                  'Yes', 'No', 'Yes');

                if strcmp(choice, 'Yes')
                    % Update the current position to the goal position
                    current_pos = [goal_pos(2),goal_pos(1)];
                    disp(['User confirmed collecting item at location: ' num2str(goal_pos)]);
                    updateStatus(['User Confirmed Collecting ' current_item]);
                    %updateStatusforNearbyItems(['User Confirmed Collecting ' current_item])

                    break; % Move to the next item
                else
                    disp('Waiting for user confirmation...');
                    updateStatus('Waiting for user confirmation...');

                    % Optionally, handle "No" case 
                end
            end
            
            %- 
            % Only for Simulating the movement in the grid
            % count = count + 0.1;
            % disp(count);
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
function pathPoints = A_star_pathfinding(environment, startNode, goalNode, item_locations_for_A_Star)
    % Debug start and goal nodes
    disp("Start Node for A*: " + mat2str(startNode));
    disp("Goal Node for A*: " + mat2str(goalNode));

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

            % Ensure pathPoints is not empty before calling findNearbyItems
            if ~isempty(pathPoints)
                findNearbyItems(pathPoints, item_locations_for_A_Star);
            end
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

function findNearbyItems(path, item_locations)
    % Define discount information
    discounted_items = { 'MilkPowder', 'Rice', 'Snacks', 'Chocolates', 'Grains', 'Bread' }; 
    discount_rates = struct('MilkPowder', 10, 'Rice', 15, 'Snacks', 5, ...
                            'Chocolates', 20, 'Grains', 12, 'Bread', 8);

    % Define proximity threshold
    proximityThreshold = 2.0; % Distance to consider items as "nearby"

    % List of item names
    item_names = { 'Vegetables', 'Fruits', 'Meat', 'Grains', 'Juices', ...
                   'Snacks', 'Fish', 'Bread', 'MilkPowder', 'Rice', ...
                   'Nuts', 'Spices', 'IceCream', 'Chocolates', 'Oil', 'Soda' };

    % Find items near the path
    nearbyItems = [];
    discountedNearbyItems = [];
    discountedItemNames = {};
    discountedPercentages = [];

    for i = 1:size(item_locations, 1)
        itemLocation = item_locations(i, :);
        for j = 1:size(path, 1)
            pathPoint = path(j, :);
            if norm(itemLocation - pathPoint) <= proximityThreshold
                nearbyItems = [nearbyItems; i]; % Store item index

                % Check if the item has a discount
                if ismember(item_names{i}, discounted_items)
                    discountedNearbyItems = [discountedNearbyItems; i];
                    discountedItemNames{end+1} = item_names{i}; % Store name
                    discountedPercentages(end+1) = discount_rates.(item_names{i}); % Store discount
                end
                break;
            end
        end
    end

    % Display nearby items
    if isempty(nearbyItems)
        disp('No nearby items found along the path.');
        updateStatusforNearbyItems('No nearby items');
    else
        nearbyItemNames = item_names(nearbyItems); % Extract item names
        disp('Nearby items along the path:');
        disp(strjoin(nearbyItemNames, ', ')); % Display as comma-separated list
        updateStatusforNearbyItems(nearbyItemNames);
    end

    % Display discounted items with their percentages
    if ~isempty(discountedNearbyItems)
        discountMessages = cellfun(@(name, percent) sprintf('%s (%d%% off)', name, percent), ...
                                    discountedItemNames, num2cell(discountedPercentages), ...
                                    'UniformOutput', false);
        disp('Discounted items nearby:');
        disp(strjoin(discountMessages, ', ')); % Highlight discounted items with percentage
        updateStatusforDiscountedItems(strjoin(discountMessages, ', '));
    else
        disp('No Nearby Items Have Discounts');
        updateStatusforDiscountedItems('No Nearby Items Have Discounts');
    end
end

% Function to update the discounted items list
function updateDiscountedItems(new_discounted_items)
    discounted_items = new_discounted_items;
    disp('Discounted items list updated:');
    disp(strjoin(discounted_items, ', '));
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
function selectedItems = grocerySelectionDialog()
    % Load the database of telephone numbers from a CSV file
    phoneData = readtable('Modified_User_Purchase_History.csv', 'TextType', 'string');
    validNumbers = string(phoneData.PhoneNumber); % Ensure conversion to string
    validNumbers = strtrim(validNumbers); % Trim any spaces

    % Initialize selectedItems as empty
    selectedItems = {};
    listbox = []; % Declare listbox as a persistent variable
    
    % Create a UI figure
    fig = uifigure('Name', 'Grocery Selection', 'Position', [200 200 400 400]);

    % Add a logo to the dialog
    logo = uiimage(fig);
    logo.Position = [150 320 100 50]; % Adjust position [x, y, width, height]
    logo.ImageSource = 'logo.png'; % Provide the path to your logo file

    % Add a label for phone number entry
    lblPhone = uilabel(fig, 'Text', 'Enter Your Telephone Number:');
    lblPhone.Position = [50 250 300 30];
    lblPhone.FontSize = 12;

    % Add an edit field for phone number input
    phoneInput = uieditfield(fig, 'text');
    phoneInput.Position = [50 220 300 30];

    % Add a validate button
    btnValidate = uibutton(fig, 'Text', 'Validate', ...
        'Position', [150 180 100 30], ...
        'ButtonPushedFcn', @(btn, event) validatePhoneNumber());

    % Callback for validate button
    function validatePhoneNumber()
        enteredNumber = strtrim(string(phoneInput.Value)); % Ensure input is string and trimmed
        if any(validNumbers == enteredNumber)
            uialert(fig, 'Phone number validated! Proceed with item selection.', 'Success');
            showItemSelection();
        else
            uialert(fig, 'Invalid phone number. Please try again.', 'Error');
        end
    end

    % Function to display item selection UI
    function showItemSelection()
        % Hide phone validation controls
        lblPhone.Visible = 'off';
        phoneInput.Visible = 'off';
        btnValidate.Visible = 'off';

        % Add a label for the prompt
        lbl = uilabel(fig, 'Text', 'Select the Items You Need:');
        lbl.Position = [50 280 300 30];
        lbl.FontSize = 12;

        % Add a listbox for item selection
        listbox = uilistbox(fig, 'Items', {'Vegetables', 'Fruits', 'Meat', 'Grains', 'Juices', 'Snacks', 'Fish', 'Bread', 'MilkPowder', 'Rice', 'Nuts', 'Spices', 'IceCream', 'Chocolates', 'Oil', 'Soda'}, 'MultiSelect', 'on');
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
    end

    % Callback for confirm button
    function confirmSelection()
        if isempty(listbox)
            uialert(fig, 'No items selected.', 'Error');
            return;
        end
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

    % Pause execution until user action
    uiwait(fig);
end

%% Function to update the status box dynamically
function updateStatus(newMessage)
    fig = gcf; % Get the current figure

    % Debugging: Check if UserData exists
    if isfield(fig.UserData, 'statusBox')
        statusBox = fig.UserData.statusBox;
        if isvalid(statusBox)
            set(statusBox, 'String', newMessage);
            drawnow; % Force UI refresh
        else
            warning('Stored statusBox is invalid. Recreating...');
            recreateStatusBox(fig, newMessage);
        end
    else
        warning('statusBox not found. Recreating...');
        recreateStatusBox(fig, newMessage);
    end
end

% Function to recreate the status box if it is missing
function recreateStatusBox(fig, newMessage)
    textPosition = [0.8, 0.9, 0.1, 0.1]; % Adjust if needed
    newStatusBox = annotation('textbox', textPosition, ...
                              'String', newMessage, ...
                              'FontSize', 12, ...
                              'FontWeight', 'bold', ...
                              'BackgroundColor', 'y', ...
                              'EdgeColor', 'k', ...
                              'LineWidth', 1.5, ...
                              'HorizontalAlignment', 'center', ...
                              'VerticalAlignment', 'middle');
    fig.UserData.statusBox = newStatusBox;
end

%% Status Box for Nearby Items
function updateStatusforNearbyItems(newMessages)
    fig = gcf; % Get the current figure

    % Check if UserData and status box exist
    if isfield(fig.UserData, 'statusBoxforNearbyItems')
        statusBoxforNearbyItems = fig.UserData.statusBoxforNearbyItems;
        if isvalid(statusBoxforNearbyItems)
            % Replace the text with the latest nearby items
            set(statusBoxforNearbyItems, 'String', newMessages);
            drawnow; % Force UI refresh
        else
            warning('Stored statusBox is invalid. Recreating...');
            recreateStatusBoxforNearbyItems(fig, newMessages);
        end
    else
        warning('statusBox not found. Recreating...');
        recreateStatusBoxforNearbyItems(fig, newMessages);
    end
end

function recreateStatusBoxforNearbyItems(fig, newMessages)
    textPosition = [0.1, 0.1, 0.15, 0.15]; % Adjust position and size
    statusBoxforNearbyItems = annotation('textbox', textPosition, ...
                              'String', newMessages, ... % Directly set the new messages
                              'FontSize', 12, ...
                              'FontWeight', 'bold', ...
                              'BackgroundColor', 'cyan', ...
                              'EdgeColor', 'k', ...
                              'LineWidth', 1.5, ...
                              'HorizontalAlignment', 'left', ...
                              'VerticalAlignment', 'top'); % Align to top
    fig.UserData.statusBoxforNearbyItems = statusBoxforNearbyItems;
end

%% Status Box for Discounted Items
function updateStatusforDiscountedItems(newMessages)
    fig = gcf; % Get the current figure

    % Check if UserData and status box exist
    if isfield(fig.UserData, 'statusBoxforDiscountedItems')
        statusBoxforDiscountedItems = fig.UserData.statusBoxforDiscountedItems;
        if isvalid(statusBoxforDiscountedItems)
            % Replace the text with the latest nearby items
            set(statusBoxforDiscountedItems, 'String', newMessages);
            drawnow; % Force UI refresh
        else
            warning('Stored statusBox is invalid. Recreating...');
            recreateStatusBoxforDiscountedItems(fig, newMessages);
        end
    else
        warning('statusBox not found. Recreating...');
        recreateStatusBoxforDiscountedItems(fig, newMessages);
    end
end

function recreateStatusBoxforDiscountedItems(fig, newMessages)
    textPosition = [0.1, 0.5, 0.15, 0.15]; % Adjust position and size
    statusBoxforDiscountedItems = annotation('textbox', textPosition, ...
                              'String', newMessages, ... % Directly set the new messages
                              'FontSize', 12, ...
                              'FontWeight', 'bold', ...
                              'BackgroundColor', 'green', ...
                              'EdgeColor', 'k', ...
                              'LineWidth', 1.5, ...
                              'HorizontalAlignment', 'left', ...
                              'VerticalAlignment', 'top'); % Align to top
    fig.UserData.statusBoxforDiscountedItems = statusBoxforDiscountedItems;
end