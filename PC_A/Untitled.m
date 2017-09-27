%%
clc
clf
clear all
close all

fc = 5000;
N = 432;
packet = randsrc(1,N,[0 1]);                             
fs = 22000;
Tsamp = 1/fs;
Rb = 440;
fsymb = Rb/2;
Tsymb = 1/fsymb;
fsfd = fs/fsymb;
alpha = 0.3;
span = 6;
constellation = [(1 + 1i) (1 - 1i) (-1 -1i) (-1 + 1i)]/sqrt(2); 
%scatterplot(constellation) 
%grid on                            
msg = buffer(packet,2)';
msgIndex = bi2de(msg, 'left-msb')'+1;
x = constellation(msgIndex);
x_upsample = upsample(x,fsfd);


pulse = rtrcpuls(alpha,Tsymb,fs,span);
s = conv(pulse,x_upsample);

fer = 0;
ter = 0;


t = (0:length(s)-1)*(Tsamp+ter);
tx_signal = s.*exp(-1i*2*pi*(fc+fer).*t); % Carrier Modulation/Upconversion 
tx_signal = tx_signal/max(abs(tx_signal));          % Limit the max amplitude to 1 to prevent clipping of waveforms

 figure
 plot(tx_signal)
% figure;
% pwelch(tx_signal,200,[],[],fs,'power')   % Satisfies blue mask! 156Hz @ -10dB

SNRdB = -10; %decide noise level
y = awgn(tx_signal, SNRdB, 'measured'); % add noise

receiverTest(y)


% figure
% subplot(2,1,1)
% plot(real(y(length(MF):end)));
% title('Before MF')
% subplot(2,1,2);
% plot(real(MF_output));
% title('After MF')
% hold on; 
% stem(fsfd*(0:length(rx_vec)-1),real(rx_vec));







