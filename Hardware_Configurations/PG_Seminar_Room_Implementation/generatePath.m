function path = generatePath(PathType)
%GENERATEPATH Generates the array of points representing the given path type
%   Input: PathType: 'straight' , 'circular' , 'rect' , 'Rcircular'
             
    if strcmpi(PathType, 'rect')
        
        x = linspace(0,15,31);
        y = zeros(1,length(x));
        path = [x' y'];
        y = linspace(0,15,31);
        x = ones(1,length(y)) * x(end);
        path = [path ; x' y'];
        x = linspace(x(end),0,31);
        y = ones(1,length(x)) * y(end);
        path = [path ; x' y'];
        y = linspace(y(end),0,31);
        x = ones(1,length(y)) * x(end);

        path = [path ; x' y'];

    elseif  strcmpi(PathType, 'circular')
    
        radius = 15;  % Define the radius of the circle
        theta = linspace(0, 2*pi, 100);  % Create 100 points along the circular path
        
        x = radius * cos(theta);  % X-coordinates for the circle
        y = radius * sin(theta);  % Y-coordinates for the circle
        
        path = [x' y'];  % Combine x and y into a path matrix



    elseif strcmpi(PathType, 'Rcircular')
    
        nPoints = 120;        % Number of points for the final smooth path
        nControlPoints = 10;   % Number of control points to define the overall shape
        scaleFactor = 10;      % Scale factor for the size of the path
        randomness = 2;        % Randomness factor for control point perturbations
    
        % Generate random control points
        controlX = linspace(0, 2*pi, nControlPoints);
        controlY = scaleFactor * sin(controlX) + randomness * randn(1, nControlPoints);
    
        % Create a spline interpolation for smooth path
        t = linspace(0, 2*pi, nPoints);  % Parametric variable for smooth interpolation
        x = interp1(controlX, scaleFactor * cos(controlX) + randomness * randn(1, nControlPoints), t, 'spline');
        y = interp1(controlX, controlY, t, 'spline');
    
        path = [x' y'];

    elseif strcmpi(PathType, 'straight')
    
        x = linspace(0, 15, 31);  % X-coordinates for the straight line
        y = zeros(1, length(x));   % Y-coordinates are all zero for a straight horizontal line
        
        path = [x' y'];  % Combine x and y into a path matrix

    end


end