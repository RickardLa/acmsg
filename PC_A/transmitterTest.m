%% Transmitter using 4-QAM
clc
clf
clear all
close all
profile on
 
% Parameters to edit
fc = 5000;                               % Carrier frequency [Hz]
N = 432;                                 % Number of bits
fs = 44000;                              % Sampling frequency [samples/s]
Rb = 440;                                % Bit rate [bit/s]
rollOff = 0.3;                           % Roll off factor for RRC-pulse
span = 2;                                % Truncation of pulse
const = [(1 + 1i) (1 - 1i) ...           % Constellation for 4-QAM. Divide by sqrt(2) for unit energy
    (-1 -1i) (-1 + 1i)]/sqrt(2);
preamble = [1 1 1 -1 -1 1 -1];
%preamble = [];

% Noise and synchronization errors for simulation
SNR = -10;                               % Signal-to-noise ratio [dB]
phiError = 0;                            % Add phase error
fcError = 0;                              % Add frequency error
tError = randi([1,100],1)                % Random time delay for frame synch
%tError = 0;
% Declare additional parameters
fsy = Rb/2;                              % Symbol frequency [symbols/s]
Tsy = 1/fsy;                             % Symbol time/period [s/symbols]
Ts = 1/fs;                               % Sampling time/period [s/sample]
fsfsy = fs/fsy;                          % Used for upsampling [samples/symbols]
pulse = rtrcpuls(rollOff,Tsy,fs,span);   % Generate pulse using rtrcpuls()

% Generate bitstream and map to constellation points
bitstream = randsrc(N,1,[0 1]);               % Generates column-vector with bits
message = buffer(bitstream,N/2);              % Buffers bitstream into data frames with length 2
messageIdx = bi2de(message, 'left-msb')+1;    % Convert data frames to decimal. Adding 1 for correct matrix-indexing
map = [zeros(1,tError) preamble const(messageIdx)];                      % Map each data frame to a constellation point

% Upsample map and convolve with RRC-pulse
mapUP = upsample(map,fsfsy);                  % Space the data fsfsy-apart to sample once per symbol
signalBase = conv(pulse,mapUP);               % Convolving generates a baseband signal containing real and imaginary parts

% Convert baseband-signal to passband-signal by modulation
t = (0:length(signalBase)-1)*Ts;                                % Signal contains samples. Multiplying by the sampling time gives the time of the signal
signalPass = signalBase.*cos(2*pi*(fc+fcError).*t+phiError);     % Baseband to passband
signalPass = signalPass/(max(abs(signalPass)));                 % Normalize signal
% Add noise to modulated signal and then transmit
signalNoise = awgn(signalPass, SNR, 'measured');
receiverTest(signalNoise,pulse)

