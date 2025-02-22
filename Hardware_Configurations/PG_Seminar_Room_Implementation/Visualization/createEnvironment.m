function  environment = createEnvironment(backgroundImg)
%CREATEENVIRONMENT Creates an environment for the UWB localization simulation.
%   This function loads and processes the supermarket layout image, and
%   defines the layout dimensions of the environment.

    % Define the supermarket layout dimensions
    supermarketLength = 11.64;  % along  (Y-axis)
    supermarketWidth = 12.21;  % along  (X-axis)
    
    cell_size = 0.5;

    % Create the figure
    fig = figure;
    img = imread(backgroundImg);

    % Display the image with 'image'
    image([0 supermarketWidth], [0 supermarketLength], img); 
    set(gca, 'YDir', 'normal'); % Correct Y-axis direction
    
    % Overlay a plot
    hold on;
    grid on;
    axis equal;

    xticks(0:cell_size:ceil(supermarketWidth));
    yticks(0:cell_size:ceil(supermarketLength));
    axis equal;
    % Apply the grid with custom ticks
    
    % Set axis limits and labels
    axis([0 supermarketWidth 0 supermarketLength]);
    xlabel('X (m)');
    ylabel('Y (m)');
    title('PG Seminar Room');
  
    % Define the environment grid (grid for [ cell_size X cell_size ] cells) 
    % rows -> Parallel to X axis, columns -> Parallel to Y axis
    

    rows = ceil(supermarketLength / cell_size);
    cols = ceil(supermarketWidth  / cell_size);
    environment = zeros(rows,cols); % rows (in Y-axis), columns (in X-axis)
    
    % Mark obstacles for each section
    
    environment(0.5:1 , 0.5:1)     = 1;   % Rack 7
    environment(3:4.5 , 0.5:1)     = 1;   % Rack 5
    environment(6:7.5 , 0.5:1)     = 1;   % Rack 3
    environment(9:10.5 , 0.5:1)    = 1;   % Rack 1
    environment(2.5:4 , 3:4.5)     = 1;   % Rack 6
    environment(6:7.5 , 3:4.5)     = 1;   % Rack 4
    environment(9:10.5 , 3:4.5)     = 1;   % Rack 2
  %  environment(0.5:1 , 4:5.5)            = 1;   % Rack 8
   % 
    environment(5.5:6 , 5.5:6)        = 1;   % Concrete pillar 1 
    environment(5.5:6 , 11.5:12)        = 1;   % Concrete pillar 2 
    % environment(0.5:1 ,11.5:12)       = 1;   % Concrete pillar 4 
    % environment(0.5:1 ,5.5:6)       = 1;   % Concrete pillar 3 
   % 
%   environment(19:23,13:25) = 1;   % Stage
   environment(10:11.5,6:12) = 1;   % Stage

   % environment(1:4,1:2)     = 1;   % Rack 7
   % environment(1:4,7:10)    = 1;   % Rack 5
   % environment(1:4,13:15)   = 1;   % Rack 3
   % environment(1:4,19:21)   = 1;   % Rack 1
   % environment(7:9,6:9)     = 1;   % Rack 6
   % environment(7:9,12:15)   = 1;   % Rack 4
   % environment(7:9,19:21)   = 1;   % Rack 2
   % environment(9:11,1:2)      = 1;   % Rack 8
   % 
   % environment(12:13,1:2)        = 1;   % Concrete pillar 1 
   % environment(23:24,1:2)        = 1;   % Concrete pillar 2 
   % environment(12:13,12:13)       = 1;   % Concrete pillar 4 
   % environment(23:24,12:13)       = 1;   % Concrete pillar 3 

   %environment(13:25,20:24) = 1;   % Stage

    % environment(2:5, 1:4) = 1;    % Rack 01
    % environment(2:5, 6:9) = 1;    % Rack 02
    % environment(7:10, 1:4) = 1;   % Rack 03
    % environment(7:10, 6:9) = 1;   % Rack 04
    % environment(12:15, 1:4) = 1;  % Rack 05
    % environment(13:16, 6:9) = 1;  % Rack 06
    % environment(21:23, 1:4) = 1;  % Rack 07
    % environment(12:13, 12:13) = 1; % Brown block 1
    % environment(12:13, 23:24) = 1; % Brown block 2
    % environment(23:24, 12:13) = 1; % Brown block 3
    % environment(23:24, 23:24) = 1; % Brown block 4
    % environment(1:4, 13:24) = 1;  % Approximate position for the stage

end
