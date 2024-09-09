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
show(tx,"ShowAntennaHeight",false)
show(rx1,"ShowAntennaHeight",false)
show(rx2,"ShowAntennaHeight",false)
show(rx3,"ShowAntennaHeight",false)

%% Ray Tracing Configuration
pm = propagationModel("raytracing", ...
                        "CoordinateSystem","cartesian", ...
                        "Method","sbr", ...
                        "AngularSeparation","low", ...
                        "MaxNumReflections",10, ...
                        "SurfaceMaterial","concrete");

c = physconst('lightspeed'); % Speed of light

%% Perform ray tracing for the receivers (using rx1 as an example)
rays1 = raytrace(tx, rx1, pm, "Type", "power");
rays1 = rays1{1,1};

%% Display Ray Tracing Results for all receivers
disp('Number of Interactions per Ray for rx1:');
disp([rays1.NumInteractions]);

disp('Propagation Distances for rx1:');
disp([rays1.PropagationDistance]);

disp('Path Loss per Ray for rx1:');
disp([rays1.PathLoss]);

%% Plot Ray Tracing Results
plot(rays1,"Colormap",jet,"ColorLimits",[100, 160])

%% Extract relevant data from ray tracing results
% Extract propagation distances (in meters)
distances = [rays1.PropagationDistance]; % in meters

% Convert distances to time delays (in seconds)
delays = distances / c; % delay in seconds

% Extract path loss (in dB)
pathLoss = [rays1.PathLoss]; % path loss in dB

% Convert path loss to linear scale
receivedPower = 10.^(-pathLoss/10); % received power in linear scale

%% Compute Power Delay Profile (PDP)
% Define delay resolution (bin size) for PDP (e.g., 1 ns)
delayResolution = 1e-9; % 1 ns
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

%% Normalize PDP (optional)
pdp = pdp / max(pdp); % Normalize to maximum power
disp(max(pdp))
%% Plot the Power Delay Profile (PDP)
figure;
stem(delayBins * 1e9, 10*log10(pdp), 'filled'); % Plot in dB scale
xlabel('Delay (ns)');
ylabel('Power (dB)');
title('Power Delay Profile (PDP)');
grid on;
