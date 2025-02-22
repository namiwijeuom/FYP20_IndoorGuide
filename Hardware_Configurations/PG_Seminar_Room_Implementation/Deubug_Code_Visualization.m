% Define cell size and environment
cell_size = 0.5;
backgroundImg = 'PG_Seminar_Room_Inverted.jpg';
environment = createEnvironment(backgroundImg);

% Define start and goal in meters
startNodeMeters = [1.5, 2.5]; % Example start in meters
goalNodeMeters = [3.5, 5.5];  % Example goal in meters

% Convert to grid indices
startNode = convertToGridNode(startNodeMeters, cell_size);
goalNode = convertToGridNode(goalNodeMeters, cell_size);

% Debug: Print start and goal nodes
disp("Start Node (Grid): " + mat2str(startNode));
disp("Goal Node (Grid): " + mat2str(goalNode));

% Check grid values
disp("Start Node Value: " + num2str(environment(startNode(1), startNode(2))));
disp("Goal Node Value: " + num2str(environment(goalNode(1), goalNode(2))));

% Run A* pathfinding
path = A_star_pathfinding(environment, startNode, goalNode);

% Plot the path
if ~isempty(path)
    figure;
    imagesc(environment);
    colormap(gray);
    hold on;
    plot(path(:, 2), path(:, 1), 'r-', 'LineWidth', 2); % Path
    title('Path Found');
else
    disp('No valid path found.');
end

function gridNode = convertToGridNode(worldNode, cell_size)
    gridNode = [floor(worldNode(2) / cell_size) + 1, floor(worldNode(1) / cell_size) + 1];
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