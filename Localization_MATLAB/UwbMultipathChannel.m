function channelOutput = UwbMultipathChannel(Signal,Distance,N,HasLos,MaxDelaySpread,SampleRate,SNR)
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here
    %N = Number of taps
    
    c = physconst('LightSpeed');
    Ts = 1/SampleRate; % Sampling period
    tau0 = Distance/c; % Delay for the LOS component in seconds (e.g., 0 means no delay)
    a0 = 1; % LOS component
    
    
    %tau = (tau0:MaxDelaySpread/N:tau0+MaxDelaySpread); % Delays in seconds, Gap between each delay MaxDelaySpread/N
    if N > 0
        %tau = tau0 + sort(rand(1, N) * MaxDelaySpread);
        tau = (tau0+MaxDelaySpread/N:MaxDelaySpread/N:tau0+MaxDelaySpread);
        maxDelaySamples = round(max(tau/Ts));
        ci = (randn(1, N) + 1i*randn(1, N))/sqrt(2); % Rayleigh fading for each tap
        
        % Initialize the channel output
        channelOutput = zeros(length(Signal)+maxDelaySamples,1);
        
        % Convolve with each path
        for i = 1:N
            delayedSignal = [zeros(round(tau(i)/Ts),1) ; Signal]; % Ts is the sample time
            % Adjust length to match channelOutput
            delayedSignal = [delayedSignal ; zeros(length(channelOutput) - length(delayedSignal),1)]; %#ok<AGROW>
            channelOutput = channelOutput + ci(i)*delayedSignal;
        end
    else
        channelOutput = zeros(length(Signal)+round(tau0/Ts),1);
    end
    
    % Add the LOS component with delay tau0
    if HasLos
        losComponent = [zeros(round(tau0/Ts),1) ; Signal]; % Delay by tau0
        % Adjust length to match channelOutput
        losComponent = [losComponent ; zeros(length(channelOutput) - length(losComponent),1)];
        channelOutput = channelOutput + a0 * losComponent;
    end
    channelOutput = awgn(channelOutput,SNR);

end

