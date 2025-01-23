% Parameters
N = 5000;  % Number of particles
T = 50;   % Number of time steps
sigma_process = 0.1;  % Process noise standard deviation
sigma_measurement = 0.5;  % Measurement noise standard deviation

% Actual object motion (unknown to particle filter)
true_position = zeros(2, T);  % [x; y] over time
true_position(:, 1) = [0; 0];  % Start at origin
velocity = [0.5; 0.2];  % Constant velocity

% Generate true positions over time
for t = 2:T
    true_position(:, t) = true_position(:, t-1) + velocity + normrnd(0, sigma_process, 2, 1);
end

% Initialize particles
particles = zeros(2, N);  % Each particle is a 2D point (x, y)
weights = ones(1, N) / N;  % Equal weights for all particles

% Particle filter loop over time
for t = 1:T
    % 1. Prediction step: update particles based on a motion model (random walk)
    particles = particles + normrnd(0, sigma_process, [2, N]);
    
    % 2. Measurement update (assume we get noisy measurements of the true position)
    measurement = true_position(:, t) + normrnd(0, sigma_measurement, 2, 1);  % Noisy measurement

    % Calculate the weights based on the measurement likelihood (Gaussian PDF)
    for i = 1:N
        % Gaussian likelihood (measurement update)
        weights(i) = mvnpdf(measurement', particles(:, i)', sigma_measurement^2 * eye(2));
    end
    
    % Normalize weights
    weights = weights / sum(weights);

    % 3. Resampling step: resample particles according to their weights
    % Use cumulative sum and random sampling for resampling
    cumulative_sum_weights = cumsum(weights);
    u = rand(1, N) / N;
    u = u + (0:N-1) / N;
    new_particles = zeros(size(particles));
    
    j = 1;
    for i = 1:N
        while u(i) > cumulative_sum_weights(j)
            j = j + 1;
        end
        new_particles(:, i) = particles(:, j);
    end
    
    % Replace old particles with resampled ones
    particles = new_particles;
    weights = ones(1, N) / N;  % Reset weights after resampling

    % 4. Estimate the current position as the weighted mean of particles
    estimate = mean(particles, 2);
    
    % Plot the results
    clf;
    plot(true_position(1,1:t), true_position(2,1:t), 'k-', 'LineWidth', 2);  % True path
    hold on;
    scatter(particles(1, :), particles(2, :), 10, 'filled', 'MarkerFaceAlpha', 0.5);  % Particles
    plot(estimate(1), estimate(2), 'rx', 'MarkerSize', 10, 'LineWidth', 2);  % Estimated position
    plot(measurement(1), measurement(2), 'bo', 'MarkerSize', 10, 'LineWidth', 2);  % Noisy measurement
    axis([-5 30 -5 15]);
    legend('True Path', 'Particles', 'Estimated Position', 'Measurement');
    title(sprintf('Time step %d', t));
    drawnow;
end


%% 
% Example points
x = 1:10;  % X-coordinates
y = rand(1, 10);  % Random Y-coordinates

figure;
h = plot(nan, nan, 'o');  % Initialize plot with an empty point

for i = 1:length(x)
    % Update the data for the point
    set(h, 'XData', x(i), 'YData', y(i));
    
    % Pause for a short time to create the animation effect
    pause(0.5);  % Adjust the pause duration as needed
end


% %% 
% x = 10*rand(2,500);
% l = length(x);
% hold on;
% grid on;
% for i=1:l
%     plot(x(1,i),x(2,i),'-b','LineWidth',2);
% 
%     pause(0.01);
% end

% %% 
% 
% % Generate random 2D points
% x = 10 * rand(2, 500);  % 2 rows, 500 columns
% l = length(x);
% 
% hold on;
% grid on;
% 
% % Set axis limits based on expected range of points
% xlim([0 10]);
% ylim([0 10]);
% 
% % Loop to plot lines connecting consecutive points
% for i = 2:l  % Start from 2 to connect the first point
%     disp(x(1,i-1:i));
%     plot(x(1,i), x(2,i), '-b', 'LineWidth', 2);  % Plot line between points
%     pause(0.01);  % Pause to create the animation effect
% end



%% 
%Particle filter previous code.


