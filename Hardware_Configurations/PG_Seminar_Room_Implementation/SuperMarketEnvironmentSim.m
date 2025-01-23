% Define the supermarket layout dimensions
supermarketLength = 40; % long side  (Y-axis)
supermarketWidth = 30;  % short side (X-axis)

% Create the figure
figure;
hold on
% Set custom ticks for the grid to match 1.5m spacing
xticks(0:2:supermarketWidth);
yticks(0:2:supermarketLength);
axis equal;
% Apply the grid with custom ticks
grid on;

% Draw the supermarket boundaries
rectangle('Position', [0 0 supermarketWidth supermarketLength], 'EdgeColor', 'b', 'LineWidth', 2);

% Add sections (example positions, adjust as needed)
% Fish/Meat section
rectangle('Position', [6 36 14 4], 'FaceColor', 'cyan');  % Position: (X,Y,width,height)
text(10,38, 7.5, 'Fish/Meat', 'HorizontalAlignment', 'center');

% Ice Cream section
rectangle('Position', [27 24 3 10], 'FaceColor', 'yellow');
text(28, 25, 'Vegetables', 'HorizontalAlignment', 'center');

% Cashier
rectangle('Position', [10 0 10 4], 'FaceColor', 'green');
text(14, 2, 'Cashier', 'HorizontalAlignment', 'center');

% Racks (spaced 2m apart, parallel to the long side)
rectangle('Position', [3 8 1 24], 'FaceColor', [0.8, 0.8, 0.8]);
text(3,33, "Rack1", 'HorizontalAlignment', 'center');

rectangle('Position', [8 8 1 24], 'FaceColor', [0.8, 0.8, 0.8]);
text(6,33, "Rack2", 'HorizontalAlignment', 'center');

rectangle('Position', [13 8 1 24], 'FaceColor', [0.8, 0.8, 0.8]);
text(9,33, "Rack3", 'HorizontalAlignment', 'center');


% Draw the door as a thick line at the bottom
line([4,6], [0, 0], 'Color', 'k', 'LineWidth', 5);
text(3,1, "Entry",'HorizontalAlignment', 'center');

% Set axis limits and labels
axis([0 supermarketWidth 0 supermarketLength]);
xlabel('X (m)');
ylabel('Y (m)');
title('Supermarket Layout');




%%

% Define the environment grid (30x40 grid for 1m x 1m cells)
environment = zeros(30, 40); % 30 rows (X-axis), 40 columns (Y-axis)

% Mark obstacles for each section

% Fish/Meat section (at (6,36) with width 14 and height 4 in the original figure)
environment(6:19, 36:39) = 1;  % X: 6-19, Y: 36-39

% Ice Cream section (at (27,24) with width 3 and height 10)
environment(27:29, 24:33) = 1; % X: 27-29, Y: 24-33

% Cashier section (at (10,0) with width 10 and height 4)
environment(10:19, 1:4) = 1;  % X: 10-19, Y: 1-4

% Racks (spaced 2m apart, parallel to the long side)
environment(3, 8:31) = 1;  % Rack1 at X: 3, Y: 8-31
environment(8, 8:31) = 1;  % Rack2 at X: 8, Y: 8-31
environment(13, 8:31) = 1; % Rack3 at X: 13, Y: 8-31

% Door (Entry) marked as free space, so no need to update environment array here

init_point = [5,2];
% dest_point = [24 ,34];  % Destination point used for UWB data measurements

dest_point = [7,35];

optimalPath = BFS_pathfinding(environment, init_point, dest_point);


% Extract x and y coordinates from the optimalPath matrix
x = optimalPath(:, 1);  % X coordinates
y = optimalPath(:, 2);  % Y coordinates
% Plot the start node in green
% plot(init_point(1),init_point(2), 'go', 'MarkerSize', 10, 'LineWidth', 2);

% Plot the goal node in red
% op_handle = plot(nan, nan, '.b');  % Initialize optimal path plot with an empty point.
plot(dest_point(1),dest_point(2), 'ro', 'MarkerSize', 10, 'LineWidth', 2,'DisplayName','Destination');

% Plot the optimal path as a red line
op_handle = plot(x, y, 'b-', 'LineWidth', 2,'DisplayName','Optimal path');  % Red line for the optimal path
% set(op_handle,'XData',x,'YData',y);

%% --------------------------- Particle filter -------------------------------


% Implementation of particle filter


