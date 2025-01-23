%FILENAME : data_supermarket_6bs_20ds_2mp_30snr --> Supermaket environment, 6 base stations,
%                                           20ns delay spread, 
%                                           2  multipaths, 30dB snr
%                                          

%Trilateration with 6 Base stations and 1 tag
baseLocs = [ 1 1;                % Locations of the anchors/basestations
            28 2;
           28 20;
            1 31;
           10 10;
           18 28];
             
                       
numofBs = length(baseLocs);
showBaseStations(baseLocs);

% ------------ Generate optimal path using RRT algorithm before executing this code ------------- 

path = optimalPath;       % This path array represents movement of the tag device -                        
showTagPath(path,'actual');        % along a rectangular path




c = physconst('LightSpeed');    % Speed of light (m/s)
snr = 10;                       % Signal-to-Noise ratio

actualDistance = zeros(1,numofBs);
estimatedPath = zeros(length(path),2);

numOfTwrSessions = 1;
NumOfMultiPaths  = 2;
maxDelaySpread = 20e-9;

estimated_distance_mean_error = 4.58; % Found using experiments.

%Iterate through each point in path to get estimation
for point_num = 1:length(path)

    tagLoc = path(point_num,:);

    for num = 1:numofBs
        actualDistance(num) = norm(tagLoc - baseLocs(num,:));   
    end

    estimatedDistance = zeros(1,numofBs);


    for twr = 1:numofBs
        estimatedDistance(twr) = ssTwr(numOfTwrSessions,actualDistance(twr),NumOfMultiPaths,true,maxDelaySpread,snr);
        estimatedDistance(twr) = estimatedDistance(twr) - estimated_distance_mean_error;
    end

    estimatedLoc = multilateration(baseLocs,estimatedDistance);
    estimatedPath(point_num,:) = estimatedLoc;
end
showTagPath(estimatedPath,'measured');
legend('Location','northeast');
hold off;


save('Measurement_data\data_supermarket_6bs_20ds_2mp_30snr',"baseLocs","path","estimatedPath",...
    "maxDelaySpread","NumOfMultiPaths","snr");









%-------------------------------------------------------------------------------------
