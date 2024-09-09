%% New code for Ranging with Multipath UWB channel
%--------------------------------------------------------------------------------------------

c = physconst('LightSpeed');    % Speed of light (m/s)
actualDistance = 20;             % In meters
% actualTprop = actualDistance/c; % In seconds
snr =20;                       % Signal-to-Noise ratio
symbolrate = 499.2e6;           % Symbol rate for HRP PHY
sps = 4;                       % Samples per symbol
ts = timescope( ...
    SampleRate=sps*symbolrate, ...
    ChannelNames={'Initiator','Responder'}, ...
    LayoutDimensions=[2 1], ...
    Name='SS-TWR');
ts.YLimits = [-0.25 0.25];
ts.ActiveDisplay = 2;
ts.YLimits = [-0.25 0.25];

N = 7;                           % Total number of multipaths in UWB channels
maxDelaySpread = 20e-9;         % Maximum delay spread in UWB channels
LOS = true;                      % Line-of-sight component

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

Rs = sp3Config.SampleRate ; 

% start initiator time at the start of transmission
initiatorView = transmitFrame; 


% Wireless Channel
% Filter the transmission frame through an UWB MultiPath channel and add propagation delay.
% Then, update timeline for both link endpoints.


receivedTransmitted = UwbMultipathChannel(transmitFrame,actualDistance,N,LOS,maxDelaySpread,Rs,snr);
% receivedTransmitted = real(receivedTransmitted);

% receivedTransmitted = real(receivedTransmitted);
% ts(transmitFrame,receivedTransmitted);
% scatterplot(transmitFrame(4:4:end));
% scatterplot(receivedTransmitted(4:4:end)); 

initiatorView = [initiatorView; zeros(length(receivedTransmitted)-length(initiatorView),1)];
responderView = receivedTransmitted;

 
% Reception at Responder
% At the responder side, detect the preamble of the 802.15.4z PHY frame,
% and then process the transmitted frame. Preamble detection consists of determining the 
% first instance of the preamble out of Nsync = PreambleDuration. Plot the initiator and 
% responder views on a timescope.

ind = lrwpanHRPFieldIndices(sp3Config); % length (start/end) of each field
sp3Preamble = sp3Wave(1:ind.SYNC(end)/sp3Config.PreambleDuration);

preamPos = helperFindFirstHRPPreamble( ...
    receivedTransmitted,sp3Preamble,sp3Config);


% Transmission from Responder
% Set the Treply time to the length of three SP3 frames to specify when to transmit the response frame.
% Set the first and last RMARKER sample indices on the responder side to be the beginning 
% of first post-SFD symbol and Treply samples later. After Treply samples, 
% transmit the response frame from the responder device.

Treply = 3*length(sp3Wave); % in samples

% Find RMARKERs at responder side
frameStart = 1+preamPos-ind.SYNC(end)/sp3Config.PreambleDuration;
sfdEnd = frameStart + ind.SYNC(end) + diff(ind.SFD);
RMARKER_R1 = sfdEnd+1;                                    
RMARKER_R2 = RMARKER_R1 + Treply;

% Transmit after Treply. Find how long the responder needs 
% to remain idle. (In samples)
idleResponderTime = Treply - diff(ind.STS)-1 - diff(ind.SHR)-1;
 


responderView = ...
     [responderView; zeros(idleResponderTime,1); ...
     responseFrame];

initiatorView = [initiatorView; zeros(idleResponderTime,1)];

% Wireless Channel
% Filter the transmission frame through an AWGN channel and add propagation delay. 
% Then, update timeline for both link endpoints.

receivedResponse = UwbMultipathChannel(responseFrame,actualDistance,N,LOS,maxDelaySpread,Rs,snr);
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
estimatedDistance = c*Tprop;                      % In meters

% This timescope illustrates the frame exchange as in Fig. 6-47a in [ 2 ] with X-axis 
% limit zoomed in to see the propagation delay between the transmitted and response frames.

reset(ts);
ts(initiatorView,responderView);
release(ts);

fprintf(['Actual distance = %d m.' ...
    '\nEstimated Distance = %0.2f m' ...
    '\nError = %0.3f m (%0.2f%%)\n'], ...
    actualDistance,estimatedDistance, ...
    estimatedDistance-actualDistance, ...
    100*(estimatedDistance-actualDistance)/actualDistance)


% ---------------------------------------------------------------------------------------------
