% Room dimensions (in meters)
room_length = 12.124; % Length in meters
room_height = 11.64;  % Height in meters
cell_size = 0.1;      % Each cell is 10x10 cm (0.1m x 0.1m)

% Calculate grid size
rows = ceil(room_height / cell_size); % Number of rows
cols = ceil(room_length / cell_size); % Number of columns

% Initialize the grid
grid = zeros(rows, cols);

% Define obstacles (manual positioning based on the map)
% Stage (yellow area at top-right)
grid(1:20, 60:120) = 1; % Approximate position for the stage

% Racks (blue and green areas)
grid(10:28, 1:19) = 1;    % Rack 01
grid(10:27, 28:44) = 1;   % Rack 02
grid(40:58, 1:19) = 1;   % Rack 03
grid(40:58, 28:44) = 1;  % Rack 04
grid(68:86, 1:19) = 1;   % Rack 05
grid(72:89, 28:44) = 1;  % Rack 06
grid(104:112, 1:19) = 1;   % Rack 07
%grid(110:118, 90:98) = 1; % Rack 08

% Define brown blocks (manual positioning based on the map)
grid(56:61, 60:65) = 1;  % Brown block 1
grid(56:61, 115:120) = 1;  % Brown block 2
grid(113:118, 60:65) = 1;  % Brown block 3
grid(113:118, 115:120) = 1; % Brown block 4

% Display the grid
figure;
imagesc(grid);
colormap(gray);
axis equal tight;
title('PG Seminar Room');
xlabel('X (meters)');
ylabel('Y (meters)');

% Adjust axis ticks and labels to show values in meters
xticks(1:10:cols);
xticklabels(arrayfun(@(x) sprintf('%.1f', x * cell_size), xticks, 'UniformOutput', false));
yticks(1:10:rows);
yticklabels(arrayfun(@(y) sprintf('%.1f', y * cell_size), yticks, 'UniformOutput', false));

% Define and plot specific points
start_pos = [20, 25]; % Example start position in grid coordinates
goal_pos = [100, 100]; % Example goal position in grid coordinates

% Convert grid coordinates to [x, y] meters
start_xy = [(start_pos(2) ) * cell_size, (start_pos(1)) * cell_size];
goal_xy = [(goal_pos(2) ) * cell_size, (goal_pos(1)) * cell_size];

