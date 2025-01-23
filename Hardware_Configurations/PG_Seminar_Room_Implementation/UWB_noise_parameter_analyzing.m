baseLocs = [ 0 0;                % Locations of the anchors/basestations
         -20 -20;
          -20 20;
           20 20;
         20 -20];


numOfBs = length(baseLocs);
        
min_x = min(baseLocs(:,1))-10;
min_y = min(baseLocs(:,2))-10;
max_x = max(baseLocs(:,1))+10;
max_y = max(baseLocs(:,2))+10;

N = 1000;  % Number of input data points
x_true = min_x + rand(N, 1) * (max_x - min_x);  
y_true = min_y + rand(N, 1) * (max_y - min_y);  
coords_true = [x_true, y_true];

numOfMultipaths = 10;
delaySpread = 20e-9;
snr = 30;

% showTagPath(coords_true,false);
distances = zeros(N,numOfBs);

for i=1:N
    for j=1:numOfBs
        distances(i,j) = norm(coords_true(i,:) - baseLocs(j,:)) ;
    end
end


coords_esti = zeros(size(coords_true));


for i=1:N
    distFromTag2Bs = distances(i,:);
    estiDistance = zeros(size(distFromTag2Bs));

    for j=1:numOfBs
        estimated = ssTwr(1,distFromTag2Bs(j),numOfMultipaths,true,delaySpread,snr);
        estiDistance(j) = estimated;
    end

    coords_esti(i,:) = multilateration(baseLocs,estiDistance);

end


% Calculate measurement noise
noise = coords_esti - coords_true;

% Plot histogram of the noise
figure;
histogram(noise(:,1), 'Normalization', 'pdf');
hold on;
histogram(noise(:,2), 'Normalization', 'pdf');
title('Histogram of Measurement Noise');


mu = mean(noise);         % Mean vector
sigma = cov(noise);       % Covariance matrix        



%% 
n = 1000;

distances = (30)*rand(1,n);
estimated = zeros(size(distances));

numOfMultipaths = 10;
delaySpread = 20e-9;
snr = 30;

for i=1:n
    estimated(i) = ssTwr(1,distances(i),numOfMultipaths,true,delaySpread,snr);
end

noise = estimated - distances;


figure;
histogram(noise, 'Normalization', 'pdf','BinWidth',0.000001);

mu = mean(noise);
sigma = cov(noise);

fprintf("Mean of the noise %.2f , Variance of the noise %.2f\n",mu,sigma);