% Implementation using pre-measured values. 
load('Measurement_data\data_supermarket_6bs_20ds_2mp_30snr.mat');
showBaseStations(baseLocs);
% op_handle = showTagPath(optimalPath,'actual');  % handle for optimal path plot
showTagPath(estimatedPath,'measured');


dt = 0.5;     % Seconds
% Modeling state transition 
global At Qt Rt mu_zt

At = [1 dt 0 0;
      0 1  0 0;
      0 0 1 dt;
      0 0 0  1];

% Process noise covariance -> Findout how to find this properly    
tuneRt = 0.2;
Rt = tuneRt * eye(4);


tuneQt = 10;
Qt = tuneQt * eye(2);
% Qt = [6.8353 0.1698;0.1698 6.5867]; %Measurement noise covariance
mu_zt = [0 0]';             %Measurement noise mean


function [Xt,pt] = ptFilter(Xtm1,zt)

    global At Qt Rt mu_zt

    M = length(Xtm1);   %Number of particles.
    Xbar_t = zeros(size(Xtm1));  %Initializing the particle set.
    Xt = Xbar_t;    
    W = zeros(1,M);     %Weights of each particle.

    zt = zt - mu_zt;  % Remove this Line
    
    for m=1:M
        %Prediction step
        xtm = At * Xtm1(:,m) + mvnrnd(zeros(1,4),Rt,1)';  
        particle = [xtm(1) xtm(3)]';
        %Correction step
        W(m) = mvnpdf(zt,particle,Qt);
        Xbar_t(:,m) = xtm;   %Updating particle set before resampling
    end
    
    %Normalization of weights
    W = W/sum(W);
    % [~,idx] = max(W);
    % pt = [Xbar_t(1,idx) Xbar_t(3,idx)];  % Best state estimate - Particle with highest weight.

    %Measure of Degeneracy - Effective sample size (Neff) (ESS)
    Neff = 1/(sum(W.^2));
    alpha = 1; %Threshold for ESS comparison

    if Neff < (alpha * M)  % Condition for resampling 
        %METHOD OF RESAMPLING - SYSTEMATIC RESAMPLING   

        csw = cumsum(W); %Cummulative sum of weights
        Ui = rand(1,M);  %Uniform distribution from 0 to 1

        for i = 1:M
            ui = Ui(i);
            j = 1;
            while ui > csw(j)
                j = j+1;
            end
            Xt(:,i) = Xbar_t(:,j); 
        end
        pt = mean(Xt,2)'; % Takes the mean of particles with equal weights (wi = 1/M)
        pt = [pt(1) pt(3)];
        
    else
        Xt = Xbar_t;
        pt = mean(Xt,2,Weights=W)'; % Takes the mean of particles with corresponding weights (wi)
        pt = [pt(1) pt(3)];
        
    end

end

%Initial particle set generation
M = 1000;  %Number of total particles.

%Assume gaussian distribution around initial point.
% initialPos = path(1,:);
% sigma = 1 * eye(2) ;    %Tune the variances as we want.
x_range = 0 + 30 .* rand(1, M); % Particles in x range [0, 30]
y_range = 0 + 40 .* rand(1, M); % Particles in y range [0, 40]

% Combine x and y particles
init_particles = [x_range; y_range];
vx0 = 0;      %Initial x velocity
vy0 = 0;      %Initial y velocity
Xtm1 = [init_particles(1,:) ;zeros(1,M)+vx0 ; init_particles(2,:) ; zeros(1,M)+vy0];
Xt = zeros(size(Xtm1));

% estimatedPath = repmat(estimatedPath,10, 1); %Add this to repeat the motion several times.
numofPoints = length(estimatedPath);
pfOutput = zeros(size(estimatedPath));

h_pf = plot(nan, nan, '.k','DisplayName',"Particles");  % Initialize plot with an empty point.
set(h_pf,'XData',init_particles(1,:),'YData',init_particles(2,:)); %Plotting initial particles.
pause(2);

for i = 1:numofPoints
    zt = estimatedPath(i,:)'; 
    [Xt,pfOutput(i,:)] = ptFilter(Xtm1,zt);
    Xtm1 = Xt;
    set(h_pf,'XData',Xt(1,:),'YData',Xt(3,:));
    
    rounded_point = round(pfOutput(i,:));

    new_optimal_path = BFS_pathfinding(environment,rounded_point,dest_point);
    set(op_handle,'XData',new_optimal_path(:, 1),'YData',new_optimal_path(:, 2));


    disp(new_optimal_path);
    pause(0.1);
end

showTagPath(pfOutput,'filtered');
legend('Location','northeast');
hold off;


