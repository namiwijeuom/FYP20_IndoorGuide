function [x_final, y_final] = C_Taylor_Algorithm(base_stations, distances, max_iterations, threshold)
    % Number of base stations
    m = size(base_stations,1);
    
    % Initial estimate using Chan's algorithm
    [x, y] = Chan_Algorithm(base_stations, distances);
    
    % Initialize variables for recursion
    x_m = x;
    y_m = y;
   
    
    for iter = 1:max_iterations
        % Calculate distances based on the current position estimate
        d_estimated = sqrt((x_m - base_stations(:, 1)).^2 + (y_m - base_stations(:, 2)).^2)
        distances
        % Calculate the sum of squared residuals
        delta_d = distances - d_estimated
        residuals = sum(delta_d.^2)
        % Calculate the weighting factor
        lambda_m = residuals / m
        
        % Update the position estimate
        x_new = sum(x_m ./ lambda_m) / sum(1 ./ lambda_m);
        y_new = sum(y_m ./ lambda_m) / sum(1 ./ lambda_m);
        
        % Check for convergence
        if abs(x_new - x_m) < threshold && abs(y_new - y_m) < threshold
            break;
        end
        
        % Update for next iteration
        x_m = x_new;
        y_m = y_new;
    end
    
    % Final position estimate
    x_final = x_new; %changex_mtox_new
    y_final = y_new; %%changey_mtoy_new
end

function [x, y] = Chan_Algorithm(base_stations, distances)
    % Number of base stations
    m = size(base_stations, 1);
    
    % Initialize matrices H and Ga
    H = zeros(m, 1);
    Ga = zeros(m, 3);
    
    % Compute K_j = x_j^2 + y_j^2 for each base station
    K = sum(base_stations.^2, 2);
    
    % Constructing H and Ga matrices
    for j = 1:m
        H(j) = distances(j)^2 - K(j);
        Ga(j, :) = [2 * base_stations(j, 1), 2 * base_stations(j, 2), 1];
    end
    
    % Estimate Za = [x, y, R] using least squares
    Za = (Ga' * Ga) \ (Ga' * H);
    
    % Extract x, y coordinates from Za
    x = Za(1);
    y = Za(2);
    
    % Correct sign issue (if necessary)
    if x < 0
        x = -x
    end
    
    if y < 0
        y = -y
    end
end

%%Example Usage:

% Example base stations (m x 2 matrix)
base_stations = [0, 0; 10, 0; 0, 10; 10, 10];

% Example distances to the target from each base station
distances = [2.35, 5.5,8.2,7.3];  % Example values, usually measured

% Parameters for the C-Taylor Algorithm
max_iterations = 100;   % Maximum number of iterations
threshold = 1e-6;       % Convergence threshold

% Get the final position using C-Taylor algorithm
[x_final, y_final] = C_Taylor_Algorithm(base_stations, distances, max_iterations, threshold);

% Output the final position
fprintf('Final position from C-Taylor Algorithm: x = %.2f, y = %.2f\n', x_final, y_final);
