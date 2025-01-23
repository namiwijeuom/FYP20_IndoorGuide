%Trilateration with 3 Base stations and 1 tag
baseLocs = [ -2 0;                % Locations of the anchors/basestations
             12 4;
             3 17;
           -15 16;
          -15 -10;
            10 -5];
           

numofBs = length(baseLocs);
showBaseStations(baseLocs);


% For now, just use 'rect' -> Rcircular has to be improved.

path = generatePath('circular');       % This path array represents movement of the tag device -                        
showTagPath(path,'actual');        % along a rectangular path




c = physconst('LightSpeed');    % Speed of light (m/s)
snr = 30;                       % Signal-to-Noise ratio

actualDistance = zeros(1,numofBs);
estimatedPath = zeros(length(path),2);

numOfTwrSessions = 1;
NumOfMultiPaths  = 1;
maxDelaySpread = 20e-9;

%Iterate through each point in path to get estimation
for point_num = 1:length(path)

    tagLoc = path(point_num,:);

    for num = 1:numofBs
        actualDistance(num) = norm(tagLoc - baseLocs(num,:));   
    end

    estimatedDistance = zeros(1,numofBs);


    for twr = 1:numofBs
        estimatedDistance(twr) = ssTwr(numOfTwrSessions,actualDistance(twr),NumOfMultiPaths,true,maxDelaySpread,snr);
    end

    estimatedLoc = multilateration(baseLocs,estimatedDistance);
    estimatedPath(point_num,:) = estimatedLoc;
end
showTagPath(estimatedPath,'measured');

%% 
% Implementation using pre-measured values. 
load('Measurement_data\data_sq_5bs_20ds_10mp_30snr.mat');

showBaseStations(baseLocs);
showTagPath(path,'actual');
showTagPath(estimatedPath,'measured');


% Kalman filter implementation

function [mu_t,sigma_t] = kalmanFilter(mu_tm1,sigma_tm1,zt)

    global At Ct Rt Qt

    mu_t_bar = At * mu_tm1;            % removed Bt * ut term

    sigma_t_bar = At * sigma_tm1 * At' + Rt;

    Kt = sigma_t_bar * Ct' * inv(Ct * sigma_t_bar * Ct' + Qt);

    mu_t = mu_t_bar + Kt * (zt - (Ct * mu_t_bar));

    ktct = Kt * Ct;

    sigma_t = (eye(size(ktct)) - ktct) * sigma_t_bar;

end


% Time step 
dt = 0.5;     % Seconds
mu_tm1 = [path(1,1) 1 path(1,2) 0]';  % Known initial point. Zero initial velocities.
sigma_tm1 = zeros(length(mu_tm1));    % Zero uncertainty due to known point.
zt = [0 0]';                          % Initializing measurment vector zt.


% Modeling state transition 
global At Rt
At = [1 dt 0 0;
      0 1  0 0;
      0 0 1 dt;
      0 0 0  1];

% Process noise covariance -> Findout how to find this properly    
tuneRt = 0.5;
Rt = tuneRt * eye(length(mu_tm1));

% Modeling the measurement 
global Ct Qt
Ct = [1 0 0 0;
      0 0 1 0];
 
tuneQt = 500;
Qt = tuneQt * eye(length(zt));
% Qt = [6.478 -0.372;-0.372 6.209];



% Prediction and Update using the measurements.
kf_output = zeros(size(estimatedPath));      % Only use xt and yt state variables
                                             % Velocities are not needed                                                  

for i=1:length(estimatedPath)

    zt = estimatedPath(i,:)';                          % Measurement
    [mu_t,sigma_t] = kalmanFilter(mu_tm1,sigma_tm1,zt); 
    kf_output(i,:) = [mu_t(1) mu_t(3)];  
    mu_tm1= mu_t;
    sigma_t = (sigma_t + sigma_t')/2;    % Divergence correction steps
    sigma_tm1 = sigma_t;

end

showTagPath(kf_output,'filtered');
legend('Location','northeast');
hold off;

