function RRT_star_latest_code()
    disp('Initializing environment...');
    
    % Define a 10x10 environment where each cell is 1x1 meter
    environment = zeros(15, 10); 
    % Adding obstacles to the environment (each obstacle is 1m x 1m)
    environment(2:3, 2:3) = 1;  % Obstacle in the range of (2,2) to (3,3)
    environment(4:5, 5:7) = 1;  % Obstacle in the range of (5,5) to (6,7)
    environment(8:9, 5:7) = 1;  % Obstacle in the range of (7,4) to (8,5)

    % Define start and goal nodes in terms of the environment grid (midpoints)
    startNode = approximateToMidpoint([1, 1]);  % Starting at the bottom-left (approx. midpoint)
    goalNode = approximateToMidpoint([7, 6]);   % Goal at near top-right (approx. midpoint)

    % Parameters for RRT* algorithm
    maxIterations = 1000;
    goalThreshold = 0.5; % Goal threshold for reaching the final node (0.5m)

    disp('Displaying environment...');
    figure;
    displayEnvironment(environment, startNode, goalNode);

    % Initialize tree with start node
    tree.nodes = startNode;
    tree.parent = 0;

    disp('Starting RRT* loop...');
    for i = 1:maxIterations
        randomPoint = randomSample(environment);
        randomPoint = approximateToMidpoint(randomPoint); % Snap to midpoint

        [nearestNode, nearestIdx] = findNearestNode(tree.nodes, randomPoint);
        newPoint = steerMidpoint(nearestNode, goalNode);  % Steer toward the goal

        if isCollisionFree(nearestNode, newPoint, environment)
            tree.nodes = [tree.nodes; newPoint];
            tree.parent = [tree.parent; nearestIdx];

            % Check if goal has been reached
            if norm(newPoint - goalNode) < goalThreshold
                disp(['Goal reached at iteration ', num2str(i)]);
                finalNode = size(tree.nodes, 1);
                break;
            end
        end
    end

    if exist('finalNode', 'var')
        path = findPath(tree, finalNode);
        plotPath(path);
        rerouteIfNeeded(tree, path, goalNode, environment);
    else
        disp('No path found.');
    end
end

%% Helper Functions

function midpoint = approximateToMidpoint(point)
    % Snap point to the nearest midpoint of the grid
    midpoint = round(point) - 0.5;
end

%%function displayEnvironment(env, startNode, goalNode)
    % Function to display the environment grid
    %%imagesc(env'); hold on;
    %%colormap(gray);  % Set obstacles as black and free space as white
    %%plot(startNode(1), startNode(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Start
    %plot(goalNode(1), goalNode(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);   % Goal 
    %axis equal;
    %grid on;  % Turn on grid display for easier visualization
    %xticks(0:1:size(env, 1));
    %yticks(0:1:size(env, 2));
%end
function displayEnvironment(env, startNode, goalNode)
    % Function to display the environment grid
    imagesc(~env');  % Invert the environment to display free space as black and obstacles as white
    hold on;
    colormap(gray);  % Use grayscale but inverted for obstacle and free space colors
    plot(startNode(1), startNode(2), 'go', 'MarkerSize', 10, 'LineWidth', 2); % Start node in green
    plot(goalNode(1), goalNode(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2);   % Goal node in red
    axis equal;
    grid on;  % Turn on grid display for easier visualization
    xticks(0:1:size(env, 1));  % Set grid ticks for better visual guidance
    yticks(0:1:size(env, 2));
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

function newPoint = steerMidpoint(fromNode, goalNode)
    % Steer from the nearest node towards the goal node by first trying to move horizontally
    % If horizontal movement is blocked, then attempt vertical movement
    newPoint = fromNode;
    
    % Horizontal movement
    if fromNode(1) ~= goalNode(1)
        newPoint(1) = goalNode(1);
    elseif fromNode(2) ~= goalNode(2)
        % If horizontal movement is not possible, try vertical movement
        newPoint(2) = goalNode(2);
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

function plotPath(path)
    % Highlight the final path
    plot(path(:, 1), path(:, 2), 'r-', 'LineWidth', 3);  % Thicker red line for visibility
    plot(path(:, 1), path(:, 2), 'ko', 'MarkerFaceColor', 'r');  % Red dots for nodes
    hold off;
end

function rerouteIfNeeded(tree, path, goalNode, environment)
    % Continuously reroute if off course
    for step = 1:size(path, 1)
        currentPosition = path(step, :);
        disp(['Current position: ', num2str(currentPosition)]);
        
        % Simulate user input (moving in a wrong direction)
        if isMovingInWrongDirection(currentPosition, goalNode)
            disp('Off course! Rerouting...');
            RRT_star_latest_code();  % Rerun RRT* to find a new path
            break;
        end
        
        % Pause for visualization
        pause(0.5);
    end
end

function wrongDirection = isMovingInWrongDirection(currentPosition, goalNode)
    % Simple check if the user is moving away from the goal
    distanceToGoal = norm(currentPosition - goalNode);
    wrongDirection = distanceToGoal > 1;  % Threshold can be adjusted
end