% % Kalman filter implementation
% 
% function [mu_t,sigma_t] = kalmanFilter(mu_tm1,sigma_tm1,zt)
% 
%     global At Ct Rt Qt
% 
%     mu_t_bar = At * mu_tm1;            % removed Bt * ut term
% 
%     sigma_t_bar = At * sigma_tm1 * At' + Rt;
% 
%     Kt = sigma_t_bar * Ct' * inv(Ct * sigma_t_bar * Ct' + Qt);
% 
%     mu_t = mu_t_bar + Kt * (zt - (Ct * mu_t_bar));
% 
%     ktct = Kt * Ct;
% 
%     sigma_t = (eye(size(ktct)) - ktct) * sigma_t_bar;
% 
% end
% 
% 
% % Time step 
% dt = 0.5;     % Seconds
% mu_tm1 = [path(1,1) 0 path(1,2) 0]';  % Known initial point. Zero initial velocities.
% sigma_tm1 = zeros(length(mu_tm1));    % Zero uncertainty due to known point.
% zt = [0 0]';                          % Initializing measurment vector zt.
% 
% 
% % Modeling state transition 
% global At Rt
% At = [1 dt 0 0;
%       0 1  0 0;
%       0 0 1 dt;
%       0 0 0  1];
% 
% % Process noise covariance -> Findout how to find this properly    
% tuneRt = 0.5;
% Rt = tuneRt * eye(length(mu_tm1));
% 
% % Modeling the measurement 
% global Ct Qt
% Ct = [1 0 0 0;
%       0 0 1 0];
% 
% tuneQt = 200;
% Qt = tuneQt * eye(length(zt));
% % Qt = [6.478 -0.372;-0.372 6.209];
% 
% 
% 
% % Prediction and Update using the measurements.
% kf_output = zeros(size(estimatedPath));      % Only use xt and yt state variables
%                                              % Velocities are not needed                                                  
% 
% for i=1:length(estimatedPath)
% 
%     zt = estimatedPath(i,:)';                          % Measurement
%     [mu_t,sigma_t] = kalmanFilter(mu_tm1,sigma_tm1,zt); 
%     kf_output(i,:) = [mu_t(1) mu_t(3)];  
%     mu_tm1= mu_t;
%     sigma_t = (sigma_t + sigma_t')/2;    % Divergence correction steps
%     sigma_tm1 = sigma_t;
% 
% end
% 
% showTagPath(kf_output,'kalman');
% legend('Location','northeast');
% hold off;
% 


% %% 
% 
% % Parameters
% N_particles = 1000; % Number of particles
% x_true = [0; 0]; % True position (for simulation)
% std_meas = 0.5; % Standard deviation of sensor measurements (x and y)
% N_steps = 100; % Number of time steps
% process_noise_std = 0.1; % Process noise standard deviation (x and y)
% 
% % Initialize particles and weights
% particles = [randn(2, N_particles) * 2]; % Random initial particles in 2D (x, y)
% weights = ones(1, N_particles) / N_particles; % Equal weights initially
% 
% % Simulation loop
% for t = 1:N_steps
%     % True movement (random walk for simulation purposes)
%     x_true = x_true + randn(2, 1) * process_noise_std;
% 
%     % Measurement (noisy measurement of the true position in 2D)
%     z = x_true + randn(2, 1) * std_meas;
% 
%     % 1. Prediction: Move particles with some noise
%     particles = particles + randn(2, N_particles) * process_noise_std;
% 
%     % 2. Update: Calculate weights based on measurement likelihood in 2D
%     for i = 1:N_particles
%         distance = norm(z - particles(:, i)); % 2D distance between particle and measurement
%         weights(i) = exp(-distance^2 / (2 * std_meas^2)); % Gaussian likelihood
%     end
%     weights = weights / sum(weights); % Normalize weights
% 
%     % 3. Resampling: Resample particles based on weights
%     indices = randsample(1:N_particles, N_particles, true, weights);
%     particles = particles(:, indices);
% 
%     % 4. Estimate: Compute weighted average of particles (x and y coordinates)
%     x_est = sum(particles .* weights, 2);
% 
%     % Display results
%     fprintf('Time step: %d, True Position: (%.2f, %.2f), Estimated Position: (%.2f, %.2f)\n', ...
%         t, x_true(1), x_true(2), x_est(1), x_est(2));
% 
%     % Visualization (optional)
%     plot(particles(1, :), particles(2, :), 'k.', 'MarkerSize', 5); hold on;
%     plot(x_true(1), x_true(2), 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g'); % True position
%     plot(x_est(1), x_est(2), 'ro', 'MarkerSize', 10); % Estimated position
%     legend('Particles', 'True Position', 'Estimated Position');
%     xlim([-5, 5]); ylim([-5, 5]); grid on; pause(0.1);
%     hold off;
% end



% Implementation using pre-measured values. 
load('Measurement_data\data_sq_5bs_20ds_10mp_30snr.mat');
showBaseStations(baseLocs);
showTagPath(path,'actual');
showTagPath(estimatedPath,'measured');
axis([-10 25 -10 25]);



dt = 0.5;     % Seconds
% Modeling state transition 
global At Qt Rt

At = [1 dt 0 0;
      0 1  0 0;
      0 0 1 dt;
      0 0 0  1];

% Process noise covariance -> Findout how to find this properly    
tuneRt = 25;
Rt = tuneRt * eye(4);


tuneQt = 5;
Qt = tuneQt * eye(2);



function [Xt,pt] = ptFilter(Xtm1,zt)

    global At Qt Rt

    M = length(Xtm1);   %Number of particles.
    Xbar_t = zeros(size(Xtm1));  %Initializing the particle set.
    Xt = Xbar_t;    
    W = zeros(1,M);     %Weights of each particle.
    
    for m=1:M

        %Prediction step
        xtm = At * [Xtm1(1,m) 0 Xtm1(2,m) 0]' + mvnrnd(zeros(1,4),Rt,1)';  %Its better to add the velocities too.
        xtm = [xtm(1) xtm(3)]';       %Current Particle
        
        %Correction step
        W(m) = mvnpdf(zt,xtm,Qt);
        Xbar_t(:,m) = xtm;   %Updating particle set before resampling

    end
    
    %Normalization of weights
    W = W/sum(W);
    [~,idx] = max(W);
    pt = Xbar_t(:,idx)';  % Best state estimate - Particle with highest weight.

    %Measure of Degeneracy - Effective sample size (Neff) (ESS)
    Neff = 1/(sum(W.^2));
    alpha = 0.5; %Threshold for ESS comparison

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
        %pt = mean(Xt,2)'; % Takes the mean of particles with equal weights (wi = 1/M)
        
    else
        Xt = Xbar_t;
        %pt = mean(Xt,2,Weights=W)';
        
    end

end




%Initial particle set generation
M = 1000;  %Number of total particles.

%Assume gaussian distribution around initial point.
initialPos = path(1,:);
sigma = 1 * eye(2) ;    %Tune the variances as we want.
init_particles =  mvnrnd(initialPos,sigma,M)'; % -10+35.*rand(2,M);
Xtm1 = init_particles;
Xt = zeros(size(Xtm1));


% estimatedPath = repmat(estimatedPath,10, 1); %Add this to repeat the motion several times
numofPoints = length(estimatedPath);
pfOutput = zeros(size(estimatedPath));

h_pf = plot(nan, nan, '.k');  % Initialize plot with an empty point
set(h_pf,'XData',Xtm1(1,:),'YData',Xtm1(2,:)); %Plotting initial particles
pause(2);

for i = 1:numofPoints
    zt = estimatedPath(i,:)'; 
    [Xt,pfOutput(i,:)] = ptFilter(Xtm1,zt);
    Xtm1 = Xt;
    
    set(h_pf,'XData',Xt(1,:),'YData',Xt(2,:));
    pause(0.1);
end

showTagPath(pfOutput,'filtered')
legend('Location','northeast');
hold off;



% %--------------Particle filter functionality check---------------------.
% 
% %Initial particle set generation
% M = 2;  %Number of total particles.
% 
% %Assume gaussian distribution around initial point.
% % initialPos = path(1,:);
% % sigma = 3 * eye(2) ; %Tune the variances as we want.
% 
% init_particles = [1 1;1.2 0.8]';
% 
% 
% % measurements = estimatedPath(1:2,:);
% measurements = [1 1.2;2 2.5];
% n = 2;
% Xtm1 = init_particles;
% Xt = zeros(size(Xtm1));
% 
% for i=1:n
% 
%     zt = measurements(i,:)';
%     Xt = ptFilter(Xtm1,zt);
% 
%     Xtm1 = Xt;
% 
% end


%% 

% Define the number of points
numPoints = 100;

% Generate data for the first plot (e.g., a sine wave)
x1 = linspace(0, 2*pi, numPoints);
y1 = sin(x1);

% Generate data for the second plot (e.g., a cosine wave)
y2 = cos(x1);

% Create the figure
figure;
hold on; % Hold on to plot multiple datasets

% Initialize two plot handles for updating
h1 = plot(x1(1), y1(1), 'r-', 'LineWidth', 2); % Red line for sine
h2 = plot(x1(1), y2(1), 'b-', 'LineWidth', 2); % Blue line for cosine

% Set axes limits
xlim([0 2*pi]);
ylim([-1.5 1.5]);

% Add a legend
legend('Sine Wave', 'Cosine Wave');

% Loop to animate the plots
for i = 1:numPoints
    % Update the data for each plot
    set(h1, 'YData', sin(x1(1:i)), 'XData', x1(1:i)); % Update sine
    set(h2, 'YData', cos(x1(1:i)), 'XData', x1(1:i)); % Update cosine
    
    % Pause for a moment to create animation effect
    pause(0.1);
end

hold off; % Release the hold




