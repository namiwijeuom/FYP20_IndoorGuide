function plotMultiplePDP(rays1, rays2, rays3, c)
    % Function to compute and plot three Power Delay Profiles (PDPs)
    % rays1, rays2, rays3 are the ray tracing results (arrays)
    % c is the speed of light (constant)

    % Define delay resolution (bin size) for PDP (e.g., 1 ns)
    delayResolution = 1e-9; % 1 ns

    % Compute and plot the PDP for rays1
    subplot(3,1,1); % First plot
    plotPDP(rays1, delayResolution, c);
    title('Power Delay Profile (PDP) - Ray Set 1');

    % Compute and plot the PDP for rays2
    subplot(3,1,2); % Second plot
    plotPDP(rays2, delayResolution, c);
    title('Power Delay Profile (PDP) - Ray Set 2');

    % Compute and plot the PDP for rays3
    subplot(3,1,3); % Third plot
    plotPDP(rays3, delayResolution, c);
    title('Power Delay Profile (PDP) - Ray Set 3');
end

function plotPDP(rays, delayResolution, c)
    % Helper function to compute and plot the PDP for a given set of rays

    % Extract relevant data from ray tracing results
    distances = [rays.PropagationDistance]; % in meters
    pathLoss = [rays.PathLoss]; % in dB
    
    % Convert to time delays and received power
    delays = distances / c; % delay in seconds
    receivedPower = 10.^(-pathLoss / 10); % received power in linear scale

    % Compute Power Delay Profile (PDP)
    maxDelay = max(delays); % maximum delay
    numBins = ceil(maxDelay / delayResolution); % number of delay bins

    % Initialize PDP array
    pdp = zeros(1, numBins);
    delayBins = (0:numBins-1) * delayResolution;

    % Accumulate power in each delay bin
    for i = 1:length(delays)
        binIndex = floor(delays(i) / delayResolution) + 1;
        pdp(binIndex) = pdp(binIndex) + receivedPower(i);
    end

    % Normalize PDP (optional)
    pdp = pdp / max(pdp); % Normalize to maximum power

    % Plot the Power Delay Profile (PDP)
    stem(delayBins * 1e9, 10*log10(pdp), 'filled'); % Plot in dB scale
    xlabel('Delay (ns)');
    ylabel('Power (dB)');
    grid on;
end

%% 3-D Indoor Scenario 
mapFileName = "FabConvert.com_autosave_market.stl";
fc = 6.5e9;
lambda = physconst("lightspeed")/fc;

%% Antenna configuration
% The transmit antenna is a 1-element uniform linear array (ULA) with one wavelength spacing
txArray = arrayConfig("Size",[1 1],"ElementSpacing",lambda);
rxArray = arrayConfig("Size",[1 1],"ElementSpacing",lambda);

%% Antenna placement
tx = txsite("cartesian", ...
    "Antenna",txArray, ...
    "AntennaPosition",[400; 400; 50], ...
    'TransmitterFrequency',6.5e9,...
    'TransmitterPower',0.0015);

rx1 = rxsite("cartesian", ...
    "Antenna",rxArray, ...
    "AntennaPosition",[50;-200; 75], ...
    "AntennaAngle",[0;90],...
    "ReceiverSensitivity",-25);

rx2 = rxsite("cartesian", ...
    "Antenna",rxArray, ...
    "AntennaPosition",[50;600; 75], ...
    "AntennaAngle",[0;90],...
    "ReceiverSensitivity",-25);

rx3 = rxsite("cartesian", ...
    "Antenna",rxArray, ...
    "AntennaPosition",[735;100; 75], ...
    "AntennaAngle",[0;90],...
    "ReceiverSensitivity",-25);

%% Load the environment map
siteviewer("SceneModel",mapFileName);
show(tx,"ShowAntennaHeight",false,"ClusterMarkers",true)
show(rx1,"ShowAntennaHeight",false)
show(rx2,"ShowAntennaHeight",false)
show(rx3,"ShowAntennaHeight",false)

%% Label TX and RX locations
% Extract positions for TX and RX sites
txPos = tx.AntennaPosition;
rx1Pos = rx1.AntennaPosition;
rx2Pos = rx2.AntennaPosition;
rx3Pos = rx3.AntennaPosition;
% Label the TX and RX using 'text' function
% Adjust the position slightly for better label visualization
text(txPos(1), txPos(2), 'TX', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'r'); % Label TX
text(rx1Pos(1), rx1Pos(2), 'RX1', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b'); % Label RX1
text(rx2Pos(1), rx2Pos(2), 'RX2', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b'); % Label RX2
text(rx3Pos(1), rx3Pos(2), 'RX3', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b'); % Label RX3

%% Ray Tracing Configuration
pm1 = propagationModel("raytracing", ...
                        "CoordinateSystem","cartesian", ...
                        "Method","sbr", ...
                        "AngularSeparation","low", ...
                        "MaxNumReflections",3, ...
                        "SurfaceMaterial","wood");

pm2 = propagationModel("raytracing", ...
                        "CoordinateSystem","cartesian", ...
                        "Method","image", ...
                        "AngularSeparation","low", ...
                        "MaxNumReflections",2, ...
                        "SurfaceMaterial","concrete");

pm3 = propagationModel("raytracing", ...
                        "CoordinateSystem","cartesian", ...
                        "Method","sbr", ...
                        "AngularSeparation","low", ...
                        "MaxNumReflections",3, ...
                        "SurfaceMaterial","glass");

%% Perform ray tracing for all receivers
rays1 = raytrace(tx,rx1,pm2,"Type","power");
rays1 = rays1{1,1};

rays2 = raytrace(tx,rx2,pm2,"Type","power");
rays2 = rays2{1,1};

rays3 = raytrace(tx,rx3,pm2,"Type","power");
rays3 = rays3{1,1};

%% Display Ray Tracing Results for all receivers
disp('Number of Interactions per Ray for rx1:');
disp([rays1.NumInteractions]);
disp('Propagation Distances for rx1:');
disp([rays1.PropagationDistance]);
disp('Path Loss per Ray for rx1:');
disp([rays1.PathLoss]);

disp('Number of Interactions per Ray for rx2:');
disp([rays2.NumInteractions]);
disp('Propagation Distances for rx2:');
disp([rays2.PropagationDistance]);
disp('Path Loss per Ray for rx2:');
disp([rays2.PathLoss]);

disp('Number of Interactions per Ray for rx3:');
disp([rays3.NumInteractions]);
disp('Propagation Distances for rx3:');
disp([rays3.PropagationDistance]);
disp('Path Loss per Ray for rx3:');
disp([rays3.PathLoss]);

%% Plot Ray Tracing Results
plot(rays1,"Colormap",jet,"ColorLimits",[100, 160])
hold on;
plot(rays2,"Colormap",jet,"ColorLimits",[100, 160])
plot(rays3,"Colormap",jet,"ColorLimits",[100, 160])
hold off;

%% Calculate Power Delay Profile
plotMultiplePDP(rays1, rays2, rays3, 3e8);