% Plot start and goal points
hold on;
plot(start_pos(2), start_pos(1), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Start point
text(start_pos(2) + 1, start_pos(1), sprintf('[%.1f, %.1f]', start_xy(1), start_xy(2)), 'Color', 'green');

plot(goal_pos(2), goal_pos(1), 'ro', 'MarkerSize', 10, 'LineWidth', 2); % Goal point
text(goal_pos(2) + 1, goal_pos(1), sprintf('[%.1f, %.1f]', goal_xy(1), goal_xy(2)), 'Color', 'red');

% Call A* function
path = a_star_algorithm(grid, start_pos, goal_pos);

% Plot the path
if ~isempty(path)
    for i = 1:length(path)-1
        plot([path(i,2), path(i+1,2)], [path(i,1), path(i+1,1)], 'r', 'LineWidth', 2);
    end
else
    disp('No path found!');
end

%% Function for A* Algorithm

% Function for A* Algorithm
function path = a_star_algorithm(grid, start_pos, goal_pos)
    % Expand obstacles to maintain at least 10 cm distance
    grid_with_buffer = expand_obstacles(grid);
    
    % Initialize open and closed lists
    open_list = [];
    closed_list = zeros(size(grid_with_buffer));
    parent = zeros(size(grid_with_buffer, 1), size(grid_with_buffer, 2), 2); % To store parent cells
    
    % Heuristic function (Manhattan distance)
    heuristic = @(pos) abs(pos(1) - goal_pos(1)) + abs(pos(2) - goal_pos(2));
    
    % Cost from start
    g_cost = zeros(size(grid_with_buffer)) + Inf;
    g_cost(start_pos(1), start_pos(2)) = 0;
    
    % Total cost
    f_cost = zeros(size(grid_with_buffer)) + Inf;
    f_cost(start_pos(1), start_pos(2)) = heuristic(start_pos);
    
    % Add start position to open list
    open_list = [start_pos, f_cost(start_pos(1), start_pos(2))];
    
    % Define movement directions (up, down, left, right)
    directions = [0, 1; 1, 0; 0, -1; -1, 0];
    
    while ~isempty(open_list)
        % Find the cell with the lowest f_cost
        [~, idx] = min(open_list(:, 3));
        current = open_list(idx, 1:2);
        open_list(idx, :) = [];
        
        % Check if goal is reached
        if isequal(current, goal_pos)
            % Reconstruct path
            path = [];
            while ~isequal(current, start_pos)
                path = [current; path];
                current = squeeze(parent(current(1), current(2), :))';
            end
            path = [start_pos; path];
            return;
        end
        
        % Mark current node as visited
        closed_list(current(1), current(2)) = 1;
        
        % Explore neighbors
        for i = 1:size(directions, 1)
            neighbor = current + directions(i, :);
            
            % Check bounds and obstacle
            if neighbor(1) < 1 || neighbor(1) > size(grid_with_buffer, 1) || ...
               neighbor(2) < 1 || neighbor(2) > size(grid_with_buffer, 2) || ...
               grid_with_buffer(neighbor(1), neighbor(2)) == 1 || ...
               closed_list(neighbor(1), neighbor(2)) == 1
                continue;
            end
            
            % Calculate g_cost for neighbor
            tentative_g_cost = g_cost(current(1), current(2)) + 1;
            
            % Check if this path is better
            if tentative_g_cost < g_cost(neighbor(1), neighbor(2))
                parent(neighbor(1), neighbor(2), :) = current;
                g_cost(neighbor(1), neighbor(2)) = tentative_g_cost;
                f_cost(neighbor(1), neighbor(2)) = tentative_g_cost + heuristic(neighbor);
                
                % Add neighbor to open list if not already there
                if isempty(open_list) || ~ismember(neighbor, open_list(:, 1:2), 'rows')
                    open_list = [open_list; neighbor, f_cost(neighbor(1), neighbor(2))];
                end
            end
        end
    end
    
    % If no path is found
    path = [];
end

% Function to expand obstacles (buffer zone around obstacles in both x and y directions)
function expanded_grid = expand_obstacles(grid)
    % Create a padded grid to handle edge cases
    padding = 2; % x0 cm corresponds to x cells (10 cm per cell)
    padded_grid = padarray(grid, [padding, padding], 0, 'both'); % Pad by 2 cells
    
    % Initialize expanded grid
    expanded_grid = grid;
    
    % Iterate through the original grid with padding
    for row = padding + 1:size(padded_grid, 1) - padding
        for col = padding + 1:size(padded_grid, 2) - padding
            % If the current cell is an obstacle, mark neighbors in the expanded grid
            if padded_grid(row, col) == 1
                expanded_grid(row-padding:row+padding, col-padding:col+padding) = 1;
            end
        end
    end
end


function path = a_star_algorithm_initial(grid, start_pos, goal_pos)
    % Initialize open and closed lists
    open_list = [];
    closed_list = zeros(size(grid));
    parent = zeros(size(grid, 1), size(grid, 2), 2); % To store parent cells
    
    % Heuristic function (Manhattan distance)
    heuristic = @(pos) abs(pos(1) - goal_pos(1)) + abs(pos(2) - goal_pos(2));
    
    % Cost from start
    g_cost = zeros(size(grid)) + Inf;
    g_cost(start_pos(1), start_pos(2)) = 0;
    
    % Total cost
    f_cost = zeros(size(grid)) + Inf;
    f_cost(start_pos(1), start_pos(2)) = heuristic(start_pos);
    
    % Add start position to open list
    open_list = [start_pos, f_cost(start_pos(1), start_pos(2))];
    
    % Define movement directions (up, down, left, right)
    directions = [0, 1; 1, 0; 0, -1; -1, 0];
    
    while ~isempty(open_list)
        % Find the cell with the lowest f_cost
        [~, idx] = min(open_list(:, 3));
        current = open_list(idx, 1:2);
        open_list(idx, :) = [];
        
        % Check if goal is reached
        if isequal(current, goal_pos)
            % Reconstruct path
            path = [];
            while ~isequal(current, start_pos)
                path = [current; path];
                current = squeeze(parent(current(1), current(2), :))';
            end
            path = [start_pos; path];
            return;
        end
        
        % Mark current node as visited
        closed_list(current(1), current(2)) = 1;
        
        % Explore neighbors
        for i = 1:size(directions, 1)
            neighbor = current + directions(i, :);
            
            % Check bounds and obstacle
            if neighbor(1) < 1 || neighbor(1) > size(grid, 1) || ...
               neighbor(2) < 1 || neighbor(2) > size(grid, 2) || ...
               grid(neighbor(1), neighbor(2)) == 1 || ...
               closed_list(neighbor(1), neighbor(2)) == 1
                continue;
            end
            
            % Calculate g_cost for neighbor
            tentative_g_cost = g_cost(current(1), current(2)) + 1;
            
            % Check if this path is better
            if tentative_g_cost < g_cost(neighbor(1), neighbor(2))
                parent(neighbor(1), neighbor(2), :) = current;
                g_cost(neighbor(1), neighbor(2)) = tentative_g_cost;
                f_cost(neighbor(1), neighbor(2)) = tentative_g_cost + heuristic(neighbor);
                
                % Add neighbor to open list if not already there
                if isempty(open_list) || ~ismember(neighbor, open_list(:, 1:2), 'rows')
                    open_list = [open_list; neighbor, f_cost(neighbor(1), neighbor(2))];
                end
            end
        end
    end
    
    % If no path is found
    path = [];
end