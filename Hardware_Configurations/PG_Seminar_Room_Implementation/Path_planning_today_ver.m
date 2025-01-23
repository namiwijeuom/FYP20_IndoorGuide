function pathPoints = RRT_star_find_path(environment, startNode, goalNode)
    % RRT* Path Planning Algorithm without visualization
    % Inputs:
    %   environment - 2D matrix (0 for free space, 1 for obstacles)
    %   startNode   - 1x2 vector [x, y] representing the start position
    %   goalNode    - 1x2 vector [x, y] representing the goal position
    % Output:
    %   pathPoints  - Nx2 matrix representing the sequence of points along the optimal path

    % Parameters for RRT* algorithm
    maxIterations = 1000;
    stepSize = 1; % Step size of 1m (1 grid cell)
    goalThreshold = 0.5; % Threshold for considering goal reached

    % Initialize output variable
    pathPoints = [];  % Ensure `pathPoints` is initialized

    % Initialize tree with start node
    tree.nodes = startNode;
    tree.parent = 0;

    % RRT* algorithm loop
    for i = 1:maxIterations
        randomPoint = randomSample(environment);
        randomPoint = approximateToMidpoint(randomPoint); % Snap to midpoint

        [nearestNode, nearestIdx] = findNearestNode(tree.nodes, randomPoint);
        newPoint = steerOptimized(nearestNode, randomPoint, goalNode, stepSize, environment);

        if isCollisionFree(nearestNode, newPoint, environment)
            tree.nodes = [tree.nodes; newPoint];
            tree.parent = [tree.parent; nearestIdx];

            % Check if goal has been reached
            if norm(newPoint - goalNode) < goalThreshold
                finalNode = size(tree.nodes, 1);
                break;
            end
        end
    end

    % Ensure that `finalNode` exists before proceeding to path extraction
    if exist('finalNode', 'var')
        path = findPath(tree, finalNode);
        pathPoints = rerouteIfNeeded(path);  % Get the path points
    else
        disp('No path found.');
    end
end

%% Helper Functions

function midpoint = approximateToMidpoint(point)
    % Snap point to the nearest midpoint of the grid
    midpoint = round(point) - 0.5;
end

function randomPoint = randomSample(environment)
    % Generate a random point in the environment
    x = randi(size(environment, 1));
    y = randi(size(environment, 2));
    randomPoint = [x, y];
end

function [nearestNode, nearestIdx] = findNearestNode(nodes, point)
    % Find the nearest node in the tree to the random point
    distances = vecnorm(nodes - point, 2, 2);
    [~, nearestIdx] = min(distances);
    nearestNode = nodes(nearestIdx, :);
end

function newPoint = steerOptimized(fromNode, randomPoint, goalNode, stepSize, environment)
    % Move from fromNode toward randomPoint or goalNode based on Manhattan distance
    direction = randomPoint - fromNode;

    % Move closer to goal in the horizontal direction first
    if abs(goalNode(1) - fromNode(1)) > 0 && isCollisionFree(fromNode, [fromNode(1) + stepSize * sign(direction(1)), fromNode(2)], environment)
        newPoint = [fromNode(1) + stepSize * sign(direction(1)), fromNode(2)];
    elseif abs(goalNode(2) - fromNode(2)) > 0 && isCollisionFree(fromNode, [fromNode(1), fromNode(2) + stepSize * sign(direction(2))], environment)
        newPoint = [fromNode(1), fromNode(2) + stepSize * sign(direction(2))];
    else
        % Fallback if no optimal step
        newPoint = fromNode;
    end
end

function isFree = isCollisionFree(fromNode, toNode, environment)
    % Check if the straight path between two points is free of obstacles
    if fromNode(1) == toNode(1)
        % Vertical movement
        yRange = linspace(fromNode(2), toNode(2), 10);
        x = round(fromNode(1));
        for y = yRange
            if environment(round(x), round(y)) == 1
                isFree = false;
                return;
            end
        end
    elseif fromNode(2) == toNode(2)
        % Horizontal movement
        xRange = linspace(fromNode(1), toNode(1), 10);
        y = round(fromNode(2));
        for x = xRange
            if environment(round(x), round(y)) == 1
                isFree = false;
                return;
            end
        end
    end
    isFree = true;
end

function path = findPath(tree, finalNodeIdx)
    % Extract the path by tracing back from the goal to the start
    path = tree.nodes(finalNodeIdx, :);
    currentIdx = finalNodeIdx;
    
    while currentIdx ~= 1  % Trace back to the root of the tree
        currentIdx = tree.parent(currentIdx);
        path = [tree.nodes(currentIdx, :); path];
    end
end

function pathPoints = rerouteIfNeeded(path)
    % Function to extract path points, simplifying any rerouting if needed
    pathPoints = path;
end




environment = zeros(15, 10);
environment(2:3, 2:3) = 1;  % Adding some obstacles
environment(4:5, 5:7) = 1;
environment(8:9, 5:7) = 1;

startNode = [6, 3];  % Start position
goalNode = [7, 6];   % Goal position

optimalPath = RRT_star_find_path(environment, startNode, goalNode);
disp('Optimal Path:');
disp(optimalPath);
