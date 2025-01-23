function estiDistance = ssTwr(NumOfSessions,Distance,N,HasLos,MaxDelaySpread,SNR)

% SSTWR Initiates Single-sided Two way ranging sessions.
%
%   estiDistance = ssTwr(NumOfSessions,Distance,N,HasLos,MaxDelaySpread,SNR)
%   This function takes given parameters and outputs the estimated distance 
%   between a transmitter and receiver.
%
% Inputs:
%   NumOfSessions  - Total number of Single sided two way ranging sessions between tx and rx.
%   Distance       - Actual distance between transmitter and receiver. (meters)
%   N              - Number of multipath effects.
%   HasLos         - Line-of-sight between tx and rx. (true/false)
%   MaxDelaySpread - Maximum delay spread between LOS path and longest path. (seconds)
%   SNR            - Signal to noise ratio (dB).
%
% Outputs:
%   estiDistance  - Estimated distance between tx and rx with multipath effects.
%
% Example:
%   estimatedDistance = ssTwr(1,10,5,true,100e-9,30);
%   
%   Number of ss-twr sessions = 1.
%   Distance between transmitter and receiver = 10 m.
%   Number of Multi paths = 5.
%   Line of sight between tx and rx = true.
%   Maximum delay spread = 100 ns.
%   Signal to noise ratio = 30dB.
%


    c = physconst('LightSpeed');    % Speed of light (m/s)

    sumOfDistances = 0;
    % Transmission from Initiator
    % Generate the waveform containing SP3 PHY frames (with no MAC frame/PSDU) to be transmitted between the devices.
    % Register the transmitted frame on the timeline of the initiator.
    
    sp3Config = lrwpanHRPConfig( ...
        Mode='HPRF', ...
        STSPacketConfiguration=3, ...
        PSDULength=0, ...
        Ranging=true);
    sp3Wave = lrwpanWaveformGenerator(zeros(0,1), sp3Config);
    [transmitFrame,responseFrame] = deal(sp3Wave);
    
    % start initiator time at the start of transmission
    initiatorView = transmitFrame; 
    
    
    % Wireless Channel
    % Filter the transmission frame through an UWB MultiPath channel and add propagation delay.
    % Then, update timeline for both link endpoints.
    
    % Multiple two-way-ranging sessions will happen. Total = "NumOfSessions"

    for i = 1:NumOfSessions
    
        receivedTransmitted = UwbMultipathChannel(transmitFrame,Distance,N,HasLos,MaxDelaySpread,sp3Config.SampleRate,SNR);
        % receivedTransmitted = real(receivedTransmitted);
        
        initiatorView = [initiatorView; zeros(length(receivedTransmitted)-length(initiatorView),1)];
        
        % Reception at Responder
        % At the responder side, detect the preamble of the 802.15.4z PHY frame,
        % and then process the transmitted frame. Preamble detection consists of determining the 
        % first instance of the preamble out of Nsync = PreambleDuration. Plot the initiator and 
        % responder views on a timescope.
        
        ind = lrwpanHRPFieldIndices(sp3Config); % length (start/end) of each field
        sp3Preamble = sp3Wave(1:ind.SYNC(end)/sp3Config.PreambleDuration);
        
        % preamPos = helperFindFirstHRPPreamble( ...
        %     receivedTransmitted,sp3Preamble,sp3Config);
        
        % % % % % ts(transmitFrame,receivedTransmitted);
        
        
        % Transmission from Responder
        % Set the Treply time to the length of three SP3 frames to specify when to transmit the response frame.
        % Set the first and last RMARKER sample indices on the responder side to be the beginning 
        % of first post-SFD symbol and Treply samples later. After Treply samples, 
        % transmit the response frame from the responder device.
        
        Treply = 3*length(sp3Wave); % in samples
        
        % Find RMARKERs at responder side
        % frameStart = 1+preamPos-ind.SYNC(end)/sp3Config.PreambleDuration;
        % sfdEnd = frameStart + ind.SYNC(end) + diff(ind.SFD);                                    
        
        % Transmit after Treply. Find how long the responder needs 
        % to remain idle. (In samples)
        idleResponderTime = Treply - diff(ind.STS)-1 - diff(ind.SHR)-1;
         
        initiatorView = [initiatorView; zeros(idleResponderTime,1)];
        
        % Wireless Channel
        % Filter the transmission frame through an AWGN channel and add propagation delay. 
        % Then, update timeline for both link endpoints.
        
        receivedResponse = UwbMultipathChannel(responseFrame,Distance,N,HasLos,MaxDelaySpread,sp3Config.SampleRate,SNR);
        % receivedResponse = real(receivedResponse);
        
        initiatorView = [initiatorView; receivedResponse];
        
        % Reception at Initiator
        % Back at the initiator side, detect the preamble of the 802.15.4z PHY frame,
        % and then process the transmitted frame.
        
        txFrameEnd = ind.STS(end);
        preamPos = helperFindFirstHRPPreamble( ...
            initiatorView(txFrameEnd+1:end),sp3Preamble,sp3Config);
        
        
        % Range Estimation
        % Estimate the propagation delay and the distance between two devices.
        % Set the first and last RMARKER sample indices on the initiator 
        % side to be the start of transmission (which is known at t=0) and the beginning of
        % first post-SFD symbol. Use the RMARKERs, Tround,
        % and Tprop to estimate the distance between initiator and responder.
        
        RMARKER_I1 = 1+ind.SFD(end);
        frameStart = 1+preamPos-ind.SYNC(end)/sp3Config.PreambleDuration;
        sfdEnd = txFrameEnd + frameStart + ind.SYNC(end) + diff(ind.SFD);
        RMARKER_I2 = sfdEnd+1;
        
        Tround = RMARKER_I2 - RMARKER_I1;                 % In samples
        Tprop = (Tround-Treply)/(2*sp3Config.SampleRate); % In seconds
        sumOfDistances = sumOfDistances + c*Tprop;        % In meters
    end

    estiDistance = sumOfDistances/NumOfSessions;          % In meters

end