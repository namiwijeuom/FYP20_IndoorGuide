function coords = multilateration(baseStations, distances)
    % MULTILATERATION calculates the coordinates of a tag based on distances
    % from known base stations.
    %
    % Inputs:
    %   baseStations - an N-by-2 matrix where each row represents the (x, y) 
    %                  coordinates of a base station.
    %   distances    - a column vector of distances from the tag to each base station.
    %
    % Output:
    %   tagX, tagY   - the estimated (x, y) coordinates of the tag.

    % Number of base stations
    numStations = size(baseStations, 1);

    % Check if we have enough base stations
    if numStations < 3
        error('At least three base stations are required for 2D multilateration.');
    end

    % Set up the system of equations based on the distance formula
    A = zeros(numStations-1, 2);
    B = zeros(numStations-1, 1);
    
    for i = 2:numStations
        A(i-1, :) = 2 * (baseStations(i, :) - baseStations(1, :));
        B(i-1) = distances(1)^2 - distances(i)^2 ...
               + baseStations(i, 1)^2 - baseStations(1, 1)^2 ...
               + baseStations(i, 2)^2 - baseStations(1, 2)^2;
    end
    
    % Solve the linear system using least squares
    coords = (A' * A) \ (A' * B);
    coords = coords';
    
end
