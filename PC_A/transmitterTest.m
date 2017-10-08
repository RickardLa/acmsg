%% Transmitter using 4-QAM
clc
clf
clear all
close all

run('commonParameters.m')

% Noise and synchronization errors for simulation
SNR = -5;                                       % Signal-to-noise ratio in dB
phaseError = -2*pi.*rand(1,1);                  % Phase error [-2pi,2pi]
tError = randi([1,50],1);                       % Time delay [1,50]

% Generate bitstream amap to constellation points
bitstream = randsrc(N,1,[0 1]);               % Random data 
message = buffer(bitstream,N/2);              % Buffers bitstream into data frames with length 2
messageIdx = bi2de(message, 'left-msb')+1;    % Convert data frames to decimal. Adding 1 for correct matrix-indexing
dataMap = constQAM(messageIdx);               % Map each data frame to a constellation point
% Upsample map and convolve with RRC-pulse
map = [zeros(1,tError) preambleMap dataMap];
mapUP =upsample(map,fsfsy);                   % Space the data fsfsy-apart to sample once per symbol
signalBase = conv(pulse,mapUP);               % Convolving generates a baseband signal containing real and imaginary parts

% Convert baseband-signal to passband-signal by modulation
t = (0:length(signalBase)-1)*Ts;                                % Signal contains samples
signalPass = real(signalBase.*exp(-1i*2*pi*fc.*t));             % Baseband to passband
signalPass = signalPass.*exp(1i*phaseError);                    % Add phase error
signalPass = signalPass/(max(abs(signalPass)));                 % Normalize signal

% Add noise to modulated signal and then transmit
signalNoise = awgn(signalPass, SNR, 'measured');
receiverTest(signalNoise,bitstream)

