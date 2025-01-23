% Implementation of particle filter


% Implementation using pre-measured values. 
load('Measurement_data\data_circular_5bs_20ds_10mp_30snr_after_mean_correction.mat');
showBaseStations(baseLocs);
showTagPath(path,'actual');
showTagPath(estimatedPath,'measured');
axis([-30 30 -30 30]);



dt = 0.5;     % Seconds
% Modeling state transition 
global At Qt Rt mu_zt

At = [1 dt 0 0;
      0 1  0 0;
      0 0 1 dt;
      0 0 0  1];

% Process noise covariance -> Findout how to find this properly    
tuneRt = 0.1;
Rt = tuneRt * eye(4);


tuneQt = 5;
Qt = tuneQt * eye(2);
% Qt = [6.8353 0.1698;0.1698 6.5867]; %Measurement noise covariance
mu_zt = [0 0]';             %Measurement noise mean


function [Xt,pt] = ptFilter(Xtm1,zt)

    global At Qt Rt mu_zt

    M = length(Xtm1);   %Number of particles.
    Xbar_t = zeros(size(Xtm1));  %Initializing the particle set.
    Xt = Xbar_t;    
    W = zeros(1,M);     %Weights of each particle.

    zt = zt - mu_zt;  % This step is added externally, not in the particle filter.
    
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
init_particles = -30+60.*rand(2,M); %mvnrnd(initialPos,sigma,M)'; % 
vx0 = 0;      %Initial x velocity
vy0 = 1;      %Initial y velocity
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
    pause(0.1);
end

showTagPath(pfOutput,'filtered');
legend('Location','northeast');
hold off;



