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
rays1 = raytrace(tx,rx1,pm1,"Type","power");
rays1 = rays1{1,1};

rays2 = raytrace(tx,rx2,pm1,"Type","power");
rays2 = rays2{1,1};

rays3 = raytrace(tx,rx3,pm1,"Type","power");
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
