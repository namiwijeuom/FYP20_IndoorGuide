function handle = showTagPath(Path,PathType)
%SHOWTAGPATH Plots the path of the given array of points
    % Path: An Nx2 array where each row is a coordinate [x, y]
    % PathType: 'actual' , 'measured' , 'kalman' 
    
    % Check if path is valid
    if size(Path, 2) ~= 2
        error('Input must be an Nx2 array representing [x, y] coordinates.');
    end
    
    if strcmpi(PathType, 'actual')
        color = 'b';
        startColor = 'bo';
        endColor = 'bx';
        pathDisName = "Actual Path";
        startLocDispName = "Actual path Start";
        endLocDispName = "Actual path End";
        
    elseif strcmpi(PathType, 'measured')
        color = 'r';
        startColor = 'ro';
        endColor = 'rx';
        pathDisName = "Measurement Path";
        startLocDispName = "Measurement path Start";
        endLocDispName =   "Measurement path End";

    elseif strcmpi(PathType, 'filtered')
        color = 'g';
        startColor = 'go';
        endColor = 'gx';
        pathDisName = "Filter Path";
        startLocDispName = "Filter path Start";
        endLocDispName =   "Filter path End";

    end

    % Plot the path 
    handle = plot(Path(:,1), Path(:,2),color,'LineWidth',1,'DisplayName',pathDisName);
    xlabel('X Position (m)');
    ylabel('Y Position (m)');
    grid on;
    
    % Mark start and end points
    hold on;
    plot(Path(1,1), Path(1,2),startColor, 'MarkerSize', 10, 'DisplayName',startLocDispName); % Start point
    plot(Path(end,1), Path(end,2),endColor, 'MarkerSize', 10, 'DisplayName',endLocDispName); % End point

    hold on;

end
