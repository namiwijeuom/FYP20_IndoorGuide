impulseDataStream = [zeros(1,1000) 1 zeros(1,1000)]' ;

Rs = 2e9; % Sample rate in symbols per second (1 samples/s)
Ts = 1/Rs; % Sampling time in seconds

snr = 100;


ylim([-2 2]);
grid on;
hold on;

rxsignal = UwbMultipathChannel(impulseDataStream,10,5,true,100e-9,Rs,snr);
% rxsignal2 = UwbMultipathChannel2(impulseDataStream,10,3,true,100e-9,Rs);

timeForImpulseResponse = (0:Ts:(length(rxsignal)-1)*Ts)' ;
stem(timeForImpulseResponse,[impulseDataStream;zeros(length(rxsignal)-length(impulseDataStream),1)]);
stem(timeForImpulseResponse,abs(rxsignal));



% timeForImpulseResponse = (0:Ts:(length(rxsignal2)-1)*Ts)' ;
% figure
% stem(timeForImpulseResponse,rxsignal2);
% grid on;