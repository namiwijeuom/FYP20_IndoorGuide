function showTagPath(tagLocations,estimated)
    % This function plots the path of the tag based on the input coordinates
    % tagLocations: an Nx2 array where each row is a coordinate [x, y]
    
    % Check if tagLocations is valid
    if size(tagLocations, 2) ~= 2
        error('Input must be an Nx2 array representing [x, y] coordinates.');
    end
    
    if estimated
        color = 'r';
        startColor = 'ro';
        endColor = 'rx';
        pathDisName = "Estimated Path";
        startLocDispName = "Estimated path Start";
        endLocDispName = "Estimated path End";

    else
        color = 'b';
        startColor = 'bo';
        endColor = 'bx';
        pathDisName = "Actual Path";
        startLocDispName = "Actual path Start";
        endLocDispName = "Actual path End";
    end


    % Plot the path 
    plot(tagLocations(:,1), tagLocations(:,2),color,'LineWidth',1,'DisplayName',pathDisName);
    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    grid on;
    
    % Mark start and end points
    hold on;
    plot(tagLocations(1,1), tagLocations(1,2),startColor, 'MarkerSize', 10, 'DisplayName',startLocDispName); % Start point
    plot(tagLocations(end,1), tagLocations(end,2),endColor, 'MarkerSize', 10, 'DisplayName',endLocDispName); % End point
    % legend({'Actual Path', 'Start', 'End'}, 'Location', 'northeast');

end
